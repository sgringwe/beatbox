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

public abstract class BeatBox.BaseLibrary : GLib.Object, BeatBox.Library {
	protected HashMap<int, Media> _medias;
	
	protected BaseLibrary() {
		_medias = new HashMap<int, Media>();
	}
	
	public abstract string key { get; }
	public abstract string name { get; }
	public abstract File folder { get; set; }
	public abstract File? default_folder { get; }
	public abstract bool uses_local_folder { get; }
	public abstract Type media_type { get; }
	public abstract PreferencesSection? preferences_section { get; }
	
	public abstract Media import_tags_to_media(Gst.DiscovererInfo info);
	
	public abstract Collection<SmartPlaylist> get_default_smart_playlists();
	
	public abstract void add_db_function(Collection<Media> added);
	public abstract void update_db_function(Collection<Media> updates);
	public abstract void remove_db_function(Collection<Media> removed);
	
	public int media_count() {
		return _medias.size;
	}
	
	public Gee.Collection<Media> medias() {
		return _medias.values;
	}
	
	public void add_medias(Collection<Media> new_media) {
		if(new_media.size == 0) // happens more often than you would think
			return;
		
		lock (_medias) {
			foreach(var s in new_media) {
				App.library.assign_id_to_media(s);
				_medias.set(s.rowid, s);
			}
		}
		
		if(new_media.size > 0) {
			add_db_function(new_media);
		}
		
		medias_added(new_media);
	}
	
	public void update_medias(Collection<Media> updates, bool updateMeta, bool record_time, bool emit) {
		foreach(Media s in updates) {
			if(s.isTemporary)
				continue;
			
			if(record_time)
				s.last_modified = (int)time_t();
		}
		
		if(emit)
			medias_updated(updates, updateMeta);
		
		/* now do background work. Note: Even if updateMeta is true, so must use preferences */
		if(updateMeta)
			App.files.save_medias(updates);
		
		update_db_function(updates);
	}
	
	public void remove_medias(Collection<Media> to_remove, bool trash) {
		medias_removed(to_remove); // call now so that lm.media_from_id() still works
		
		lock (_medias) {
			foreach(Media s in to_remove) {
				_medias.unset(s.rowid);
			}
		}

		foreach(var p in App.playlists.playlists()) {
			if(p is StaticPlaylist) {
				((StaticPlaylist)p).remove_medias(to_remove);
				App.playlists.update_playlist(p);
			}
		}
		
		remove_db_function(to_remove);
		
		if(trash) {
			App.files.remove_medias(to_remove);
		}
	}
	
	void clear_medias(bool locals_only) {
		var unset = new LinkedList<Media>();
		
		foreach(int i in _medias.keys) {
			Media s = _medias.get(i);
			
			// If it isn't temporary or on the web...
			if(!locals_only || s.is_local) {
				
				// If it is a podcast, just revert to the online version. Otherwise
				// remove the media
				
				// TODO: Abstract this
				if(locals_only && s.backup_uri != null) {
					s.uri = s.backup_uri;
				}
				else {
					unset.add(s);
				}
			}
		}
		
		remove_medias(unset, false);
	}
	
	public void set_local_folder(File folder) {
		//if(!App.operations.doing_ops) {
			FilesOperation op = new FilesOperation(this, set_local_folder_start_sync, set_local_folder_start_async, 
													set_local_folder_cancel, _("Setting %s Folder").printf(name));
			op.finished_func = import_operation_finished;
			op.files.add(folder);
			op.import_type = FilesOperation.ImportType.SET;
			App.operations.queue_operation(op);
		//}
		//else {
		//	warning("User tried to set music folder while doing operations");
		//}
	}
	
	private void set_local_folder_start_sync(Operation op) {
		File folder = ((FilesOperation)op).files.to_array()[0];
		
		App.operations.current_status = _("Importing %s from %s...").printf(Markup.escape_text(name.down()), "<b>" + Markup.escape_text(folder.get_path()) + "</b>");
		
		clear_medias(true);
		App.playback.clear_queue();
		App.playback.reset_history();
		App.playback.stop_playback();
		
		App.settings.main.music_mount_name = "";
		this.folder = folder;
	}
	
	private void set_local_folder_start_async(Operation op) {
		App.files.start_import();
		App.files.queue_music_files_bootstrap_async ();
	}
	
	private void set_local_folder_cancel(Operation op) {
		// Cancellation is instant
	}
	
	/** Add files to library operation **/
	public void add_files(Collection<File> files, bool from_command_line) {
		if(!App.operations.doing_ops) {
			FilesOperation op = new FilesOperation(this, add_files_start_sync, add_files_start_async, 
													add_files_cancel, _("Adding files to %s Library").printf(name));
			op.finished_func = import_operation_finished;
			op.files = files;
			op.import_type = from_command_line ? FilesOperation.ImportType.COMMANDLINE_IMPORT : FilesOperation.ImportType.IMPORT;
			App.operations.queue_operation(op);
		}
		else {
			warning("User tried to add files to library while doing operations");
		}
	}
	
