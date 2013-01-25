// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * Copyright (c) 2012 BeatBox Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 * 
 * The BeatBox project hereby grant permission for non-gpl compatible GStreamer
 * plugins to be used and distributed together with GStreamer and BeatBox. This
 * permission is above and beyond the permissions granted by the GPL license
 * BeatBox is covered by.
 */

namespace BeatBox.UI {

    /**
     * Sets the alignment of a widget by modifying the margin and align properties.
     */
    public Gtk.Widget wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
        widget.valign = Gtk.Align.FILL;
        widget.halign = Gtk.Align.FILL;

        widget.margin_top = top;
        widget.margin_right = right;
        widget.margin_bottom = bottom;
        widget.margin_left = left;

        return widget;
    }

    /**
     * Makes a Gtk.Window draggable
     */
    public void make_window_draggable (Gtk.Window window) {
        window.add_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.POINTER_MOTION_MASK);
        window.button_press_event.connect ( (event) => {
            window.begin_move_drag ((int)event.button, (int)event.x_root, (int)event.y_root, event.time);
            return true;
        });
    }

    /**
     * elementaryOS fonts
     */

    public enum TextStyle {
        TITLE,
        H1,
        H2,
        H3
    }

    const string H1_STYLESHEET    = ".h1 { font: open sans bold 24;  }";
    const string H2_STYLESHEET    = ".h2 { font: open sans light 18; }";
    const string H3_STYLESHEET    = ".h3 { font: open sans bold 12;  }";
    const string TITLE_STYLESHEET = ".title { font: raleway 36; }";

    public void apply_style_to_label (Gtk.Label label, TextStyle text_style) {
        var style_provider = new Gtk.CssProvider ();
        var style_context = label.get_style_context ();

        try {
            switch (text_style) {
                case TextStyle.TITLE:
                    style_provider.load_from_data (TITLE_STYLESHEET, -1);
                    style_context.add_class ("title");
                    break;
                case TextStyle.H1:
                    style_provider.load_from_data (H1_STYLESHEET, -1);
                    style_context.add_class ("h1");
                    break;
                case TextStyle.H2:
                    style_provider.load_from_data (H2_STYLESHEET, -1);
                    style_context.add_class ("h2");
                    break;
                case TextStyle.H3:
                    style_provider.load_from_data (H3_STYLESHEET, -1);
                    style_context.add_class ("h3");
                    break;
            }
        }
        catch (Error err) {
            warning ("Couldn't apply style to label: %s", err.message);
            return;
        }

        style_context.add_provider (style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
    
    public Gtk.MenuItem create_suggestion_menu_item(string primary, string? secondary, Gdk.Pixbuf? pixbuf) {
		Gtk.MenuItem item;
		string markup = "<span weight='medium' size='10500'>" + validate_markup(primary, 20) + "</span>" + 
													(!String.is_empty(secondary) ? ("\n<span foreground=\"#999\">" + validate_markup(secondary, 20) + "</span>") : "");
		
		// Decide what kind of menu to create
		if(pixbuf == null) {
			item = new Gtk.MenuItem.with_label("");
		}
		else {
			item = new Gtk.ImageMenuItem.with_label("");
		}
		
		// Find the label in the menuitem and set it's markup
		foreach(var child in item.get_children()) {
			if(child is Gtk.Label) {
				((Gtk.Label)child).set_markup(markup);
			}
		}
		
		// If it's an image, set the image
		if(item is Gtk.ImageMenuItem) {
			((Gtk.ImageMenuItem)item).set_always_show_image(true);
			((Gtk.ImageMenuItem)item).set_image(new Gtk.Image.from_pixbuf(pixbuf.scale_simple(32, 32, Gdk.InterpType.BILINEAR)));
		}
		
		return item;
	}
	
	public string validate_markup(string s, int max_length) {
		string rv = Markup.escape_text(s);
		
		if(s.length > max_length)
			rv = Markup.escape_text(s.substring(0, max_length - 1)) + "...";
		
		return rv;
	}
}

