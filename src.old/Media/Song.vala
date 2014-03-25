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

public class BeatBox.Song : BeatBox.Media {
	public override string key { get { return "song"; } }
	
	// used mostly for temporary songs. For example,
	// a list of top 10 songs.
	public int rank { get; set; default = 0; }
	
	public override string title { get; set; default = "Unknown Title"; }
	public override string artist { get; set; default = "Unknown Artist"; }
	public override string album { get; set; default = ""; }
	public override string genre { get; set; default = ""; }
	
	public override MediaType media_type { get { return MediaType.SONG; } }
	public override bool is_local { 
		get { return !isTemporary; } 
	}
	public override bool uses_resume_pos { get { return false; } }
	public override bool supports_gapless { get { return true; } }
	public override bool can_save_metadata { get { return true; } }
	public override bool can_seek { get { return true; } }
	public override string? backup_uri { get { return null; } }
	public override bool allow_fixing_length { get { return true; } }
	
	public Song(string uri) {
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
		Song rv = new Song(uri);
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
		//rv.isPreview = isPreview;
		rv.isTemporary = isTemporary;
		rv.last_modified = last_modified;
		rv.pulseProgress = pulseProgress;
		rv.showIndicator = showIndicator;
		rv.unique_status_image = unique_status_image;
		rv.location_unknown = location_unknown;
		
		return rv;
	}
	
	public static Song song_from_track(string root, GPod.Track track) {
		Song rv = new Song("file://" + Path.build_path("/", root, GPod.iTunesDB.filename_ipod2fs(track.ipod_path)));
		
		rv.isTemporary = true;
		if(track.title != null) {			rv.title = track.title; }
		if(track.artist != null) {			rv.artist = track.artist; }
		if(track.albumartist != null) {		rv.album_artist = track.albumartist; }
		if(track.album != null) {			rv.album = track.album; }
		if(track.genre != null) {			rv.genre = track.genre; }
		if(track.comment != null) {			rv.comment = track.comment; }
		if(track.composer != null) {		rv.composer = track.composer; }
		if(track.grouping != null) {		rv.grouping = track.grouping; }
		rv.album_number = track.cd_nr;
		rv.album_count = track.cds;
		rv.track = track.track_nr;
		rv.track_count = track.tracks;
		rv.bitrate = track.bitrate;
		rv.year = track.year;
		rv.date_added = (int)track.time_added;
		rv.last_modified = (int)track.time_modified;
		rv.last_played = (int)track.time_played;
		rv.rating = track.rating * 20;
		rv.play_count = track.playcount;
		rv.bpm = track.BPM;
		rv.skip_count = track.skipcount;
		rv.length = track.tracklen  / 1000;
		rv.file_size = track.size;
		
		if(rv.artist == "" && rv.album_artist != null)
			rv.artist = rv.album_artist;
		else if(rv.album_artist == "" && rv.artist != null)
			rv.album_artist = rv.artist;
		
		return rv;
	}
	
	public override void update_track(ref unowned GPod.Track t) {
		if(t == null)
			return;
			
		if(title != null) 			t.title = title;
		if(artist != null) 			t.artist = artist;
		if(album_artist != null) 	t.albumartist = album_artist;
		if(album != null) 			t.album = album;
		if(genre != null) 			t.genre = genre;
		if(comment != null) 		t.comment = comment;
		if(composer != null) 		t.composer = composer;
		if(grouping != null)		t.grouping = grouping;
		t.cd_nr = (int)album_number;
		t.cds = (int)album_count;
		t.track_nr = (int)track;
		t.tracks = (int)track_count;
		t.bitrate = (int)bitrate;
		t.year = (int)year;
		t.time_modified = (time_t)last_modified;
		t.time_played = (time_t)last_played;
		t.rating = rating * 20;
		t.playcount = play_count;
		t.recent_playcount = play_count;
		t.BPM = (uint16)bpm;
		t.skipcount = skip_count;
		t.tracklen = (int)length * 1000;
		t.size = file_size;
		t.mediatype = GPod.MediaType.AUDIO;
		t.lyrics_flag = 1;
		t.description = lyrics;
		
		if(t.artist == "" && t.albumartist != null)
			t.artist = t.albumartist;
		else if(t.albumartist == "" && t.artist != null)
			t.albumartist = t.artist;
	}
	
	/* caller must set ipod_path */
	public override GPod.Track track_from_media() {
		GPod.Track t = new GPod.Track();
		
		if(title != null) 			t.title = title;
		if(artist != null) 			t.artist = artist;
		if(album_artist != null) 	t.albumartist = album_artist;
		if(album != null) 			t.album = album;
		if(genre != null) 			t.genre = genre;
		if(comment != null) 		t.comment = comment;
		if(composer != null) 		t.composer = composer;
		if(grouping != null)		t.grouping = grouping;
		t.cd_nr = (int)album_number;
		t.cds = (int)album_count;
		t.track_nr = (int)track;
		t.tracks = (int)track_count;
		t.bitrate = (int)bitrate;
		t.year = (int)year;
		t.time_modified = (time_t)last_modified;
		t.time_played = (time_t)last_played;
		t.rating = rating;
		t.playcount = play_count;
		t.recent_playcount = play_count;
		t.BPM = (uint16)bpm;
		t.skipcount = skip_count;
		t.tracklen = (int)length * 1000;
		t.size = file_size;
		t.mediatype = GPod.MediaType.AUDIO;
		t.lyrics_flag = 1;
		t.description = lyrics;
		
		if(t.artist == "" && t.albumartist != null)
			t.artist = t.albumartist;
		else if(t.albumartist == "" && t.artist != null)
			t.albumartist = t.artist;
		
		return t;
	}
	
	public override MediaEditorInterface? get_editor_widget() {
		return new SongEditor();
	}
}
