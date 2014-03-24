/*-
 * Copyright (c) 2012 Lucas Baudin <xapantu@gmail.com>
 *
 * Originally Written by Lucas Baudin for BeatBox Music Player
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

public interface BeatBox.LibraryWindowInterface : Gtk.Window {
	public abstract TopDisplayInterface top_display { get; protected set; }
	public abstract NowPlayingViewInterface now_playing { get; protected set; }
	public abstract ListSetupInterface setups { get; protected set; }
	public abstract ulong video_area_xid { get; }
	
	public abstract bool dragging_from_music { get; set; }
	
	public signal void view_changed(View view);
	
	public abstract void setup_playback();
    public abstract void update_sensitivities ();
    
    public abstract void add_view(View view);
    public abstract void remove_view(View view);
    public abstract void set_active_view(View view);
    public abstract View get_current_view ();
    public abstract View? get_view_from_object(GLib.Object object);
    
    public abstract void set_current_view_selection(int selected);
    public abstract int get_current_view_selection();
    
    public abstract int get_sidebar_width();
    public abstract void doAlert(string title, string sub_title);
    public abstract void confirm_set_library_folder(Library lib, File file);
    
    public abstract void show_notification(string title, string sub_title, Gdk.Pixbuf? pixbuf);
    
    public abstract void set_search_string(string search);
    
    // TODO: s/TreeViewSetup.Hint/MediaType
    public abstract void set_statusbar_info(TreeViewSetup.Hint media_type, uint medias, uint64 size, uint seconds);
    public abstract void add_statusbar_widget(Gtk.Widget w, bool left_side);
}
