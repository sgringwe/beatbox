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
 
public enum MediaType {
	SONG,
	PODCAST,
	AUDIOBOOK,
	STATION,
	VIDEO,
	TV_SHOW,
	ITEM;
	
	public string to_string(int n) {
		switch(this) {
			case SONG:
				return ngettext("Song", "Songs", n);
			case PODCAST:
				return ngettext("Podcast", "Podcasts", n);
			case AUDIOBOOK:
				return ngettext("Audiobook", "Audiobooks", n);
			case STATION:
				return ngettext("Station", "Stations", n);
			case VIDEO:
				return ngettext("Video", "Videos", n);
			case TV_SHOW:
				return ngettext("TV Show", "TV Shows", n);
			case ITEM:
				return ngettext("Media", "Medias", n);
			default:
				error("Unknown media type");
		}
	}
}

public abstract class BeatBox.Media : GLib.Object {
	public abstract string key { get; } // Replacement for MediaType
	public static int PREVIEW_ROWID = -2;

	// basic info
	public int rowid { get; construct set; default = 0; }
	public string uri { get; set; default = ""; }
	public uint file_size { get; set; default = 0; }
	
	// tags that all inherit
	public bool has_embedded { get; set; default = false; }
	public bool is_video { get; set; default = false; }
	public uint length { get; set; default = 0; }
	public uint rating { get; set; default = 0; }
	public uint play_count { get; set; default = 0; }
	public uint skip_count { get; set; default = 0; }
	public uint date_added { get; set; default = 0; }
	public uint last_played { get; set; default = 0; }
	public uint last_modified { get; set; default = 0; }
	public string comment { get; set; default = ""; }
	
	public bool isTemporary { get; set; default = false; }
	public bool location_unknown { get; set; default = false; }
	
	public Gdk.Pixbuf? unique_status_image;
	public bool showIndicator;
	public int pulseProgress;
	
	public int resume_pos { get; set; default = 0; }
	
	
	// THESE SHOULD ONLY BE IN SONG
	public string composer { get; set; default = ""; }
	public string album_artist { get; set; default = ""; }
	public string grouping { get; set; default = ""; }
	public uint year { get; set; default = 0; }
	public uint track { get; set; default = 0; }
	public uint track_count { get; set; default = 0; }
	public uint album_number { get; set; default = 0; }
	public uint album_count { get; set; default = 0; }
	public uint bitrate { get; set; default = 0; }
	public uint bpm { get; set; default = 0; }
	public uint samplerate { get; set; default = 0; }
	public string lyrics { get; set; default = ""; }
	public string lastfm_url { get; set; default = ""; }
	
	// THESE SHOULD ONLY BE IN PODCAST
	public string rss_uri { get; set; default = ""; }
	public string podcast_url { get; set; default = ""; }
	public bool is_new_podcast { get; set; default = false; }
	public int date_released { get; set; default = 0; }
	
	// tags that all media types must have
	public abstract string title { get; set; }
	public abstract string artist { get; set; }
	public abstract string album { get; set; }
	public abstract string genre { get; set; }
	
	public abstract MediaType media_type { get; }
	public abstract bool is_local { get; }
	public abstract bool uses_resume_pos { get; }
	public abstract bool supports_gapless { get; }
	public abstract bool can_save_metadata { get; }
	public abstract bool can_seek { get; }
	public abstract string? backup_uri { get; }
	public abstract bool allow_fixing_length { get; }
	
	public abstract string get_primary_display_text();
	public abstract string get_secondary_display_text();
	public abstract Media copy();
	public abstract void update_track(ref unowned GPod.Track t);
	public abstract GPod.Track track_from_media();
	
	// For media editor
	public abstract MediaEditorInterface? get_editor_widget();
	
	//core stuff
	public Media(string uri) {
		this.uri = uri;
	}
	
	//audioproperties
	public string pretty_length() {
		uint minute = 0;
		uint seconds = length;
		
		while(seconds >= 60) {
			++minute;
			seconds -= 60;
		}
		
		return minute.to_string() + ":" + ((seconds < 10 ) ? "0" + seconds.to_string() : seconds.to_string());
	}
	
	public string pretty_last_played() {
		var t = Time.local(last_played);
		string rv = t.format("%m/%e/%Y %l:%M %p");
		return rv;
	}
	
	public string pretty_date_added() {
		var t = Time.local(date_added);
		string rv = t.format("%m/%e/%Y %l:%M %p");
		return rv;
	}
	
	public int compare(Media o) {
		int rv = 0;
		switch(media_type) {
			case MediaType.SONG:
				rv = compare_song(o);
				break;
			case MediaType.PODCAST:
				rv = compare_podcast(o);
				break;
			default:
				rv = compare_default(o);
				break;
		}
		return rv;
	}
	
	private int compare_song(Media o) {
		if (track == o.track) {
			return advanced_string_compare(title, o.title);
		}
		else {
			return (track > o.track) ? 1 : -1;
		}
	}
	
	private int compare_podcast(Media o) {
		if (date_released == o.date_released) {
			return advanced_string_compare(title, o.title);
		}
		else {
			return (date_released > o.date_released) ? 1 : -1;
		}
	}
	
	private int compare_default(Media o) {
		return advanced_string_compare(title, o.title);
	}
	
	int advanced_string_compare(string a, string b) {
		if(a == "" && b != "")
			return 1;
		else if(a != "" && b == "")
			return -1;
		else if(a == b)
			return 0;
		
		return (a > b) ? 1 : -1;
	}
}
