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

public class BeatBox.Info : GLib.Object, BeatBox.InfoInterface {
	private static string SEPARATOR = "<separator>";
	
	LinkedList<InfoSource> sources;
	
	public LastFMInterface lastfm { get; protected set; }
	public LyricsInterface lyrics { get; protected set; }
	
	HashMap<string, ArtistInfo> artists;
	HashMap<string, AlbumInfo> albums;
	HashMap<string, TrackInfo> tracks;
	
	public TrackInfo current_track { get; protected set; }
	public AlbumInfo current_album { get; protected set; }
	public ArtistInfo current_artist { get; protected set; }
	
	public Info() {
		lastfm = new LastFMCore();
		lyrics = new LyricsManager();
		
		sources = new LinkedList<InfoSource>();
		
		artists = new HashMap<string, ArtistInfo>();
		albums = new HashMap<string, AlbumInfo>();
		tracks = new HashMap<string, TrackInfo>();
		
		App.playback.media_played.connect(media_played);
		
		// We only periodically save this info in the database
		setup_periodic_saves();
		
		// Load what we already have from the database
		load_info_from_database();//Idle.add(load_info_from_database);
	}
	
	void setup_periodic_saves() {
		DatabaseTransactionFiller track_filler = new DatabaseTransactionFiller();
		track_filler.filler = periodic_track_filler;
		track_filler.pre_transaction_execute = "DELETE FROM 'tracks'";
		App.database.add_periodic_transaction(track_filler);
		
		DatabaseTransactionFiller album_filler = new DatabaseTransactionFiller();
		album_filler.filler = periodic_album_filler;
		album_filler.pre_transaction_execute = "DELETE FROM 'albums'";
		App.database.add_periodic_transaction(album_filler);
		
		DatabaseTransactionFiller artist_filler = new DatabaseTransactionFiller();
		artist_filler.filler = periodic_artist_filler;
		artist_filler.pre_transaction_execute = "DELETE FROM 'artists'";
		App.database.add_periodic_transaction(artist_filler);
	}
	
	bool load_info_from_database() {
		message("Loading info from database...");
		load_tracks();
		load_albums();
		load_artists();
		
		return false;
	}

	public void add_source(InfoSource source) {
		sources.add(source);
	}
	
	public void remove_source(InfoSource source) {
		sources.remove(source);
	}
	
	// These functions return null if nothing is yet fetched. It does not
	// fetch if nothing found
	public TrackInfo? get_track_info(string artist, string title) {
		return tracks.get(get_track_key(artist, title));
	}
	
	public AlbumInfo? get_album_info(string album_artist, string album) {
		return albums.get(get_album_key(album_artist, album));
	}
	
	public ArtistInfo? get_artist_info(string artist) {
		return artists.get(get_artist_key(artist));
	}
	
	public TrackInfo? get_track_info_from_key(string key) {
		return tracks.get(key);
	}
	
	public AlbumInfo? get_album_info_from_key(string key) {
		return albums.get(key);
	}
	
	public ArtistInfo? get_artist_info_from_key(string key) {
		return artists.get(key);
	}
	
	public TrackInfo? get_track_info_from_media(Media m) {
		return tracks.get(get_track_key(m.artist, m.title));
	}
	
	public AlbumInfo? get_album_info_from_media(Media m) {
		return albums.get(get_album_key(m.artist, m.album));
	}
	
	public ArtistInfo? get_artist_info_from_media(Media m) {
		return artists.get(get_artist_key(m.artist));
	}
	
	/** Fetchers. These use all the sources available to fetch
	 * the requested information. Once that info is found, it stops
	 * looking */
	public void fetch_track_info(string artist, string title) {
		if(sources.size == 0) {
			debug("User has no info sources!");
			return;
		}
		
		try {
			new Thread<void*>.try (null, () => {
				TrackInfo all_info = new TrackInfo();
				all_info.artist = artist;
				all_info.title = title;
				
				foreach(var source in sources) {
					TrackInfo temp = source.fetch_track_info(artist, title);
					all_info.merge_info(temp);
				}
				
				Idle.add( () => {
					tracks.set(get_track_key(artist, title), all_info);
					track_info_updated(all_info);
					
					if(App.playback.current_media != null && 
					App.playback.current_media.artist == artist && App.playback.current_media.title == title) {
						current_track = tracks.get(get_track_key(artist, title));
					}
					
					return false;
				});
				
				return null;
			});
		}
		catch (Error err) {
			warning ("Could not create thread: %s", err.message);
		}
	}
	
