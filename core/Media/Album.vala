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

public class BeatBox.Album : GLib.Object {
	string album_artist;
	string album;
	HashMap<Media, int> media; // 1 = has
	Gdk.Pixbuf pixbuf;
	
	public Album(string alb_artist, string alb) {
		album_artist = alb_artist;
		album = alb;
		media = new HashMap<Media, int>();
	}
	
	public string get_album_artist() {
		return album_artist;//media.keys.to_array()[0].album_artist;
	}
	
	public void set_album(string alb) {
		album = alb;
	}
	
	public string get_album() {
		return album;//media.keys.to_array()[0].album;
	}
	
	public int add_media(Media m) {
		media.set(m, 1);
		
		return media.size;
	}
	
	public int remove_media(Media m) {
		media.unset(m);
		
		return media.size;
	}
	
	public int count() {
		return media.size;
	}
	
	public Collection<Media> get_medias() {
		return media.keys;
	}
	
	public Collection<Media> get_medias_sorted() {
		Gee.List<Media> ordered_media = new Gee.LinkedList<Media>();
		ordered_media.add_all(media.keys);
		ordered_media.sort((GLib.CompareFunc)compare_func);
		return ordered_media;
	}
		
	
	public Gdk.Pixbuf? get_art() {
		return pixbuf;
	}
	
	public void set_art(Gdk.Pixbuf pix) {
		this.pixbuf = pix;
	}
	
	public static int compare_func(Media a, Media b) {
		return a.compare(b);
	}
}
