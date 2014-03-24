/*-
 * Copyright (c) 2012       Scott Ringwelski <sgringwe@mtu.edu>
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

public class BeatBox.StyledBox : Gtk.Box {
	CssProvider style_provider;
	string class_style;
	
	private const string WIDGET_STYLESHEET = """
        .borderButton{
			-unico-inner-stroke-width: 0;
			-GtkButton-default-border: 0;
            -GtkButton-image-spacing: 0;
            -GtkButton-inner-border: 0;
            -GtkButton-interior-focus: false;
			
			background-image: -gtk-gradient (linear,
                                             left top, 
                                             left bottom,
                                             from (shade (#d5d3d1, 1.05)),
                                             to (#d5d3d1));
			
            -unico-border-gradient: -gtk-gradient (linear, 
												   left top, 
												   left bottom,
                                                   from (alpha (#fff, 0.9)),
                                                   to (alpha (#fff, 0.5)));

            -unico-outer-stroke-gradient: -gtk-gradient (linear, 
														 left top, 
														 left bottom,
                                                         from (alpha (#000, 0.3)),
                                                         to (alpha (#000, 0.3)));
        }
        
        .StyledBox .top {
			border-radius: 6px 6px 0 0;
            -unico-outer-stroke-width: 1px 1px 0 1px;
		}
		
		.StyledBox .right {
			border-radius: 0 0 0 0;
			-unico-outer-stroke-width: 0 1px 0 0;
		}
		
		.StyledBox .bottom {
			border-radius: 0 0 6px 6px;
			-unico-outer-stroke-width: 0 1px 1px 1px;
		}
		
		.StyledBox .left {
			border-radius: 0 0 0 0;
			-unico-outer-stroke-width: 0 0 0 1px;
		}
        
        .gray {
			background-image: -gtk-gradient (linear,
                                             left top, 
                                             left bottom,
                                             from (shade (#d5d3d1, 1.05)),
                                             to (#d5d3d1));
		}
		
		.black {
			background-image: -gtk-gradient (linear,
                                             left top, 
                                             left bottom,
                                             from (shade (#383838, 1.05)),
                                             to (#383838));
		}
		
		.white {
			background-image: -gtk-gradient (linear,
                                             left top, 
                                             left bottom,
                                             from (shade (#f8f8f8, 1.05)),
                                             to (#f8f8f8));
		}
		
		.pure_white {
			background-color: #fff;
			background-image: none;
		}
		
		.transparent {
			background-image: none;
			background-color: rgba(0,0,0,0);
		}
		
    """;
    
    Gtk.Box inner;
	Gtk.Label title_label;
	Gtk.EventBox center;
	Gtk.Box content;
	
	public signal void button_pressed(Gdk.EventButton event);
	public signal void button_released(Gdk.EventButton event);
	public signal void scrolled(Gdk.EventScroll event);
	
	public StyledBox(string title, string class_style) {
		this.class_style = class_style;
		title_label = new Gtk.Label("");
		content = new Box(Orientation.VERTICAL, 0);
		
		style_provider = new CssProvider();
        try  {
            style_provider.load_from_data (WIDGET_STYLESHEET, -1);
        } catch (Error e) {
            stderr.printf ("\nStyledBox: Couldn't load style provider.\n");
        }
        
		get_style_context().add_class("StyledBox");
		get_style_context().add_class(class_style);
		get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		homogeneous = false;
		
		inner = new Box(Orientation.HORIZONTAL, 0);
		var top = new Button();
		var right = new Button();
		var bottom = new Button();
		var left = new Button();
		
		center = new EventBox();
		if(class_style != "white") {
			center.get_style_context().add_class(class_style);
			center.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		}
		center.add(content);
		
		if(title != "") {
			EventBox title_box = new EventBox();
			title_box.get_style_context().add_class("pure_" + class_style);
			title_box.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
			title_box.add(title_label);
			title_label.set_markup("<b>" + Markup.escape_text(title) + "</b>");
			content.pack_start(title_box, false, true, 0);
		}
		
		inner.pack_start(left, false, true, 0);
		inner.pack_start(center, true, true, 0);
		inner.pack_start(right, false, true, 0);
		
		this.set_orientation(Orientation.VERTICAL);
		pack_start(top, false, true, 0);
		pack_start(inner, true, true, 0);
		pack_start(bottom, false, true, 0);
		
		top.get_style_context().add_class("top");
		right.get_style_context().add_class("right");
		bottom.get_style_context().add_class("bottom");
		left.get_style_context().add_class("left");
		top.get_style_context().add_class("borderButton");
		right.get_style_context().add_class("borderButton");
		bottom.get_style_context().add_class("borderButton");
		left.get_style_context().add_class("borderButton");
		top.get_style_context().add_class(class_style);
		right.get_style_context().add_class(class_style);
		bottom.get_style_context().add_class(class_style);
		left.get_style_context().add_class(class_style);
		top.get_style_context().remove_class(Gtk.STYLE_CLASS_BUTTON);
		right.get_style_context().remove_class(Gtk.STYLE_CLASS_BUTTON);
		bottom.get_style_context().remove_class(Gtk.STYLE_CLASS_BUTTON);
		left.get_style_context().remove_class(Gtk.STYLE_CLASS_BUTTON);
		
		top.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		right.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		bottom.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		left.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
	}
	
	private string _title;
	public string title {
		get {
			return _title;
		}
		set {
			_title = value;
			
		}
	}
	
	public void set_widget(Widget w) {
		content.pack_start(w, true, true, 0);
		w.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		
		// Turn off scroll event on w
		if(w is ScrolledWindow) {
			w.scroll_event.connect((ev) => {
				GLib.Signal.stop_emission_by_name(w, "scroll-event");

				return true;
			});
		}
	}
	
	public override bool button_press_event(Gdk.EventButton event) {
		button_pressed(event);
		return false;
	}
	
	public override bool button_release_event(Gdk.EventButton event) {
		button_released(event);
		return false;
	}
	
	protected override bool scroll_event(Gdk.EventScroll event) {
		scrolled(event);
		return false;
	}
}

