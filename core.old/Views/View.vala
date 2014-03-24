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

/* A high level interface for main views for easy plugin use.
 * 
 * Classes that implement this interface:
 * 		SourceView: Includes music, podcasts, stations, playlists, etc. Previously ViewWrapper
 *		MusicStoreView
 *		DeviceView: Would have sub views of MUSIC and PODCAST type
 *
 * This abstracts lots of the code such as the context menu, icons, search, statusbar text, and more
 * out from various areas and into the specific view.
 *
 * Allows for plugins to easily add a view by simply implementing this interface, and BeatBox
 * will take care of the low level details.
 *
 * Drafted by Scott Ringwelski for BeatBox Music Player
 *
 * 6/27/2012: Drafted first version
*/

public interface BeatBox.View : Gtk.Box {
	public enum ViewType {
		MUSIC,
		PODCAST,
		AUDIOBOOK,
		STATION,
		SIMILAR,
		QUEUE,
		HISTORY,
		PLAYLIST,
		SMART_PLAYLIST,
		CDROM,
		DEVICE,
		DEVICE_AUDIO,
		DEVICE_PODCAST,
		DEVICE_AUDIOBOOK,
		ALBUM_LIST,
		DUPLICATES,
		NOW_PLAYING,
		STORE;
	}
	
	public abstract ViewType get_view_type();
	public abstract Object? get_object(); // Users may associate object with a view
	
	// Sidebar stuff
	public abstract Gdk.Pixbuf get_view_icon();
	public abstract string get_view_name();
	public abstract GLib.List<View> get_sub_views(); // for example, devices come with sub views
	public abstract Gtk.Menu? get_context_menu();
	public abstract void set_as_current_view();
	public abstract void unset_as_current_view();
	public abstract bool can_receive_drop();
	public abstract void drag_received(Gtk.SelectionData data);
	public abstract SideTreeCategory get_sidetree_category();
	
	// Search
	public abstract bool supports_search();
	public abstract void search_activated(string search); // Again, i think it'd be good to only tell current view
	public abstract void search_changed(string search); // This is called after requested_search_timeout(). Can return null or search suggestions
	public abstract int requested_search_timeout(); // how long to wait before calling get_search_menu
	public abstract GLib.List<Gtk.MenuItem>? get_search_menu(string search);
	
	// View selector
	public abstract bool supports_view_selector();
	public abstract void view_selection_changed(int option); // TODO: Make that an enum
	
	// Playback
	public abstract bool can_set_as_current_list();
	public abstract void set_as_current_list(Media? m); // See view wrapper's implementation
	public abstract void play_first_media();
	
	// Other
	public abstract string? get_statusbar_text(); // null for no statusbar
	public abstract void reset_view(); // would probably only be used when user clears library
}
