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

public class BeatBox.PodcastManager : GLib.Object, BeatBox.PodcastInterface {
	Cancellable canceller;
	
	int current_download_index;
	GLib.File new_dest;
	
	static string CANCELLING_DOWNLOADS = _("Cancelling remaining downloads...");
	static string FETCHING_NEW = _("Fetching new podcast episodes");
	static string FETCHING_NEW_SPECIFIC = _("Searching for new %s podcast episodes...");
	static string FETCHING_FROM_RSS = _("Fetching podcast from %s");
	static string DOWNLOADING_LOCALLY = _("Downloading %s (%d of %d)");
	
	public PodcastManager() {
		
	}
	
	/** Find new podcasts operation **/
	public void find_new_podcasts() {
		MediasOperation op = new MediasOperation(find_new_podcasts_start_sync, find_new_podcasts_start_async, find_new_podcasts_cancel, _("Downloading new Podcasts"));
		App.operations.queue_operation(op);
	}
	
	void find_new_podcasts_start_sync (Operation op) {
		App.operations.current_status = FETCHING_NEW;
	}

	void find_new_podcasts_start_async (Operation op) {
		HashSet<string> rss_urls = new HashSet<string>();
		HashSet<string> mp3_urls = new HashSet<string>();
		HashMap<string, string> rss_names = new HashMap<string, string>();
		
		foreach(Media pod in App.library.podcast_library.medias()) {
			if(!pod.isTemporary) {
				if(pod.rss_uri != null)	rss_urls.add(pod.rss_uri);
				if(pod.podcast_url != null)	mp3_urls.add(pod.podcast_url);
				if(pod.rss_uri != null) rss_names.set(pod.rss_uri, pod.artist);
			}
		}
		
		App.operations.operation_progress = 0;
		App.operations.operation_total = 10 * rss_urls.size;
		App.operations.current_status = FETCHING_NEW;
		
		LinkedList<Media> new_podcasts = new LinkedList<Media>();
		var rss_index = 0;
		foreach(string rss in rss_urls) {
			if(App.operations.operation_cancelled)
				break;
				
			if(rss == null || rss == "")
				continue;
			
			App.operations.current_status = FETCHING_NEW_SPECIFIC.printf("<b>" + Markup.escape_text(rss_names.get(rss)) + "</b>");
			
			// create an HTTP session to twitter
			var session = new Soup.SessionSync();
			var message = new Soup.Message ("GET", rss);
			session.timeout = 30;
			
			// send the HTTP request
			session.send_message(message);
			
			Xml.Node* node = getRootNode(message);
			if(node != null) {
				findNewItems(rss, node, mp3_urls, ref new_podcasts);
			}
			
			++rss_index;
			App.operations.operation_progress = rss_index * 10;
		}
		
		App.operations.operation_progress = App.operations.operation_total;
		
		Idle.add( () => {
			App.library.podcast_library.add_medias(new_podcasts);
			App.operations.finish_operation();
			
			if(App.settings.main.download_new_podcasts) {
				download_podcasts(new_podcasts);
			}
			
			return false;
		});
	}
	
	void find_new_podcasts_cancel(Operation op) {
		canceller.cancel();
	}
	
	public bool is_valid_rss(string url) {
		// create an HTTP session to twitter
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", url);
		
		// send the HTTP request
		session.send_message(message);
		
		Xml.Node* node = getRootNode(message);
		stdout.printf("got root node\n");
		if(node == null)
			return false;
		
		return node->name == "rss";
	}
	
	/** Add files to library operation **/
	public void parse_new_rss(string rss) {
		if(!App.operations.doing_ops) {
			ParseRssOperation op = new ParseRssOperation(parse_new_rss_start_sync, parse_new_rss_start_async, parse_new_rss_cancel, _("Parsing new Podcast RSS"));
			op.rss = rss;
			App.operations.queue_operation(op);
		}
		else {
			warning("User tried to add files to library while doing operations");
		}
	}
	
	void parse_new_rss_start_sync (Operation op) {
		App.operations.current_status = FETCHING_FROM_RSS.printf("<b>" + Markup.escape_text(((ParseRssOperation)op).rss) + "</b>");
	}

