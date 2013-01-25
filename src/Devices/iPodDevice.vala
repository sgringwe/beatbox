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

using GPod;
using Gee;

public class BeatBox.iPodDevice : GLib.Object, BeatBox.Device {
	DevicePreferences pref;
	iTunesDB db;
	Mount mount;
	GLib.Icon icon;
	bool currently_syncing;
	bool currently_transferring;
	
	HashMap<unowned GPod.Track, Media> medias;
	HashMap<unowned GPod.Track, Media> songs;
	HashMap<unowned GPod.Track, Media> podcasts;
	HashMap<unowned GPod.Track, Media> audiobooks;
	HashMap<unowned GPod.Playlist, StaticPlaylist> playlists;
	HashMap<unowned GPod.Playlist, SmartPlaylist> smart_playlists;
	
	HashMap<Media, unowned GPod.Track> to_add; // used to add all new songs at the end when idle
	
	public iPodDevice(Mount mount) {
		this.mount = mount;
		
		pref = App.devices.get_device_preferences(get_unique_identifier());
		if(pref == null) {
			pref = new DevicePreferences(get_unique_identifier());
			App.devices.add_device_preferences(pref);
		}
		
		icon = mount.get_icon();
		currently_syncing = false;
		currently_transferring = false;
		
		medias = new HashMap<unowned GPod.Track, Media>();
		songs = new HashMap<unowned GPod.Track, Media>();
		podcasts = new HashMap<unowned GPod.Track, Media>();
		audiobooks = new HashMap<unowned GPod.Track, Media>();
		playlists = new HashMap<unowned GPod.Playlist, StaticPlaylist>();
		smart_playlists = new HashMap<unowned GPod.Playlist, SmartPlaylist>();
		to_add = new HashMap<Media, unowned GPod.Track>();
	}
	
	public DevicePreferences get_preferences() {
		return pref;
	}
	
	public bool start_initialization() {
		try {
			db = iTunesDB.parse(get_path());
		}
		catch(Error err) {
			stdout.printf("Error parsing db at %s: %s\n", get_path(), err.message);
			return false;
		}
		
		return true;
	}
	
	public void finish_initialization() {
		device_unmounted.connect( () => {
			
		});
		
		try {
			new Thread<void*>.try (null, finish_initialization_thread);
		}
		catch(Error err) {
			warning ("Could not create thread to finish ipod initialization: %s", err.message);
		}
	}
	
	void* finish_initialization_thread() {
		// get all songs first
		for(int i = 0; i < db.tracks.length(); ++i) {
			unowned GPod.Track t = db.tracks.nth_data(i);
			//stdout.printf("found track and rating is %d and app rating %d and id is %d\n", (int)db.tracks.nth_data(i).rating, (int)db.tracks.nth_data(i).app_rating, (int)db.tracks.nth_data(i).id);
			
			Media m;
			if(t.mediatype == GPod.MediaType.AUDIO) {
				m = Song.song_from_track(get_path(), t);
				this.medias.set(t, m);
				this.songs.set(t, m);
			}
			else if(t.mediatype == GPod.MediaType.PODCAST || t.mediatype == 0x00000006) {// 0x00000006 = video podcast
				m = Podcast.podcast_from_track(get_path(), t);
				this.medias.set(t, m);
				this.podcasts.set(t, m);
			}
			/*else if(t.mediatype == GPod.MediaType.AUDIOBOOK) {
				m = Audiobook.from_track(get_path(), t);
				this.medias.set(t, m);
				this.audiobooks.set(t, m);
			}*/
		}
		
		Idle.add( () => {
			initialized(this);
			
			return false;
		});
		
		return null;
	}
	
	public bool isNew() {
		return mount.get_default_location().get_parse_name().has_prefix("afc://");
	}
	
	public string getContentType() {
		if(isNew())
			return "ipod-new";
		else
			return "ipod-old";
	}
	
	public string getDisplayName() {
		return db.playlist_mpl().name;
	}
	
	public void setDisplayName(string name) {
		db.playlist_mpl().name = name;
		try {
			mount.get_default_location().set_display_name(name);
		}
		catch(GLib.Error err) {
			stdout.printf("Could not set iPod Mount Display Name: %s\n", err.message);
		}
		
		warning("TODO: Update side tree name");
		//App.window.sideTree.setNameFromObject(App.window.sideTree.convertToFilter(App.window.sideTree.devices_iter), this, name);
	}
	
