/*-
 * Copyright (c) 2011-2012	   Scott Ringwelski <sgringwe@mtu.edu>
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

public class BeatBox.SongEditor : GLib.Object, MediaEditorInterface {
	Media current_media;
	
	Box horiz; // Contains textVert and numerVert
	Box textVert; // separates text editors
	Box numerVert; // separates numerical editors
	
	Box lyricsContent;
	InfoBar lyricsInfobar;
	Label lyricsInfobarLabel;
	TextView lyricsText;
	
	HashMap<string, FieldEditor> fields;// a hashmap with each property and corresponding editor
	
	public SongEditor() {
		fields = new HashMap<string, FieldEditor>();
		
		App.info.lyrics.lyrics_fetched.connect(lyricsFetched);
	}
	
	public Collection<FieldEditor> get_fields() {
		return fields.values;
	}
	
	public Viewport get_metadata_view(Collection<Media> originals) {
		Viewport rv = new Viewport(null, null);
		fields = new HashMap<string, FieldEditor>();
		Media sum = originals.to_array()[0].copy();
		
		/** find what these medias have what common, and keep those values **/
		foreach(Media s in originals) {
			if(s.track != sum.track)
				sum.track = 0;
			if(s.album_number != sum.album_number)
				sum.album_number = 0;
			if(s.title != sum.title)
				sum.title = "";
			if(s.artist != sum.artist)
				sum.artist = "";
			if(s.album_artist != sum.album_artist)
				sum.album_artist = "";
			if(s.album != sum.album)
				sum.album = "";
			if(s.genre != sum.genre)
				sum.genre = "";
			if(s.comment != sum.comment)
				sum.comment = "";
			if(s.year != sum.year)
				sum.year = 0;
			if(s.bitrate != sum.bitrate)
				sum.bitrate = 0;
			if(s.composer != sum.composer)
				sum.composer = "";
			if(s.grouping != sum.grouping)
				sum.grouping = "";
			//length = 0;
			//samplerate = 0;
			if(s.bpm != sum.bpm)
				sum.bpm = 0;
			if(s.rating != sum.rating)
				sum.rating = 0;
			//if(s.media_type != sum.media_type)
			//	sum.media_type = MediaType.SONG;
			//score = 0;
			//play_count = 0;
			//skip_count = 0;
			//date_added = 0;
			//last_played = 0;
		}
		
		fields.set("Title", new FieldEditorImpl.for_string(_("Title"), sum.title));
		fields.set("Artist", new FieldEditorImpl.for_string(_("Artist"), sum.artist));
		fields.set("Album Artist", new FieldEditorImpl.for_string(_("Album Artist"), sum.album_artist));
		fields.set("Album", new FieldEditorImpl.for_string(_("Album"), sum.album));
		fields.set("Genre", new FieldEditorImpl.for_string(_("Genre"), sum.genre));
		fields.set("Composer", new FieldEditorImpl.for_string(_("Composer"), sum.composer));
		fields.set("Grouping", new FieldEditorImpl.for_string(_("Grouping"), sum.grouping));
		fields.set("Comment", new FieldEditorImpl.for_long_string(_("Comment"), sum.comment));
		fields.set("Track", new FieldEditorImpl.for_integer(_("Track"), (int)sum.track, 0, 500));
		fields.set("Disc", new FieldEditorImpl.for_integer(_("Disc"), (int)sum.album_number, 0, 500));
		fields.set("Year", new FieldEditorImpl.for_integer(_("Year"), (int)sum.year, 0, 9999));
		fields.set("Rating", new FieldEditorImpl.for_rating(_("Rating"), (int)sum.rating));
		//fields.set("Media Type", new FieldEditor.for_integer("Media Type", ((int)sum.media_type)));
		
		horiz = new Box(Orientation.HORIZONTAL, 0);
		textVert = new Box(Orientation.VERTICAL, 0);
		numerVert = new Box(Orientation.VERTICAL, 0);
		
		textVert.pack_start(fields.get("Title"), false, true, 0);
		textVert.pack_start(fields.get("Artist"), false, true, 5);
		textVert.pack_start(fields.get("Album Artist"), false, true, 5);
		textVert.pack_start(fields.get("Composer"), false, true, 5);
		textVert.pack_start(fields.get("Album"), false, true, 5);
		textVert.pack_start(fields.get("Comment"), false, true, 5);
		
		fields.get("Title").set_width_request(300);
		fields.get("Artist").set_width_request(300);
		fields.get("Album Artist").set_width_request(300);
		fields.get("Composer").set_width_request(300);
		fields.get("Album").set_width_request(300);
		fields.get("Comment").set_width_request(300);
		
		numerVert.pack_start(fields.get("Track"), false, true, 0);
		numerVert.pack_start(fields.get("Disc"), false, true, 5);
		numerVert.pack_start(fields.get("Genre"), false, true, 5);
		numerVert.pack_start(fields.get("Grouping"), false, true, 5);
		numerVert.pack_start(fields.get("Year"), false, true, 5);
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
		
		rv.set(_("Lyrics"), get_lyrics_viewport());
		
		return rv;
	}
	
	Viewport get_lyrics_viewport() {
		Viewport rv = new Viewport(null, null);
		
		var padding = new Box(Orientation.VERTICAL, 10);
		lyricsContent = new Box(Orientation.VERTICAL, 10);
		
		lyricsInfobarLabel = new Label("");
		
		lyricsInfobarLabel.set_justify(Justification.LEFT);
		lyricsInfobarLabel.set_single_line_mode(true);
		lyricsInfobarLabel.ellipsize = Pango.EllipsizeMode.END;
		
		lyricsInfobar = new InfoBar();
		lyricsInfobar.add_buttons("Try again", Gtk.ResponseType.OK);
		lyricsInfobar.set_message_type (Gtk.MessageType.WARNING);
		
		(lyricsInfobar.get_content_area() as Gtk.Container).add (lyricsInfobarLabel);

		lyricsInfobar.response.connect(fetchLyricsClicked);
		
		lyricsText = new TextView();
		lyricsText.set_wrap_mode(WrapMode.WORD_CHAR);
		if(current_media != null)	lyricsText.get_buffer().text = current_media.lyrics;
		
		ScrolledWindow scroll = new ScrolledWindow(null, null);
		Viewport viewport = new Viewport(null, null);
		
		viewport.set_shadow_type(ShadowType.ETCHED_IN);
		scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		viewport.add(lyricsText);
		scroll.add(viewport);
		
		lyricsContent.pack_start(lyricsInfobar, false, true, 0);
		lyricsContent.pack_start(scroll, true, true, 0);
		
		lyricsText.set_size_request(400, -1);
		scroll.set_size_request(400, -1);
		viewport.set_size_request(400, -1);
		
		padding.pack_start(lyricsContent, true, true, 0);
		rv.add(padding);

		return rv;
	}
	
	public void change_media(Media sum) {
		current_media = sum;
		
		fields.get("Title").set_value(sum.title);
		fields.get("Artist").set_value(sum.artist);
		fields.get("Album Artist").set_value(sum.album_artist);
		fields.get("Album").set_value(sum.album);
		fields.get("Genre").set_value(sum.genre);
		fields.get("Comment").set_value(sum.comment);
		fields.get("Track").set_value((int)sum.track);
		fields.get("Disc").set_value((int)sum.album_number);
		fields.get("Year").set_value((int)sum.year);
		fields.get("Rating").set_value((int)sum.rating);
		fields.get("Composer").set_value(sum.composer);
		fields.get("Grouping").set_value(sum.grouping);
		//fields.get("Media Type").set_value(((int)sum.media_type).to_string());
		
		if(lyricsText != null) {
			lyricsText.get_buffer().text = current_media.lyrics;
		}

		fetch_lyrics (false);
	}
	
	public void save_medias(Collection<Media> medias) {
		foreach(Media s in medias) {
			if(fields.get("Title").checked())
				s.title = fields.get("Title").get_value().get_string();
			if(fields.get("Artist").checked())
				s.artist = fields.get("Artist").get_value().get_string();
			if(fields.get("Album Artist").checked())
				s.album_artist = fields.get("Album Artist").get_value().get_string();
			if(fields.get("Album").checked())
				s.album = fields.get("Album").get_value().get_string();
			if(fields.get("Genre").checked())
				s.genre = fields.get("Genre").get_value().get_string();
			if(fields.get("Composer").checked())
				s.composer = fields.get("Composer").get_value().get_string();
			if(fields.get("Grouping").checked())
				s.grouping = fields.get("Grouping").get_value().get_string();
			if(fields.get("Comment").checked())
				s.comment = fields.get("Comment").get_value().get_string();
				
			if(fields.get("Track").checked())
				s.track = fields.get("Track").get_value().get_int();
			if(fields.get("Disc").checked())
				s.album_number = fields.get("Disc").get_value().get_int();
			if(fields.get("Year").checked())
				s.year = fields.get("Year").get_value().get_int();
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
				
			// save lyrics
			if(lyricsText != null) {
				var lyrics = lyricsText.get_buffer().text;
				if (!String.is_empty(lyrics))
					s.lyrics = lyrics;
			}
		}
		
		App.library.song_library.update_medias(medias, true, true, true);
	}
	
	void fetchLyricsClicked() {
		fetch_lyrics (true);
	}
	
	void fetch_lyrics (bool overwrite) {
		if(current_media == null) {
			return;
		}
		
		lyricsInfobar.hide();

		// fetch lyrics here
		if (!(!String.is_empty(current_media.lyrics) && !overwrite)) {
			App.info.lyrics.fetch_lyrics(current_media.artist, current_media.album_artist, current_media.title);
		}
	}
	
	void lyricsFetched(Lyrics lyrics) {
		lyricsInfobarLabel.set_text ("");
		lyricsInfobar.hide();

		string song_title = fields["Title"].get_value().get_string();
		string song_artist = fields["Artist"].get_value().get_string();

		if (lyrics.title != song_title)
			return;

		if (!String.is_empty(lyrics.content)) {
			lyricsText.get_buffer().text = lyrics.content;
		}
		else {
			lyricsInfobar.show_all();
			lyricsInfobarLabel.set_text ("Lyrics not found for " + song_title + " by " + song_artist);
		}
	}
}
