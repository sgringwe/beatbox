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


// Note that a 'Podcast' represents a single episode within a podcast.
public class BeatBox.Podcast : BeatBox.Media {
	public override string key { get { return "podcast"; } }
	
	public uint episode { get; set; } // The episode #
	public string author { get; set; } // Author of podcast. example) NPR
	public string name { get; set; } // name of the entire podcast. example) NPR Car Talk
	public string category { get; set; } // Category, or genre, of this podcast. Ex) Hobbies
	public string description { get; set; } 
	
	// Title is the only normal usage here.
	public override string title { get; set; default = "Unknown Title"; }
	
	// Points to podcast author
	public override string artist { 
		get { return author; }
		set { author = value; }
	}
	
	// Points to podcast name
	public override string album {
		get { return name; }
		set { name = value; }
	}
	
	// Points to podcast category
	public override string genre {
		get { return category; }
		set { category = value; }
	}
	
	public override MediaType media_type { get { return MediaType.PODCAST; } }
	public override bool is_local { 
		get { return !isTemporary && !uri.has_prefix("http:/"); } 
	}
	public override bool uses_resume_pos { get { return true; } }
	public override bool supports_gapless { get { return true; } }
	public override bool can_save_metadata { get { return true; } }
	public override bool can_seek { get { return true; } }
	public override string? backup_uri { get { return podcast_url; } }
	public override bool allow_fixing_length { get { return true; } }
	
	public Podcast(string uri) {
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
		Podcast rv = new Podcast(uri);
		rv.file_size = file_size;
		rv.rowid = rowid;
		rv.episode = episode;
		rv.title = title;
		rv.author = author;
		rv.name = name;
		rv.category = category;
		rv.comment = comment;
		rv.length = length;
		rv.rating = rating;
		rv.play_count = play_count;
		rv.skip_count = skip_count;
		rv.date_added = date_added;
		rv.last_played = last_played;
		rv.description = description; 
		//rv.isPreview = isPreview;
		rv.isTemporary = isTemporary;
		rv.last_modified = last_modified;
		rv.pulseProgress = pulseProgress;
		rv.showIndicator = showIndicator;
		rv.unique_status_image = unique_status_image;
		rv.location_unknown = location_unknown;
		
		rv.podcast_url = podcast_url;
		rv.rss_uri = rss_uri;
		rv.is_new_podcast = is_new_podcast;
		rv.resume_pos = resume_pos;
		rv.date_released = date_released;
		
		return rv;
	}
	
	public string pretty_podcast_date() {
		var t = Time.local(date_released);
		string rv = t.format("%m/%e/%Y %l:%M %p");
		return rv;
	}
	
	public static Podcast podcast_from_track(string root, GPod.Track track) {
		Podcast rv = new Podcast("file://" + Path.build_path("/", root, GPod.iTunesDB.filename_ipod2fs(track.ipod_path)));
		
		rv.isTemporary = true;
		if(track.title != null) {			rv.title = track.title; }
		if(track.artist != null) {			rv.artist = track.artist; }
		//if(track.albumartist != null) {		rv.album_artist = track.albumartist; }
		if(track.album != null) {			rv.album = track.album; }
		if(track.genre != null) {			rv.genre = track.genre; }
		if(track.comment != null) {			rv.comment = track.comment; }
		//if(track.composer != null) {		rv.composer = track.composer; }
		//if(track.grouping != null) {		rv.grouping = track.grouping; }
		//rv.album_number = track.cd_nr;
		//rv.album_count = track.cds;
		//rv.track = track.track_nr;
		//rv.track_count = track.tracks;
		//rv.bitrate = track.bitrate;
		//rv.year = track.year;
		rv.date_added = (int)track.time_added;
		rv.last_modified = (int)track.time_modified;
		rv.last_played = (int)track.time_played;
		rv.rating = track.rating * 20;
		rv.play_count = track.playcount;
		//rv.bpm = track.BPM;
		rv.skip_count = track.skipcount;
		rv.length = track.tracklen  / 1000;
		rv.file_size = track.size;
		
		if(track.mediatype == GPod.MediaType.PODCAST) {
			rv.is_video = false;
		}
		else if(track.mediatype == 0x00000006) {
			rv.is_video = true;
		}
		
		rv.podcast_url = track.podcasturl;
		rv.is_new_podcast = track.mark_unplayed == 1;
		rv.resume_pos = (int)track.bookmark_time;
		rv.date_released = (int)track.time_released;
		
		//if(rv.artist == "" && rv.album_artist != null)
		//	rv.artist = rv.album_artist;
		//else if(rv.album_artist == "" && rv.artist != null)
		//	rv.album_artist = rv.artist;
		
		return rv;
	}
	
