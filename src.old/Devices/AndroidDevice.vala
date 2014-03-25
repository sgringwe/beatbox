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

public class BeatBox.AndroidDevice : GLib.Object, BeatBox.Device {
	Mount mount;
	GLib.Icon icon;
	
	public AndroidDevice(Mount mount) {
		this.mount = mount;
	}
	
	public DevicePreferences get_preferences() {
		return new DevicePreferences(get_unique_identifier());
	}
	
	public bool start_initialization() {
		return false;
	}
	
	public void finish_initialization() {
		
		//initialized(this);
	}
	
	public string getContentType() {
		return "android";
	}
	public string getDisplayName() {
		return mount.get_name();
	}
	
	public void setDisplayName(string name) {
		
	}
	
	public string get_fancy_description() {
		return _("No Description");
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
		return (uint64)0;
	}
	
	public string get_fancy_capacity() {
		return _("Unknown capacity");
	}
	
	public uint64 get_used_space() {
		return (uint64)0;
	}
	
	public uint64 get_free_space() {
		return (uint64)0;
	}
	
	public void unmount() {
		
	}
	
	public void eject() {
		
	}
	
	public void get_device_type() {
		
	}
	
	public bool supports_podcasts() {
		return false;
	}
	
	public bool supports_audiobooks() {
		return false;
	}
	
	public Collection<Media> get_medias() {
		return new LinkedList<Media>();
	}
	
	public Collection<Media> get_songs() {
		return new LinkedList<Media>();
	}
	
	public Collection<Media> get_podcasts() {
		return new LinkedList<Media>();
	}
	
	public Collection<Media> get_audiobooks() {
		return new LinkedList<Media>();
	}
	
	public Collection<StaticPlaylist> get_static_playlists() {
		return new LinkedList<StaticPlaylist>();
	}
	
	public Collection<SmartPlaylist> get_smart_playlists() {
		return new LinkedList<SmartPlaylist>();
	}
	
	public void sync_medias(LinkedList<Media> list) {
		return;
	}
	
	public void add_medias(LinkedList<Media> list) {
		return;
	}
	
	public void remove_medias(LinkedList<Media> list) {
		return;
	}
	
	public bool will_fit(LinkedList<Media> list) {
		return false;
	}
	
	public void transfer_to_library(LinkedList<Media> list) {
		return;
	}
	
	public bool is_syncing() {
		return false;
	}
	
	public bool is_transferring() {
		return false;
	}
}