	public string get_fancy_description() {
		/*unowned GPod.iPodInfo ipod_info = db.device.get_ipod_info();
		stdout.printf("got here\n");
		GPod.iPodModel enum_model = ipod_info.ipod_model;
		GPod.iPodGeneration enum_gen = ipod_info.ipod_generation;*/
		stdout.printf("got here\n");
		string model = "model here";//GPod.iPodInfo.get_ipod_model_name_string(enum_model);
		stdout.printf("got here\n");
		//var gen = GPod.iPodInfo.get_ipod_generation_string(enum_gen);
		string gen = "gen 1";
		return gen + " " + model;
	}
	
	public void set_mount(Mount mount) {
		this.mount = mount;
	}
	
	public Mount get_mount() {
		return mount;
	}
	
	public string get_path() {
		return mount.get_default_location().get_path();
	}
	
	public void set_icon(GLib.Icon icon) {
		this.icon = icon;
	}
	
	public GLib.Icon get_icon() {
		return icon;
	}
	
	public uint64 get_capacity() {
		uint64 rv = 0;
		
		try {
			var file_info = File.new_for_path(get_path()).query_filesystem_info("filesystem::*", null);
			rv = file_info.get_attribute_uint64(GLib.FileAttribute.FILESYSTEM_SIZE);
		}
		catch(Error err) {
			stdout.printf("Error calculating capacity of iPod: %s\n", err.message);
		}
		
		return rv;
	}
	
	public string get_fancy_capacity() {
		return _("Unknown Capacity");//db.device.get_ipod_info().capacity.to_string() + "GB";
	}
	
	public uint64 get_used_space() {
		return get_capacity() - get_free_space();
	}
	
	public uint64 get_free_space() {
		uint64 rv = 0;
		
		try {
			var file_info = File.new_for_path(get_path()).query_filesystem_info("filesystem::*", null);
			rv = file_info.get_attribute_uint64(GLib.FileAttribute.FILESYSTEM_FREE);
		}
		catch(Error err) {
			stdout.printf("Error calculating free space on iPod: %s\n", err.message);
		}
		
		return rv;
	}
	
	public void unmount() {
		if(mount != null) {
			mount.unmount_with_operation(MountUnmountFlags.NONE, null, null);
		}
	}
	
	public void eject() {
		
	}
	
	public void get_device_type() {
		
	}
	
	public bool supports_podcasts() {
		return db.device.supports_podcast();
	}
	
	public bool supports_audiobooks() {
		return true; // no device.supports_audiobook(), but there is audiobook playlist
	}
	
	public Collection<Media> get_medias() {
		return medias.values;
	}
	
	public Collection<Media> get_songs() {
		return songs.values;
	}
	
	public Collection<Media> get_podcasts() {
		return podcasts.values;
	}
	
	public Collection<Media> get_audiobooks() {
		return audiobooks.values;
	}
	
	public Collection<StaticPlaylist> get_static_playlists() {
		return playlists.values;
	}
	
	public Collection<SmartPlaylist> get_smart_playlists() {
		return smart_playlists.values;
	}
	
	public void sync_medias(LinkedList<Media> list) {
		if(!will_fit(list)) {
			warning("Tried to sync medias that will not fit\n");
			return;
		}
		
		if(!App.operations.doing_ops) {
			MediasOperation op = new MediasOperation(sync_medias_start_sync, sync_medias_start_async, sync_medias_cancel, _("Syncing %s").printf(Markup.escape_text(getDisplayName())));
			op.medias = list;
			App.operations.queue_operation(op);
		}
		else {
			warning("User tried to sync with device while doing operations");
		}
	}
	
	public void sync_medias_start_sync (Operation op) {
		App.operations.current_status = _("Syncing ") + " <b>" + Markup.escape_text(getDisplayName()) + "</b>...";
		to_add = new HashMap<Media, unowned GPod.Track>();
	}

