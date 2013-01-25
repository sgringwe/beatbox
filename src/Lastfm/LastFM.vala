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
 * 
 * The BeatBox project hereby grant permission for non-gpl compatible GStreamer
 * plugins to be used and distributed together with GStreamer and BeatBox. This
 * permission is above and beyond the permissions granted by the GPL license
 * BeatBox is covered by.
 */

using Gee;

public class BeatBox.LastFMCore : GLib.Object, BeatBox.LastFMInterface {
	/** NOTICE: These API keys and secrets are unique to BeatBox and BeatBox
	 * only. To get your own, FREE key go to http://www.last.fm/api/account */
	public const string api = "a40ea1720028bd40c66b17d7146b3f3b";
	public const string secret = "92ba5023f6868e680a3352c71e21243d";
	
	public const string HTTP_BASE = "http://ws.audioscrobbler.com/2.0/";
	public const string HTTPS_BASE = "https://ws.audioscrobbler.com/2.0/";
	
	// Mostly conveniences
	public string session_key {
		get { return BeatBox.App.settings.lastfm.session_key; }
		set { BeatBox.App.settings.lastfm.session_key = value; }
	}
	public bool is_subscriber {
		get { return BeatBox.App.settings.lastfm.is_subscriber; }
		set { BeatBox.App.settings.lastfm.is_subscriber = value; }
	}
	public string username {
		get { return BeatBox.App.settings.lastfm.username; }
		set { BeatBox.App.settings.lastfm.username = value; }
	}
	
	LastFM.SimilarMedias similarMedias;
	LastFM.TopArtistSongs topArtistSongs;
	LastFM.TopArtistAlbums topArtistAlbums;
	
	public LastFMCore() {
		similarMedias = new LastFM.SimilarMedias();
		topArtistSongs = new LastFM.TopArtistSongs();
		topArtistAlbums = new LastFM.TopArtistAlbums();
		
		similarMedias.similar_retrieved.connect(similar_retrieved_signal);
		topArtistSongs.top_artist_songs_retrieved.connect(top_artist_songs_retrieved_signal);
		topArtistAlbums.top_artist_albums_retrieved.connect(top_artist_albums_retrieved_signal);
	}
	
	/** Last.FM Api functions **/
	// for now, assume always use https
	public void query(string type, HashMap<string, string> params, bool requires_sk, Soup.SessionCallback call_back) {
		if(requires_sk && BeatBox.String.is_empty(session_key)) {
			warning("User must authenticate before calling method %s", params.get("method"));
			return;
		}
		
		try {
			new Thread<void*>.try (null, () => {
				// use sync call with yield and idle signal handler
				// generate the md5 by sorting the params, appending them 1 by 1, and then adding the secret
				string url = HTTPS_BASE;
				string md5_arg = "";
				var headers = new Soup.MessageHeaders(Soup.MessageHeadersType.REQUEST);
				
				// Add the api key and session key
				params.set("api_key", api);
				if(requires_sk) {
					params.set("sk", session_key);
				}
				
				// Convert the params into a sorted list
				generate_url_md5_headers(params, ref url, ref md5_arg, ref headers);
				md5_arg += secret;
				
				string md5_string = generate_md5(md5_arg);
				params.set("api_sig", md5_string);
				
				// Now generate params and headers with the api_sig
				url = HTTPS_BASE;
				headers = new Soup.MessageHeaders(Soup.MessageHeadersType.REQUEST);
				generate_url_md5_headers(params, ref url, ref md5_arg, ref headers);
				
				var session = new Soup.SessionSync();
				var message = new Soup.Message (type, url);
				message.request_headers = headers;
		
				session.send_message(message);
                
                call_back(session, message);
                
                return null;
			});
		} catch(Error err) {}
	}
	
