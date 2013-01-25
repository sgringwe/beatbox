/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

using Gee;
using Xml;

public class Store.store : GLib.Object {
	public static string api = "http://api.7digital.com/1.2/";
	public static string key = "7dtjyu9qbu";
	public static string country = "US";
	static string session_key;
	
	public static StoreView view;
	
	public store() {
		
	}
	
	// TODO: Fix the fact that this is just duplicate code from last.fm
	// Caller must free node
	public static Xml.Node* query(string type, string method, HashMap<string, string> params, bool requires_sk) {
		if(requires_sk && BeatBox.String.is_empty(session_key)) {
			warning("User must authenticate before calling method %s", params.get("method"));
			return null;
		}
		
		// use sync call with yield and idle signal handler
		// generate the md5 by sorting the params, appending them 1 by 1, and then adding the secret
		string url = api + method;
		string md5_arg = "";
		var headers = new Soup.MessageHeaders(Soup.MessageHeadersType.REQUEST);
		
		// Add the api key, country and if necessary the session key
		params.set("oauth_consumer_key", key);
		params.set("country", country); // TODO: Fixme
		if(requires_sk) {
			params.set("sk", "TODO");
		}
		
		// Convert the params into a sorted list
		generate_url_md5_headers(params, ref url, ref md5_arg, ref headers);
		
		stdout.printf("parsing %s\n", url);
		
		var session = new Soup.SessionSync();
		var message = new Soup.Message (type, url);
		message.request_headers = headers;

		session.send_message(message);
		
		Xml.Node* node = Store.XMLParser.getRootNode(message);
		
		return node;
	}
	
	// Since we will unlikely have much more than 5 params, simple selection sort is fine.
	static void generate_url_md5_headers(HashMap<string, string> untouched_params, ref string? url, ref string? md5, ref Soup.MessageHeaders? headers) {
		var params = new HashMap<string, string>();
		
		// Create a copy of hashmap so we can remove from it
		foreach(var entry in untouched_params.entries) {
			params.set(entry.key, entry.value);
		}
		
		int count = params.size;
		for(int i = 0; i < count; ++i) {
			Map.Entry<string, string>? lowest = null;
			
			foreach(var entry in params.entries) {
				if(lowest == null || lowest.key > entry.key) {
					lowest = entry;
				}
			}
			
			if(headers != null)		headers.append(lowest.key, lowest.value);
			if(url != null)			url += ((i == 0) ? "?" : "&") + lowest.key + "=" + lowest.value;
			if(md5 != null)			md5 += lowest.key + lowest.value;
			
			params.unset(lowest.key);
		}
	}
	
	// TODO: Consistent params
	public static Release? getRelease(int id, int imagesize) {
		var params = new HashMap<string, string>();
		params.set("releaseid", id.to_string());
		params.set("imagesize", imagesize.to_string());
		
		Xml.Node* node = query("GET", "release/details", params, false);
		if(node == null)
			return null;
		
		var release = XMLParser.parseRelease(node);
		
		delete node;
		
		return release;
	}
	
	public static Artist? getArtist(int id) {
		var params = new HashMap<string, string>();
		params.set("artistid", id.to_string());
		
		Xml.Node* node = query("GET", "artist/details", params, false);
		if(node == null)
			return null;
		
		var artist = XMLParser.parseArtist(node);
		
		delete node;
		
		return artist;
	}
	
