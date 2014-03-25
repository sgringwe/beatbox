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

public interface BeatBox.PlaylistInterface : GLib.Object {
	public signal void playlist_added(BasePlaylist p);
	public signal void playlist_changed(BasePlaylist p);
	public signal void playlist_removed(BasePlaylist p);
	
	public abstract int playlist_count();
	public abstract int add_playlist(BasePlaylist p);
	public abstract void update_playlist(BasePlaylist p);
	public abstract void remove_playlist(int id);
	public abstract BasePlaylist playlist_from_id(int id);
	public abstract BasePlaylist? playlist_from_name(string name);
	public abstract Collection<BasePlaylist> playlists();
	
	public abstract void add_playlist_to_library(Library library, string playlist_name, LinkedList<File> files);
}
