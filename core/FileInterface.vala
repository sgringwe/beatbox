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

public interface BeatBox.FileInterface : GLib.Object {
	public abstract void count_music_files(GLib.File music_folder, ref LinkedList<GLib.File> files);
	public abstract async void queue_music_files_bootstrap_async ();
	public abstract void queue_music_files(GLib.File music_folder);
	
	public abstract void start_import();
	public abstract void queue_file_to_import(string file);
	public abstract void import_files(Collection<GLib.File> files);
	
	public abstract void save_medias(Collection<Media> to_save);
	public abstract void remove_medias(Collection<Media> to_remove);
	
	public abstract GLib.File? get_new_destination(Media s);
	
	public abstract bool update_file_hierarchy(Media s, bool delete_old, bool emit_update, bool copy_album_art);
}
