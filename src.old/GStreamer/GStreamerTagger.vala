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

/**
 * This class uses GStreamer functions to discover all media from a folder.
 **/
public class BeatBox.GStreamerTagger : GLib.Object {
	int size;
	static int DISCOVER_SET_SIZE = 50;
	Gst.Discoverer d;
	Gst.Discoverer art_d;
	Gee.HashMap<string, int> uri_to_id;
	Gee.LinkedList<string> uri_queue;
	
	public signal void media_imported(Media m);
	public signal void import_error(string file);
	public signal void queue_finished();
	
	public GStreamerTagger() {
		try {
			d = new Gst.Discoverer((Gst.ClockTime)(10*Gst.SECOND));
		}
		catch(Error err) {
			critical("Metadata reader could not create discoverer object: %s\n", err.message);
		}
		d.discovered.connect(import_media);
		d.finished.connect(finished);
		
		try {
			art_d = new Gst.Discoverer((Gst.ClockTime)(10*Gst.SECOND));
		}
		catch(Error err) {
			critical("Metadata reader could not create discoverer object: %s\n", err.message);
		}
		
		uri_to_id = new Gee.HashMap<string, int>();
		uri_queue = new Gee.LinkedList<string>();
	}
	
	void finished() {
		if(!App.operations.operation_cancelled && uri_queue.size > 0) {
			try {
				d = new Gst.Discoverer((Gst.ClockTime)(10*Gst.SECOND));
			}
			catch(Error err) {
				critical("Metadata reader could not create discoverer object: %s\n", err.message);
			}
			d.discovered.connect(import_media);
			d.finished.connect(finished);
			
			size = 0;
			d.start();
			for(int i = 0; i < DISCOVER_SET_SIZE && i < uri_queue.size; ++i) {
				d.discover_uri_async(uri_queue.get(i));
			}
		}
		else {
			debug("queue finished\n");
			queue_finished();
		}
	}
	
	public void discoverer_start_import() {
		size = 0;
		uri_queue.clear();
	}
	
	public void discoverer_queue_file(string file) {
		uri_queue.add(file);
		d.start();
		if(size < DISCOVER_SET_SIZE) {
			++size;
			d.discover_uri_async(file);
		}
	}
	
	// This is the concurrent way of importing
	public void discoverer_import_medias(Gee.LinkedList<string> files) {
		size = 0;
		uri_queue.clear();
		
		foreach(string s in files) {
			uri_queue.add(s);
			
			d.start();
			if(size < DISCOVER_SET_SIZE) {
				++size;
				d.discover_uri_async(s);
			}
		}
	}
	
	public void fetch_art(Gee.LinkedList<Media> files) {
		size = 0;
		uri_queue.clear();
		stdout.printf("gstreamer tagger fetching art for %d\n", files.size);
		
		uri_to_id.clear();
		foreach(Media m in files) {
			string uri = m.uri;
			uri_queue.add(uri);
			uri_to_id.set(uri, m.rowid);
			
			art_d.start();
			if(size < DISCOVER_SET_SIZE) {
				++size;
				art_d.discover_uri_async(uri);
			}
		}
	}
	
	void import_media(Gst.DiscovererInfo info, Error err) {
		uri_queue.remove(info.get_uri());
		--size;
		
		if(info != null && info.get_tags() != null) {
			Media s = ((FilesOperation)App.operations.current_op).library.import_tags_to_media(info);
			
			media_imported(s);
		}
		
		// TODO: How to do importing for various media types without extreme duplication???
		/*else {
			Media s = taglib_import_media(info.get_uri());
			
			if(s == null)
				import_error(File.new_for_uri(info.get_uri()).get_path());
			else
				media_imported(s);
		}*/
	}
	
	/*public Media? taglib_import_media(string uri) {
		Media s = new Media(uri);
		TagLib.File tag_file;
		
		tag_file = new TagLib.File(File.new_for_uri(uri).get_path());
		
		if(tag_file != null && tag_file.tag != null && tag_file.audioproperties != null) {
			try {
				s.title = tag_file.tag.title;
				s.artist = tag_file.tag.artist;
				s.album = tag_file.tag.album;
				s.genre = tag_file.tag.genre;
				s.comment = tag_file.tag.comment;
				s.year = (int)tag_file.tag.year;
				s.track = (int)tag_file.tag.track;
				s.bitrate = tag_file.audioproperties.bitrate;
				s.length = tag_file.audioproperties.length;
				s.samplerate = tag_file.audioproperties.samplerate;
				s.date_added = (int)time_t();
				
				// get the size
				//s.file_size = (int)(GLib.File.new_for_path(file_path).query_info("*", FileQueryInfoFlags.NONE).get_size());
				
			}
			finally {
				if(s.title == null || s.title == "") {
					string[] paths = uri.split("/", 0);
					s.title = paths[paths.length - 1];
				}
				if(s.artist == null || s.artist == "") s.artist = "Unknown Artist";
				if(s.album == null)	s.album = "";
				
				s.album_artist = s.artist;
				s.album_number = 1;
			}
		}
		else {
			return null;
		}
		
		return s;
	}*/
	
	public bool save_media(Media s) {
		return false;
	}
	
	public bool save_embeddeart_d(Gdk.Pixbuf pix) {
		
		return false;
	}
}
