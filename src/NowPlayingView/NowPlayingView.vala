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
using Gee;

public class BeatBox.NowPlayingView : Notebook, NowPlayingViewInterface {
	bool video_is_enabled;
	public ulong video_area_xid { get; private set; }
	DrawingArea video_area;
	HashMap<MediaType, NowPlayingPage> types_to_pages;
	
	NowPlayingPage dashboard;
	
	public NowPlayingView() {
		types_to_pages = new HashMap<MediaType, NowPlayingPage>();
		
		show_tabs = false;
		show_border = false;
		
		// Add a dashboard page which is shown when no media is playing
		dashboard = new NowPlayingPage();
		video_area = new DrawingArea();
		append_page(dashboard);
		append_page(video_area);
		
		video_area.double_buffered = false;
		
		add_section(MediaType.SONG, new SongSummarySection());
		//add_section(MediaType.SONG, new SongArtistSection());
		
		add_section(MediaType.PODCAST, new PodcastSummarySection());
		
		App.playback.media_played.connect(media_played);
		App.playback.playback_stopped.connect(playback_stopped);
		App.playback.video_enabled.connect(video_enabled);
		video_area.realize.connect(video_area_realized);
	}
	
	public void add_section(MediaType media_key, Widget w) {
		if(types_to_pages.get(media_key) == null) {
			add_page(media_key, new NowPlayingPage());
		}
		
		types_to_pages.get(media_key).add_section(w);
	}
	
	// Must specify type in case that this widget is on multiple pages
	public void remove_section(MediaType media_key, Widget w) {
		if(types_to_pages.get(media_key) == null) {
			return; // nothing to do but tell them they suck and return
		}
		
		types_to_pages.get(media_key).remove_section(w);
	}
	
	public void add_dashboard_section(Widget w) {
		dashboard.add_section(w);
	}
	
	public void remove_dashboard_section(Widget w) {
		dashboard.remove_section(w);
	}
	
	public bool has_content_to_show() {
		Media m = App.playback.current_media;
		
		if(m != null && types_to_pages.get(m.media_type) != null && types_to_pages.get(m.media_type).section_count() > 0) {
			return true;
		}
		else if(m == null && dashboard.section_count() > 0) {
			return true;
		}
		
		return false;
	}
	
	private void add_page(MediaType media_key, NowPlayingPage page) {
		if(types_to_pages.get(media_key) != null) {
			warning("Already page for type %s", media_key.to_string(1));
			return;
		}
		
		append_page(page);
		types_to_pages.set(media_key, page);
		
		update_current_page();
	}
	
	void media_played(Media m, Media? old) {
		video_is_enabled = false;
		
		update_current_page();
	}
	
	void playback_stopped(Media? was_playing) {
		update_current_page();
	}
	
	// If playback notify's that video is in the current media, always show the
	// video screen.
	void video_enabled() {
		video_is_enabled = true;
		
		update_current_page();
	}
	
	void video_area_realized() {
        video_area_xid = (ulong)Gdk.X11Window.get_xid(video_area.get_window());
    }
	
	private void update_current_page() {
		Media m = App.playback.current_media;
		
		if(video_is_enabled) {
			set_current_page(page_num(video_area));
		}
		else if(m != null && types_to_pages.get(m.media_type) != null) {
			set_current_page(page_num(types_to_pages.get(m.media_type)));
		}
		else if(m == null && dashboard.section_count() > 0) {
			set_current_page(page_num(dashboard));
		}
	}
}	
