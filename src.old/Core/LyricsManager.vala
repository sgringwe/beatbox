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
 * 
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */
 
public class BeatBox.LyricsManager : GLib.Object, BeatBox.LyricsInterface {
	Gee.LinkedList<LyricFetcher> sources;
	
	string artist;
	string album_artist;
	string title;
	
	public LyricsManager() {
		sources = new Gee.LinkedList<LyricFetcher>();
	}
	
	public void add_source(LyricFetcher source) {
		sources.add(source);
	}
	
	public void remove_source(LyricFetcher source) {
		sources.remove(source);
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
		
		foreach(var fetcher in sources) {
			try {
				lyrics = fetcher.fetch_lyrics (title, album_artist, artist);
			}
			catch (Error e) {
				// Try a different source...
				continue;
			}
			
			// If we get here, there was no error in fetching. Double check and
			// if we do indeed have lyrics, we are done.
			if(!String.is_empty(lyrics.content)) {
				break;
			}
		}
		
		// Whether or not we actually got lyrics, send the signal that we
		// are finished trying.
		Idle.add( () => {
			lyrics_fetched (lyrics);
			return false;
		});
		
		return null;
	}

}
