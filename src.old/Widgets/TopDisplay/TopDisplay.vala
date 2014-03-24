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

public class BeatBox.TopDisplay : Box, BeatBox.TopDisplayInterface {
	private int current_display_key;
	private Gee.HashMap<int, Display> displays;
	private Gee.HashMap<Display, bool> display_enabled_map;
	
	private MetadataDisplay meta_display;
	private BufferDisplay buffer_display;
	private OperationDisplay operation_display;
	
	private Notebook view_container;
	private Button switch_button;
	private Button cancel_button;
	
	public TopDisplay() {
		displays = new Gee.HashMap<int, Display>();
		display_enabled_map = new Gee.HashMap<Display, bool>();
		current_display_key = -1;
		
        switch_button = new Button();
        view_container = new Notebook();
        cancel_button = new Button();
        
        view_container.show_tabs = false;
		view_container.show_border = false;
		
		switch_button.set_image(App.icons.GO_NEXT.render_image(IconSize.MENU));
		switch_button.set_relief(Gtk.ReliefStyle.NONE);
		
		cancel_button.set_image(App.icons.PROCESS_STOP.render_image (IconSize.MENU));
		cancel_button.set_relief(Gtk.ReliefStyle.NONE);
		cancel_button.set_no_show_all(true);
		
		this.set_orientation(Orientation.HORIZONTAL);
		this.pack_start(switch_button, false, false, 0);
		this.pack_start(view_container, true, true, 0);
		this.pack_start(cancel_button, false, false, 0);
		
		meta_display = new MetadataDisplay();
		buffer_display = new BufferDisplay();
		operation_display = new OperationDisplay();
		
		add_display(meta_display);
		add_display(buffer_display);
		add_display(operation_display);
		
		switch_button.clicked.connect(switch_clicked);
		cancel_button.clicked.connect(cancel_clicked);
		
		view_container.show_all();
		switch_button.show_all();
		set_no_show_all(true);
	}
	
	public int add_display(Display display) {
		int key = displays.size;
		
		displays.set(key, display);
		view_container.append_page(display);
		
		// Setup some signal handlers
		display.enabled.connect( () => {
			set_display_enabled(key, true);
		});
		display.disabled.connect( () => {
			set_display_enabled(key, false);
		});
		
		set_display_enabled(key, display.is_enabled);
		
		if(current_display_key != -1) {
			set_current_display(current_display_key); // Appending auto-switches, so switch back
		}
		
		return key;
	}
	
	public void set_display_enabled(int key, bool enabled) {
		Display d = displays.get(key);
		
		if(d != null/* && enabled != display_enabled_map.get(d)*/) {
			display_enabled_map.set(d, enabled);
			
			switch_button.set_visible(enabled_displays_count() > 1);
			
			if(enabled && key != current_display_key) {
				set_current_display(key);
			}
			else if(!enabled && key == current_display_key) {
				switch_clicked();
			}
		}
		
		set_visible(enabled_displays_count() > 0);
	}
	
	public bool remove_display(int key) {
		if(displays.get(key) != null) {
			Display d = displays.get(key);
			
			displays.unset(key);
			display_enabled_map.unset(d);
			view_container.remove_page(view_container.page_num(displays.get(key)));
			
			set_visible(enabled_displays_count() > 0);
			
			return true;
		}
		else {
			return false;
		}
	}
	
	void set_current_display(int key) {
		if(key < 0 || key >= view_container.get_n_pages())
			return;
		
		debug("setting current display to %d", key);
		current_display_key = key;
		
		Display d = displays.get(key);
		d.show_all();
		view_container.set_current_page(view_container.page_num(d));
		cancel_button.set_visible(d.is_cancellable());
	}
	
	void switch_clicked() {
		if(current_display_key == -1) // as a precaution
			return;
		
		int previous_key = current_display_key;
		
		int i = (current_display_key + 1) % displays.size;
		while(i != previous_key) {
			Display d = displays.get(i);
			
			if(display_enabled_map.get(d)) {
				set_current_display(i);
				break;
			}
			
			i = (i + 1) % displays.size;
		}
	}
	
	void cancel_clicked() {
		displays.get(current_display_key).cancel();
	}
	
	int enabled_displays_count() {
		int rv = 0;
		
		foreach(Display display in displays.values) {
			if(display_enabled_map.get(display)) {
				++rv;
			}
		}
		
		return rv;
	}
}

