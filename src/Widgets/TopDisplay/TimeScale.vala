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

public class BeatBox.TimeScale : Box {
	private Label left_time;
	private Label right_time;
	private Scale scale;
	
	private const string WIDGET_STYLESHEET = """
        .scale.slider,
        .scale.slider:insensitive {
			background-image: none;
			background: none;
			margin: 0px;
			padding: 0px;
		}
		.scale {
			margin: 0px;
			padding: 0px;
			-GtkRange-slider-width: 6;
		}
    """;
	
	public TimeScale() {
		var style_provider = new CssProvider();

        try  {
            style_provider.load_from_data (WIDGET_STYLESHEET, -1);
        } catch (Error e) {
            warning("Couldn't load style provider.\n");
        }
		
		left_time = new Label("0:00");
		right_time = new Label("0:00");
		scale = new Scale.with_range(Orientation.HORIZONTAL, 0, 1, 1);
		
		left_time.margin_right = 6;
		right_time.margin_left = 6;
		
		//get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
		//scale.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		
		scale.set_draw_value(false);
		
		set_orientation(Orientation.HORIZONTAL);
		pack_start(left_time, false, false, 0);
		pack_start(scale, true, true, 0);
		pack_start(right_time, false, false, 0);
		
		scale.button_press_event.connect(scale_button_press);
		scale.button_release_event.connect(scale_button_release);
		scale.value_changed.connect(value_changed);
		scale.change_value.connect(change_value);
		App.playback.current_position_update.connect(player_position_update);
		
		App.library.medias_updated.connect(medias_updated);
		App.playback.media_played.connect(media_played);
	}
	
	/** scale functions **/
	public void set_scale_range(double min, double max) {
		scale.set_range(min, max);
	}
	
	public void set_scale_value(double val) {
		scale.set_value(val);
	}
	
	public double get_scale_value() {
		return scale.get_value();
	}
	
	bool scale_button_press(Gdk.EventButton event) {
		event.button = 2;
		
		//calculate percentage to go to based on location
		Gtk.Allocation extents;
		int point_x = 0;
		int point_y = 0;
		
		scale.get_pointer(out point_x, out point_y);
		scale.get_allocation(out extents);
		
		// get seconds of media
		double mediatime = (double)((double)point_x/(double)extents.width) * scale.get_adjustment().upper;
		
		change_value(ScrollType.NONE, mediatime);
		
		return true;
	}
	
	bool scale_button_release(Gdk.EventButton event) {
		event.button = 2;
		
		Gtk.Allocation extents;
		int point_x = 0;
		int point_y = 0;
		
		scale.get_pointer(out point_x, out point_y);
		scale.get_allocation(out extents);
		
		// get seconds of media
		double mediatime = (double)((double)point_x/(double)extents.width) * scale.get_adjustment().upper;
	
		change_value(ScrollType.NONE, mediatime);
		
		return true;
	}
		
	public bool change_value(ScrollType scroll, double val) {
		App.playback.current_position_update.disconnect(player_position_update);
		scale.set_value(val);
		App.playback.current_position_update.connect(player_position_update);
		App.playback.set_position((int64)(val * 1000000000));
		
		return false;
	}
	
	void player_position_update(int64 position) {
		double sec = 0.0;
		if(App.playback.current_media != null) {
			sec = ((double)position/1000000000);
			set_scale_value(sec);
		}
	}
	
	void value_changed() {
		string current_time = "";
		string total_time = "";
		
		//make pretty current time
		int minute = 0;
		int seconds = (int)scale.get_value();
		
		while(seconds >= 60) {
			++minute;
			seconds -= 60;
		}
		
		current_time = minute.to_string() + ":" + ((seconds < 10 ) ? "0" + seconds.to_string() : seconds.to_string());
		
		//make pretty remaining time
		minute = 0;
		seconds = (int)App.playback.current_media.length - (int)scale.get_value();
		
		while(seconds >= 60) {
			++minute;
			seconds -= 60;
		}
		
		total_time = minute.to_string() + ":" + ((seconds < 10 ) ? "0" + seconds.to_string() : seconds.to_string());
		
		left_time.set_text(current_time);
		right_time.set_text(total_time);
	}
	
	void medias_updated(Gee.Collection<Media> ids) {
		if(App.playback.current_media != null) {
			set_scale_range(0.0, (double)App.playback.current_media.length);
			value_changed();
		}
	}
	
	void media_played(Media m, Media? old) {
		set_scale_range(0.0, (double)App.playback.current_media.length);
		value_changed();
	}
}

