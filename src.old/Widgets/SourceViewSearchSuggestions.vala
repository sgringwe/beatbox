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

using Gee;
using Gtk;

public class BeatBox.SourceViewSearchSuggestions : GLib.Object {
	public enum GroupType {
		TOP_MEDIAS,
		TOP_ARTISTS,
		TOP_ALBUMS,
		TOP_GENRES
	}
	
	public static GLib.List<Gtk.MenuItem> get_suggestions(SourceView source_view, GLib.List<Media> medias, string given_search) {
		var rv = new GLib.List<Gtk.MenuItem>();
		var search = given_search.down();
		
		var track_score = new HashMap<Media, int>(); // media.rowid, score
		var album_score = new HashMap<string, int>(); // artist - album, score
		var artist_score = new HashMap<string, int>(); // artist, score
		var genre_score = new HashMap<string, int>(); // artist, score
		
		// first calculate scores for each song. this is used to calculate
		// genre, artist, and album scores
		foreach(var m in medias) {
			var score = calculate_score(m, search);
			
			if(search in m.title.down()) {
				bool has_prefix = m.title.down().has_prefix(search);
				track_score.set(m, score + ((has_prefix) ? 3 : 0)); // extra score if search is in title of song
			}
			if(search in m.album.down()) {
				//track_score.set(m, score);
				bool has_prefix = m.album.down().has_prefix(search);
				album_score.set(m.album_artist + "<separator>" + m.album, album_score.get(m.album_artist + "<separator>" + m.album) + score + 2 + ((has_prefix) ? 3 : 0));
			}
			if(search in m.album_artist.down() || search in m.album_artist.down()) {
				//track_score.set(m, score);
				bool has_prefix = m.album_artist.down().has_prefix(search);
				album_score.set(m.album_artist + "<separator>" + m.album, album_score.get(m.album_artist + "<separator>" + m.album) + score + 1 + ((has_prefix) ? 3 : 0));
				artist_score.set(m.album_artist, artist_score.get(m.album_artist) + score + 1);
			}
			if(m.genre != "" && search in m.genre.down()) {
				//track_score.set(m, score);
				album_score.set(m.album_artist + "<separator>" + m.album, album_score.get(m.album_artist + "<separator>" + m.album) + score);
				artist_score.set(m.album_artist, artist_score.get(m.album_artist) + score);
				genre_score.set(m.genre, genre_score.get(m.genre) + score);
			}
		}
		
		// Find top 4
		var topTracks = getTopTracks(track_score, 5);
		var topArtists = getTopScores(artist_score, 4);
		var topAlbums = getTopScores(album_score, 5);
		var topGenres = getTopScores(genre_score, 3);
		
		// Convert to LinkedList<Media>
		var tracks = new LinkedList<Media>();
		foreach(var m in topTracks) {
			tracks.add(m);
		}
		
		var artists = new LinkedList<Media>();
		foreach(var artist in topArtists) {
			Media m = new Song("");
			m.album_artist = artist;
			artists.add(m);
		}
		
		var albums = new LinkedList<Media>();
		foreach(var album in topAlbums) {
			Media m = new Song("");
			
			string[] data = album.split("<separator>", 0);
			m.album_artist = data[0];
			m.album = data[1];
			
			albums.add(m);
		}
		
		var genres = new LinkedList<Media>();
		foreach(var genre in topGenres) {
			Media m = new Song("");
			m.genre = genre;
			genres.add(m);
		}
		
		bool results = false;
		if(tracks.size > 0) {
			results = true;
			
			foreach(var m in tracks) {
				var item = create_menu_item(m, GroupType.TOP_MEDIAS);
				rv.append(item);
				item.activate.connect( () => {
					App.playback.play_media(m, false);
					if(!App.playback.playing)
						App.playback.play();
					
					source_view.list_view.set_as_current_list(null);
				});
			}
			
			if(albums.size > 0 || artists.size > 0 || genres.size > 0)
				rv.append(new SeparatorMenuItem());
		}
		if(albums.size > 0) {
			results = true;
			
			foreach(var m in albums) {
				var item = create_menu_item(m, GroupType.TOP_ALBUMS);
				rv.append(item);
				item.activate.connect( () => {
					source_view.album_filter = m.album;
					source_view.artist_filter = m.album_artist;
					
					// User likely does not want to stare at 1 album
					if(App.window.get_current_view_selection() == 1)
						App.window.set_current_view_selection(0);
				});
			}
			
			if(artists.size > 0 || genres.size > 0)
				rv.append(new SeparatorMenuItem());
		}
		if(artists.size > 0) {
			results = true;
			
			foreach(var m in artists) {
				var item = create_menu_item(m, GroupType.TOP_ARTISTS);
				rv.append(item);
				item.activate.connect( () => {
					source_view.artist_filter = m.album_artist;
				});
			}
			
			if(genres.size > 0)
				rv.append(new SeparatorMenuItem());
		}
		if(genres.size > 0) {
			results = true;
			
			foreach(var m in genres) {
				var item = create_menu_item(m, GroupType.TOP_GENRES);
				rv.append(item);
				item.activate.connect( () => {
					source_view.genre_filter = m.genre;
					
					source_view.list_view.do_search (null);
					source_view.set_statusbar_info();
				});
			}
		}
		
		return rv;
	}
	