	private void sync_medias_start_async (Operation op) {
		var list = ((MediasOperation)op).medias;
		currently_syncing = true;
		App.operations.operation_progress = 0;
		int sub_index = 0;
		App.operations.operation_total = 100;
		
		db.start_sync();
		
		// for each song that is on device, but not in this.list, remove
		sub_index = 0;
		App.operations.current_status = _("Removing old medias from iPod and updating current ones");
		var removed = new HashMap<unowned GPod.Track, Media>();
		foreach(var e in medias.entries) {
			if(!App.operations.operation_cancelled) {
				Media match = App.library.match_media_to_list(e.value, list);
				
				// If entry e is not on the list to be synced, it is to be removed
				if(match == null) {
					unowned GPod.Track t = e.key;
					
					if(t != null) {
						remove_media(t);
						removed.set(t, e.value);
					}
				}
			}
			
			++sub_index;
			App.operations.operation_progress = (int)(15.0 * (double)((double)sub_index/(double)medias.size));
		}
		
		medias.unset_all(removed);
		songs.unset_all(removed);
		podcasts.unset_all(removed);
		audiobooks.unset_all(removed);
		
		sub_index = 0;
		foreach(var entry in medias.entries) {
			if(!App.operations.operation_cancelled) {
				Media m = App.library.match_media_to_list(entry.value, list);
				if(m != null) {
					unowned GPod.Track t = entry.key;
					m.update_track(ref t);
					//stdout.printf("updated trac and its rating is %d\n", (int)t.rating);
					
					var pix_from_file = App.covers.get_art_from_media_folder(m);
					if(pix_from_file != null)
						t.set_thumbnails_from_pixbuf(pix_from_file);
				}
				else {
					warning("Could not update %s, no match in sync list. Should have been removed\n", entry.key.title);
				}
			}
			
			App.operations.operation_progress = (int)(15.0 + (double)(10.0 * (double)((double)sub_index /(double)medias.size)));
		}
		
		message("Adding new medias...\n");
		
		// now add all in list that weren't in medias
		App.operations.current_status = _("Adding new media to iPod...");
		sub_index = 0;
		int new_media_size = 0;
		var list_to_add = new LinkedList<Media>();
		foreach(Media m in list) {
			bool found_match = false;
			foreach(var test in medias.values) {
				if(test != m && test.title.down() == m.title.down() && test.artist.down() == m.artist.down()) {
					found_match = true;
					break;
				}
			}
			
			if(!found_match) {
				list_to_add.add(m);
				++new_media_size;
			}
		}
		
		// Actually add new items
		foreach(var m in list_to_add) {
			if(!App.operations.operation_cancelled) {
				add_media(m);
				++sub_index;
			}
			
			App.operations.operation_progress = (int)(25.0 + (double)(50.0 * (double)((double)sub_index/(double)new_media_size)));
		}
		
		App.operations.operation_progress = 78;
		
		if(!App.operations.operation_cancelled) {
			sync_playlists();
			sync_podcasts();
		}
		
		App.operations.current_status = App.operations.operation_cancelled ? _("Cancelling Sync...") : _("Finishing sync process...");
			
		try {
			db.write();
		}
		catch(GLib.Error err) {
			critical("Error when writing iPod database. iPod contents may be incorrect: %s\n", err.message);
		}
		
		App.operations.operation_progress = 98;
		
		if(!App.operations.operation_cancelled) {
			message("Cleaning up iPod music folder of unused files that are not in the database\n");
			var music_folder = File.new_for_path(GPod.Device.get_music_dir(get_path()));
			var used_paths = new LinkedList<string>();
			foreach(unowned GPod.Track t in medias.keys) {
				used_paths.add(Path.build_path("/", get_path(), GPod.iTunesDB.filename_ipod2fs(t.ipod_path)));
			}
			cleanup_files(music_folder, used_paths);
		}
			
		db.stop_sync();
		
		Idle.add( () => {
			pref.last_sync_time = (int)time_t();
			currently_syncing = false;
			sync_finished(!App.operations.operation_cancelled);
			App.operations.finish_operation();
			
			return false;
		});
	}
	
	private void sync_medias_cancel(Operation op) {
		warning("TODO: Implement me");
	}
	
	public bool is_syncing() {
		return currently_syncing;
	}
	
	public bool is_transferring() {
		return currently_transferring;
	}
	
	public bool will_fit(LinkedList<Media> list) {
		uint64 list_size = 0;
		foreach(var m in list) {
			list_size += m.file_size;
		}
		
		return get_capacity() > list_size;
	}
	
