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

using Gtk;

public class BeatBox.AdvancedSearchBox : Granite.Widgets.SearchBar {
	Gtk.Menu search_suggester;
	bool listen_for_change;
	string last_search;
	
	View current_view;
	HashTable<View, string> views_search;
	
	public AdvancedSearchBox() {
		base(_("Search..."));
		
		search_suggester = new Gtk.Menu();
		search_suggester.attach_to_widget(this, null);
		search_suggester.set_size_request (Icons.ALBUM_VIEW_IMAGE_SIZE, -1);
		
		listen_for_change = true;
		views_search = new HashTable<View, string>(null, null);
		
		this.changed.connect(search_field_changed);
		this.activate.connect(search_field_activate);
		search_suggester.key_press_event.connect(keyPressed);
		App.window.view_changed.connect(view_changed);
	}
	
	void view_changed(View view) {
		if(current_view != null) {
			views_search.set(current_view, get_text());
		}
		
		current_view = view;
		
		if(views_search.get(current_view) != null) {
			listen_for_change = false;
			set_text(views_search.get(current_view));
			listen_for_change = true;
		}
	}
	
	void search_field_activate() {
		View view = App.window.get_current_view();
		
		if(view.supports_search()) {
			view.search_activated(get_text());
		}
	}
	
	void search_field_changed() {
		if(!listen_for_change) {
			return;
		}
		
		View view = App.window.get_current_view();
		var new_search = get_text();
		last_search = new_search;
		
		if(view.supports_search()) {
			// First notify that the search field changed
			view.search_changed(new_search);
			
			// Now to show the menu. Do so in a thread since it can take
			// a while potentially (analyzing, fetching to web).
			if(new_search == "") {
				clear_menu();
				search_suggester.popdown ();
			}
			else {
				if(view.requested_search_timeout() == 0) {
					start_show_menu_process(new_search);
				}
				else {
					Timeout.add(view.requested_search_timeout(), () => {
						start_show_menu_process(new_search);
						
						return false;
					});
				}
			}
		}
	}
	
	void start_show_menu_process(string search) {
		if(search == last_search && search.length > 2) {
			try {
				new Thread<void*>.try (null, update_contents);
			} catch (Error err) {
				warning ("Could not create search suggester thread: %s", err.message);
			}
		}
		else if(search.length <= 2) {
			clear_menu();
			search_suggester.popdown ();
		}
	}
	
	// go through visible table and find top tracks, albums, artists, genres.
	void* update_contents() {
		var new_menu_items = App.window.get_current_view().get_search_menu(last_search);
		
		Idle.add( () => {
			if(new_menu_items != null) {
				clear_menu();
				foreach(Gtk.MenuItem item in new_menu_items) {
					search_suggester.append(item);
				}
				
				search_suggester.show_all();
				search_suggester.popup (null, null, menu_pos_func, 3, get_current_event_time());
			}
			
			return false;
		});
		
		return null;
	}
	
	public void clear_menu() {
		foreach(var child in search_suggester.get_children()) {
			search_suggester.remove(child);
		}
	}
	
	bool keyPressed(Gdk.EventKey event) {
		if(event.keyval == 0xff08) { //backspace
			backspace ();
			return false;
		}
		else if(Regex.match_simple("[a-zA-Z0-9]", event.str) || 
				event.str == "-" || event.str == "-" || event.str == "&" ||
				event.str == "(" || event.str == ")" || event.str == "/" ||
				event.str == "." || event.str == "!" || event.str == "?" ||
				event.str == " ") {
			insert_at_cursor(event.str);
			return false;
		}

		return false;
	}
	
	void menu_pos_func(Gtk.Menu menu, out int x, out int y, out bool push_in) {
		int dest_x, dest_y;
		int win_x, win_y;
		translate_coordinates(App.window, 0, get_allocated_height(), out dest_x, out dest_y);
		App.window.get_position(out win_x, out win_y);
		
		x = dest_x + win_x;
		y = dest_y + win_y + 16;
		push_in = true;
	}
}
