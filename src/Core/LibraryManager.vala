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
using SQLHeavy;
using BeatBox.String;

/** This is where all the media stuff happens. Here, medias are retrieved
 * from the db, added to the queue, sorted, and more. LibraryWindow is
 * the visual representation of this class
 */
public class BeatBox.LibraryManager : GLib.Object, BeatBox.LibraryInterface {
	private const string LOAD_KNOWN_LIBRARIES_QUERY = "SELECT rowid,* FROM 'known_libraries'";
	
	int top_id;
	HashMap<int, Media> _medias;
	HashMap<string, int> known_libraries;
	HashMap<string, Library> libraries;
	
	/*public TreeViewSetup music_setup { set; get; }
	public TreeViewSetup podcast_setup { set; get; }
	public TreeViewSetup station_setup  { set; get; }
	public TreeViewSetup similar_setup  { set; get; }
	public TreeViewSetup queue_setup  { set; get; }
	public TreeViewSetup history_setup  { set; get; }
	public TreeViewSetup album_list_setup  { set; get; }*/
	
	public Library song_library { get; protected set; }
	public Library podcast_library { get; protected set; }
	public Library station_library { get; protected set; }
	/*public Library audiobook_library { get; protected set; }
	public Library video_library { get; protected set; }*/
	
	public LibraryManager() {
		_medias = new HashMap<int, Media>();
		known_libraries = new HashMap<string, int>();
		libraries = new HashMap<string, Library>();
		
		load_known_libraries();
		
		// Connect signals
		App.covers.cover_changed.connect(cover_changed);
	}
	