	static Gtk.MenuItem create_menu_item(Media m, GroupType type) {
		Gtk.MenuItem item;
		Gdk.Pixbuf? pixbuf = null;
		
		if(type == GroupType.TOP_ALBUMS || type == GroupType.TOP_MEDIAS)
			pixbuf = App.covers.get_album_art_from_media(m);
		if(pixbuf == null)
			pixbuf = App.icons.DEFAULT_ALBUM_ART_PIXBUF;
		
		if(type == GroupType.TOP_MEDIAS) {
			item = UI.create_suggestion_menu_item(m.title, m.artist, pixbuf);
		}
		else if(type == GroupType.TOP_ALBUMS) {
			item = UI.create_suggestion_menu_item(m.album, m.album_artist, pixbuf);
		}
		else if(type == GroupType.TOP_ARTISTS) {
			item = UI.create_suggestion_menu_item(m.album_artist, null, null);
		}
		else { // if(type == GroupType.TOP_GENRES) {
			item = UI.create_suggestion_menu_item(m.genre, null, null);
		}
		
		return item;
	}
	
	static int calculate_score (Media m, string search) {
		int rv = 0;
		
		rv = (int)(m.rating + (m.play_count) + ((m.last_played != 0) ? 1 : 0) +
					((search in m.title.down()) ? 2 : 0));
		
		return rv;
	}
	
	static LinkedList<string> getTopScores(HashMap<string, int> table, int size) {
		LinkedList<string> rv = new LinkedList<string>();
		
		int min_top_score = -1;
		foreach(var s in table.keys) {
			if(rv.size < size) {
				rv.add(s);
				
				if(table.get(s) < min_top_score || min_top_score == -1)
					min_top_score = table.get(s);
			}
			else if(table.get(s) > min_top_score) {
				// Find current minimum and remove it
				int current_min = -1;
				string current_string = "";
				foreach(var top in rv) {
					if(table.get(top) < current_min || current_min == -1) {
						current_min = table.get(top);
						current_string = top;
					}
				}
				
				rv.remove(current_string);
				rv.add(s);
				
				// find new min_top_score
				min_top_score = table.get(rv.get(0));
				foreach(var top in rv) {
					if(table.get(top) < min_top_score)
						min_top_score = table.get(top);
				}
			}
		}
		
		return rv;
	}
	
	static LinkedList<Media> getTopTracks(HashMap<Media, int> table, int size) {
		LinkedList<Media> rv = new LinkedList<Media>();
		
		int min_top_score = -1;
		foreach(var m in table.keys) {
			if(rv.size < size) {
				rv.add(m);
				
				if(table.get(m) < min_top_score || min_top_score == -1)
					min_top_score = table.get(m);
			}
			else if(table.get(m) > min_top_score) {
				// Find current minimum and remove it
				int current_min = -1;
				Media? current_media = null;
				foreach(Media top in rv) {
					if(table.get(top) < current_min || current_min == -1) {
						current_min = table.get(top);
						current_media = top;
					}
				}
				
				if(current_media != null) {
					rv.remove(current_media);
					rv.add(m);
				}
				
				// find new min_top_score
				min_top_score = table.get(rv.get(0));
				foreach(Media top in rv) {
					if(table.get(top) < min_top_score)
						min_top_score = table.get(top);
				}
			}
		}
		
		return rv;
	}
}
