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

public class BeatBox.Station : BeatBox.Media {
	public override string key { get { return "station"; } }
	
	public string name { get; set; default = "Unknown Station"; }
	public string host { get; set; default = "Unknown Host"; }
	
	// non-traditional values here.
	//
	// title: The name of the station. For example, 'idobi Radio' or '98.5 The Rock'
	// artist: The host of the station. Not used yet AFAIK
	// album: Not used
	// genre: The genre of music this station fits in. For example, Top 40, Talk radio, Rock
	public override string title {
		get { return name; }
		set { name = value; }
	}
	
	// Points to host
	public override string artist {
		get { return host; }
		set { host = value; }
	}
	
	public override string album { get; set; default = ""; }
	public override string genre { get; set; default = ""; }
	
	public override MediaType media_type { get { return MediaType.STATION; } }
	public override bool is_local { 
		get { return false; } 
	}
	public override bool uses_resume_pos { get { return false; } }
	public override bool supports_gapless { get { return false; } }
	public override bool can_save_metadata { get { return false; } }
	public override bool can_seek { get { return false; } }
	public override string? backup_uri { get { return null; } }
	public override bool allow_fixing_length { get { return false; } }
	
	public string current_song_title { get; set; }
	public string current_song_album { get; set; }
	public string current_song_artist { get; set; }
	public string current_song_genre { get; set; }
	
	
	public Station(string uri) {
		base(uri);
	}
	
	public override string get_primary_display_text() {
		var title = (!String.is_empty(current_song_title)) ? ("<b>" + Markup.escape_text(current_song_title) + "</b>") : ("<b>" + _("Unknown Song") + "</b>");
		var artist = (!String.is_empty(current_song_artist) ? (_(" by ") + "<b>" + Markup.escape_text(current_song_artist) + "</b>") : "");
		var album = (!String.is_empty(current_song_album) ? (_(" on ") + "<b>" + Markup.escape_text(current_song_album) + "</b>") : "");
		
		return title + artist + album;
	}
	
	public override string get_secondary_display_text() {
		if(name == null) {
			return "";
		}
		
		return "<b>" + Markup.escape_text(name).replace("\n", "") + "</b>";
	}
	
	public override Media copy() {
		Station rv = new Station(uri);
		
		rv.file_size = file_size;
		rv.rowid = rowid;
		
		rv.name = name;
		rv.host = host;
		rv.album = album;
		rv.genre = genre;
		
		rv.current_song_title = current_song_title;
		rv.current_song_album = current_song_album;
		rv.current_song_artist = current_song_artist;
		rv.current_song_genre = current_song_genre;
		
		rv.comment = comment;
		rv.rating = rating;
		rv.play_count = play_count;
		rv.skip_count = skip_count;
		rv.date_added = date_added;
		rv.last_played = last_played;
		
		//rv.isPreview = isPreview;
		rv.isTemporary = isTemporary;
		rv.last_modified = last_modified;
		rv.pulseProgress = pulseProgress;
		rv.showIndicator = showIndicator;
		rv.unique_status_image = unique_status_image;
		rv.location_unknown = location_unknown;
		
		return rv;
	}
	
	public override void update_track(ref unowned GPod.Track t) {
		// Do nothing
	}
	
	/* caller must set ipod_path */
	public override GPod.Track track_from_media() {
		GPod.Track t = new GPod.Track();
		
		
		return t;
	}
	
	public override MediaEditorInterface? get_editor_widget() {
		return new StationEditor();
	}
}
