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

using GLib;

[DBus (name = "org.gnome.SettingsDaemon.MediaKeys")]
public interface GnomeMediaKeys : GLib.Object {
    public abstract void GrabMediaPlayerKeys (string application, uint32 time) throws GLib.IOError;
    public abstract void ReleaseMediaPlayerKeys (string application) throws GLib.IOError;
    public signal void MediaPlayerKeyPressed (string application, string key);
}

public class BeatBox.MediaKeyListener : GLib.Object {
	private GnomeMediaKeys media_object;
	public int last_pause_time;
	
	public MediaKeyListener() {
        try {
            media_object = Bus.get_proxy_sync (BusType.SESSION, "org.gnome.SettingsDaemon", "/org/gnome/SettingsDaemon/MediaKeys");
        } catch (IOError e) {
            stderr.printf ("Mediakeys error: %s\n", e.message);
        }
		
        if(media_object != null) {
            media_object.MediaPlayerKeyPressed.connect(mediaKeyPressed);
            try {
				media_object.GrabMediaPlayerKeys("beatbox", (uint32)0);
			}
			catch(IOError err) {
				stdout.printf("Could not grab media player keys: %s\n", err.message);
			}
        }
	}
	
	public void releaseMediaKeys() {
		try {
			media_object.ReleaseMediaPlayerKeys("beatbox");
		}
		catch(IOError err) {
			stdout.printf("Could not release media player keys: %s\n", err.message);
		}
	}
	
	private void mediaKeyPressed(dynamic Object bus, string application, string key) {
		if(application != "beatbox")
			return;
		
		if(key == "Previous") {
			App.playback.request_previous();
		}
		else if(key == "Play") {
			if(App.playback.playing)
				App.playback.pause();
			else
				App.playback.play();
			
			var elapsed = (int)time_t() - last_pause_time;
			
			if(App.playback.media_active && App.playback.playing && (elapsed > 60)) {
				Media current = App.playback.current_media;
				
				App.window.show_notification(current.title, current.artist + "\n" + current.album, App.covers.get_album_art_from_media(current));
			}
			else if(!App.playback.playing) {
				last_pause_time = (int)time_t();
			}
		}
		else if(key == "Next") {
			App.playback.request_next();
		}
		else {
			warning("Unused key pressed: %s\n", key);
		}
	}
}
