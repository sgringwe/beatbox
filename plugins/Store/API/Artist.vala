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

public class Store.Artist : GLib.Object, Store.SearchResult {
	public int artistID;
	public string name;
	public string sortName;
	public string appearsAs;
	public string imagePath;
	public string url;
	public double popularity;
	public Gdk.Pixbuf image;
	
	public string search_type { get; set; }
	public string search_change { get; set; }
	public int search_rank { get; set; }
	public double search_score { get; set; }
	
	public signal void artist_fetched();
	
	/* Gets all the details of the artist */
	public Artist(int id) {
		artistID = id;
	}
	
	public LinkedList<Store.Release>? getReleases(int page, int pageSize, string? type, int imagesize) {
		var rv = new LinkedList<Store.Release>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("artistid", artistID.to_string());
		params.set("imagesize", imagesize.to_string());
		if(type != null)	params.set("type", type);
		
		Xml.Node* node = Store.store.query("GET", "artist/releases", params, false);
		if(node == null)
			return rv;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "release") {
				Store.Release toAdd = Store.XMLParser.parseRelease(iter);
				
				if(toAdd != null) {
					rv.add(toAdd);
				}
			}
		}
		
		delete node;
		
		return rv;
	}
	
	public LinkedList<Store.Artist>? getSimilar(int page, int pageSize) {
		var rv = new LinkedList<Store.Artist>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("artistid", artistID.to_string());
		
		Xml.Node* node = Store.store.query("GET", "artist/similar", params, false);
		if(node == null)
			return rv;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "artist") {
				Store.Artist toAdd = Store.XMLParser.parseArtist(iter);
				
				if(toAdd != null)
					rv.add(toAdd);
			}
		}
		
		delete node;
		
		return rv;
	}
	
	public LinkedList<Store.Track> getTopTracks(int page, int max) {
		var rv = new LinkedList<Store.Track>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", "100");
		params.set("q", name);
		
		Xml.Node* node = Store.store.query("GET", "track/search", params, false);
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
				
				if(toAdd != null && toAdd.store_artist.name == name) {
					toAdd.search_type = "track";
					toAdd.search_rank = rv.size;
					rv.add(toAdd);
					
					if(rv.size >= max)
						return rv;
				}
			}
		}
		
		delete node;
		
		return rv;
	}
	
	public LinkedList<Store.Tag> getTags(int page, int pageSize) {
		var rv = new LinkedList<Store.Tag>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("artistid", artistID.to_string());
		
		Xml.Node* node = Store.store.query("GET", "artist/tags", params, false);
		if(node == null)
			return rv;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "tag") {
				Store.Tag toAdd = Store.XMLParser.parseTag(iter);
				
				if(toAdd != null)
					rv.add(toAdd);
			}
		}
		
		delete node;
		
		return rv;
	}
	
	
}
