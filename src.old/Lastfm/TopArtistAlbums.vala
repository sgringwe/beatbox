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

public class LastFM.TopArtistAlbums : Object {
	static const int MAX_RESULTS = 5;
	
	BeatBox.Media _base;
	bool working;
	
	HashTable<int, BeatBox.ExternalAlbum> albums;
	
	BeatBox.ExternalAlbum toAdd;
	
	public signal void top_artist_albums_retrieved(HashTable<int, BeatBox.ExternalAlbum> albums);
	
	public class TopArtistAlbums() {
		working = false;
	}
	
	public void queryForTopArtistAlbums(BeatBox.Media s) {
		_base = s;
		
		if(!working) {
			working = true;
			
			try {
				new Thread<void*>.try (null, top_artist_albums_thread_function);
			}
			catch (Error err) {
				warning ("ERROR: Could not create top artist albums thread: %s", err.message);
			}
		}
	}
	
	void* top_artist_albums_thread_function () {	
		albums = new HashTable<int, BeatBox.ExternalAlbum>(null, null);
		
		getTopArtistAlbums(_base.artist);
		
		Idle.add( () => {
			load_pixbufs.begin();
			top_artist_albums_retrieved(albums);
			return false;
		});
		
		working = false;
		
		return null;	
    }
    
    async void load_pixbufs() {
		foreach(var album in albums.get_values()) {
			uri_to_pixbuf(album);
		}
	}
	
	async void uri_to_pixbuf(BeatBox.ExternalAlbum album) {
		GLib.File file = GLib.File.new_for_uri(album.pixbuf_url);
		if(file == null) {
			message ("Could not read image_uri as file");
			return;
		}
		
		FileInputStream filestream;
		Gdk.Pixbuf? pix = null;
		
		/*try {
			filestream = yield file.read_async();
			pix = yield new Gdk.Pixbuf.from_stream_at_scale_async(filestream, -1, BeatBox.Icons.ALBUM_VIEW_IMAGE_SIZE, true);
		} catch(GLib.Error err) {
			warning("Failed to save album art locally from %s: %s", album.pixbuf_url, err.message);
		}*/
		
		if(pix != null) {
			album.pixbuf = BeatBox.App.covers.add_shadow_to_album_art(pix);
		}
	}
	
	void getTopArtistAlbums(string artist) {
		var artist_fixed = BeatBox.LastFMCore.fix_for_url(artist);
		var url = "http://ws.audioscrobbler.com/2.0/?method=artist.gettopalbums&artist=" + artist_fixed + "&api_key=" + BeatBox.LastFMCore.api;
		
		Soup.SessionSync session = new Soup.SessionSync();
		Soup.Message message = new Soup.Message ("GET", url);
		
		session.timeout = 30;// after 30 seconds, give up
		
		/* send the HTTP request */
		session.send_message(message);
		
		Xml.Doc* doc = Xml.Parser.parse_memory((string)message.response_body.data, (int)message.response_body.length);
		
		if(doc == null)
			GLib.message("Could not load top artist albums information for %s", artist);
		else if(doc->get_root_element() == null)
			GLib.message("Oddly, top artist albums information was invalid");
		else {
			//GLib.message("Getting top artist albums with %s...", url);
			toAdd = null;
			
			parse_top_artist_albums_nodes(doc->get_root_element(), "");
		}
		
		delete doc;
	}
	
	void parse_top_artist_albums_nodes(Xml.Node* node, string parent) {
		if(albums.size() > MAX_RESULTS)
			return;
							
		Xml.Node* iter;
		for (iter = node->children; iter != null; iter = iter->next) {
            if (iter->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            string node_name = iter->name;
            
            if(parent == "topalbums") {
				if(node_name == "album") {
					BeatBox.ExternalAlbum a = new BeatBox.ExternalAlbum(_base.album_artist, "", false);
					
					Xml.Node* album_iter;
					for(album_iter = iter->children; album_iter != null; album_iter = album_iter->next) {
						string album_node_name = album_iter->name;
						string album_node_content = album_iter->get_content ();
						
						if(album_node_name == "name")
							a.album = album_node_content;
						else if(album_node_name == "image") {
							if(album_iter->get_prop("size") == "large") {
								a.pixbuf_url = album_node_content;
							}
						}
						else if(album_node_name == "url")
							a.url = album_node_content;
					}
					delete album_iter;
					
					albums.set((int)albums.size(), a);
					if(albums.size() > MAX_RESULTS)
						return;
				}
			}
			
			parse_top_artist_albums_nodes(iter, parent+node_name);
		}
		
		delete iter;
	}
}
