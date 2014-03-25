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

public interface BeatBox.Device : GLib.Object {
	public signal void initialized(Device d);
	public signal void device_unmounted();
	public signal void progress_notification(string? message, double progress);
	public signal void sync_finished(bool success);
	
	public abstract DevicePreferences get_preferences();
	public abstract bool start_initialization();
	public abstract void finish_initialization();
	public abstract string getContentType();
	public abstract string getDisplayName();
	public abstract void setDisplayName(string name);
	public abstract string get_fancy_description();
	public abstract void set_mount(Mount mount);
	public abstract Mount get_mount();
	public abstract string get_path();
	public abstract void set_icon(GLib.Icon icon);
	public abstract GLib.Icon get_icon();
	public abstract uint64 get_capacity();
	public abstract string get_fancy_capacity();
	public abstract uint64 get_used_space();
	public abstract uint64 get_free_space();
	public abstract void unmount();
	public abstract void eject();
	public abstract void get_device_type();
	public abstract bool supports_podcasts();
	public abstract bool supports_audiobooks();
	public abstract Collection<Media> get_medias();
	public abstract Collection<Media> get_songs();
	public abstract Collection<Media> get_podcasts();
	public abstract Collection<Media> get_audiobooks();
	public abstract Collection<StaticPlaylist> get_static_playlists();
	public abstract Collection<SmartPlaylist> get_smart_playlists();
	public abstract void sync_medias(LinkedList<Media> list);
	public abstract void add_medias(LinkedList<Media> list);
	public abstract void remove_medias(LinkedList<Media> list);
	public abstract bool is_syncing();
	public abstract bool will_fit(LinkedList<Media> list);
	public abstract bool is_transferring();
	public abstract void transfer_to_library(LinkedList<Media> list);
	
	public string get_unique_identifier() {
		Mount m = get_mount();
		string uuid = m.get_uuid();
		File root = m.get_root();
		string rv = "";
		
		if(root != null && root.get_uri() != null) {
			rv += root.get_uri();
		}
		if(uuid != null && uuid != "") {
			rv += ("/" + uuid);
		}
		
		return rv;
	}
}
