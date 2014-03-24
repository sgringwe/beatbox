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

public interface BeatBox.IconsInterface : GLib.Object {
	public enum Type {
        MIMETYPE,
        ACTION,
        STATUS,
        APP,
        OTHER
    }

    public enum FileType {
        SVG,
        PNG
    }
    
    public const int ALBUM_VIEW_IMAGE_SIZE = 140;
	
	// 128 x 128
	public abstract BeatBox.Icon DEFAULT_ALBUM_ART { get; protected set; }
	public abstract BeatBox.Icon DROP_ALBUM { get; protected set; }
	public abstract BeatBox.Icon MUSIC_FOLDER { get; protected set; }

	// 22 x 22
	public abstract BeatBox.Icon HISTORY { get; protected set; }

	// 16 x 16
	public abstract BeatBox.Icon BEATBOX { get; protected set; }
	public abstract BeatBox.Icon STATION { get; protected set; }
	public abstract BeatBox.Icon MUSIC { get; protected set; }
	public abstract BeatBox.Icon PODCAST { get; protected set; }
	public abstract BeatBox.Icon AUDIOBOOK { get; protected set; }
	public abstract BeatBox.Icon AUDIO_CD { get; protected set; }
	public abstract BeatBox.Icon PLAYLIST { get; protected set; }
	public abstract BeatBox.Icon SMART_PLAYLIST { get; protected set; }
	public abstract BeatBox.Icon LASTFM_LOVE { get; protected set; }
	public abstract BeatBox.Icon LASTFM_BAN { get; protected set; }
	public abstract BeatBox.Icon STARRED { get; protected set; }
	public abstract BeatBox.Icon NOT_STARRED { get; protected set; }
	public abstract BeatBox.Icon NEW_PODCAST { get; protected set; }

	// Symbolic icons
	public abstract BeatBox.Icon PANE_HIDE_SYMBOLIC { get; protected set; }
	public abstract BeatBox.Icon PANE_SHOW_SYMBOLIC { get; protected set; }
	public abstract BeatBox.Icon MEDIA_PLAY_SYMBOLIC { get; protected set; }
	public abstract BeatBox.Icon MEDIA_PAUSE_SYMBOLIC { get; protected set; }
	public abstract BeatBox.Icon STARRED_SYMBOLIC { get; protected set; }
	public abstract BeatBox.Icon NOT_STARRED_SYMBOLIC { get; protected set; }
	public abstract BeatBox.Icon PROCESS_COMPLETED { get; protected set; }
	public abstract BeatBox.Icon PROCESS_ERROR { get; protected set; }
	public abstract BeatBox.Icon PROCESS_STOP { get; protected set; }
	public abstract BeatBox.Icon SHUFFLE_ON { get; protected set; }
	public abstract BeatBox.Icon SHUFFLE_OFF { get; protected set; }
	public abstract BeatBox.Icon REPEAT_ON { get; protected set; }
	public abstract BeatBox.Icon REPEAT_ONCE { get; protected set; }
	public abstract BeatBox.Icon REPEAT_OFF { get; protected set; }
	public abstract BeatBox.Icon EQ { get; protected set; }
	public abstract BeatBox.Icon VIEW_COLUMN { get; protected set; }
	public abstract BeatBox.Icon VIEWS { get; protected set; }
	public abstract BeatBox.Icon VIEW_DETAILS { get; protected set; }
	public abstract BeatBox.Icon VIEW_ICONS { get; protected set; }
	public abstract BeatBox.Icon VIEW_VIDEO { get; protected set; }
	public abstract BeatBox.Icon INFO { get; protected set; }
	public abstract BeatBox.Icon GO_NEXT { get; protected set; }
	public abstract BeatBox.Icon GO_HOME { get; protected set; }
	
	// Pre-rendered icons
	public abstract Gdk.Pixbuf DEFAULT_ALBUM_ART_PIXBUF { get; protected set; }
	public abstract Gdk.Pixbuf DEFAULT_ALBUM_SHADOW_PIXBUF { get; protected set; }
	public abstract Gdk.Pixbuf DROP_ALBUM_PIXBUF { get; protected set; }
	
	public abstract GLib.Icon? render_gicon(string icon_name, Gtk.IconSize size, Gtk.StyleContext? context = null);
	public abstract Gdk.Pixbuf? render_icon(string icon_name, Gtk.IconSize size, Gtk.StyleContext? context = null);
	public abstract Gtk.Image? render_image(string icon_name, Gtk.IconSize size);
}
