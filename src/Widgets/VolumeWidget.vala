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
using Cairo;
using Gtk;
using Gdk;

public class BeatBox.VolumeWidget : Gtk.Box {
	static const double MUTED_MINIMUM = 0.05;
	static const double LOW_MINIMUM = 0.25;
	static const double FULL_MINIMUM = 0.95;
	Scale volume;
	Gtk.Image image;
	
	public signal void volume_changed();
	
	static string[] icons = { 	"audio-volume-muted",
								"audio-volume-low",
								"audio-volume-medium",
								"audio-volume-high"};
	
    public VolumeWidget(double vol) {
		set_orientation(Orientation.VERTICAL);
		
		volume = new Scale.with_range(Orientation.VERTICAL, 0, 1, 0.2);
		volume.draw_value = false;
		volume.inverted = true;
		volume.set_value(vol);
		pack_start(volume, true, true, 6);
		
		image = new Gtk.Image();
		pack_end(image, false, false, 0);
		update_image();
		
		volume.value_changed.connect(value_changed);
    }
    
	void value_changed() {
		update_image();
		volume_changed();
	}
    
    void update_image() {
		double val = volume.get_value();
		if(val < MUTED_MINIMUM)
			image.set_from_icon_name(icons[0], Gtk.IconSize.MENU);
		else if(val < LOW_MINIMUM)
			image.set_from_icon_name(icons[1], Gtk.IconSize.MENU);
		else if(val < FULL_MINIMUM)
			image.set_from_icon_name(icons[2], Gtk.IconSize.MENU);
		else
			image.set_from_icon_name(icons[3], Gtk.IconSize.MENU);
	}
	
	public double get_volume() {
		return volume.get_value();
	}
	
	public void set_volume(double val) {
		volume.set_value(val);
	}
}

