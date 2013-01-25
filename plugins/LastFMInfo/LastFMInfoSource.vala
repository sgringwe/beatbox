using Xml;

public class BeatBox.LastFMInfoSource : GLib.Object, InfoSource {
	/** NOTICE: These API keys and secrets are unique to BeatBox and BeatBox
	 * only. To get your own, FREE key go to http://www.last.fm/api/account */
	public static const string api = "a40ea1720028bd40c66b17d7146b3f3b";
	public static const string secret = "92ba5023f6868e680a3352c71e21243d";
	
	public string token;
	public string session_key;
	
	public LastFMInfoSource() {
		
	}
	
	// These are called from a thread
	public TrackInfo fetch_track_info(string artist, string title) {
		TrackInfo rv = new TrackInfo();
		
		if(artist == null || title == null) {
			warning("Null param passed for fetch_track_info");
			return rv;
		}
		
		string url = "http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=" + api + 
					 "&artist=" + Uri.escape_string (artist, "", false) + 
					 "&track=" + Uri.escape_string (title, "", false);
		
		Xml.Node* root = query_for_xml(url);
		if(root != null) {
			parse_track_info(root, "", ref rv);
		}
		
		return rv;
	}
	
	public AlbumInfo fetch_album_info(string artist, string album) {
		AlbumInfo rv = new AlbumInfo();
		
		if(artist == null || album == null) {
			warning("Null param passed for fetch_album_info");
			return rv;
		}
		
		string url = "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=" + api + 
					 "&artist=" + Uri.escape_string (artist, "", false) + 
					 "&album=" + Uri.escape_string (album, "", false);
		
		Xml.Node* root = query_for_xml(url);
		
		if(root != null) {
			parse_album_info(root, "", ref rv);
		}
		
		return rv;
	}
	
	public ArtistInfo fetch_artist_info(string artist) {
		ArtistInfo rv = new ArtistInfo();
		
		if(artist == null) {
			warning("Null param passed for fetch_artist_info");
			return rv;
		}
		
		string url = "http://ws.audioscrobbler.com/2.0/?method=artist.getinfo&api_key=" + api + 
					 "&artist=" + Uri.escape_string (artist, "", false);
		
		Xml.Node* root = query_for_xml(url);
		
		if(root != null) {
			parse_artist_info(root, "", ref rv);
		}
		
		return rv;
	}
	
	// TODO: Move this and Store's same function to a helper util.
	private Xml.Node* query_for_xml(string url) {
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		
		// send the HTTP GET request
		session.send_message(message);
		
		if(message == null) {
			warning("Failed to get response from url %s", url);
			return null;
		}
		
		Xml.Node* node = get_root_node(message);
		
		return node;
	}
	
	private Xml.Node* get_root_node(Soup.Message message) {
		Xml.Parser.init();
		Xml.Doc* doc = Xml.Parser.parse_memory((string)message.response_body.data, (int)message.response_body.length);
		if(doc == null)
			return null;
		
        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            delete doc;
            return null;
        }
        
        // make sure we got an 'ok' response
		for (Xml.Attr* prop = root->properties; prop != null && prop->name != "status" ; prop = prop->next) {
			if(prop->children->content != "ok")
				return null;
		}
		