	void load_known_libraries() {
		try {
			var results = App.database.execute(LOAD_KNOWN_LIBRARIES_QUERY);
			if(results == null) {
				warning("Could not load known libraries from database. Expect re-imports and duplicate smart playlists.");
				return;
			}
			
			for (; !results.finished; results.next() ) {
				string key = results.fetch_string(1);
				
				lock(known_libraries) {
					debug("Found known library %s", key);
					known_libraries.set (key, 1);
				}
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error loading known libraries. Expect re-imports and duplicate smart playlists.: %s", err.message);
		}
	}
	
	public void init_default_libraries() {
		song_library = new SongLibrary();
		podcast_library = new PodcastLibrary();
		station_library = new StationLibrary();
		
		add_library(song_library);
		add_library(podcast_library);
		add_library(station_library);
	}
	
	// Always run this method when adding a media
	public void assign_id_to_media(Media m) {
		if(m.rowid != 0 && m.rowid > top_id) {
			top_id = m.rowid;
		}
		else if(m.rowid == 0) {
			m.rowid = ++top_id;
		}
		
		// Either way, save it here so we have it
		_medias.set(m.rowid, m);
		
		// Just in case...
		if(m.date_added == 0) {
			m.date_added = (int)time_t();
		}
	}
	
	public Collection<Library> all_libraries() {
		return libraries.values;
	}
	
	public void add_library(Library library) {
		if(libraries.get(library.key) != null) {
			warning("Already a library for type %s.", library.key);
			return;
		}
		
		libraries.set(library.key, library);
		
		foreach(var m in library.medias()) {
			_medias.set(m.rowid, m);
		}
		
		// If it is not a 'known' library (aka, has been added before), then
		// do an initial import with its default_folder and add its default
		// smart playlists
		if(known_libraries.get(library.key) == 0) {
			known_libraries.set(library.key, 1);
			
			if(library.uses_local_folder && library.default_folder != null) {
				library.set_local_folder(library.default_folder);
			}
			
			foreach(var playlist in library.get_default_smart_playlists()) {
				App.playlists.add_playlist(playlist);
			}
			
			DatabaseTransactionFiller db_filler = new DatabaseTransactionFiller();
			db_filler.data = library;
			db_filler.filler = add_known_lib_to_db_filler;
			
			App.database.queue_transaction(db_filler);
		}
		
		library.medias_added.connect(medias_added_to_sub_library);
		library.medias_updated.connect(medias_updated_in_sub_library);
		library.medias_removed.connect(medias_removed_from_sub_library);
	}
	
	public Library? get_library(string key) {
		return libraries.get(key);
	}
	
	// We track all medias in this manager, and these listeners help us do just that.
	public void medias_added_to_sub_library(Collection<Media> added) {
		foreach(var m in added) {
			_medias.set(m.rowid, m);
		}
		
		medias_added(added);
	}
	
	void medias_updated_in_sub_library(Collection<Media> updated, bool metadata_changed) {
		medias_updated(updated, metadata_changed);
	}
	
	void medias_removed_from_sub_library(Collection<Media> removed) {
		foreach(var m in removed) {
			_medias.unset(m.rowid);
		}
		
		medias_removed(removed);
	}
	
	/** The following are helper methods that send control to the
	 * correct library based on the type **/
	public void add_media(Media new_media) {
		var collection = new LinkedList<Media>();
		collection.add(new_media);
		add_medias(collection);
	}
	
	public void add_medias(Collection<Media> new_media) {
		Library relevant_library;
		
		if((relevant_library = check_library_exists(new_media)) != null) {
			relevant_library.add_medias(new_media);
		}
		else {
			warning("No library found for added medias. Cannot add.");
		}
	}
	
	public void update_media(Media m, bool updateMeta, bool record_time, bool emit) {
		var collection = new LinkedList<Media>();
		collection.add(m);
		update_medias(collection, updateMeta, record_time, emit);
	}
	
	public void update_medias(Collection<Media> updates, bool updateMeta, bool record_time, bool emit) {
		Library relevant_library;
		
		if((relevant_library = check_library_exists(updates)) != null) {
			relevant_library.update_medias(updates, updateMeta, record_time, emit);
		}
		else {
			warning("No library found for updated medias. Cannot update.");
		}
	}
	
	public void remove_medias(Collection<Media> to_remove, bool trash) {
		Library relevant_library;
		
		if((relevant_library = check_library_exists(to_remove)) != null) {
			relevant_library.remove_medias(to_remove, trash);
		}
		else {
			warning("No library found for removed medias. Cannot remove.");
		}
	}
	
	Library? check_library_exists(Collection<Media> items) {
		if(items.size == 0)
			return null;
		
		Media to_test = items.to_array()[0];
		return libraries.get(to_test.key);
	}
	
	void add_known_lib_to_db_filler(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler) {
		Library added = (Library)db_filler.data;
		
		try {
			Query query = transaction.prepare ("INSERT INTO 'known_libraries' ('key') VALUES (:key);");
			query.set_string(":key", added.key);
			query.execute();
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not save known library: %s \n", err.message);
		}
	}
	
	void cover_changed(string artist, string album) {
		Gee.LinkedList<Media> updated_medias = new Gee.LinkedList<Media>();

		foreach(var m in medias()) {
			if(m.album_artist == artist && m.album == album) {
				updated_medias.add(m);
			}
		}
		
		Idle.add( () => {
			update_medias(updated_medias, false, false, true); return false;
		});
	}
	
	/*****************************************
	 * key for accessing album,artist objects
	 * ***************************************/
	public string album_key(Media m) {
		return m.album_artist + m.album;
	}
	
	public string artist_key(Media m) {
		return m.album_artist;
	}
	
	public void recheck_files_not_found_async () {
		try {
			new Thread<void*>.try (null, recheck_files_not_found_thread);
		}
		catch (GLib.Error err) {
			warning ("Could not create thread to check file locations: %s", err.message);
		}
	}

	private void* recheck_files_not_found_thread () {
		Media[] cache_media;
		var not_found = new LinkedList<Media>();
		var found = new LinkedList<Media>(); // files that location were unknown but now are found
		
		lock(_medias) {
			cache_media = _medias.values.to_array();
		}
		
		for(int i = 0; i < cache_media.length; ++i) {
			var m = cache_media[i];
			
			if(m.is_local) {
				if(File.new_for_uri(m.uri).query_exists() && m.location_unknown) {
					m.location_unknown = false;
					found.add(m);
				}
				else if(!File.new_for_uri(m.uri).query_exists() && !m.location_unknown) {
					m.location_unknown = true;
					not_found.add(m);
				}
			}
		}
		
		Idle.add( () => {
			if(not_found.size > 0) {
				warning("Some media files could not be found and are being marked as such.\n");
				warning("TODO: update_medias assumes consistent media type. How to deal with mixes?");
				update_medias(not_found, false, false, true);
				
				foreach(var m in not_found) {
					App.playback.media_not_found(m);
				}
			}
			if(found.size > 0) {
				warning("Some media files whose location were unknown were found.\n");
				warning("TODO: update_medias assumes consistent media type. How to deal with mixes?");
				update_medias(found, false, false, true);

				foreach(var m in found) {
					App.playback.media_found(m);
				}
			}
			
			return false;
		});
		
		return null;
	}
	
	/******************** Media stuff ******************/
	// We really only want to clear the songs that are permanent and on the file system
	// Dont clear podcasts that link to a url, device media, temporary media, previews, songs
	/*public void clear_medias() {
		var unset = new LinkedList<Media>();
		
		foreach(int i in _media.keys) {
			Media s = _media.get(i);
			
			// If it isn't temporary or on the web...
			if(!(s.isTemporary || s.isPreview || s.uri.has_prefix("http://"))) {
				
				// If it is a podcast, just revert to the online version. Otherwise
				// remove the media
				if( (s.mediatype == MediaType.PODCAST && s.podcast_url != null && s.podcast_url.has_prefix("http://")) || 
					s.mediatype == MediaType.STATION) {
					s.uri = s.podcast_url;
				}
				else {
					unset.add(s);
				}
			}
		}
		
		remove_medias(unset, false);
	}*/
	
	public int media_count() {
		return _medias.size;
	}
	
	public Collection<int> media_ids() {
		return _medias.keys;
	}
	
	public Collection<Media> medias() {
		return _medias.values;
	}
	
	public HashMap<int, Media> media_hash() {
		return _medias;
	}
	
	/** Used extensively. All other media data stores a media rowid, and then
	 * use this to retrieve the media. This is for memory saving and 
	 * consistency
	 */
	public Media media_from_id(int id) {
		return _medias.get(id);
	}
	
	public Media? match_media_to_list(Media m, Collection<Media> to_match) {
		Media? rv = null;
		
		lock (_medias) {
			foreach(var test in to_match) {
				if(!test.isTemporary && test != m && test.title.down() == m.title.down() && test.artist.down() == m.artist.down()) {
					rv = test;
					break;
				}
			}
		}
		
		return rv;
	}
	
	public Media? media_from_name(string title, string artist) {
		Media[] searchable;
		
		lock(_medias) {
			searchable = _medias.values.to_array();
		}
		
		for(int i = 0; i < searchable.length; ++i) {
			Media s = searchable[i];
			if(!s.isTemporary && s.title.down() == title.down() && s.artist.down() == artist.down()) {
				return s;
			}
		}
		
		return null;
	}
	
	public void medias_from_name(Collection<Media> tests, ref LinkedList<Media> found, ref LinkedList<Media> not_found) {
		Media[] searchable;
		
		lock(_medias) {
			searchable = _medias.values.to_array();
		}
		
		foreach(Media test in tests) {
			bool found_match = false;
			for(int i = 0; i < searchable.length; ++i) {
				Media s = searchable[i];
				if(test.title.down() == s.title.down() && test.artist.down() == s.artist.down()) {
					found.add(s);
					found_match = true;
					break;
				}
			}
			
			if(!found_match)
				not_found.add(test);
		}
	}
	
	public Media? media_from_file(string uri) {
		Media[] searchable;
		
		lock(_medias) {
			searchable = _medias.values.to_array();
		}
		
		for(int i = 0; i < searchable.length; ++i) {
			Media s = searchable[i];
			if(s.uri == uri) {
				return s;
			}
		}

		return null;
	}

	/**
	 * Search function
	 */
	public void do_search (Collection<Media> to_search,
	                        out LinkedList<Media> ? results,
	                        out LinkedList<Media> ? album_results,
	                        out LinkedList<Media> ? genre_results,
	                        out LinkedList<Media> ? year_results,
	                        out LinkedList<Media> ? rating_results,
	                        TreeViewSetup.Hint hint,
	                        string search = "", // Search string
	                        string album_artist = "",
	                        string album = "",
	                        string genre = "",
	                        int year = -1, // All years
	                        int rating = -1 // All ratings
	                        )
	{
		results = new LinkedList<Media>();
		album_results = new LinkedList<Media>();
		genre_results = new LinkedList<Media>();
		year_results = new LinkedList<Media>();
		rating_results = new LinkedList<Media>();

		int[] kmp_table = null;
		if(search.length > 0) {
			kmp_table = new int[search.length];
			kmp_generate_table(search, kmp_table);
		}

		bool include_temps = hint == TreeViewSetup.Hint.CDROM ||
		                     hint == TreeViewSetup.Hint.DEVICE_AUDIO || 
		                     hint == TreeViewSetup.Hint.DEVICE_PODCAST ||
		                     hint == TreeViewSetup.Hint.DEVICE_AUDIOBOOK ||
		                     hint == TreeViewSetup.Hint.QUEUE ||
		                     hint == TreeViewSetup.Hint.HISTORY ||
		                     hint == TreeViewSetup.Hint.ALBUM_LIST;
		
		foreach(Media s in to_search) {
			bool valid_song =   s != null && search.length > 0 &&
			                  ( !s.isTemporary || include_temps ) &&
			                  ( kmp_is_match(s.title, search, kmp_table) ||
			                    kmp_is_match(s.album_artist, search, kmp_table) ||
			                    kmp_is_match(s.artist, search, kmp_table) ||
			                    kmp_is_match(s.album, search, kmp_table) ||
			                    kmp_is_match(s.genre, search, kmp_table) ||
			                    search == s.year.to_string()); // We want full match here

			if (valid_song || search.length == 0)
			{
				if (rating == -1 || (int)s.rating == rating)
				{
					if (year == -1 || (int)s.year == year)
					{
						if (album_artist.length == 0 || s.album_artist == album_artist)
						{
							if (genre.length == 0 || s.genre == genre)
							{
								if (album.length == 0 || s.album == album)
								{
									results.add (s);
								}

								genre_results.add (s);
							}
					
							album_results.add (s);
						}

						year_results.add (s);
					}

					rating_results.add (s);
				}
			}
		}
	}
}