	// Since we will unlikely have much more than 5 params, simple selection sort is fine.
	void generate_url_md5_headers(HashMap<string, string> untouched_params, ref string? url, ref string? md5, ref Soup.MessageHeaders? headers) {
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
	
	public static string fix_for_url (string fix) {
		return Uri.escape_string (fix, "", false);
	}
	
	public string generate_md5(string text) {
		return Checksum.compute_for_string(ChecksumType.MD5, text, text.length);
	}
	
	public void authenticate_user(string username, string password) {
		var params = new HashMap<string, string>();
		params.set("method", "auth.getMobileSession");
		params.set("username", username);
		params.set("password", password);
		
		query("POST", params, false, (sess, msg) => {
			string user = "";
			string key = "";
			bool subsc = false;;
			
			Xml.Doc* doc = Xml.Parser.parse_memory((string)msg.response_body.data, (int)msg.response_body.length);
			if(doc == null) return;
			
			Xml.Node* root = doc->get_root_element();
			if(root == null) return;
			
			for (Xml.Node* iter = root->children; iter != null; iter = iter->next) {
				if(iter->name == "session") {
					for(Xml.Node* n = iter->children; n != null; n = n->next) {
						if(n->name == "key") {
							key = n->get_content();
						}
						else if(n->name == "subscriber") {
							subsc = int.parse(n->get_content()) == 1;
						}
						else if(n->name == "name") {
							user = n->get_content();
						}
					}
				}
			}
			
			delete doc;
			
			bool success = false;
			if(!BeatBox.String.is_empty(key)) {
				App.info.lastfm.session_key = key;
				App.info.lastfm.is_subscriber = subsc;
				App.info.lastfm.username = user;
				
				success = true;
			}
			
			Idle.add( () => { App.info.lastfm.login_returned(success); return false; });
		});
	}
	
	public void logout_user() {
		session_key = "";
		username = "";
		is_subscriber = false;
		
		logged_out();
	}
	
	public void love_track(string title, string artist) {
		var params = new HashMap<string, string>();
		params.set("method", "track.love");
		params.set("artist", artist);
		params.set("track", title);
		
		query("POST", params, true, (sess, msg) => {
			
		});
	}
	
	public void ban_track(string title, string artist) {
		var params = new HashMap<string, string>();
		params.set("method", "track.ban");
		params.set("artist", artist);
		params.set("track", title);
		
		query("POST", params, true, (sess, msg) => {
			
		});
	}
	
	/** Update's the user's currently playing track on last.fm
	 * 
	 */
	public void post_now_playing() {
		if(!BeatBox.App.playback.media_active)
			return;
		
		var artist = BeatBox.App.playback.current_media.artist;
		var title = BeatBox.App.playback.current_media.title;
		var album_artist = BeatBox.App.playback.current_media.album_artist;
		var album = BeatBox.App.playback.current_media.album;
		
		var params = new HashMap<string, string>();
		params.set("method", "track.updateNowPlaying");
		params.set("track", title);
		params.set("artist", artist);
		params.set("albumArtist", album_artist);
		params.set("album", album);
		params.set("duration", BeatBox.App.playback.current_media.length.to_string());
		
		query("POST", params, true, (sess, msg) => {
			// TODO: Use corrections. Be careful though, because 
			// corrections should not be used in the scrobble() POST.
			debug("Now playing Message length: %lld\n%s\n",
                   msg.response_body.length,
                   msg.response_body.data);
		});
	}
	
	/**
	 * Scrobbles the currently playing track to last.fm
	 */
	// TODO: Set the 'chosenByUser' param to 0 for radio, etc.
	// See http://www.last.fm/api/scrobbling
	public void scrobble() {
		if(!BeatBox.App.playback.media_active)
			return;
		
		var timestamp = (int)time_t();
		var artist = BeatBox.App.playback.current_media.artist;
		var title = BeatBox.App.playback.current_media.title;
		var album_artist = BeatBox.App.playback.current_media.album_artist;
		var album = BeatBox.App.playback.current_media.album;
		
		var params = new HashMap<string, string>();
		params.set("method", "track.scrobble");
		params.set("track", title);
		params.set("artist", artist);
		params.set("albumArtist", album_artist);
		params.set("album", album);
		params.set("timestamp", timestamp.to_string());
		
		query("POST", params, true, (sess, msg) => {
			// TODO: Use the corrections returned
		});
	}
	
	public void fetch_current_similar_songs() {
		similarMedias.getSimilarTracks(BeatBox.App.playback.current_media);
	}
	
	void similar_retrieved_signal(Gee.LinkedList<BeatBox.Media> similarDos, Gee.LinkedList<BeatBox.Media> similarDont) {
		similar_retrieved(similarDos, similarDont);
	}
	
	public void fetch_top_artist_songs() {
		topArtistSongs.queryForTopArtistSongs(BeatBox.App.playback.current_media);
	}
	
	void top_artist_songs_retrieved_signal(HashTable<int, BeatBox.Media> songs) {
		top_artist_songs_retrieved(songs);
	}
	
	public void fetch_top_artist_albums() {
		topArtistAlbums.queryForTopArtistAlbums(BeatBox.App.playback.current_media);
	}
	
	void top_artist_albums_retrieved_signal(HashTable<int, BeatBox.ExternalAlbum> albums) {
		top_artist_albums_retrieved(albums);
	}
}