		// we actually want one level down from root. top level is <response status="ok" ... >
		return root;
	}
	
	// XML parsers
	void parse_track_info(Xml.Node* node, string parent, ref TrackInfo info) {
		// Loop over the passed node's children
        for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
            // Spaces between tags are also nodes, discard them
            if (iter->type != ElementType.ELEMENT_NODE) {
                continue;
            }

            string node_name = iter->name;
            string node_content = iter->get_content ();
                       
            if(parent == "track") {
				if(node_name == "name") {
					info.title = node_content;
				}
				else if(node_name == "url") {
					InfoURL url = new InfoURL();
					url.uri = node_content;
					url.title = "Last.fm Page";
					info.more_info_urls.add(url);
				}
				else if(node_name == "streamable") {
					// info.streamable = int.parse(node_content) == 1;
				}
			}
			else if(parent == "trackartist") {
				if(node_name == "name") {
					info.artist = node_content;
				}
			}
			else if(parent == "trackwiki") {
				if(node_name == "summary") {
					info.short_desc = node_content;
				}
				else if(node_name == "content") {
					info.full_desc = node_content;
				}
			}
			/*else if(parent == "tracktoptagstag") {
				if(node_name == "name") {
					if(tagToAdd != null)
						_tags.add(tagToAdd);
					
					tagToAdd = new LastFM.Tag();
					tagToAdd.tag = node_content;
				}
				else if(node_name == "url")
					tagToAdd.url = node_content;
			}*/

            // Followed by its children nodes
            parse_track_info(iter, parent + node_name, ref info);
        }
	}
	
	void parse_album_info(Xml.Node* node, string parent, ref AlbumInfo info) {
        // Loop over the passed node's children
        for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
            // Spaces between tags are also nodes, discard them
            if (iter->type != ElementType.ELEMENT_NODE) {
                continue;
            }

            string node_name = iter->name;
            string node_content = iter->get_content ();
                       
            if(parent == "album") {
				if(node_name == "name") {
					info.album = node_content;
				}
				else if(node_name == "artist") {
					info.album_artist = node_content;
				}
				else if(node_name == "url") {
					InfoURL url = new InfoURL();
					url.uri = node_content;
					url.title = "Last.fm Page";
					info.more_info_urls.add(url);
				}
				else if(node_name == "releasedate") {
					info.release_date = node_content;
				}
				else if(node_name == "image") {
					if(iter->get_prop("size") == "large") {
						info.art_uri = node_content;
					}
				}
			}
			/*else if(parent == "albumtoptagstag") {
				if(node_name == "name") {
					if(tagToAdd != null)
						_tags.add(tagToAdd);
					
					tagToAdd = new LastFM.Tag();
					tagToAdd.tag = node_content;
				}
				else if(node_name == "url")
					tagToAdd.url = node_content;
			}*/
			else if(parent == "albumwiki") {
				if(node_name == "summary") {
					info.short_desc = node_content;
				}
			}
			/*else if(parent == "albumtracks") {
				if(node_name == "track") {
					BeatBox.Media m = new BeatBox.Media("");
					m.isTemporary = true;
					m.track = int.parse(iter->get_prop("rank"));
					
					for(Xml.Node* track_iter = iter->children; track_iter != null; track_iter = track_iter->next) {
						string track_node_name = track_iter->name;
						string track_node_content = track_iter->get_content ();
						
						if(track_node_name == "name")
							m.title = track_node_content;
						else if(track_node_name == "duration")
							m.length = int.parse(track_node_content);
						else if(track_node_name == "url")
							m.lastfm_url = track_node_content;
					}
					
					m.album = _name;
					m.album_artist = _artist;
					m.artist = _artist;
					
					_tracks.add(m);
				}
			}*/

            // Followed by its children nodes
            parse_album_info (iter, parent + node_name, ref info);
        }
    }
    
    void parse_artist_info (Xml.Node* node, string parent, ref ArtistInfo info) {
        // Loop over the passed node's children
        for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
            // Spaces between tags are also nodes, discard them
            if (iter->type != ElementType.ELEMENT_NODE) {
                continue;
            }
			
            string node_name = iter->name;
            string node_content = iter->get_content ();
            
            if(parent == "artist") {
				if(node_name == "name") {
					info.artist = node_content;
				}
				else if(node_name == "url") {
					InfoURL url = new InfoURL();
					url.uri = node_content;
					url.title = "Last.fm Page";
					info.more_info_urls.add(url);
				}
				//else if(node_name == "streamable") {
				//the uri will be lastfm://artist/info.artist/similarartists.
				// see http://www.last.fm/api/radio
				//}
				else if(node_name == "image") {
					if(iter->get_prop("size") == "extralarge") {
						info.photo_uri = node_content;
					}
				}
			}
			/*else if(parent == "artistsimilarartist") {
				if(node_name == "name") {
					if(similarToAdd != null)
						_similarArtists.add(similarToAdd);
					
					similarToAdd = new ArtistInfo();
					similarToAdd.name = node_content;
				}
				else if(node_name == "url")
					similarToAdd.url = node_content;
				else if(node_name == "image") {
					//TODO
				}
			}*/
			/*else if(parent == "artisttagstag") {
				if(node_name == "name") {
					if(tagToAdd != null)
						_tags.add(tagToAdd);
					
					tagToAdd = new LastFM.Tag();
					tagToAdd.tag = node_content;
				}
				else if(node_name == "url")
					tagToAdd.url = node_content;
			}*/
			else if(parent == "artistbio") {
				if(node_name == "summary") {
					info.short_desc = node_content;
				}
				else if(node_name == "content") {
					info.full_desc = node_content;
				}
			}
            
            // Followed by its children nodes
            parse_artist_info (iter, parent + node_name, ref info);
        }
    }
}
