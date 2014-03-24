/*-
 * Copyright (c) 2011-2012 BeatBox developers
 *
 * Originally Written by Scott Ringwelski and Victor Eduardo for
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
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 *              Lucas Baudin <xapantu@gmail.com>
 */


/**
 * A place to store icon information and pixbufs.
 * Use render() or render_image() to load these icons
 * FIXME: deprecate backup stuff and convert the namespace into a Class
 * with static properties and constructor. Also implies modifiying BeatBox.Icon
 */

public class BeatBox.Icons : GLib.Object, BeatBox.IconsInterface {
    /**
     * Size of the cover art used in the album view
     **/
    public const int ALBUM_VIEW_IMAGE_SIZE = 140;

	// 128 x 128
	public BeatBox.Icon DEFAULT_ALBUM_ART { get; protected set; }
	public BeatBox.Icon DROP_ALBUM { get; protected set; }
	public BeatBox.Icon MUSIC_FOLDER { get; protected set; }

	// 22 x 22
	public BeatBox.Icon HISTORY { get; protected set; }

	// 16 x 16
	public BeatBox.Icon BEATBOX { get; protected set; }
	public BeatBox.Icon STATION { get; protected set; }
	public BeatBox.Icon MUSIC { get; protected set; }
	public BeatBox.Icon PODCAST { get; protected set; }
	public BeatBox.Icon AUDIOBOOK { get; protected set; }
	public BeatBox.Icon AUDIO_CD { get; protected set; }
	public BeatBox.Icon PLAYLIST { get; protected set; }
	public BeatBox.Icon SMART_PLAYLIST { get; protected set; }
	public BeatBox.Icon LASTFM_LOVE { get; protected set; }
	public BeatBox.Icon LASTFM_BAN { get; protected set; }
	public BeatBox.Icon STARRED { get; protected set; }
	public BeatBox.Icon NOT_STARRED { get; protected set; }
	public BeatBox.Icon NEW_PODCAST { get; protected set; }

	// SYMBOLIC ICONS
	public BeatBox.Icon PANE_HIDE_SYMBOLIC { get; protected set; }
	public BeatBox.Icon PANE_SHOW_SYMBOLIC { get; protected set; }
	public BeatBox.Icon MEDIA_PLAY_SYMBOLIC { get; protected set; }
	public BeatBox.Icon MEDIA_PAUSE_SYMBOLIC { get; protected set; }
	public BeatBox.Icon STARRED_SYMBOLIC { get; protected set; }
	public BeatBox.Icon NOT_STARRED_SYMBOLIC { get; protected set; }
	public BeatBox.Icon PROCESS_COMPLETED { get; protected set; }
	public BeatBox.Icon PROCESS_ERROR { get; protected set; }
	public BeatBox.Icon PROCESS_STOP { get; protected set; }
	public BeatBox.Icon SHUFFLE_ON { get; protected set; }
	public BeatBox.Icon SHUFFLE_OFF { get; protected set; }
	public BeatBox.Icon REPEAT_ON { get; protected set; }
	public BeatBox.Icon REPEAT_ONCE { get; protected set; }
	public BeatBox.Icon REPEAT_OFF { get; protected set; }
	public BeatBox.Icon EQ { get; protected set; }
	public BeatBox.Icon VIEW_COLUMN { get; protected set; }
	public BeatBox.Icon VIEWS { get; protected set; }
	public BeatBox.Icon VIEW_DETAILS { get; protected set; }
	public BeatBox.Icon VIEW_ICONS { get; protected set; }
	public BeatBox.Icon VIEW_VIDEO { get; protected set; }
	public BeatBox.Icon INFO { get; protected set; }
	public BeatBox.Icon GO_NEXT { get; protected set; }
	public BeatBox.Icon GO_HOME { get; protected set; }

	/**
	 * RENDERED ICONS.
	 * These are pre-rendered pixbufs. Any static image which otherwise would need
	 * to be rendered many times should be a preloaded pixbuf. They are loaded
	 * in the init() function.
	 */
	public Gdk.Pixbuf DEFAULT_ALBUM_ART_PIXBUF { get; protected set; }
	public Gdk.Pixbuf DEFAULT_ALBUM_SHADOW_PIXBUF { get; protected set; }
	public Gdk.Pixbuf DROP_ALBUM_PIXBUF { get; protected set; }
	
