/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

using Gtk;
using Gee;
using Granite;

public class BeatBox.PodcastEditor : Object, MediaEditorInterface {
	private Box horiz; // separates text with numerical editors
	private Box textVert; // separates text editors
	private Box numerVert; // separates numerical editors
	
	private HashMap<string, FieldEditor> fields;// a hashmap with each property and corresponding editor
	
	public PodcastEditor() {
		fields = new HashMap<string, FieldEditor>();
	}
	
	public Collection<FieldEditor> get_fields() {
		return fields.values;
	}
	
	public Viewport get_metadata_view(Collection<Media> originals) {
		Viewport rv = new Viewport(null, null);
		Media sum = originals.to_array()[0].copy();
		
		/** find what these podcasts have what common, and keep those values **/
		foreach(Media s in originals) {
			if(s.track != sum.track) // episode
				sum.track = 0;
			if(s.title != sum.title) // podcast title
				sum.title = "";
			if(s.artist != sum.artist) // podcast author. if this changes, so should album_artist for sorting.
				sum.artist = "";
			if(s.album != sum.album) // podcast name
				sum.album = "";
			if(s.genre != sum.genre) // category
				sum.genre = "";
			if(s.comment != sum.comment)
				sum.comment = "";
			if(s.rating != sum.rating)
				sum.rating = 0;
			//if(s.media_type != sum.media_type)
			//	sum.media_type = MediaType.SONG;
		}
		
		fields.set("Title", new FieldEditorImpl.for_string(_("Title"), sum.title));
		fields.set("Author", new FieldEditorImpl.for_string(_("Author"), sum.artist));
		fields.set("Podcast", new FieldEditorImpl.for_string(_("Podcast"), sum.album));
		fields.set("Genre", new FieldEditorImpl.for_string(_("Genre"), sum.genre));
		fields.set("Comment", new FieldEditorImpl.for_long_string(_("Comment"), sum.comment));
		fields.set("Episode", new FieldEditorImpl.for_integer(_("Track"), (int)sum.track, 0, 500));
		fields.set("Rating", new FieldEditorImpl.for_rating(_("Rating"), (int)sum.rating));
		//fields.set("Media Type", new FieldEditor.for_int("Media Type", ((int)sum.media_type)));
		
		fields.get("Title").set_width_request(300);
		fields.get("Author").set_width_request(300);
		fields.get("Podcast").set_width_request(300);
		fields.get("Comment").set_width_request(300);
		
		horiz = new Box(Orientation.HORIZONTAL, 0);
		textVert = new Box(Orientation.VERTICAL, 0);
		numerVert = new Box(Orientation.VERTICAL, 0);
		
		textVert.pack_start(fields.get("Title"), false, true, 0);
		textVert.pack_start(fields.get("Author"), false, true, 5);
		textVert.pack_start(fields.get("Podcast"), false, true, 5);
		textVert.pack_start(fields.get("Comment"), false, true, 5);
		
		numerVert.pack_start(fields.get("Episode"), false, true, 0);
		numerVert.pack_start(fields.get("Genre"), false, true, 5);
		numerVert.pack_start(fields.get("Rating"), false, true, 5);
		//numerVert.pack_end(fields.get("Media Type"), false, true, 5);
		
		horiz.set_size_request(300, -1);
		fields.get("Comment").set_size_request(-1, 100);
		
		horiz.pack_start(UI.wrap_alignment(textVert, 0, 30, 0, 0), false, true, 0);
		horiz.pack_end(numerVert, false, true, 0);
		rv.add(horiz);
		
		return rv;
	}
	
	public HashMap<string, Viewport> get_extra_views() {
		var rv = new HashMap<string, Viewport>();
		
		//rv.set(_("Podcast stuff"), new Viewport(null, null));
		
		return rv;
	}
	
	public void change_media(Media sum) {
		fields.get("Title").set_value(sum.title);
		fields.get("Author").set_value(sum.artist);
		fields.get("Podcast").set_value(sum.album);
		fields.get("Genre").set_value(sum.genre);
		fields.get("Comment").set_value(sum.comment);
		fields.get("Episode").set_value((int)sum.track);
		fields.get("Rating").set_value((int)sum.rating);
		//fields.get("Media Type").set_value(((int)sum.media_type).to_string());
	}
	
	public void save_medias(Collection<Media> medias) {
		foreach(Media s in medias) {
			if(fields.get("Title").checked())
				s.title = fields.get("Title").get_value().get_string();
			if(fields.get("Author").checked()) {
				s.artist = fields.get("Author").get_value().get_string();
				s.album_artist = s.artist;
			}
			if(fields.get("Podcast").checked())
				s.album = fields.get("Podcast").get_value().get_string();
			if(fields.get("Genre").checked())
				s.genre = fields.get("Genre").get_value().get_string();
			if(fields.get("Comment").checked())
				s.comment = fields.get("Comment").get_value().get_string();
				
			if(fields.get("Episode").checked())
				s.track = fields.get("Episode").get_value().get_int();
			if(fields.get("Rating").checked())
				s.rating = fields.get("Rating").get_value().get_int();
			/*if(fields.get("Media Type").checked()) {
				int type = int.parse(fields.get("Media Type").get_value());
				if(type == 0)
					s.media_type = MediaType.SONG;
				else if(type == 1)
					s.media_type = MediaType.PODCAST;
				else if(type == 2)
					s.media_type = MediaType.AUDIOBOOK;
			}*/
		}
		
		App.library.podcast_library.update_medias(medias, true, true, true);
	}
}
