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

public class BeatBox.MetadataDisplay : BeatBox.Display, Box {
	bool _is_enabled;
	public bool is_enabled { get { return _is_enabled; } }
	
	private Label label;
	private Label station_label;
	private TimeScale time_scale;
	
	public MetadataDisplay() {
		label = new Label("");
		station_label = new Label("");
        time_scale = new TimeScale();
		
		label.xalign = 0.5f;
		label.set_justify(Justification.LEFT);
		label.ellipsize = Pango.EllipsizeMode.END;
		
		station_label.xalign = 0.5f;
		station_label.set_justify(Justification.LEFT);
		station_label.ellipsize = Pango.EllipsizeMode.END;
		
		station_label.set_no_show_all(true);
        
        this.set_orientation(Orientation.VERTICAL);
        pack_start(label, false, false, 0);
        pack_start(time_scale, false, false, 0);
        pack_start(station_label, true, true, 0);
        
        App.library.medias_updated.connect(medias_updated);
		App.playback.media_played.connect(media_played);
		App.playback.playback_stopped.connect(playback_stopped);
		
		show_all();
		set_no_show_all(true);
	}
	
	void medias_updated(Gee.Collection<Media> ids) {
		update_metadata();
	}
	
	void media_played(Media m, Media ?old) {
		update_metadata();
		enabled();
	}
	
	void playback_stopped(Media? was_playing) {
		disabled();
	}
	
	void update_metadata() {
		if(App.playback.media_active) {
			label.set_markup(App.playback.current_media.get_primary_display_text());
			
			if(!App.playback.current_media.can_seek) {
				label.margin_top = 2;
				time_scale.hide();
				station_label.show();
				
				if(App.playback.current_media.get_secondary_display_text() != null) {
					station_label.set_markup(App.playback.current_media.get_secondary_display_text());
				}
			}
			else {
				label.margin_top = 2;
				station_label.hide();
				time_scale.show_all();
			}
		}
		else {
			disabled();
		}
	}
	
	public bool is_cancellable() {
		return false;
	}
	
	public void cancel() {
		// Do nothing
	}
}
