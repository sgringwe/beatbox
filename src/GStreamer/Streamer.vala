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

using Gst;
using Gtk;

public class BeatBox.Streamer : GLib.Object {
	BeatBox.Pipeline pipe;
	
	InstallGstreamerPluginsDialog dialog;
	
	public bool doing_gapless;
	Media next_gapless_media;
	
	bool checked_video;
	bool set_resume_pos;
	bool is_video_enabled;
	bool buffering;
	bool internal_playing_flag;
	
	/** signals **/
	public signal void end_of_stream();
	public signal void buffer_percent_update(int percent);
	public signal void current_position_update(int64 position);
	public signal void media_not_found();
	public signal void video_enabled();
	
	public Streamer() {
		pipe = new BeatBox.Pipeline();
		
		pipe.bus.enable_sync_message_emission();
		
		pipe.bus.add_watch(busCallback);
		pipe.bus.sync_message.connect(sync_message);
		pipe.playbin.about_to_finish.connect(about_to_finish);
		
		// If volume is down low, let's raise it up so that they aren't confused why no audio is playing
		double vol = App.settings.equalizer.volume /100.0;
		if(vol < 0.2)
			vol = 0.7;
		setVolume(vol);
		
		Timeout.add(500, doPositionUpdate);
	}
	
	// Hackish solution to setting the resume position for videos that may take a while to load/buffer
	// Here we keep trying to set the position to the resume position. ONce we
	// succeed we say 'set_resume_pos = true' and no longer try. This whole function could use
	// some work
	public bool doPositionUpdate() {
		int64 position = getPosition();
		
		if(App.playback.media_active && !App.playback.current_media.uses_resume_pos) {
			if(!set_resume_pos && !internal_playing_flag)
				setPosition(0);
			
			set_resume_pos = true;
			current_position_update(position);
		}
		else {
			if(set_resume_pos || (App.playback.media_active && getPosition() >= (int64)(App.playback.current_media.resume_pos - 1) * 1000000000)) {
				// If playing external uri, only update if playing.
				if(internal_playing_flag || (App.playback.media_active && App.playback.current_media.uri.has_prefix("file://"))) {
					set_resume_pos = true;
					current_position_update(getPosition());
				}
			}
			else if(App.playback.media_active) {
				setPosition((int64)App.playback.current_media.resume_pos * 1000000000);
			}
		}
		
		// Keep updating the songs resume position as it plays
		if(App.playback.media_active && set_resume_pos) {
			double sec = ((double)position/1000000000);
			App.playback.current_media.resume_pos = (int)sec;
		}
		
		return true;
	}
	
	/* Basic playback functions */
	public void play() {
		setState(State.PLAYING);
	}
	
	public void pause() {
		setState(State.PAUSED);
	}
	
	public void setState(State s) {
		if(s == State.PAUSED)
			internal_playing_flag = false;
		else if(s == State.PLAYING)
			internal_playing_flag = true;
		
		pipe.playbin.set_state(s);
	}
	
	// This is never called when doing a gapless transition.
	public void setURI(string uri, bool playing, bool use_resume_position) {
		assert(!doing_gapless);
		
		setState(State.READY);
		
		pipe.playbin.uri = uri.replace("#", "%23");
		
		if(playing)
			play();
		else
			pause();
		
		if(use_resume_position)
			setPosition((int64)App.playback.current_media.resume_pos * 1000000000);
		else
			setPosition(0);
		
		checked_video = false;
		set_resume_pos = false;
		doing_gapless = false;
		
		if(pipe.video.element != null && is_video_enabled) {
			var xoverlay = pipe.video.element as XOverlay;
			xoverlay.set_window_handle((uint)App.window.video_area_xid);
		}
	}
	
	public void setPosition(int64 pos) {
		pause();
		pipe.playbin.seek_simple(Gst.Format.TIME, Gst.SeekFlags.FLUSH, pos);
		if(App.playback.playing)
			play();
			
		current_position_update(pos);
	}
	
	public int64 getPosition() {
		int64 rv = (int64)0;
		Format f = Format.TIME;
		
		pipe.playbin.query_position(ref f, out rv);
		
		return rv;
	}
	
	public int64 getDuration() {
		int64 rv = (int64)0;
		Format f = Format.TIME;
		
		pipe.playbin.query_duration(ref f, out rv);
		
		return rv;
	}
	
	public void setVolume(double val) {
		pipe.playbin.volume = val;
	}
	
	public double getVolume() {
		return pipe.playbin.volume;
	}
	
	/* Extra stuff */
	public void enableEqualizer() {
		pipe.enableEqualizer();
	}
	
	public void disableEqualizer() {
		pipe.disableEqualizer();
	}
	
	public void setEqualizerGain(int index, int val) {
		pipe.eq.setGain(index, val);
	}
	
	public void setVideoEnabled(bool val) {
		if(pipe.video.element == null)
			return;
		
		is_video_enabled = val;
		Gst.PlayFlag flags;
		pipe.playbin.get("flags", out flags);
		if(val) {
			flags = (flags | Gst.PlayFlag.VIDEO);
			if(pipe.video.element != null) {
				var xoverlay = pipe.video.element as XOverlay;
				xoverlay.set_window_handle((uint)App.window.video_area_xid);
				message("Video enabled. Videos will now be output to proper area in app.\n");
			}
		}
		else {
			flags = (flags & ~Gst.PlayFlag.VIDEO);
		}
		
		((Gst.Element)pipe.playbin).set("flags", flags);
	}
	