	/**********************************
	 * Specifically only adding medias. This is different and not a part
	 * of sync. This is usually called on drag and drop to iPod.
	 *********************************/
	public void add_medias(LinkedList<Media> list) {
		// Check if all current media + this list will fit.
		var new_list = new LinkedList<Media>();
		foreach(var m in list)
			new_list.add(m);
		foreach(var m in medias.values)
			new_list.add(m);
		
		if(!will_fit(new_list)) {
			warning("Tried to sync medias that will not fit\n");
			return;
		}
		
		if(!App.operations.doing_ops) {
			MediasOperation op = new MediasOperation(add_medias_start_sync, add_medias_start_async, add_medias_cancel, _("Syncing %s").printf(Markup.escape_text(getDisplayName())));
			op.medias = list;
			App.operations.queue_operation(op);
		}
		else {
			warning("User tried to sync with device while doing operations");
		}
	}
	
	private void add_medias_start_sync (Operation op) {
		App.operations.current_status = _("Syncing") + " <b>" + Markup.escape_text(getDisplayName()) + "</b>...";
		to_add = new HashMap<Media, unowned GPod.Track>();
	}

	private void add_medias_start_async (Operation op) {
		var list = ((MediasOperation)op).medias;
		currently_syncing = true;
		App.operations.operation_progress = 0;
		App.operations.operation_total = list.size + 2;
		
		db.start_sync();
		
		++App.operations.operation_progress;
		
		// Actually add new items
		foreach(var m in list) {
			if(!App.operations.operation_cancelled) {
				add_media(m);
				++App.operations.operation_progress;
			}
		}
		
		App.operations.current_status = App.operations.operation_cancelled ? _("Cancelling Sync...") : _("Finishing sync process...");
		++App.operations.operation_progress;
		
		try {
			db.write();
		}
		catch(Error err) {
			critical("Error when writing iPod database. iPod contents may be incorrect: %s\n", err.message);
		}
		
		db.stop_sync();
		
		Idle.add( () => {
			currently_syncing = false;
			sync_finished(!App.operations.operation_cancelled);
			App.operations.finish_operation();
			
			return false;
		});
	}
	
	private void add_medias_cancel(Operation op) {
		warning("TODO: Implement me");
	}
	
	/* Adds to track list, mpl, and copies the file over */
	void add_media(Media s) {
		if(s == null)
			return;
		
		GPod.Track t = s.track_from_media();
		
		var pix_from_file = App.covers.get_art_from_media_folder(s);
		if(pix_from_file != null)
			t.set_thumbnails_from_pixbuf(pix_from_file);
		
		App.operations.current_status = _("Adding") + " <b>" + Markup.escape_text(t.title) + "</b> " + 
							_("by") + " <b>" + Markup.escape_text(t.artist) + "</b> " + 
							_("to") + " " + Markup.escape_text(getDisplayName());
		message("Adding media %s by %s\n", t.title, t.artist);
		db.track_add((owned)t, -1);
		
		unowned GPod.Track added = db.tracks.nth_data(db.tracks.length() - 1);
		
		if(added == null || added.title != s.title) {
			warning("Track was not properly appended. Returning.\n");
			return;
		}
		
		unowned GPod.Playlist mpl = db.playlist_mpl();
		mpl.add_track(added, -1);
		
		if(added.mediatype == GPod.MediaType.PODCAST) {
			unowned GPod.Playlist ppl = db.playlist_podcasts();
			ppl.add_track(added, -1);
		}
		/*else if(added.mediatype == GPod.MediaType.AUDIOBOOK) {
			unowned GPod.Playlist apl = db.playlist_audiobooks();
			apl.add_track(added, -1);
		}*/
		
		bool success = false;
		try {
			success = GPod.iTunesDB.cp_track_to_ipod(added, File.new_for_uri(s.uri).get_path());
			debug("Copied media %s to ipod\n", added.title);
		}
		catch(Error err) {
			warning("Error adding/copying song %s to iPod: %s\n", s.title, err.message);
		}
		
		if(success) {
			Media m;
			if(added.mediatype == GPod.MediaType.AUDIO) {
				m = Song.song_from_track(get_path(), added);
				this.medias.set(added, m);
				this.songs.set(added, m);
			}
			else if(added.mediatype == GPod.MediaType.PODCAST || added.mediatype == 0x00000006) {// 0x00000006 = video podcast
				m = Podcast.podcast_from_track(get_path(), added);
				this.medias.set(added, m);
				this.podcasts.set(added, m);
			}
			/*else if(added.mediatype == GPod.MediaType.AUDIOBOOK) {
				m = Audiobook.from_track(get_path(), added);
				this.medias.set(added, m);
				this.audiobooks.set(added, m);
			}*/
		}
		else {
			warning("Failed to copy track %s to iPod. Removing it from database.\n", added.title);
			remove_media(added);
		}
	}
	
