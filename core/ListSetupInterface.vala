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

public interface BeatBox.ListSetupInterface : GLib.Object {
	public const string MUSIC_KEY = "<music_list_key>";
	public const string PODCAST_KEY = "<podcast_list_key>";
	public const string STATION_KEY = "<station_list_key>";
	public const string QUEUE_KEY = "<queue_list_key>";
	public const string HISTORY_KEY = "<history_list_key>";
	public const string SIMILAR_KEY = "<similar_list_key>";
	
	public abstract bool add_setup(string key, TreeViewSetup setup);
	public abstract TreeViewSetup? get_setup(string key); // Creates and returns a new one if none exists
	public abstract bool remove_setup(string key);
}