	public void fetch_album_info(string album_artist, string album) {
		if(sources.size == 0) {
			debug("User has no info sources!");
			return;
		}
		
		try {
			new Thread<void*>.try (null, () => {
				AlbumInfo all_info = new AlbumInfo();
				all_info.album_artist = album_artist;
				all_info.album = album;
				
				foreach(InfoSource source in sources) {
					AlbumInfo temp = source.fetch_album_info(album_artist, album);
					all_info.merge_info(temp);
				}
				
				if(!String.is_empty(all_info.art_uri) && App.covers.get_album_art_from_key(all_info.album_artist, all_info.album) == null) {
					App.covers.save_album_locally_for_meta(all_info.album_artist, all_info.album, all_info.art_uri, true);
				}
				
				Idle.add( () => {
					albums.set(get_album_key(album_artist, album), all_info);
					album_info_updated(all_info);
					
					if(App.playback.current_media != null && 
					App.playback.current_media.album_artist == album_artist && App.playback.current_media.album == album) {
						current_album = albums.get(get_album_key(album_artist, album));
					}
					
					return false;
				});
				
				return null;
			});
		}
		catch (Error err) {
			warning ("Could not create thread: %s", err.message);
		}
	}
	
	public void fetch_artist_info(string artist) {
		if(sources.size == 0) {
			debug("User has no info sources!");
			return;
		}
		
		try {
			new Thread<void*>.try (null, () => {
				ArtistInfo all_info = new ArtistInfo();
				all_info.artist = artist;
				
				foreach(InfoSource source in sources) {
					ArtistInfo temp = source.fetch_artist_info(artist);
					all_info.merge_info(temp);
				}
				
				Idle.add( () => {
					artists.set(get_artist_key(artist), all_info);
					artist_info_updated(all_info);
					
					if(App.playback.current_media != null && App.playback.current_media.artist == artist) {
						current_artist = artists.get(get_artist_key(artist));
					}
					
					return false;
				});
				
				return null;
			});
		}
		catch (Error err) {
			warning ("Could not create thread: %s", err.message);
		}
	}
	
	public Collection<TrackInfo> get_tracks() {
		return tracks.values;
	}
	
	public Collection<AlbumInfo> get_albums() {
		return albums.values;
	}
	
	public Collection<ArtistInfo> get_artists() {
		return artists.values;
	}
	
	void media_played(Media m, Media? old) {
		current_track = tracks.get(get_track_key(m.artist, m.title));
		current_album = albums.get(get_album_key(m.album_artist, m.album));
		current_artist = artists.get(get_artist_key(m.artist));
		
		Timeout.add(1000, () => {
			if(App.playback.current_media == m) {
				int player_duration = (int)(App.playback.get_duration()/1000000000);
				if(player_duration > 1 && Math.fabs((double)(player_duration - m.length)) > 3) {
					m.length = (int)(App.playback.get_duration()/1000000000);
					App.library.update_media(m, false, false, true);
				}
			}
			
			return false;
		});
		Timeout.add(3000, () => {
			if(App.playback.current_media == m) {
				// TODO: Fix logic for radio station to use current_song_*****
				
				//if(artists.get(get_artist_key(m.artist)) == null) {
					fetch_artist_info(m.artist);
				//}
				//if(albums.get(get_album_key(m.album, m.album_artist)) == null || App.covers.get_album_art_from_media(m) == null) {
					fetch_album_info(m.album_artist, m.album);
				//}
				//if(tracks.get(get_track_key(m.artist, m.title)) == null) {
					fetch_track_info(m.artist, m.title);
				//}
			}
			
			return false;
		});
	}
	
	// Use these to generate keys which are used as the keys for hashmaps
	public string get_track_key(string? artist, string? title) {
		if(artist == null || title == null)
			return "";
		
		return artist + SEPARATOR + title;
	}
	
	public string get_album_key(string? album_artist, string? album) {
		if(album_artist == null || album == null)
			return "";
		
		return album_artist + SEPARATOR + album;
	}
	
	public string get_artist_key(string? artist) {
		if(artist == null)
			return "";
		
		return artist;
	}
	