	/**
	 * Loads icon information and renders [preloaded] pixbufs
	 **/
	public Icons() {
        DEFAULT_ALBUM_ART = new BeatBox.Icon ("albumart", 138, Type.MIMETYPE, null, true);

		// 128 x 128
		DROP_ALBUM = new BeatBox.Icon ("drop-album", 128, Type.MIMETYPE, null, true);
		MUSIC_FOLDER = new BeatBox.Icon ("folder-music", 128, Type.MIMETYPE, null, true);

		// 22 x 22
		HISTORY = new BeatBox.Icon ("document-open-recent", 22, Type.ACTION, null, false);

		// 16 x 16
		BEATBOX        = new BeatBox.Icon ("beatbox", 16, Type.APP, null, true);
		STATION        = new BeatBox.Icon ("internet-radio", 16, Type.MIMETYPE, null, true);
		MUSIC          = new BeatBox.Icon ("library-music", 16, Type.MIMETYPE, null, true);
		PODCAST        = new BeatBox.Icon ("library-podcast", 16, Type.MIMETYPE, null, true);
		AUDIOBOOK      = new BeatBox.Icon ("library-audiobook", 16, Type.MIMETYPE, null, true);
		AUDIO_CD       = new BeatBox.Icon ("media-cdrom-audio", 16, Type.MIMETYPE, null, true);
		PLAYLIST       = new BeatBox.Icon ("playlist", 16, Type.MIMETYPE, null, true);
		SMART_PLAYLIST = new BeatBox.Icon ("playlist-automatic", 16, Type.MIMETYPE, null, true);
		LASTFM_LOVE    = new BeatBox.Icon ("lastfm-love", 16, Type.ACTION, null, true);
		LASTFM_BAN     = new BeatBox.Icon ("lastfm-ban", 16, Type.ACTION, null, true);
		STARRED        = new BeatBox.Icon ("starred", 16, Type.STATUS, null, true);
		NOT_STARRED    = new BeatBox.Icon ("non-starred", 16, Type.STATUS, null, true);
		NEW_PODCAST    = new BeatBox.Icon ("podcast-new", 16, Type.STATUS, null, true);

		// SYMBOLIC ICONS (16 x 16)
		PANE_SHOW_SYMBOLIC = new BeatBox.Icon ("pane-show-symbolic", 16, Type.ACTION, null, true);
		PANE_HIDE_SYMBOLIC = new BeatBox.Icon ("pane-hide-symbolic", 16, Type.ACTION, null, true);
		REPEAT_ONCE        = new BeatBox.Icon ("media-playlist-repeat-one-symbolic", 16, Type.STATUS, null, true);
		REPEAT_OFF         = new BeatBox.Icon ("media-playlist-no-repeat-symbolic", 16, Type.STATUS, null, true);
		SHUFFLE_OFF        = new BeatBox.Icon ("media-playlist-no-shuffle-symbolic", 16, Type.STATUS, null, true);
		EQ                 = new BeatBox.Icon ("media-eq-symbolic", 16, Type.STATUS, null, true);

		MEDIA_PLAY_SYMBOLIC  = new BeatBox.Icon ("media-playback-start-symbolic", 16, Type.ACTION, null, false);
		MEDIA_PAUSE_SYMBOLIC = new BeatBox.Icon ("media-playback-pause-symbolic", 16, Type.ACTION, null, false);
		STARRED_SYMBOLIC     = new BeatBox.Icon ("starred-symbolic", 16, Type.STATUS, null, false);
		NOT_STARRED_SYMBOLIC = new BeatBox.Icon ("non-starred-symbolic", 16, Type.STATUS, null, false);
		PROCESS_COMPLETED    = new BeatBox.Icon ("process-completed-symbolic", 16, Type.STATUS, null, false);
		PROCESS_ERROR        = new BeatBox.Icon ("process-error-symbolic", 16, Type.STATUS, null, false);
		PROCESS_STOP         = new BeatBox.Icon ("process-stop-symbolic", 16, Type.ACTION, null, false);
		SHUFFLE_ON           = new BeatBox.Icon ("media-playlist-shuffle-symbolic", 16, Type.STATUS, null, false);
		REPEAT_ON            = new BeatBox.Icon ("media-playlist-repeat-symbolic", 16, Type.STATUS, null, false);
		VIEW_COLUMN          = new BeatBox.Icon ("view-column-symbolic", 16, Type.ACTION, null, false);
		VIEW_DETAILS         = new BeatBox.Icon ("view-list-symbolic", 16, Type.ACTION, null, false);
		VIEW_ICONS           = new BeatBox.Icon ("view-grid-symbolic", 16, Type.ACTION, null, false);
		VIEW_VIDEO			 = new BeatBox.Icon ("view-video-symbolic", 16, Type.ACTION, null, false);
		VIEWS                = new BeatBox.Icon ("view-grid-symbolic", 16, Type.ACTION, null, false);
		INFO                 = new BeatBox.Icon ("info-symbolic", 16, Type.ACTION, null, false);
		GO_NEXT				 = new BeatBox.Icon ("go-next-symbolic", 16, Type.ACTION, null, false);
		GO_HOME				 = new BeatBox.Icon ("go-home-symbolic", 16, Type.ACTION, null, false);

		/* Render Pixbufs */
		DEFAULT_ALBUM_ART_PIXBUF = DEFAULT_ALBUM_ART.render (null);
		DROP_ALBUM_PIXBUF = DROP_ALBUM.render(null);

        DEFAULT_ALBUM_ART_PIXBUF = DEFAULT_ALBUM_ART.render (null);

        // 168x168
        var shadow_icon = new BeatBox.Icon ("albumart-shadow", 168, Type.OTHER, FileType.PNG, true);
        DEFAULT_ALBUM_SHADOW_PIXBUF = shadow_icon.render (null);
	}
	
