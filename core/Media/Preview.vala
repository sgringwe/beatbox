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

public class BeatBox.Preview : BeatBox.Media {
	public override string key { get { return "preview"; } }
	
	// used mostly for temporary songs. For example,
	// a list of top 10 songs.
	public int rank { get; set; default = 0; }
	
	public override string title { get; set; default = "Unknown Title"; }
	public override string artist { get; set; default = "Unknown Artist"; }
	public override string album { get; set; default = ""; }
	public override string genre { get; set; default = ""; }
	
	public override MediaType media_type { get { return MediaType.SONG; } }
	public override bool is_local { 
		get { return false; } 
	}
	public override bool uses_resume_pos { get { return false; } }
	public override bool supports_gapless { get { return false; } }
	public override bool can_save_metadata { get { return false; } }
	public override bool can_seek { get { return true; } }
	public override string? backup_uri { get { return null; } }
	public override bool allow_fixing_length { get { return false; } }
	
	public Preview(string uri) {
		base(uri);
	}
	
	public override string get_primary_display_text() {
		string title = "<b>" + Markup.escape_text(title) + "</b>";
		string artist = ((artist != "" && artist != _("Unknown Artist")) ? (_(" by ") + "<b>" + Markup.escape_text(artist) + "</b>") : "");
		string album = ((album != "" && album != _("Unknown Album")) ? (_(" on ") + "<b>" + Markup.escape_text(album) + "</b>") : "");
		
		return title + artist + album;
	}
	
	public override string get_secondary_display_text() {
		return "";
	}
	
	public override Media copy() {
		Preview rv = new Preview(uri);
		rv.file_size = file_size;
		rv.rowid = rowid;
		rv.track = track;
		rv.track_count = track_count;
		rv.album_number = album_number;
		rv.album_count = album_count;
		rv.title = title;
		rv.artist = artist;
		rv.composer = composer;
		rv.album_artist = album_artist;
		rv.album = album;
		rv.genre = genre;
		rv.grouping = grouping;
		rv.comment = comment;
		rv.year = year;
		rv.bitrate = bitrate;
		rv.length = length;
		rv.samplerate = samplerate;
		rv.bpm = bpm;
		rv.rating = rating;
		rv.play_count = play_count;
		rv.skip_count = skip_count;
		rv.date_added = date_added;
		rv.last_played = last_played;
		rv.lyrics = lyrics;
		rv.isTemporary = isTemporary;
		rv.last_modified = last_modified;
		rv.pulseProgress = pulseProgress;
		rv.showIndicator = showIndicator;
		rv.unique_status_image = unique_status_image;
		rv.location_unknown = location_unknown;
		
		return rv;
	}
	
	public static Preview song_from_track(string root, GPod.Track track) {
		Preview rv = new Preview("");
		
		rv.isTemporary = true;
		
		return rv;
	}
	
	public override void update_track(ref unowned GPod.Track t) {
		
	}
	
	/* caller must set ipod_path */
	public override GPod.Track track_from_media() {
		GPod.Track t = new GPod.Track();
		
		return t;
	}
	
	public override MediaEditorInterface? get_editor_widget() {
		return null;
	}
}
