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

public class BeatBox.Artist : GLib.Object {
	string album_artist;
	Gdk.Pixbuf pix;
	bool generated_pix;
	HashMap<Media, int> media; // 1 = has
	
	public Artist(string alb_artist) {
		album_artist = alb_artist;
		media = new HashMap<Media, int>();
	}
	
	public string get_album_artist() {
		return album_artist;//media.keys.to_array()[0].album_artist;
	}
	
	public Gdk.Pixbuf? get_pixbuf() {
		if(generated_pix)
			return pix;
		else
			return generate_pix();
	}
	
	public Gdk.Pixbuf? generate_pix() {
		
		// REMOVED SO THERE WAS NO DEPENDENCE ON LM IN CORE
		
		/*LibraryManager lm = Beatbox._program.lm;
		
		LinkedList<Gdk.Pixbuf> arts = new LinkedList<Gdk.Pixbuf>();
		HashMap<string, int> albs = new HashMap<string, int>();
		foreach(var m in media.keys) {
			string key = lm.album_key(m);
			
			if(albs.get(key) == 0) {
				albs.set(key, 1);
				var pixbuf = lm.get_cover_album_art_from_key(m.album_artist, m.album);
				if(pixbuf != null)
					arts.add(pixbuf);
			}
			
			if(arts.size > 4)
				break;
		}
		*/
		//Gdk.Pixbuf _canvas;
		/*if(arts.size > 1) {
			int partial_size = Icons.ALBUM_VIEW_IMAGE_SIZE - (arts.size * 12);
			_canvas = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, Icons.ALBUM_VIEW_IMAGE_SIZE, Icons.ALBUM_VIEW_IMAGE_SIZE);
			_canvas.fill(0x00000000);// transparent black
			
			int x = 0;
			int y = 0;
			for(int i = 0; i < arts.size; ++i) {
				var scaled_pix = arts.get(i).scale_simple(partial_size, partial_size, Gdk.InterpType.BILINEAR);
				scaled_pix.copy_area(0, 0, partial_size, partial_size, _canvas, x, y);
				
				x += 12;
				y += 12; 
			}
		}
		else *if(arts.size == 1) {
			_canvas = arts.get(0);
		}
		else {
			_canvas = Icons.DEFAULT_ALBUM_ART_PIXBUF;
		}
		
		if(arts.size > 0)
			generated_pix = true;
		
		pix = _canvas;*/
		
		return pix;
		
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
}