	/**
	 * @param surface_size size of the new pixbuf. Set a value of 0 to use the pixbuf's default size.
	 **/
	public Gdk.Pixbuf get_pixbuf_shadow (Gdk.Pixbuf pixbuf, int surface_size = ALBUM_VIEW_IMAGE_SIZE,
	                                      int shadow_size = 5, double alpha = 0.8)
	{
		int S_WIDTH = (surface_size > 0)? surface_size : pixbuf.width;
		int S_HEIGHT = (surface_size > 0)? surface_size : pixbuf.height;

		var buffer_surface = new Granite.Drawing.BufferSurface (S_WIDTH, S_HEIGHT);

		S_WIDTH -= 2 * shadow_size;
		S_HEIGHT -= 2 * shadow_size;

		buffer_surface.context.rectangle (shadow_size, shadow_size, S_WIDTH, S_HEIGHT);
		buffer_surface.context.set_source_rgba (0, 0, 0, alpha);
		buffer_surface.context.fill();
		buffer_surface.fast_blur(2, 3);
		Gdk.cairo_set_source_pixbuf(buffer_surface.context, pixbuf.scale_simple (S_WIDTH, S_HEIGHT, Gdk.InterpType.BILINEAR), shadow_size, shadow_size);
		buffer_surface.context.paint();

		return buffer_surface.load_to_pixbuf();
	}
	
	public GLib.Icon? render_gicon(string icon_name, Gtk.IconSize size, Gtk.StyleContext? context = null) {
		var icon = new BeatBox.Icon (icon_name, null, null, null, false);
		return icon.get_gicon ();
	}
	
	public Gdk.Pixbuf? render_icon (string icon_name, Gtk.IconSize size, Gtk.StyleContext? context = null) {
		var icon = new BeatBox.Icon (icon_name, null, null, null, false);
		return icon.render (size, context);
	}

	public Gtk.Image? render_image (string icon_name, Gtk.IconSize size) {
		var icon = new BeatBox.Icon (icon_name, null, null, null, false);
		return icon.render_image (size);
	}
}