	void parse_new_rss_start_async (Operation op) {
		string rss = ((ParseRssOperation)op).rss;
		App.operations.operation_progress = 3;
		App.operations.operation_total = 10;
		
		debug("podcast_rss: %s", rss);
		
		// create an HTTP session to twitter
		var session = new Soup.SessionSync();
		var message = new Soup.Message ("GET", rss);
		session.timeout = 30;
		
		// send the HTTP request
		session.send_message(message);
		
		Xml.Node* node = getRootNode(message);
		if(node == null) {
			warning("Failed to find root xml node for new rss feed. Cannot add feed");
			App.operations.finish_operation();
		}
		
		App.operations.operation_progress = 8;
			
		HashSet<string> mp3_urls = new HashSet<string>();
		LinkedList<Media> new_podcasts = new LinkedList<Media>();
		foreach(Media m in App.library.podcast_library.medias()) {
			Podcast pod = (Podcast)m;
			if(pod.podcast_url == null)
				pod.podcast_url = "";
			
			mp3_urls.add(pod.podcast_url);
		}
		
		// This is where it actually goes into the xml to extract the episodes
		findNewItems(rss, node, mp3_urls, ref new_podcasts);
		
		App.operations.operation_progress = 10;
		
		App.library.add_medias(new_podcasts);
		App.operations.finish_operation();
	}
	
	void parse_new_rss_cancel(Operation op) {
		warning("TODO: Implement me");
	}
	
	Xml.Node* getRootNode(Soup.Message message) {
		Xml.Parser.init();
		Xml.Doc* doc = Xml.Parser.parse_memory((string)message.response_body.data, (int)message.response_body.length);
		if(doc == null)
			return null;
		//stdout.printf("%s", (string)message.response_body.data);
        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            delete doc;
            return null;
        }
		
