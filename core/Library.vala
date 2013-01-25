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

public interface BeatBox.Library : GLib.Object {
	public signal void medias_added(Collection<Media> added);
	public signal void medias_updated(Collection<Media> updated, bool metadata_changed = false);
	public signal void medias_removed(Collection<Media> removed);
	
	public abstract string key { get; }
	public abstract string name { get; }
	public abstract File folder { get; set; }
	public abstract File? default_folder { get; }
	public abstract bool uses_local_folder { get; }
	public abstract Type media_type { get; }
	public abstract PreferencesSection? preferences_section { get; }
	
	public abstract int media_count();
	public abstract void add_medias(Collection<Media> new_media);
	public abstract void update_medias(Collection<Media> updates, bool updateMeta, bool record_time, bool emit);
	public abstract void remove_medias(Collection<Media> to_remove, bool trash);
	public abstract Collection<Media> medias();
	
	public abstract void set_local_folder(File folder);
	public abstract void add_files(Collection<string> files, bool from_command_line);
	public abstract void add_folders(Collection<string> folders);
	public abstract void rescan_local_folder();
	
	public abstract Media import_tags_to_media(Gst.DiscovererInfo info);
	
	public abstract Collection<SmartPlaylist> get_default_smart_playlists();
}
