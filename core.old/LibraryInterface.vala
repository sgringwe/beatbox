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

public interface BeatBox.LibraryInterface : GLib.Object {
	// The different libraries
	public abstract Library song_library { get; protected set; }
	public abstract Library podcast_library { get; protected set; }
	public abstract Library station_library { get; protected set; }
	/*public abstract Library audiobook_library { get; protected set; }
	public abstract Library video_library { get; protected set; }*/
	
	public signal void library_added(Library lib);
	public signal void library_removed(Library lib);
	
	public signal void medias_added(Collection<Media> added);
	public signal void medias_updated(Collection<Media> updated, bool metadata_changed = false);
	public signal void medias_removed(Collection<Media> removed);
	public signal void medias_imported(Library library, FilesOperation.ImportType import_type, Collection<Media> new_medias, Collection<string> not_imported);
	
	public abstract void assign_id_to_media(Media m);
	
	public abstract void medias_added_to_sub_library(Collection<Media> added);
	
	public abstract Collection<Library> all_libraries();
	public abstract void add_library(Library library);
	public abstract Library? get_library(string key);
	
	public abstract void add_media(Media new_media);
	public abstract void add_medias(Collection<Media> new_media);
	public abstract void update_media(Media m, bool updateMeta, bool record_time, bool emit);
	public abstract void update_medias(Collection<Media> updates, bool updateMeta, bool record_time, bool emit);
	public abstract void remove_medias(Collection<Media> to_remove, bool trash);
	
	public abstract void recheck_files_not_found_async();
	
	public abstract void do_search (Collection<Media> to_search,
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
	                        int rating = -1); // All years
	
	// Medias; All inclusive of all media types
	public abstract Collection<Media> medias();
	public abstract int media_count();
	public abstract Media media_from_id(int id);
	public abstract Media? media_from_file(string uri);
	public abstract Media? match_media_to_list(Media m, Collection<Media> to_match);
	public abstract Media? media_from_name(string title, string artist);
	public abstract void medias_from_name(Collection<Media> tests, ref LinkedList<Media> found, ref LinkedList<Media> not_found);
	
	public abstract string album_key(Media m);
}