	/** Search methods
	 * simply return objects matching the search string
	 * @search the string to search
	 * @sort Either name, popularity, or score.
	*/
	public Collection<Artist> searchArtists(int page, int pageSize, string search, string? sort) {
		var rv = new LinkedList<Artist>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("q", search);
		if(sort != null)	params.set("sort", sort);
		
		Xml.Node* node = query("GET", "artist/search", params, false);
		if(node == null)
			return rv;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "searchResult") {
				Artist toAdd = new Artist(0);
				double score = 0.0;
				
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "score")
						score = double.parse(subIter->get_content());
					else if(subIter->name == "artist")
						toAdd = Store.XMLParser.parseArtist(subIter);
				}
				
				if(toAdd != null) {
					toAdd.search_score = score;
					toAdd.search_type = "artist";
					rv.add(toAdd);
				}
			}
		}
		
		delete node;
		
		return rv;
	}
	
	public LinkedList<Store.Release> searchReleases(int page, int pageSize, string search, string? sort) {
		var rv = new LinkedList<Store.Release>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("q", search);
		if(sort != null)	params.set("sort", sort);
		
		Xml.Node* node = query("GET", "release/search", params, false);
		if(node == null)
			return rv;
        
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "searchResult") {
				Store.Release toAdd = new Store.Release(0);
				
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "release")
						toAdd = Store.XMLParser.parseRelease(subIter);
				}
				
				if(toAdd != null) {
					toAdd.search_type = "release";
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	public LinkedList<Store.Track> searchTracks(int page, int pageSize, string search, string? sort) {
		var rv = new LinkedList<Store.Track>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("q", search);
		if(sort != null)	params.set("sort", sort);
		
		Xml.Node* node = query("GET", "track/search", params, false);
		if(node == null)
			return rv;
        
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "searchResult") {
				Store.Track toAdd = new Store.Track(0);
				
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "track")
						toAdd = Store.XMLParser.parseTrack(subIter);
				}
				
				if(toAdd != null) {
					toAdd.search_type = "track";
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	
	/** Chart methods
	 * Return current top x objects
	 * @period Either week, month, or year
	 * @toDate The last day to include, in YYYYDDMM format
	 * @tag an optional tag (rock, pop). If null, ignored
	 * 
	*/
	public LinkedList<Store.Artist> topArtistsForPeriod(int page, int pageSize, string period, string? toDate) {
		var rv = new LinkedList<Store.Artist>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("period", period);
		if(toDate != null)	params.set("todate", toDate);
		
		Xml.Node* node = query("GET", "artist/chart", params, false);
		if(node == null)
			return rv;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "chartItem") {
				Store.Artist toAdd = new Store.Artist(0);
				int position = 0;
				string change = "";
				
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "position")
						position = int.parse(subIter->get_content());
					else if(subIter->name == "change")
						change = subIter->get_content();
					else if(subIter->name == "artist")
						toAdd = Store.XMLParser.parseArtist(subIter);
				}
				
				if(toAdd != null) {
					toAdd.search_rank = position;
					toAdd.search_change = change;
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	LinkedList<Store.Artist> topArtistsForTag(int page, int pageSize, string tags, string? period) {
		var rv = new LinkedList<Artist>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("tags", tags);
		if(period != null)	params.set("period", period);
		
		Xml.Node* node = query("GET", "artist/bytag/top", params, false);
		if(node == null)
			return rv;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "taggedItem") {
				Store.Artist toAdd = new Store.Artist(0);
				
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "artist")
						toAdd = Store.XMLParser.parseArtist(subIter);
				}
				
				if(toAdd != null) {
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	//"&imagesize=200" + "&type=album" + "&sort=popularity";
	public LinkedList<Store.Release> topReleasesForPeriod(int page, int pageSize, string period, string? toDate, int imagesize) {
		var rv = new LinkedList<Store.Release>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("period", period);
		params.set("imagesize", imagesize.to_string());
		if(toDate != null)		params.set("todate", toDate);
		
		Xml.Node* node = query("GET", "release/chart", params, false);
		if(node == null)
			return rv;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "chartItem") {
				Store.Release toAdd = new Store.Release(0);
				int position = 0;
				string change = "";
			
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "position")
						position = int.parse(subIter->get_content());
					else if(subIter->name == "change")
						change = subIter->get_content();
					else if(subIter->name == "release")
						toAdd = Store.XMLParser.parseRelease(subIter);
				}
				
				if(toAdd != null) {
					toAdd.search_type = "release";
					toAdd.search_rank = position;
					toAdd.search_change = change;
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	public LinkedList<Store.Release> topReleasesForTags(int page, int pageSize, string tags, string? period) {
		var rv = new LinkedList<Store.Release>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("tags", tags);
		if(period != null)	params.set("period", period);
		
		Xml.Node* node = query("GET", "release/bytag/top", params, false);
		if(node == null)
			return rv;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "taggedItem") {
				Store.Release toAdd = new Store.Release(0);
			
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "release")
						toAdd = Store.XMLParser.parseRelease(subIter);
				}
				
				if(toAdd != null) {
					toAdd.search_type = "release";
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	public LinkedList<Store.Track> topTracksForPeriod(int page, int pageSize, string period, string? toDate) {
		var rv = new LinkedList<Store.Track>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("period", period);
		if(toDate != null)		params.set("todate", toDate);
		
		Xml.Node* node = query("GET", "track/chart", params, false);
		if(node == null)
			return rv;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "chartItem") {
				Store.Track toAdd = new Store.Track(0);
				int position = 0;
				string change = "";
				
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "position")
						position = int.parse(subIter->get_content());
					else if(subIter->name == "change")
						change = subIter->get_content();
					else if(subIter->name == "track")
						toAdd = Store.XMLParser.parseTrack(subIter);
				}
				
				if(toAdd != null) {
					toAdd.search_change = change;
					toAdd.search_rank = position;
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	/** Get releases of certain timeframe
	 * @fromDate the first day in YYYYMMDD format. Defaults today
	 * @toDate the last day in YYYYMMDD format. Defaults today
	*/
	public LinkedList<Store.Release> getReleasesInRange(int page, int pageSize, string? fromDate, string? toDate) {
		var rv = new LinkedList<Store.Release>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		if(fromDate != null)	params.set("todate", fromDate);
		if(toDate != null)		params.set("todate", toDate);
		
		Xml.Node* node = query("GET", "release/bydate", params, false);
		if(node == null)
			return rv;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "release") {
				Store.Release toAdd = Store.XMLParser.parseRelease(iter);
				
				if(toAdd != null)
					rv.add(toAdd);
			}
		}
		
		return rv;
	}
	
	/** Returns releases matching all tag(s), starting with most recent
	 * @tags One or more tags to match
	 * 
	*/
	public LinkedList<Store.Release> newReleasesByTag(int page, int pageSize, string tags) {
		var rv = new LinkedList<Store.Release>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("tags", tags);
		
		Xml.Node* node = query("GET", "release/bytag/new", params, false);
		if(node == null)
			return rv;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "taggedItem") {
				Store.Release toAdd = new Store.Release(0);
				
				for(Xml.Node* subIter = iter->children; subIter != null; subIter = subIter->next) {
					if(subIter->name == "release")
						toAdd = Store.XMLParser.parseRelease(subIter);
				}
				
				if(toAdd != null) {
					toAdd.search_type = "release";
					rv.add(toAdd);
				}
			}
		}
		
		return rv;
	}
	
	/** Helper to parse uri images into pixbufs from store **/
	public static Gdk.Pixbuf? getPixbuf(string url, int width, int height) {
		Gdk.Pixbuf rv; 
		
		if(url == null || url == "") {
			return null;
		}
		
		File file = File.new_for_uri(url);
		FileInputStream filestream;
		
		try {
			filestream = file.read(null);
			rv = new Gdk.Pixbuf.from_stream_at_scale(filestream, width, height, true, null);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not fetch album art from %s: %s\n", url, err.message);
			rv = null;
		}
		
		return rv;
	}
}
