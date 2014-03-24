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

namespace BeatBox.PlaylistUtils {
	
	/** Saves a playlist as a .m3u file in the given folder **/
	public bool save_playlist_m3u(StaticPlaylist p, string folder) {
		bool rv = false;
		string to_save = "#EXTM3U";
		
		foreach(var s in p.medias()) {
			to_save += "\n\n#EXTINF:" + s.length.to_string() + ", " + s.artist + " - " + s.title + "\n" + File.new_for_uri(s.uri).get_path();
		}
		
		File dest = GLib.File.new_for_path(Path.build_path("/", folder, p.name.replace("/", "_") + ".m3u"));
		try {
			// find a file path that doesn't exist
			string extra = "";
			while((dest = GLib.File.new_for_path(Path.build_path("/", folder, p.name.replace("/", "_") + extra + ".m3u"))).query_exists()) {
				extra += "_";
			}
			
			var file_stream = dest.create(FileCreateFlags.NONE);
			
			// Write text data to file
			var data_stream = new DataOutputStream (file_stream);
			data_stream.put_string(to_save);
			rv = true;
		}
		catch(Error err) {
			warning("Could not save playlist %s to m3u file %s: %s\n", p.name, dest.get_path(), err.message);
		}
		
		return rv;
	}
	
	/** Saves a playlist as a .pls file in the given folder **/
	public bool save_playlist_pls(StaticPlaylist p, string folder) {
		bool rv = false;
		string to_save = "[playlist]\n\nNumberOfEntries=" + p.medias().size.to_string() + "\nVersion=2";
		
		int index = 1;
		foreach(var s in p.medias()) {
			to_save += "\n\nFile" + index.to_string() + "=" + File.new_for_uri(s.uri).get_path() + "\nTitle" + index.to_string() + "=" + s.title + "\nLength" + index.to_string() + "=" + s.length.to_string();
			++index;
		}
		
		File dest = GLib.File.new_for_path(Path.build_path("/", folder, p.name.replace("/", "_") + ".pls"));
		try {
			// find a file path that doesn't exist
			string extra = "";
			while((dest = GLib.File.new_for_path(Path.build_path("/", folder, p.name.replace("/", "_") + extra + ".pls"))).query_exists()) {
				extra += "_";
			}
			
			var file_stream = dest.create(FileCreateFlags.NONE);
			
			// Write text data to file
			var data_stream = new DataOutputStream (file_stream);
			data_stream.put_string(to_save);
			rv = true;
		}
		catch(Error err) {
			warning("Could not save playlist %s to pls file %s: %s\n", p.name, dest.get_path(), err.message);
		}
		
		return rv;
	}
	
	/** Parses the paths that are in the playlist file.
	 * 
	 * @param locals Filled all files that are on the file system
	 * @param stations Filled with uris that point to what is (likely) a station
	*/
	public bool parse_paths_from_m3u(string path, ref Gee.LinkedList<File> locals, ref Gee.LinkedList<Media> stations) {
		// now try and load m3u file
		// if some files are not found by media_from_file(), ask at end if user would like to import the file to library
		// if so, just do import_individual_files
		// if not, do nothing and accept that music files are scattered.
		
		var file = File.new_for_path(path);
		if(!file.query_exists())
			return false;
		
		try {
			string line;
			string previous_line = "";
			var dis = new DataInputStream(file.read());
			
			while ((line = dis.read_line(null)) != null) {
				if(line.has_prefix("http:/")) {
					Station s = new Station(line);
					
					s.name = "Radio Station";
					
					if(s.length <= 0)
						stations.add(s);
					else {
						var to_add = File.new_for_path(line);
						if(!to_add.query_exists())
							to_add = File.new_for_uri(line);
						
						locals.add(to_add);
					}
				}
				else if(line[0] != '#' && line.replace(" ", "").length > 0) {
					var to_add = File.new_for_path(line);
					if(!to_add.query_exists())
						to_add = File.new_for_uri(line);
					
					locals.add(to_add);
				}
				
				previous_line = line;
			}
		}
		catch(Error err) {
			warning("Could not load m3u file at %s: %s\n", path, err.message);
			return false;
		}
		
		return true;
	}
	