	public override void update_track(ref unowned GPod.Track t) {
		if(t == null)
			return;
			
		if(title != null) 			t.title = title;
		if(artist != null) 			t.artist = artist;
		//if(album_artist != null) 	t.albumartist = album_artist;
		if(album != null) 			t.album = album;
		if(genre != null) 			t.genre = genre;
		if(comment != null) 		t.comment = comment;
		//if(composer != null) 		t.composer = composer;
		//if(grouping != null)		t.grouping = grouping;
		//t.cd_nr = (int)album_number;
		//t.cds = (int)album_count;
		//t.track_nr = (int)track;
		//t.tracks = (int)track_count;
		//t.bitrate = (int)bitrate;
		//t.year = (int)year;
		t.time_modified = (time_t)last_modified;
		t.time_played = (time_t)last_played;
		t.rating = rating * 20;
		t.playcount = play_count;
		t.recent_playcount = play_count;
		//t.BPM = (uint16)bpm;
		t.skipcount = skip_count;
		t.tracklen = (int)length * 1000;
		t.size = file_size;
		t.lyrics_flag = 1;
		t.description = description;
		
		if(is_video)
			t.mediatype = 0x00000006;
		else
			t.mediatype = GPod.MediaType.PODCAST;
		
		t.podcasturl = podcast_url;
		t.mark_unplayed = (play_count == 0) ? 1 : 0;
		t.bookmark_time = resume_pos;
		t.time_released = date_released;
		
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
		//if(album_artist != null) 	t.albumartist = album_artist;
		if(album != null) 			t.album = album;
		if(genre != null) 			t.genre = genre;
		if(comment != null) 		t.comment = comment;
		//if(composer != null) 		t.composer = composer;
		//if(grouping != null)		t.grouping = grouping;
		//t.cd_nr = (int)album_number;
		//t.cds = (int)album_count;
		//t.track_nr = (int)track;
		//t.tracks = (int)track_count;
		//t.bitrate = (int)bitrate;
		//t.year = (int)year;
		t.time_modified = (time_t)last_modified;
		t.time_played = (time_t)last_played;
		t.rating = rating;
		t.playcount = play_count;
		t.recent_playcount = play_count;
		//t.BPM = (uint16)bpm;
		t.skipcount = skip_count;
		t.tracklen = (int)length * 1000;
		t.size = file_size;
		//t.lyrics_flag = 1;
		t.description = description;
		
		if(is_video)
			t.mediatype = 0x00000006;
		else
			t.mediatype = GPod.MediaType.PODCAST;
		
		t.podcasturl = podcast_url;
		t.mark_unplayed = (play_count == 0) ? 1 : 0;
		t.bookmark_time = resume_pos;
		t.time_released = date_released;
		
		if(t.artist == "" && t.albumartist != null)
			t.artist = t.albumartist;
		else if(t.albumartist == "" && t.artist != null)
			t.albumartist = t.artist;
		
		return t;
	}
	
	public override MediaEditorInterface? get_editor_widget() {
		return new PodcastEditor();
	}
}
