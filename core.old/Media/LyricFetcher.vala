/*-
 * Copyright (c) 2011-2012	   Scott Ringwelski <sgringwe@mtu.edu>
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

public errordomain FetchingError {
	LYRICS_NOT_FOUND,
	NO_INTERNET_CONNECTION
}

public class BeatBox.LyricFetcher : GLib.Object {

	private string artist;
	private string album_artist;
	private string title;
	
	public signal void lyrics_fetched (Lyrics _lyrics);
	
	public LyricFetcher() {
	}
	
	public void fetch_lyrics(string artist, string album_artist, string title) {
		this.artist = artist;
		this.album_artist = album_artist;
		this.title = title;
		
		try {
			new Thread<void*>.try (null, fetch_lyrics_thread);
		}
		catch(GLib.Error err) {
			warning ("ERROR: Could not create lyrics thread: %s \n", err.message);
		}
	}
	
	public void* fetch_lyrics_thread () {
		Lyrics lyrics = new Lyrics ();

		try {
			var source = new AZLyricsFetcher ();
			lyrics = source.fetch_lyrics (title, album_artist, artist);
		}
		catch (Error e) {
			if (e is FetchingError.LYRICS_NOT_FOUND) {
				lyrics.content = "";
			}
		}

		Idle.add( () => {
			lyrics_fetched (lyrics);
			return false;
		});
		
		return null;
	}

}

// TODO: A struct would me more convenient (and lighter)
public class Lyrics : Object {

	public string title;
	public string artist;
	public string content;

	public Lyrics () {
		title = "";
		artist = "";
		content = "";
	}
}

/** LYRIC SOURCES **/

private class AZLyricsFetcher : Object {

	private const string URL_FORMAT = "http://www.azlyrics.com/lyrics/%s/%s.html";

	public Lyrics fetch_lyrics (string title, string album_artist, string artist) throws FetchingError {
		Lyrics rv = new Lyrics ();
		rv.title = title;

		var url = parse_url (artist, title);
		File page = File.new_for_uri(url);

		uint8[] uintcontent;
		string etag_out;
		bool load_successful = false;
		
		try {
			page.load_contents(null, out uintcontent, out etag_out);
			load_successful = true;
			rv.artist = artist;
		}
		catch (Error err) {
			//warning("Could not load contents of %s : %s\n", url, err.message);
			load_successful = false;
		}

		// Try again using album artist
		if (!load_successful && album_artist != null && album_artist.length > 0) {
			try {
				url = parse_url (album_artist, title);
				page = File.new_for_uri (url);
				page.load_contents (null, out uintcontent, out etag_out);
				rv.artist = album_artist;
				load_successful = true;
			}
			catch (Error err) {
				//warning ("Could not load contents of %s : %s\n", url, err.message);
				load_successful = false;
			}
		}
		
		if (load_successful)
			rv.content = parse_lyrics (uintcontent) + "\n";
		else
			throw new FetchingError.LYRICS_NOT_FOUND (@"Lyrics not found for $title");		

		return rv;
	}
	
	private string parse_url (string artist, string title) {
		return URL_FORMAT.printf (fix_string (artist), fix_string (title));
	}
	
	private string fix_string (string? str) {
		if (str == null)
			return "";

		var fixed_string = new StringBuilder ();
		unichar c;
		
		for (int i = 0; str.get_next_char (ref i, out c);) {
			c = c.tolower();
			if (('a' <= c && c <= 'z') || ('0' <= c && c <= '9'))
				fixed_string.append_unichar (c);
		}

		return fixed_string.str;
	}

	private string parse_lyrics (uint8[] uintcontent) {
		string content = (string) uintcontent;
		string lyrics = "";
		var rv = new StringBuilder ();

		const string START_STRING = "<!-- start of lyrics -->";
		const string END_STRING = "<!-- end of lyrics -->";

		var start = content.index_of (START_STRING, 0) + START_STRING.length;
		var end = content.index_of (END_STRING, start);
		
		if (start != -1 && end != -1 && end > start) {
			lyrics = content.substring (start, end - start);
			rv.append(remove_html(lyrics).strip());
		}

		rv.append ("\n");

		return rv.str;
	}
	
	string remove_html(string s) {
		if(s == null || s == "")
			return "";
		
		string rv = s;
		
		try {
			var r = new Regex("<.*?>");
			rv = r.replace(s, s.length, 0, "");
		} catch(RegexError err) {
			warning("Regex error: %s. Now playing view will have bad text\n", err.message);
		}
		
		return rv;
	}
}