	/**********************************
	 * Specifically only removing medias. This is different and not a part
	 * of sync. This is usually called on right click -> Remove.
	 *********************************/
	public void remove_medias(LinkedList<Media> list) {
		if(!App.operations.doing_ops) {
			MediasOperation op = new MediasOperation(remove_medias_start_sync, remove_medias_start_async, remove_medias_cancel, _("Syncing %s").printf(Markup.escape_text(getDisplayName())));
			op.medias = list;
			App.operations.queue_operation(op);
		}
		else {
			warning("User tried to sync with device while doing operations");
		}
	}
	
	private void remove_medias_start_sync (Operation op) {
		App.operations.current_status = _("Removing from ") + " <b>" + Markup.escape_text(getDisplayName()) + "</b>...";
	}

	private void remove_medias_start_async (Operation op) {
		var list = ((MediasOperation)op).medias;
		currently_syncing = true;
		App.operations.operation_progress = 0;
		App.operations.operation_total = medias.size + 2;
		
		db.start_sync();
		
		++App.operations.operation_progress; // add first of 2 extra after sync
		
		var removed = new HashMap<unowned GPod.Track, Media>();
		foreach(var e in medias.entries) {
			foreach(var m in list) {
				if(!App.operations.operation_cancelled) {
					// If entry e is on the list to be removed, it is to be removed
					if(m == e.value) {
						unowned GPod.Track t = e.key;
						
						if(t != null) {
							remove_media(t);
							removed.set(t, e.value);
						}
					}
				}
			}
			
			++App.operations.operation_progress;
		}
		
		medias.unset_all(removed);
		songs.unset_all(removed);
		podcasts.unset_all(removed);
		audiobooks.unset_all(removed);
		
		App.operations.current_status = App.operations.operation_cancelled ? _("Cancelling Sync...") : _("Finishing sync process...");
		
		try {
			db.write();
		}
		catch(GLib.Error err) {
			critical("Error when writing iPod database. iPod contents may be incorrect: %s\n", err.message);
		}
		
		++App.operations.operation_progress;
		db.stop_sync();
		
		Idle.add( () => {
			currently_syncing = false;
			sync_finished(!App.operations.operation_cancelled);
			App.operations.finish_operation();
			
			return false;
		});
	}
	
	private void remove_medias_cancel(Operation op) {
		warning("TODO: Implement me");
	}
	
	void remove_media(GPod.Track t) {
		string title = t.title;
		
		App.operations.current_status = _("Removing") + " <b>" + Markup.escape_text(t.title) + "</b> " + 
							_("by") + " <b>" + t.artist + "</b> " + 
							_("from") + " " + Markup.escape_text(getDisplayName());
		/* first delete it off disk */
		if(t.ipod_path != null) {
			var path = Path.build_path("/", get_path(), GPod.iTunesDB.filename_ipod2fs(t.ipod_path));
			var file = File.new_for_path(path);
			
			if(file.query_exists()) {
				try {
					file.delete();
					debug("Successfully removed music file %s from iPod Disk\n", path);
				}
				catch(Error err) {
					warning("Could not delete iPod File at %s. Unused file will remain on iPod: %s\n", path, err.message);
				}
			}
			else {
				warning("File not found, could not delete iPod File at %s. File may already be deletedd\n", path);
			}
		}
		
		t.remove();
		
		db.playlist_mpl().remove_track(t);
		db.playlist_podcasts().remove_track(t);
		foreach(unowned GPod.Playlist p in db.playlists) {
			if(p.contains_track(t));
				p.remove_track(t);
		}
		
		message("Removed media %s\n", title);
	}
	
