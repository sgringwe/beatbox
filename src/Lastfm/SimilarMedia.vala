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

public class LastFM.SimilarMedias : Object {
	BeatBox.Media base_media;
	bool working;
	
	Gee.LinkedList<BeatBox.Media> similar;
	
	public signal void similar_retrieved (Gee.LinkedList<BeatBox.Media> internals, Gee.LinkedList<BeatBox.Media> externals);
	
	public class SimilarMedias() {
		working = false;
	}
	
	/** Gets similar medias
	 * @param artist The artist of media to get similar to
	 * @param title The title of media to get similar to
	 * @return The medias that are similar
	 */
	public void getSimilarTracks(BeatBox.Media s) {
		if(working) {
			message("Can't fetch similar songs: already fetching");
			return;
		}
		
		working = true;
		
		base_media = s;
		
		var params = new Gee.HashMap<string, string>();
		params.set("method", "track.getsimilar");
		params.set("artist", s.artist);
		params.set("track", s.title);
		
		BeatBox.App.info.lastfm.query("GET", params, false, (sess, msg) => {
			Xml.Doc* doc = Xml.Parser.parse_memory((string)msg.response_body.data, (int)msg.response_body.length);
			if(doc == null) {
				GLib.message("Could not load similar artist information for %s by %s\n", base_media.title, base_media.artist);
				
				working = false;
				return;
			}
			
			Xml.Node* root = doc->get_root_element();
			if(root == null) {
				GLib.message("Oddly, similar artist information was invalid\n");
				
				working = false;
				return;
			}
			
			similar = new Gee.LinkedList<BeatBox.Media>();
			var similarDos = new Gee.LinkedList<BeatBox.Media>();
			var similarDont = new Gee.LinkedList<BeatBox.Media>();
			
			parse_similar_nodes(root, "");
			
			BeatBox.App.library.medias_from_name(similar, ref similarDos, ref similarDont);
			similarDos.offer_head(base_media);
			
			Idle.add( () => {
				similar_retrieved(similarDos, similarDont);
				return false;
			});
		
			working = false;
			
			delete doc;
			
		});
	}
	
	void parse_similar_nodes(Xml.Node* node, string parent) {
		Xml.Node* iter;
		for (iter = node->children; iter != null; iter = iter->next) {
			
            if (iter->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }

            string node_name = iter->name;
            
            if(parent == "similartracks") {
				if(node_name == "track") {
					BeatBox.Song m = new BeatBox.Song("");
					m.isTemporary = true;
					m.album = "";
					
					Xml.Node* track_iter;
					for(track_iter = iter->children; track_iter != null; track_iter = track_iter->next) {
						string track_node_name = track_iter->name;
						string track_node_content = track_iter->get_content ();
						
						if(track_node_name == "name")
							m.title = track_node_content;
						// Disable duration since they are incorrect from last.fm
						/*else if(track_node_name == "duration")
							m.length = int.parse(track_node_content)/1000;*/
						else if(track_node_name == "url")
							m.lastfm_url = track_node_content;
						else if(track_node_name == "artist") {
							Xml.Node* artist_iter;
							for(artist_iter = track_iter->children; artist_iter != null; artist_iter = artist_iter->next) {
								string artist_node_name = artist_iter->name;
								
								if(artist_node_name == "name") {
									m.artist = artist_iter->get_content();
									m.album_artist = m.artist;
									break;
								}
							}
						}
					}
					
					similar.add(m);
				}
			}
			
			parse_similar_nodes(iter, parent+node_name);
		}
		
		delete iter;
	}
}