		// we actually want one level down from root. top level is <response status="ok" ... >
		return root;
	}
	
	// parses a xml root node for new podcasts
	void findNewItems(string rss, Xml.Node* node, HashSet<string> existing, ref LinkedList<Media> found) {
		string pod_title = ""; string pod_author = ""; string category = ""; string summary = ""; string image_url = "";
		int image_width, image_height;
		int visited_items = 0;
		
		node = node->children->next;
		
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != Xml.ElementType.ELEMENT_NODE) {
				continue; // should this be break?
			}
			
			string name = iter->name;
			string content = iter->get_content();
			
			if(name == "title")
				pod_title = content.replace("\n","").replace("\t","").replace("\r","");
			else if(name == "author")
				pod_author = content.replace("\n","").replace("\t","").replace("\r","");
			else if(name == "category") {
				if(content != "")
					category = content.replace("\n","").replace("\t","").replace("\r","");
				
				for (Xml.Attr* prop = iter->properties; prop != null; prop = prop->next) {
					string attr_name = prop->name;
					string attr_content = prop->children->content;
					
					if(attr_name == "text" && attr_content != "") {
						category = attr_content;
					}
				}
			}
			else if(name == "image") {
				for (Xml.Node* image_iter = iter->children; image_iter != null; image_iter = image_iter->next) {
					if(image_iter->name == "url")
						image_url = image_iter->get_content();
					else if(image_iter->name == "width")
						image_width = int.parse(image_iter->get_content());
					else if(image_iter->name == "height")
						image_height = int.parse(image_iter->get_content());
				}
			}
			else if(name == "summary" || name == "description") {
				summary = iter->get_content().replace("\n","").replace("\t","").replace("\r","").replace("<p>", "").replace("</p>", "");
			}
			else if(name == "item") {
				Podcast new_p = new Podcast("");
			
				for (Xml.Node* item_iter = iter->children; item_iter != null; item_iter = item_iter->next) {
					//stdout.printf("name is %s", item_iter->name);
					if(item_iter->name == "title")
						new_p.title = item_iter->get_content();
					else if(name == "author") {
						pod_author = item_iter->get_content().replace("\n","").replace("\t","").replace("\r","");
						new_p.artist = pod_author;
						new_p.album_artist = pod_author;
					}
					else if(item_iter->name == "enclosure") {
						for (Xml.Attr* prop = item_iter->properties; prop != null; prop = prop->next) {
							string attr_name = prop->name;
							string attr_content = prop->children->content;
							
							if(attr_name == "url" && attr_content != null) {
								new_p.podcast_url = attr_content;
								new_p.uri = attr_content;
							}
						}
					}
					else if(item_iter->name == "pubDate") {
						GLib.Time tm = GLib.Time ();
						tm.strptime (item_iter->get_content(),
									"%a, %d %b %Y %H:%M:%S %Z");
						new_p.date_released = int.parse(tm.format("%s"));
					}
					else if(item_iter->name == "duration") {
						string[] dur_pieces = item_iter->get_content().split(":", 0);
						
						int seconds = 0; int minutes = 0; int hours = 0;
						seconds = int.parse(dur_pieces[dur_pieces.length - 1]);
						if(dur_pieces.length > 1)
							minutes = int.parse(dur_pieces[dur_pieces.length - 2]);
						if(dur_pieces.length > 2)
							hours = int.parse(dur_pieces[dur_pieces.length - 3]);
							
						new_p.length = seconds + (minutes * 60) + (hours * 3600);
					}
					else if(item_iter->name == "subtitle" || item_iter->name == "description") {
						new_p.comment = item_iter->get_content().replace("\n","").replace("\t","").replace("\r","");
					}
				}
				
				if(new_p.podcast_url != null && !existing.contains(new_p.podcast_url) && new_p.podcast_url != "") {
					if(pod_author == null || pod_author == "")
						pod_author = pod_title;
					if(category == null || category == "")
						category = "Podcast";
					
					//new_p.mediatype = MediaType.PODCAST;
					new_p.rss_uri = rss;
					new_p.genre = category;
					new_p.artist = pod_author;
					new_p.album_artist = pod_author;
					new_p.album = pod_title;
					//new_p.album = ??
					if(new_p.comment == "")			new_p.comment = summary;
					
					found.add(new_p);
				}
				
				++visited_items;
				++App.operations.operation_progress;
				
				//if(visited_items >= max_items - 1)
				//	return;
			}
		}
	}
	
	/** Save episodes locally operation **/
	public void download_podcasts(Collection<Media> podcasts) {
		if(podcasts == null)
			return;
		
		/** Notice here that we ACTUALLY queue this operation if ther are others going on **/
		if(File.new_for_path(App.settings.main.music_folder).query_exists()) {
			MediasOperation op = new MediasOperation(download_podcasts_start_sync, download_podcasts_start_async, download_podcasts_cancel, _("Downloading Podcast Episodes"));
			op.medias = podcasts;
			App.operations.queue_operation(op);
		}
		else if(!File.new_for_path(App.settings.main.music_folder).query_exists()) {
			warning("User tried to download podcasts, but music folder not mounted");
		}
	}
	
	void download_podcasts_start_sync (Operation op) {
		App.operations.current_status = _("Downloading Podcast Episodes...");
	}

	void download_podcasts_start_async (Operation op) {
		var downloads = ((MediasOperation)op).medias;
		current_download_index = 0;
		canceller = new Cancellable();
		App.operations.operation_progress = 0;
		App.operations.operation_total = 1000; // So we can have sub-progresses
		
		foreach(Media s in downloads) {
			if(App.operations.operation_cancelled || canceller.is_cancelled())
				break;
			
			var online_file = File.new_for_uri(s.podcast_url);
			if(online_file.query_exists() && s.uri == s.uri) {
				App.operations.current_status = DOWNLOADING_LOCALLY.printf("<b>" + Markup.escape_text(s.title) + "</b>", (current_download_index + 1), downloads.size);
				
				new_dest = App.files.get_new_destination(s);
				copy_locally(s);
				
				int file_size = 5; // 5 is sane backup
				try {
					file_size = (int)(new_dest.query_info("*", FileQueryInfoFlags.NONE).get_size());
				}
				catch(Error err) {
					stdout.printf("Could not calculate downloaded podcast's file size: %s", err.message);
				}
				
				s.file_size = file_size;
			}
			else {
				stdout.printf("Skipped downloading podcast %s. Either not connected to internet, or is already saved locally.\n", s.title);
			}
			
			++current_download_index;
		}
		
		Idle.add( () => {
			App.operations.finish_operation();
			
			return false;
		});
	}
	
	void download_podcasts_cancel(Operation op) {
		canceller.cancel();
		App.operations.current_status = CANCELLING_DOWNLOADS;
	}
	
	bool copy_locally(Media s) {
		bool success = false;
		
		try {
			GLib.File dest = App.files.get_new_destination(s);
			if(dest == null)
				return false;
			
			GLib.File original = GLib.File.new_for_uri(s.uri);
			
			/* copy the file over */
			debug("Copying %s to %s", s.uri, dest.get_uri());
			success = original.copy(dest, FileCopyFlags.NONE, canceller, download_progress_callback);
			
			if(success || dest.query_exists()) {
				success = true;
				debug("success copying file\n");
				s.uri = dest.get_uri();
				
				// Save the uri change in the database
				Idle.add( () => {
					var collection = new LinkedList<Media>();
					collection.add(s);
					App.library.podcast_library.update_medias(collection, false, false, true);
					return false;
				});
			}
			else
				warning("Failure: Could not copy imported media %s to media folder %s", s.uri, dest.get_path());
		}
		catch(GLib.Error err) {
			warning("Could not copy imported media %s to media folder: %s", s.uri, err.message);
		}
		
		return success;
	}
	
	void download_progress_callback(int64 current_num_bytes, int64 total_num_bytes) {
		int total_length = ((MediasOperation)App.operations.current_op).medias.size;
		int starting_point = (int)(1000.0f * ((double)current_download_index/(double)total_length));
		double single_song_range = (double)(1000.0 * (1.0f/(double)total_length));
		double song_progress = (double)current_num_bytes/(double)total_num_bytes;
		App.operations.operation_progress = (int)(starting_point + (single_song_range * song_progress));
	}
}
