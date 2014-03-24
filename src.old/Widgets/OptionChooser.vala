/* Copyright (c) 2011 Mathijs Henquet
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
 *
 * Authors:
 *      Mathijs Henquet <mathijs.henquet@gmail.com>
 *      ammonkey <am.monkeyd@gmail.com>
 * 		Scott Ringwelski <sgringwe@mtu.edu>
 *
 */

using Gtk;
using Gdk;
using Gee;

public class BeatBox.Option : GLib.Object {
	public string text { get; set; }
	public string tooltip { get; set; }
	public Image image { get; set; }
	public RadioMenuItem item { get; set; }
	
	public Option(string text, string tooltip, Image image) {
		this.text = text;
		this.tooltip = tooltip;
		this.image = image;
	}
}

public class BeatBox.OptionChooser : ToggleButton {
	/**
	 * MenuPosition:
	 * CENTER: Center-align the menu relative to the button's position.
	 * LEFT: Left-align the menu relative to the button's position.
	 * RIGHT: Right-align the menu relative to the button's position.
	 * INSIDE_WINDOW: Keep the menu inside the GtkWindow. Center-align when possible.
	 **/
	public enum MenuPosition {
		CENTER,
		LEFT,
		RIGHT,
		INSIDE_WINDOW
	}

	public Gtk.Action? myaction;
	public ulong toggled_sig_id;
	public MenuPosition menu_position;
	
	private int LONG_PRESS_TIME = Gtk.Settings.get_default ().gtk_double_click_time * 2;
	private int timeout = -1;
	private uint last_click_time = -1;

	private Gtk.Menu menu;
	
	HashMap<int, Option> options;

	int current_index;
	int previous_index; // for left click
	bool toggling;
	
	Box content;
	EventBox image_bin;

	public signal void option_changed(int index);

	public OptionChooser () {
		options = new HashMap<int, Option>();
		toggling = false;

		current_index = 0;
		previous_index = 0;
		
		this.menu_position = MenuPosition.LEFT;
		
		menu = new Gtk.Menu();
		content = new Box(Orientation.HORIZONTAL, 0);
		image_bin = new EventBox();
		var arrow = new Gtk.Arrow(ArrowType.DOWN, ShadowType.NONE);
		arrow.xalign = 1.0f;
		arrow.margin_left = 3;
		
		content.pack_start(image_bin, true, true, 0);
		content.pack_end(arrow, false, false, 0);
		
		menu.attach_to_widget(this, null);
		
		// make the event box transparent
		image_bin.set_above_child(true);
		image_bin.set_visible_window(false);

		mnemonic_activate.connect (on_mnemonic_activate);

		//var button = get_child () as Gtk.Button;
		add(content);
		events |= EventMask.BUTTON_PRESS_MASK
					  |  EventMask.BUTTON_RELEASE_MASK;

		button_press_event.connect (on_button_press_event);
		button_release_event.connect (on_button_release_event);
		
		show_all();
	}
	
	public void setOption(int index) {
		if(index < 0 || index >= options.size) {
			warning("Invalid index for setting option");
			return;
		}

		options.get(index).item.set_active(true);

		current_index = index;
		option_changed(index);

		if (image_bin.get_child () != null)
			image_bin.remove (image_bin.get_child());

		image_bin.add (options.get(index).image);

		show_all ();
	}

	public int append_option(string text, Gtk.Image image, string tooltip) {
		Option option = new Option(text, tooltip, image);
		Gtk.RadioMenuItem item;
		
		if (options.size == 0)
			item = new RadioMenuItem.with_label(new SList<Gtk.RadioMenuItem>(), text);
		else
			item = new RadioMenuItem.with_label_from_widget(options.get(0).item, text);
		
		image.set_tooltip_text(option.tooltip);
		menu.append(item);
		option.item = item;
		options.set(options.size, option);
		
		int this_index = options.size - 1;
		item.toggled.connect( () => {
			if(!toggling) {
				toggling = true;
				setOption(this_index);
				toggling = false;
			}
		});

		item.show();
		previous_index = options.size - 1;

		return options.size - 1;
	}
	
	private void update_menu_properties () {
		//menu.attach_to_widget (this, null);
		menu.deactivate.connect ( () => {
			deactivate_menu ();
		});
		menu.deactivate.connect (popdown_menu);
	}