	/* Callbacks */
	private bool busCallback(Gst.Bus bus, Gst.Message message) {
		switch (message.type) {
		case Gst.MessageType.ERROR:
			GLib.Error err;
			string debug;
			message.parse_error (out err, out debug);
			warning ("Error: %s\n", err.message);
			
			break;
		case Gst.MessageType.ELEMENT:
		
			// This is where we 'make it official' that the next media is
			// playing, during gapless playback transition.
			if (message.src == pipe.playbin && message.get_structure().has_name("playbin2-stream-changed")) {
				next_track_starting();
            }
			else if(message.get_structure() != null && is_missing_plugin_message(message) && (dialog == null || !dialog.visible)) {
				dialog = new InstallGstreamerPluginsDialog(message);
			}
			
			break;
		case Gst.MessageType.EOS:
			if(!doing_gapless) {
				end_of_stream();
			}
			
			break;
		case Gst.MessageType.STATE_CHANGED:
			Gst.State oldstate;
            Gst.State newstate;
            Gst.State pending;
            message.parse_state_changed (out oldstate, out newstate,
                                         out pending);
            
            // update internal variables
			internal_playing_flag = (newstate == Gst.State.PLAYING);
            
            
            // TODO: This is a poor way to handle checking for video. search
            // for prepare-window-xid in message.get_structure()
            if(newstate != Gst.State.PLAYING)
				break;
			
			if(!checked_video && is_video_enabled) {
				Idle.add( () => {
					if(getPosition() > 0) {
						checked_video = true;
						
						if(pipe.video.element != null) {
							var xoverlay = pipe.video.element as XOverlay;
							xoverlay.set_window_handle((uint)App.window.video_area_xid);
						}
						
						if(pipe.videoStreamCount() > 0) {
							//App.playback.current_media.is_video = true;
							
							//warning("TODO: Show video mode");
							video_enabled();
						}
						else {
							//App.playback.current_media.is_video = false;
							
							//warning("TODO: Hide video mode");
							//App.window.hide_video_mode();
						}
					}
					
					return false;
				});
			}
			
			
			break;
		case Gst.MessageType.TAG:
            Gst.TagList tag_list;
            
            message.parse_tag (out tag_list);
            if(tag_list != null) {
				if(tag_list.get_tag_size(TAG_TITLE) > 0) {
					string title = "";
					tag_list.get_string(TAG_TITLE, out title);
					
					/// TODO: Put this in a better spot. Abstract it somehow. Translate it.
					if(App.playback.current_media.media_type == MediaType.STATION && title != "") { // is radio
						string[] pieces = title.split("-", 0);
						
						if(pieces.length >= 2) {
							string old_title = App.playback.current_media.title;
							string old_artist = App.playback.current_media.artist;
							((Station)App.playback.current_media).current_song_artist = (pieces[0] != null) ? pieces[0].chug().strip() : "Unknown Artist";
							((Station)App.playback.current_media).current_song_title = (pieces[1] != null) ? pieces[1].chug().strip() : title;
							
							if(old_title != ((Station)App.playback.current_media).current_song_title || old_artist != ((Station)App.playback.current_media).current_song_artist) {
								
								// The song on the radio station changed. Send out a signal
								// to update everything. We don't call App.library.playMedia because we don't want
								// to change playcount, etc. of this station.
								App.playback.media_played(App.playback.current_media, App.playback.current_media);
							}
						}
						else {
							// if the title doesn't follow the general title - artist format, probably not a media change and instead an advert
							
							/// FIXME: There is really no point in showing the random adverts from 
							/// radio stations, or is there?
							//App.window.topDisplay.set_label_markup(App.playback.current_media.album_artist + "\n" + title);
						}
						
					}
				}
				
			}
            break;
		case Gst.MessageType.BUFFERING:
			int buff_percent = 0;
			message.parse_buffering(out buff_percent);
			
			if(buff_percent < 100) {
				buffering = true;
				setState(State.PAUSED);
			}
			else if(App.playback.playing) {
				buffering = false;
				setState(State.PLAYING);
			}
			buffer_percent_update(buff_percent);
			
			break;
		default:
			break;
		}
 
		return true;
	}
	
	void sync_message(Gst.Message message) {
		if(message.get_structure() == null) {
			return;
		}
		
		string message_type = message.get_structure().get_name();
		if(message_type == "prepare-xwindow-id") {
			
			message.src.set_property("force-aspect-ratio", true);
			if(pipe.video.element != null && App.window.video_area_xid != 0) {
				var xoverlay = pipe.video.element as XOverlay;
				xoverlay.set_window_handle((uint)App.window.video_area_xid);
			}
			else {
				warning("Video area should have been realized by now");
			}
			
			// Notify that a video is being played.
			video_enabled();
		}
	}
	
	void about_to_finish() {
		Media s = App.playback.getNext(false);
		
		if(s != null && s.supports_gapless && !s.uri.has_prefix("http:/")) {
			GLib.message("Prepared next song for gapless playback (%s)", s.uri);
			pipe.playbin.uri = s.uri;
			
			next_gapless_media = s;
			doing_gapless = true;
		}
		else {
			GLib.message("not doing gapless in streamer because no next song\n");
		}
	}
	
	void next_track_starting() {
		if(doing_gapless) {
			GLib.message("Gapless transition to %s finished", next_gapless_media.title);
			App.playback.play_media(next_gapless_media, false);
			checked_video = false;
			
			// TODO: If the there are video streams, pause and then play the video because
			// gapless will mess it up (http://git.gnome.org/browse/banshee/tree/libbanshee/banshee-player-pipeline.c,
			// function next_track_starting)
			
			// Finally inform of end of stream
			end_of_stream();
		}
		
		next_gapless_media = null;
		doing_gapless = false;
	}
}
