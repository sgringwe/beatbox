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

public class LastFM.TopArtistSongs : Object {
	static const int MAX_RESULTS = 15;
	
	BeatBox.Media _base;
	bool working;
	
	HashTable<int, BeatBox.Media> songs;
	
	BeatBox.Media toAdd;
	
	public signal void top_artist_songs_retrieved(HashTable<int, BeatBox.Media> songs);
	
	public class TopArtistSongs() {
		working = false;
	}
	
	public void queryForTopArtistSongs(BeatBox.Media s) {
		_base = s;
		
		if(!working) {
			working = true;
			
			try {
				new Thread<void*>.try (null, top_artist_songs_thread_function);
			}
			catch (Error err) {
				warning("ERROR: Could not create similar thread: %s", err.message);
			}
		}
	}
	
	private void* top_artist_songs_thread_function () {	
		songs = new HashTable<int, BeatBox.Media>(null, null);
		
		getTopArtistTracks(_base.artist);
		
		for(int i = 0; i < songs.size(); ++i) {
			var ext = songs.get(i);
			var match = BeatBox.App.library.media_from_name(ext.title, ext.artist);
			if(match != null)
				songs.set(i, match);
		}
		
		Idle.add( () => {
			top_artist_songs_retrieved(songs);
			return false;
		});
		
		working = false;
		
		return null;	
    }
	
	/** Gets similar medias
	 * @param artist The artist of media to get similar to
	 * @param title The title of media to get similar to
	 * @return The medias that are similar
	 */
	void getTopArtistTracks(string artist) {
		var artist_fixed = BeatBox.LastFMCore.fix_for_url(artist);
		var url = "http://ws.audioscrobbler.com/2.0/?method=artist.gettoptracks&artist=" + artist_fixed + "&api_key=" + BeatBox.LastFMCore.api;
		
		Soup.SessionSync session = new Soup.SessionSync();
		Soup.Message message = new Soup.Message ("GET", url);
		
		session.timeout = 30;// after 30 seconds, give up
		
		/* send the HTTP request */
		session.send_message(message);
		
		Xml.Doc* doc = Xml.Parser.parse_memory((string)message.response_body.data, (int)message.response_body.length);
		
		if(doc == null)
			GLib.message("Could not load top artist songs information for %s", artist);
		else if(doc->get_root_element() == null)
			GLib.message("Oddly, similar artist information was invalid");
		else {
			//message("Getting similar tracks with %s...", url);
			toAdd = null;
			
			parse_top_artist_tracks_nodes(doc->get_root_element(), "");
		}
		
		delete doc;
	}
	
	void parse_top_artist_tracks_nodes(Xml.Node* node, string parent) {
		if(songs.size() > MAX_RESULTS)
			return;
							
		Xml.Node* iter;
		for (iter = node->children; iter != null; iter = iter->next) {
            if (iter->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            string node_name = iter->name;
            
            if(parent == "toptracks") {
				if(node_name == "track") {
					BeatBox.Song m = new BeatBox.Song("");
					m.isTemporary = true;
					
					Xml.Node* track_iter;
					for(track_iter = iter->children; track_iter != null; track_iter = track_iter->next) {
						string track_node_name = track_iter->name;
						string track_node_content = track_iter->get_content ();
						
						if(track_node_name == "name")
							m.title = track_node_content;
						else if(track_node_name == "duration")
							m.length = int.parse(track_node_content);
						else if(track_node_name == "url")
							m.lastfm_url = track_node_content;
					}
					
					m.album_artist = _base.album_artist;
					m.artist = _base.artist;
					
					songs.set((int)songs.size(), m);
					if(songs.size() > MAX_RESULTS)
						return;
				}
			}
			
			parse_top_artist_tracks_nodes(iter, parent+node_name);
		}
		
		delete iter;
	}
}