	private void add_files_start_sync (Operation op) {
		App.operations.current_status = _("Adding files to %s library...").printf(name);
	}

	private void add_files_start_async (Operation op) {
		App.files.import_files(((FilesOperation)op).files);
	}
	
	private void add_files_cancel(Operation op) {
		// Cancellation is instant
	}
	
	/** Add folders to library **/
	public void add_folders(Collection<File> folders) {
		if(!App.operations.doing_ops) {
			FilesOperation op = new FilesOperation(this, add_folders_start_sync, add_folders_start_async, 
													add_folders_cancel, _("Add folders to %s Library").printf(name));
			op.finished_func = import_operation_finished;
			op.files = folders;
			App.operations.queue_operation(op);
		}
		else {
			warning("User tried to add folders to library while doing operations");
		}
	}
	
	private void add_folders_start_sync (Operation op) {
		var folders = ((FilesOperation)op).files;
		
		if(folders.size == 1) {
			App.operations.current_status = _("Adding media from %s to %s library...").printf("<b>" + Markup.escape_text(folders.to_array()[0].get_path()) + "</b>", name);
		}
		else {
			App.operations.current_status = _("Adding media from %s folders to %s library...").printf("<b>" + folders.size.to_string() + "</b>", name);
		}
	}
	
	private void add_folders_start_async (Operation op) {
		var all_files = new LinkedList<File>();
		
		foreach(var folder in ((FilesOperation)op).files) {
			App.files.count_music_files(folder, ref all_files);
		}
		
		App.files.import_files(all_files);
	}
	
	private void add_folders_cancel(Operation op) {
		// Cancellation is instant
	}
	
	/** Rescan music folder operation **/
    public void rescan_local_folder() {
		if(!App.operations.doing_ops) {
			FilesOperation op = new FilesOperation(this, rescan_local_folder_start_sync, rescan_local_folder_start_async, 
													rescan_local_folder_cancel, _("Rescanning %s Folder").printf(name));
			op.finished_func = import_operation_finished;
			op.import_type = FilesOperation.ImportType.RESCAN;
			App.operations.queue_operation(op);
		}
		else {
			warning("User tried to rescan library folder while doing operations");
		}
	}
    
	private void rescan_local_folder_start_sync (Operation op) {
		App.operations.current_status = _("Rescanning %s folder for changes...").printf(name);
	}
 
	private void rescan_local_folder_start_async (Operation op) {
		HashMap<string, Media> paths = new HashMap<string, Media>();
		LinkedList<Media> to_remove = new LinkedList<Media>();
		LinkedList<File> to_import = new LinkedList<File>();
		
		App.operations.operation_total = 100;
		App.operations.operation_progress = 0;
		
		string local_folder_uri = folder.get_uri();
		foreach(Media s in _medias.values) {
			if(!s.isTemporary && s.uri.contains(local_folder_uri))
				paths.set(s.uri, s);
				
			if(s.uri.contains(local_folder_uri) && !File.new_for_uri(s.uri).query_exists())
				to_remove.add(s);
		}
		App.operations.operation_progress = 5;
		
		// get a list of the current files
		var files = new LinkedList<File>();
		App.files.count_music_files(File.new_for_uri(local_folder_uri), ref files);
		App.operations.operation_progress = 10;
		
		foreach(File f in files) {
			if(paths.get(f.get_uri()) == null)
				to_import.add(f);
		}
		
		debug ("Importing %d new items\n", to_import.size);
		if(to_import.size > 0) {
			App.files.import_files(to_import);
		}
		else {
			App.operations.operation_progress = 90;
		}
		
		Idle.add( () => {
			if(!App.operations.operation_cancelled)	remove_medias(to_remove, false);
			if(to_import.size == 0) {
				App.operations.finish_operation();
			}
			
			return false; 
		});
	}
	
	private void rescan_local_folder_cancel (Operation op) {
		App.operations.current_status = "Cancelling rescan...";
	}
	
	private void import_operation_finished(Operation op) {
		assert(op is FilesOperation);
		
		FilesOperation file_op = (FilesOperation)op;
		
		App.library.medias_imported(file_op.library, file_op.import_type, file_op.imports, file_op.failed_imports);
		
		if(file_op.import_type == FilesOperation.ImportType.COMMANDLINE_IMPORT) {
			if(file_op.imports.size > 0) {
				App.playback.play_media(file_op.imports.to_array()[0], false);
				
				if(!App.playback.playing) {
					App.playback.play();
				}
			}
		}
		
		App.library.recheck_files_not_found_async();
	}
}