	// These load info from the database at startup
	void load_tracks() {
		try {
			var results = App.database.execute("SELECT rowid,* FROM 'tracks'");
			if(results == null) {
				warning("Could not fetch track info from database");
				return;
			}
			
			for (; !results.finished; results.next() ) {
				TrackInfo t = new TrackInfo();
				
				t.title = results.fetch_string(1);
				t.artist = results.fetch_string(2);
				t.full_desc = results.fetch_string(3);
				t.short_desc = results.fetch_string(4);
				t.merged_desc = results.fetch_string(5);
				t.load_tags(results.fetch_string(6));
				t.load_more_info_urls(results.fetch_string(7));
				t.lyrics = results.fetch_string(8);
				
				lock(tracks) {
					tracks.set(get_track_key(t.artist, t.title), t);
				}
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error loading tracks: %s", err.message);
		}
	}
	
	void load_albums() {
		try {
			var results = App.database.execute("SELECT rowid,* FROM 'albums'");
			if(results == null) {
				warning("Could not fetch album info from database");
				return;
			}
			
			for (; !results.finished; results.next() ) {
				AlbumInfo a = new AlbumInfo();
				
				a.album = results.fetch_string(1);
				a.album_artist = results.fetch_string(2);
				a.full_desc = results.fetch_string(3);
				a.short_desc = results.fetch_string(4);
				a.merged_desc = results.fetch_string(5);
				a.load_tags(results.fetch_string(6));
				a.load_more_info_urls(results.fetch_string(7));
				a.load_similar_albums(results.fetch_string(8));
				a.release_date = results.fetch_string(9);
				a.art_uri = results.fetch_string(10);
				
				lock(albums) {
					albums.set(get_album_key(a.album_artist, a.album), a);
				}
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error loading albums: %s", err.message);
		}
	}
	
	void load_artists() {
		try {
			var results = App.database.execute("SELECT rowid,* FROM 'artists'");
			if(results == null) {
				warning("Could not fetch artist info from database");
				return;
			}
			
			for (; !results.finished; results.next() ) {
				ArtistInfo a = new ArtistInfo();
				
				a.artist = results.fetch_string(1);
				a.full_desc = results.fetch_string(2);
				a.short_desc = results.fetch_string(3);
				a.merged_desc = results.fetch_string(4);
				a.load_tags(results.fetch_string(5));
				a.load_more_info_urls(results.fetch_string(6));
				a.load_similar_artists(results.fetch_string(7));
				a.photo_uri = results.fetch_string(8);
				
				lock(artists) {
					artists.set(get_artist_key(a.artist), a);
				}
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error loading artists: %s", err.message);
		}
	}
	
	// The periodic database transaction fillers
	void periodic_track_filler(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler) {
		try {
			SQLHeavy.Query query = transaction.prepare("""INSERT INTO 'tracks' ('title', 'artist', 'full_desc', 'short_desc', 'merged_desc', 'tags', 'more_info_urls', 'lyrics') 
														VALUES (:title, :artist, :full_desc, :short_desc, :merged_desc, :tags, :more_info_urls, :lyrics);""");
			
			foreach(TrackInfo t in tracks.values) {
				query.set_string(":title", t.title);
				query.set_string(":artist", t.artist);
				query.set_string(":full_desc", t.full_desc);
				query.set_string(":short_desc", t.short_desc);
				query.set_string(":merged_desc", t.merged_desc);
				query.set_string(":tags", t.get_tags_string());
				query.set_string(":more_info_urls", t.get_more_info_urls_string());
				query.set_string(":lyrics", t.lyrics);
				
				query.execute();
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error saving tracks: %s", err.message);
		}
	}
	
	void periodic_album_filler(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler) {
		try {
			SQLHeavy.Query query = transaction.prepare("""INSERT INTO 'albums' ('album', 'album_artist', 'full_desc', 'short_desc', 'merged_desc', 'tags', 'more_info_urls', 'release_date', 'similar_albums', 'art_uri') 
														VALUES (:album, :album_artist, :full_desc, :short_desc, :merged_desc, :tags, :more_info_urls, :release_date, :similar_albums, :art_uri);""");
			
			foreach(AlbumInfo a in albums.values) {
				query.set_string(":album", a.album);
				query.set_string(":album_artist", a.album_artist);
				query.set_string(":full_desc", a.full_desc);
				query.set_string(":short_desc", a.short_desc);
				query.set_string(":merged_desc", a.merged_desc);
				query.set_string(":tags", a.get_tags_string());
				query.set_string(":more_info_urls", a.get_more_info_urls_string());
				query.set_string(":release_date", a.release_date);
				query.set_string(":similar_albums", a.get_similar_albums_string());
				query.set_string(":art_uri", a.art_uri);
				
				query.execute();
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error saving albums: %s", err.message);
		}
	}
	
	void periodic_artist_filler(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler) {
		try {
			SQLHeavy.Query query = transaction.prepare("""INSERT INTO 'artists' ('artist', 'full_desc', 'short_desc', 'merged_desc', 'tags', 'more_info_urls', 'similar_artists', 'photo_uri') 
														VALUES (:artist, :full_desc, :short_desc, :merged_desc, :tags, :more_info_urls, :similar_artists, :photo_uri);""");
			
			foreach(ArtistInfo a in artists.values) {
				query.set_string(":artist", a.artist);
				query.set_string(":full_desc", a.full_desc);
				query.set_string(":short_desc", a.short_desc);
				query.set_string(":merged_desc", a.merged_desc);
				query.set_string(":tags", a.get_tags_string());
				query.set_string(":more_info_urls", a.get_more_info_urls_string());
				query.set_string(":similar_artists", a.get_similar_artists_string());
				query.set_string(":photo_uri", a.photo_uri);
				
				query.execute();
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error saving artists: %s", err.message);
		}
	}
}
