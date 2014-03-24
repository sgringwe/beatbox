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

public class BeatBox.BufferDisplay : BeatBox.Display, Box {
	bool _is_enabled;
	public bool is_enabled { get { return _is_enabled; } }
	
	private Label buffering_status;
	private ProgressBar buffering_bar;
	
	public BufferDisplay() {
		buffering_status = new Label("");
		buffering_bar = new ProgressBar();
		
		buffering_status.xalign = 0.5f;
		buffering_status.set_justify(Justification.CENTER);
		buffering_status.margin_left = 0;
		buffering_status.ellipsize = Pango.EllipsizeMode.END;
		
		this.set_orientation(Orientation.VERTICAL);
		pack_start(buffering_status, false, false, 0);
		pack_start(buffering_bar, false, false, 0);
		
		App.playback.buffer_percent_update.connect(player_buffering_update);
		App.playback.media_played.connect(media_played);
		App.playback.playback_stopped.connect(playback_stopped);
	}
	
	void player_buffering_update(int percent) {
		if(!App.playback.media_active || App.playback.current_media.uri.has_prefix("file:/")) {
			disabled();
		}
		else {
			if(percent >= 0 && percent < 100) {
				var name = (App.playback.current_media.title.length > 50)
					? App.playback.current_media.title.substring(
							App.playback.current_media.title.index_of_nth_char(0),
							App.playback.current_media.title.index_of_nth_char(50)) 
					: App.playback.current_media.title;
				
				buffering_bar.set_fraction((double)((double)percent / (double)100));
				
				if(name != null) {
					buffering_status.set_markup(_("Buffering %s...").printf("<b>" + Markup.escape_text(name) + "</b>"));
				}
				else {
					buffering_status.set_markup(_("Buffering..."));
				}
				
				enabled();
			}
			else {
				disabled();
			}
		}
	}
	
	// When a new media is played, assume it doesn't need buffering until the
	// gstreamer playbin starts sending off buffering updates
	void media_played(Media m, Media ?old) {
		disabled();
	}
	
	void playback_stopped(Media? was_playing) {
		disabled();
	}
	
	public bool is_cancellable() {
		return true;
	}
	
	public void cancel() {
		App.playback.stop_playback();
	}
}
