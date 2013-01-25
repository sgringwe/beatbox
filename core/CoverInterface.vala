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

// ALL art has shadows on it unless otherwise specified.
public interface BeatBox.CoverInterface : GLib.Object {
	// Emitted when a cover is changed for an artist and an album.
	public signal void cover_changed(string album_artist, string album);
	
	// Emitted when a new cover is saved in the cache. Used to set the cover of every media
    // which belong to this album.
	public signal void new_cover_in_cache(string album_artist, string album, Gdk.Pixbuf pix); // is this not the same as cover_changed???
	
	public abstract Gdk.Pixbuf DEFAULT_COVER_SHADOW { get; }
//	public abstract Gdk.Pixbuf default_cover_art { get; }
//	public abstract Gdk.Pixbuf default_cover_art_with_shadow { get; }
	
	public abstract Gdk.Pixbuf add_shadow_to_album_art (Gdk.Pixbuf pixbuf, bool use_default_size = true, bool stretch = true);
	
	public abstract void fetch_cover_of_media(Media m);
	
	// Adds the shadow to pix
	public abstract void set_album_art(Media m, Gdk.Pixbuf pix, bool emit);
	public abstract void save_album_art_in_cache (Media m, Gdk.Pixbuf? pixbuf);
	public abstract void save_album_locally_for_meta(string album_artist, string album, string image_uri, bool emit = true);
	public abstract void save_album_locally(Media m, string image_uri, bool emit = true);
	
	public abstract string get_media_coverart_key (Media s);
	public abstract string get_cached_album_art_path(string key);
	public abstract string? get_best_album_art_file(Media m);
	public abstract Gdk.Pixbuf? get_art_from_media_folder(Media m);
	public abstract Gdk.Pixbuf? get_album_art_from_key(string album_artist, string album);
	public abstract Gdk.Pixbuf? get_album_art_from_media(Media m);
	
	public abstract async void fetch_image_cache_async ();
	public abstract void fetch_remaining_album_art();
}