	void cleanup_files(GLib.File music_folder, LinkedList<string> used_paths) {
		GLib.FileInfo file_info = null;
		
		try {
			var enumerator = music_folder.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = Path.build_path("/", music_folder.get_path(), file_info.get_name());
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && !used_paths.contains(file_path)) { /* delete it, it's unused */
					stdout.printf("Deleting unused file %s\n", file_path);
					var file = File.new_for_path(file_path);
					file.delete();
				}
				else if(file_info.get_file_type() == GLib.FileType.REGULAR) {
					used_paths.remove(file_path);
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY) {
					cleanup_files(GLib.File.new_for_path(file_path), used_paths);
				}
			}
		}
		catch(GLib.Error err) {
			stdout.printf("Could not pre-scan music folder. Progress percentage may be off: %s\n", err.message);
		}
	}
	
	void sync_podcasts() {
		
	}
	
	/* should be called from thread */
	// index = 75 at this point. will go to 95
	private void sync_playlists() {
		App.operations.current_status = _("Syncing playlists");
		
		// first remove all playlists from db
		var all_playlists = new LinkedList<unowned GPod.Playlist>();
		foreach(unowned GPod.Playlist p in db.playlists) {
			if(!p.is_mpl() && !p.is_podcasts() && !p.is_audiobooks()) {
				all_playlists.add(p);
			}
		}
		foreach(unowned GPod.Playlist p in all_playlists) {
			p.remove();
		}
		
		App.operations.operation_progress = 78;
		
		int sub_index = 0;
		warning("TODO: FIxme");
		foreach(BasePlaylist base_playlist in App.playlists.playlists()) {
			if(base_playlist is StaticPlaylist) {
				StaticPlaylist playlist = (StaticPlaylist)base_playlist;
				
				GPod.Playlist p = playlist.get_gpod_playlist();
				db.playlist_add((owned)p, -1);
				
				unowned GPod.Playlist added = db.playlists.nth_data(db.playlists.length() - 1);
				foreach(var entry in medias.entries) {
					Media match = App.library.match_media_to_list(entry.value, App.playlists.playlist_from_id(playlist.id).analyze(new LinkedList<Media>()));
					if(match != null) {
						added.add_track(entry.key, -1);
					}
				}
			}
			else {
				SmartPlaylist playlist = (SmartPlaylist)base_playlist;
				
				GPod.Playlist p = playlist.get_gpod_playlist();
			
				db.playlist_add((owned)p, -1);
				unowned GPod.Playlist pl = db.playlists.nth_data(db.playlists.length() - 1);
				playlist.set_playlist_properties(pl);
			}
			
			++sub_index;
			App.operations.operation_progress = (int)(78.0 + (double)(7.0 * (double)((double)sub_index/(double)App.playlists.playlists().size)));
		}
		
		App.operations.operation_progress = 90;
		db.spl_update_live();
		App.operations.operation_progress = 95;
	}
	
	public void transfer_to_library(LinkedList<Media> list) {
		if(!App.operations.doing_ops) {
			MediasOperation op = new MediasOperation(transfer_to_library_start_sync, transfer_to_library_start_async, transfer_to_library_cancel, _("Transferring from %s").printf(Markup.escape_text(getDisplayName())));
			op.medias = list;
			App.operations.queue_operation(op);
		}
		else {
			warning("User tried to transfer from device while doing operations");
		}
	}
	
	private void transfer_to_library_start_sync (Operation op) {
		var list = ((MediasOperation)op).medias;
		App.operations.current_status = _("Importing %s items to library...").printf("<b>" + list.size.to_string() + "</b>");
	}

	private void transfer_to_library_start_async (Operation op) {
		var list = ((MediasOperation)op).medias;
		currently_transferring = true;
		App.operations.operation_progress = 0;
		App.operations.operation_total = list.size;
		
		foreach(var m in list) {
			if(App.operations.operation_cancelled)
				break;
			
			Media copy = m.copy();
			if(File.new_for_uri(copy.uri).query_exists()) {
				copy.rowid = 0;
				copy.isTemporary = false;
				copy.date_added = (int)time_t();
				
				App.operations.current_status = _("Importing") + " <b>" + Markup.escape_text(copy.title) + "</b> " + _("to library");
				
				if(App.files.update_file_hierarchy(copy, false, false, false)) {
					App.library.add_media(copy);
				}
			}
			else {
				stdout.printf("Skipped transferring media %s. Either already in library, or has invalid file path to ipod.\n", copy.title);
			}
			
			++App.operations.operation_progress;
		}
		
		Idle.add( () => {
			currently_transferring = false;
			App.operations.finish_operation();
			
			return false;
		});
	}
	
	private void transfer_to_library_cancel(Operation op) {
		warning("TODO: Implement me");
	}
}
