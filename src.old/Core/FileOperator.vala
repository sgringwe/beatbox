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

public class BeatBox.FileOperator : Object, FileInterface {
	GStreamerTagger tagger;
	GStreamerTagger art_tagger;
	
	bool inThread;
	LinkedList<Media> toSave;
	
	LinkedList<Media> new_imports;
	LinkedList<Media> all_new_imports;
	LinkedList<string> import_errors;
	bool _all_files_queued;
	
	public FileOperator() {
		inThread = false;
		toSave = new LinkedList<Media>();
		new_imports = new LinkedList<Media>();
		all_new_imports = new LinkedList<Media>();
		import_errors = new LinkedList<string>();
		
		tagger = new GStreamerTagger();
		art_tagger = new GStreamerTagger();
		
		tagger.media_imported.connect(media_imported);
		tagger.import_error.connect(import_error);
		tagger.queue_finished.connect(queue_finished);

		/* Create album-art cache dir */
		var album_art_folder = GLib.File.new_for_path(App.settings.get_album_art_cache_dir ());
		if(!album_art_folder.query_exists()) {
			try {
				album_art_folder.make_directory_with_parents(null);
			}
			catch(GLib.Error err) {
				warning ("Could not create folder in cache directory: %s", err.message);
			}
		}	
	}
	
	private bool is_valid_file_type(string type) {
		var typeDown = type.down();
		
		return (typeDown.has_suffix(".mp3") || typeDown.has_suffix(".m4a") || 
				typeDown.has_suffix(".wma") || typeDown.has_suffix(".ogg") || 
				typeDown.has_suffix(".flac") || typeDown.has_suffix(".mp4") || 
				typeDown.has_suffix(".oga") || typeDown.has_suffix(".m4p") ||
				typeDown.has_suffix(".aac") || typeDown.has_suffix(".alac"));
	}
	