	public override void show_all () {
		menu.show_all ();
		base.show_all ();
	}

	private void deactivate_menu () {
		if (myaction != null)
			myaction.block_activate ();

		active = false;

		if (myaction != null)
			myaction.unblock_activate ();
	}

	private void popup_menu_and_depress_button (Gdk.EventButton ev) {
		if (myaction != null)
			myaction.block_activate ();

		active = true;

		if (myaction != null)
			myaction.unblock_activate ();

		popup_menu (ev);
	}

	private bool on_button_release_event (Gdk.EventButton ev) {
		if (ev.time - last_click_time < LONG_PRESS_TIME) {
			if (myaction != null) {
				myaction.activate ();
			} else {
				active = true;
				popup_menu (ev);
			}
		}

		if (timeout != -1) {
			Source.remove ((uint) timeout);
			timeout = -1;
		}

		return true;
	}

	private bool on_button_press_event (Gdk.EventButton ev) {
		// If the button is kept pressed, don't make the user wait when there's no action
		int max_press_time = (myaction != null)? LONG_PRESS_TIME : 0;

		if (timeout == -1 && ev.button == 1) {
			last_click_time = ev.time;
			timeout = (int) Timeout.add(max_press_time, () => {
				// long click
				timeout = -1;
				popup_menu_and_depress_button (ev);
				return false;
			});
		}

		return true;
	}

	private bool on_mnemonic_activate (bool group_cycling) {
		// ToggleButton always grabs focus away from the editor,
		// so reimplement Widget's version, which only grabs the
		// focus if we are group cycling.
		if (!group_cycling) {
			activate ();
		} else if (can_focus) {
			grab_focus ();
		}

		return true;
	}

	protected new void popup_menu (Gdk.EventButton? ev = null) {
		//if (has_fetcher)
			fetch_menu ();

		try {
			menu.popup (null,
						null,
						get_menu_position,
						(ev == null) ? 0 : ev.button,
						(ev == null) ? get_current_event_time () : ev.time);
		} finally {
			// Highlight the parent
			if (menu.attach_widget != null)
				menu.attach_widget.set_state_flags (StateFlags.SELECTED, true);

			menu.select_first (false);
		}
	}

	protected void popdown_menu () {
		menu.popdown ();

		// Unhighlight the parent
		if (menu.attach_widget != null)
			menu.attach_widget.set_state_flags (StateFlags.NORMAL, true);
	}

	private void fetch_menu () {
		update_menu_properties ();
	}

	private void get_menu_position (Gtk.Menu menu, out int x, out int y, out bool push_in) {
		Allocation menu_allocation;
		menu.get_allocation (out menu_allocation);
		if (menu.attach_widget == null ||
			menu.attach_widget.get_window () == null) {
			// Prevent null exception in weird cases
			x = 0;
			y = 0;
			push_in = true;
			return;
		}

		menu.attach_widget.get_window ().get_origin (out x, out y);
		Allocation allocation;
		menu.attach_widget.get_allocation (out allocation);

		/*if (menu_position == MenuPosition.RIGHT) {
			x += allocation.x;
			x -= menu_allocation.width;
			x += allocation.width;
		}
		else if (menu_position != MenuPosition.LEFT) {
			/* Centered menu */
			x += allocation.x;
			//x -= menu_allocation.width / 2;
			//x += allocation.width / 2;
		//}

		int width, height;
		menu.get_size_request (out width, out height);

		/*if (menu_position == MenuPosition.INSIDE_WINDOW) {
			/* Get window geometry *
			var parent_widget = get_toplevel ();

			Gtk.Allocation window_allocation;
			parent_widget.get_allocation (out window_allocation);

			parent_widget.get_window ().get_origin (out x, out y);
			int parent_window_x0 = x;
			int parent_window_xf = parent_window_x0 + window_allocation.width;

			// Now check if the menu is outside the window and un-center it
			// if that's the case

			if (x + menu_allocation.width > parent_window_xf)
				x = parent_window_xf - menu_allocation.width; // Move to left

			if (x < parent_window_x0)
				x = parent_window_x0; // Move to right
		}*/

		y += allocation.y;

		if (y + height >= menu.attach_widget.get_screen ().get_height ())
			y -= height;
		else
			y += allocation.height;

		push_in = true;
	}
}
