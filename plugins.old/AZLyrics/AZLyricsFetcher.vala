public class BeatBox.AZLyricsFetcher : Object, BeatBox.LyricFetcher {
	const string URL_FORMAT = "http://www.azlyrics.com/lyrics/%s/%s.html";

	public Lyrics fetch_lyrics (string title, string album_artist, string artist) throws LyricFetchingError {
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
			throw new LyricFetchingError.LYRICS_NOT_FOUND (@"Lyrics not found for $title");		

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
			warning("Regex error: %s. Lyrics will have bad text\n", err.message);
		}
		
		return rv;
	}
}