	public void count_music_files(GLib.File music_folder, ref LinkedList<GLib.File> files) {
		GLib.FileInfo file_info = null;
		
		try {
			var enumerator = music_folder.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = music_folder.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					files.add(GLib.File.new_for_path(file_path));
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY) {
					count_music_files(GLib.File.new_for_path(file_path), ref files);
				}
			}
		}
		catch(GLib.Error err) {
			warning("Could not pre-scan music folder. Progress percentage may be off: %s", err.message);
		}
	}
	
	/** Queueing is done when setting the music folder, since that typically
	 * involves large folder hierarchies, and we want to concurrently find files
	 * and import them at the same time **/
	public async void queue_music_files_bootstrap_async () {
		try {
			new Thread<void*>.try (null, queue_music_files_bootstrap_thread);
		}
		catch (Error err) {
			warning ("Could not create thread for queue_music_files_bootstrap: %s", err.message);
		}
	}

	private void* queue_music_files_bootstrap_thread () {
		FilesOperation files_op = (FilesOperation)App.operations.current_op;
		queue_music_files (files_op.files.to_array()[0]);
		return null;
	}
	
	public void queue_music_files(GLib.File music_folder) {
		GLib.FileInfo file_info = null;
		
		try {
			var enumerator = music_folder.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = music_folder.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					++App.operations.operation_total;
					queue_file_to_import(GLib.File.new_for_path(file_path).get_uri());
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY) {
					queue_music_files(GLib.File.new_for_path(file_path));
				}
			}
		}
		catch(GLib.Error err) {
			warning("Could not pre-scan music folder. Progress percentage may be off: %s", err.message);
		}
        
        // Let it be known that all files are queued and may now finish import
        FilesOperation files_op = (FilesOperation)App.operations.current_op;
        if(music_folder.get_path() == files_op.files.to_array()[0].get_path()) {
			all_files_queued();
			
			// If we found no files, we have to say queue finished ourselves
			if(App.operations.operation_total == 0) {
				Idle.add( () => {
					queue_finished();
					return false;
				});
			}
		}
	}
	
	public void save_medias(Collection<Media> to_save) {
		// Only save permanent files who are songs or podcasts
		foreach(Media s in to_save) {
			if(!s.isTemporary && s.can_save_metadata)
				toSave.offer(s);
		}
		
		if(!inThread/* && App.window.initializationFinished*/) {
			try {
				inThread = true;
				new Thread<void*>.try (null, save_media_thread);
			}
			catch (Error err) {
				warning ("Could not create thread to rescan music folder: %s", err.message);
			}
		}
	}
        
	public void* save_media_thread () {
		while(true) {
			Media s = toSave.poll();
			
			if(s == null) {
				inThread = false;
				return null;
			}
			
			if(App.settings.main.write_metadata_to_file) {
				TagLib.File tag_file;
				tag_file = new TagLib.File(GLib.File.new_for_uri(s.uri).get_path());
				
				if(tag_file != null && tag_file.tag != null && tag_file.audioproperties != null) {
					try {
						tag_file.tag.title = s.title;
						tag_file.tag.artist = s.artist;
						tag_file.tag.album = s.album;
						tag_file.tag.genre = s.genre;
						tag_file.tag.comment = s.comment;
						tag_file.tag.year = s.year;
						tag_file.tag.track  = s.track;
						
						tag_file.save();
					}
					finally {
						
					}
				}
				else {
					debug ("Could not save %s.", s.uri);
				}
			}
			
			if(App.settings.main.update_folder_hierarchy)
				update_file_hierarchy(s, true, false, true);
		}
	}
	
	// TODO: Library's should have some sort of file naming convention function
	public GLib.File? get_new_destination(Media s) {
		Library library = App.library.get_library(s.key);
		
		if(library == null || library.folder == null) {
			warning("No library given for media %s. Cannot build new location for file", s.title);
			return null;
		}
		
		GLib.File dest;
		
		try {
			/* initialize file objects */
			GLib.File original = GLib.File.new_for_uri(s.uri);
			
			var ext = "";
			if(s.uri.has_prefix("cdda://"))
				ext = ".mp3";
			else
				ext = get_extension(s.uri);
			
			dest = GLib.File.new_for_path(Path.build_path("/", library.folder.get_path(), s.album_artist.replace("/", "_"), s.album.replace("/", "_"), s.track.to_string() + " " + s.title.replace("/", "_") + ext));
			
			if(original.get_path() == dest.get_path()) {
				debug("File is already in correct location");
				return null;
			}
			
			string extra = "";
			while((dest = GLib.File.new_for_path(Path.build_path("/", library.folder.get_path(), s.album_artist.replace("/", "_"), s.album.replace("/", "_"), s.track.to_string() + " " + s.title.replace("/", "_") + extra + ext))).query_exists()) {
				extra += "_";
			}
			
			/* make sure that the parent folders exist */
			if(!dest.get_parent().query_exists())
				dest.get_parent().make_directory_with_parents(null);
		}
		catch(GLib.Error err) {
			debug("Could not find new destination!: %s", err.message);
		}
		
		return dest;
	}
	
	public bool update_file_hierarchy(Media s, bool delete_old, bool emit_update, bool copy_album_art) {
		bool success = false;
		
		try {
			GLib.File dest = get_new_destination(s);
			if(dest == null)
				return false;
			
			GLib.File original = GLib.File.new_for_uri(s.uri);
			
			/* copy the file over */
			if(!delete_old) {
				debug("Copying %s to %s", s.uri, dest.get_uri());
				success = original.copy(dest, FileCopyFlags.NONE, null, null);
			}
			else {
				debug("Moving %s to %s", s.uri, dest.get_uri());
				success = original.move(dest, FileCopyFlags.NONE, null, null);
			}
			
			if(success || dest.query_exists()) {
				success = true;
				s.uri = dest.get_uri();
				
				// Save the uri change in the database
				Idle.add( () => {
					App.library.update_media(s, false, false, emit_update); return false;
				});
				
				if(copy_album_art && original.get_uri().has_prefix("file://") && 
				original.get_parent().get_path() != null) {
					var old_art_file = GLib.File.new_for_path(App.covers.get_best_album_art_file(s));
					var new_art_path = Path.build_path("/", dest.get_parent().get_path(), "Album.jpg");
					
					if(!GLib.File.new_for_path(new_art_path).query_exists() && old_art_file.query_exists() &&
					old_art_file.copy(GLib.File.new_for_path(new_art_path), FileCopyFlags.NONE, null, null)) {
						debug("Copied album art to %s", new_art_path);
					}
				}
			}
			else
				warning("Failure: Could not copy imported media %s to media folder %s", s.uri, dest.get_path());
			
			/* if we are supposed to delete the old, make sure there are no items left in folder if we do */
			if(delete_old) {
				var dummy = new LinkedList<GLib.File>();
				count_music_files(original.get_parent(), ref dummy);
				int old_folder_items = dummy.size;
				// must check for .jpg's as well.
				
				if(old_folder_items == 0) {
					debug("going to delete %s because no files are in it", original.get_parent().get_path());
					original.get_parent().delete();
				}
			}
		}
		catch(GLib.Error err) {
			warning("Could not copy imported media %s to media folder: %s", s.uri, err.message);
		}
		
		return success;
	}
	
	public void remove_medias(Collection<Media> to_remove) {
		var dummy_list = new LinkedList<GLib.File>();
		
		foreach(Media m in to_remove) {
			try {
				var file = GLib.File.new_for_uri(m.uri);
				file.trash();
				
				if(file.get_parent().query_exists()) {
					count_music_files(file.get_parent(), ref dummy_list);
					int old_folder_items = dummy_list.size;
					
					//TODO: COPY ALBUM AND IMAGE ARTWORK
					if(old_folder_items == 0) {
						debug("Going to delete %s because no files are in it", file.get_parent().get_path());
						file.get_parent().delete();
						
						if(file.get_parent().get_parent().query_exists()) {
							dummy_list.clear();
							count_music_files(file.get_parent().get_parent(), ref dummy_list);
							int old_folder_parent_items = dummy_list.size;
							
							if(old_folder_parent_items == 0) {
								debug("going to delete %s because no files are in it", file.get_parent().get_parent().get_path());
							}
						}
					}
				}
			}
			catch(GLib.Error err) {
				warning("Could not move file %s to trash: %s (you could be using a file system which is not supported)", m.uri, err.message);
				
				//tell the user the file could not be moved and ask if they'd like to delete permanently instead.
				//Gtk.MessageDialog md = new Gtk.MessageDialog(lm.lw, Gtk.DialogFlags.MODAL, Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, "Could not trash file %s, would you like to permanently delete it? You cannot undo these changes.", s);
			}
		}
	}
	
	/*public static void guess_content_type(GLib.File root, ref int audio, ref int other) {
		GLib.FileInfo file_info = null;
		
		try {
			var enumerator = root.enumerate_children(FileAttribute.STANDARD_NAME + "," + FileAttribute.STANDARD_TYPE, 0);
			while ((file_info = enumerator.next_file ()) != null) {
				var file_path = root.get_path() + "/" + file_info.get_name();
				
				if(file_info.get_file_type() == GLib.FileType.REGULAR && is_valid_file_type(file_info.get_name())) {
					++audio;
				}
				else if(file_info.get_file_type() == GLib.FileType.REGULAR) {
					++other;
				}
				else if(file_info.get_file_type() == GLib.FileType.DIRECTORY)
					guess_content_type(GLib.File.new_for_path(file_path), ref audio, ref other);
			}
		}
		catch(GLib.Error err) {
			message("Could not guess content types: %s", err.message);
		}
	}*/
	
	public string get_extension(string name) {
		return name.slice(name.last_index_of(".", 0), name.length);
	}
	
	// These methods are used to concurrently queue and import files
	public void start_import() {
		all_new_imports.clear();
		new_imports.clear();
		import_errors.clear();
		
		_all_files_queued = false;
		tagger.discoverer_start_import();
	}
	
	public void queue_file_to_import(string file) {
		if(App.library.media_from_file(file) == null)
			tagger.discoverer_queue_file(file);
	}
	
	void all_files_queued() {
		_all_files_queued = true;
	}
	
	// This method is for consecutive queue -> import
	public void import_files(Collection<GLib.File> files) {
		var new_files = new LinkedList<string>();
		foreach(var file in files) {
			if(App.library.media_from_file(file.get_uri()) == null)
				new_files.add(file.get_uri());
		}
		
		all_new_imports = new LinkedList<Media>();
		new_imports.clear();
		import_errors.clear();
		
		App.operations.operation_progress = 0;
		App.operations.operation_total = new_files.size;
		
		if(new_files.size == 0) {
			_all_files_queued = true;
			queue_finished();
		}
		else {
			tagger.discoverer_import_medias(new_files);
			_all_files_queued = true;
		}
	}
	
	void media_imported(Media m) {
		new_imports.add(m);
		all_new_imports.add(m);
		
		++App.operations.operation_progress;
		
		if(new_imports.size >= 200) {
			FilesOperation files_op = (FilesOperation)App.operations.current_op;
			files_op.library.add_medias(new_imports); // give user some feedback
			
			new_imports.clear();
		}
	}
	
	void import_error(string file) {
		++App.operations.operation_progress;
		import_errors.add(file);
	}
	
	void queue_finished() {
		if(!_all_files_queued)
			return;
		
		FilesOperation files_op = (FilesOperation)App.operations.current_op;
		files_op.imports = all_new_imports;
		files_op.failed_imports = import_errors;
		
		files_op.library.add_medias(new_imports);
		new_imports.clear();
		
		// If the user wants their imports to be copied to their music folder, transition
		// into that copy right now. If they don't, finish.
		if(files_op.should_copy() && App.settings.main.copy_imported_music) {
			App.operations.current_status = _("Copying files to %s Folder...").printf("<b>" + Markup.escape_text(files_op.library.name) + "</b>");
			App.operations.operation_progress = 0;
			
			try {
				new Thread<void*>.try (null, copy_imports_thread);
			}
			catch (Error err) {
				warning ("Could not create thread to copy files: %s", err.message);
			}
		}
		else {
			App.operations.finish_operation();
		}
	}
	
	public void* copy_imports_thread() {
		App.operations.operation_total = all_new_imports.size;
		
		foreach(Media s in all_new_imports) {
			if(!App.operations.operation_cancelled) {
				App.operations.current_status = _("Copying %s to %s Folder").printf("<b>" + Markup.escape_text(s.title) + "</b>", Markup.escape_text(((FilesOperation)App.operations.current_op).library.name));
				update_file_hierarchy(s, false, false, true);
			}
			
			++App.operations.operation_progress;
		}
		
		Idle.add( () => {
			App.library.update_medias(all_new_imports, false, false, false); // save new uri in db
			App.operations.finish_operation();
			
			return false;
		});
		
		return null;
	}
}