	/** Parses the paths that are in the playlist file.
	 * 
	 * @param locals Filled all files that are on the file system
	 * @param stations Filled with uris that point to what is (likely) a station
	*/
	public bool parse_paths_from_pls(string path, ref Gee.LinkedList<File> locals, ref Gee.LinkedList<Media> stations) {
		var files = new Gee.HashMap<int, string>();
		var titles = new Gee.HashMap<int, string>();
		var lengths = new Gee.HashMap<int, string>();
		
		var file = File.new_for_path(path);
		if(!file.query_exists())
			return false;
		
		try {
			string line;
			var dis = new DataInputStream(file.read());
			
			while ((line = dis.read_line(null)) != null) {
				if(line.has_prefix("File")) {
					parse_index_and_value("File", line, ref files);
				}
				else if(line.has_prefix("Title")) {
					parse_index_and_value("Title", line, ref titles);
				}
				else if(line.has_prefix("Length")) {
					parse_index_and_value("Length", line, ref lengths);
				}
			}
		}
		catch(Error err) {
			warning("Could not load m3u file at %s: %s\n", path, err.message);
			return false;
		}
		
		foreach(var entry in files.entries) {
			if(entry.value.has_prefix("http:/")/* && lengths.get(entry.key) != null && int.parse(lengths.get(entry.key)) <= 0*/)  {
				Station s = new Station(entry.value);
				s.name = titles.get(entry.key);
				
				if(s.name == null)
					s.name = "Radio Station";
				
				stations.add(s);
			}
			else {
				var to_add = File.new_for_path(entry.value);
				if(!to_add.query_exists())
					to_add = File.new_for_uri(entry.value);
				
				locals.add(to_add);
			}
		}
		
		
		return true;
	}
	
	// Helper method for pls parser
	void parse_index_and_value(string prefix, string line, ref Gee.HashMap<int, string> map) {
		int index;
		string val;
		string[] parts = line.split("=", 2);
		
		index = int.parse(parts[0].replace(prefix,""));
		val = parts[1];
		
		map.set(index, val);
	}
	
	/** Given a playlist, exports it as a pls or m3u (user choice).
	 * 
	 * @param main_window main window for the file chooser to know
	 * @param default_folder The default folder to show the user to save the playlist
	*/
	public void export_playlist_to_file(StaticPlaylist p, Gtk.Window main_window, File? default_folder) {
		string file = "";
		string name = "";
		string extension = "";
		
		var file_chooser = new Gtk.FileChooserDialog (_("Export Playlist"), main_window,
								  Gtk.FileChooserAction.SAVE,
								  Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
								  Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT);
		
		// filters for .m3u and .pls
		var m3u_filter = new Gtk.FileFilter();
		m3u_filter.add_pattern("*.m3u");
		m3u_filter.set_filter_name("MPEG Version 3.0 Extended (*.m3u)");
		file_chooser.add_filter(m3u_filter);
		
		var pls_filter = new Gtk.FileFilter();
		pls_filter.add_pattern("*.pls");
		pls_filter.set_filter_name("Shoutcast Playlist Version 2.0 (*.pls)");
		file_chooser.add_filter(pls_filter);
		
		file_chooser.do_overwrite_confirmation = true;
		file_chooser.set_current_name(p.name + ".m3u");
		
		// set original folder. if we don't, then file_chooser.get_filename() starts as null, which is bad for signal below.
		if(default_folder != null && default_folder.query_exists())
			file_chooser.set_current_folder(default_folder.get_path());
		else
			file_chooser.set_current_folder(Environment.get_home_dir());
			
		
		// listen for filter change
		file_chooser.notify["filter"].connect( () => {
			if(file_chooser.get_filename() == null) // happens when no folder is chosen. need way to get textbox text, rather than filename
				return;
			
			if(file_chooser.filter == m3u_filter) {
				debug("changed to m3u\n");
				var new_file = file_chooser.get_filename().replace(".pls", ".m3u");
				
				if(new_file.slice(new_file.last_index_of(".", 0), new_file.length).length == 0) {
					new_file += ".m3u";
				}
				
				file_chooser.set_current_name(new_file.slice(new_file.last_index_of("/", 0) + 1, new_file.length));
			}
			else {
				debug("changed to pls\n");
				var new_file = file_chooser.get_filename().replace(".m3u", ".pls");
				
				if(new_file.slice(new_file.last_index_of(".", 0), new_file.length).length == 0) {
					new_file += ".pls";
				}
				
				file_chooser.set_current_name(new_file.slice(new_file.last_index_of("/", 0) + 1, new_file.length));
			}
		});
		
		if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
			file = file_chooser.get_filename();
			extension = file.slice(file.last_index_of(".", 0), file.length);
			
			if(extension.length == 0 || extension[0] != '.') {
				extension = (file_chooser.filter == m3u_filter) ? ".m3u" : ".pls";
				file += extension;
			}
			
			name = file.slice(file.last_index_of("/", 0) + 1, file.last_index_of(".", 0));
			debug("Playlist name is %s extension is %s\n", name, extension);
		}
		
		file_chooser.destroy ();
		
		string original_name = p.name;
		if(file != "") {
			var f = File.new_for_path(file);
			
			string folder = f.get_parent().get_path();
			p.name = name; // temporary to save
			
			if(file.has_suffix(".m3u"))
				save_playlist_m3u(p, folder);
			else
				save_playlist_pls(p, folder);
		}
		
		p.name = original_name;
	}
}
