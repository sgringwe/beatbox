/*-
 * Copyright (c) 2011-2012	   Scott Ringwelski <sgringwe@mtu.edu>
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

using Gee;
using Gtk;
using BeatBox.String;

public class BeatBox.ExternalAlbumGrid : FastGrid {
	public signal void item_chosen(GLib.Object o);
	
	public ExternalAlbumGrid() {
		base(new ExternalAlbum("", "", true));
		
		set_compare_func(compare_func);
		set_value_func(val_func);
		set_search_func(grid_search_func);
		
		item_activated.connect(item_activated_signal);
	}
	
	public void item_activated_signal(TreePath path) {
		item_chosen(get_selected_objects().nth_data(0));
	}
	
	/** **************************************************
	 * View search. All lists use same search algorithm 
	 * *************************************************/
	protected void grid_search_func (string search, HashTable<int, GLib.Object> table, ref HashTable<int, GLib.Object> show) {
		int show_index = 0;
		
		for(int i = 0; i < table.size(); ++i) {
			ExternalAlbum m = (ExternalAlbum)table.get(i);
			
			if(search in m.artist.down() || search in m.album.down()) {
				show.set(show_index++, table.get(i));
			}
		}
	}
	
	/***********************************************
	 * Grid value func. Returns markup and pix based on ExternalAlbum
	 * ********************************************/
	string TEXT_MARKUP = "%s\n%s";
	string TOOLTIP_MARKUP = "%s\n%s";
	Value val_func (int row, int column, GLib.Object a_o) {
		ExternalAlbum a = (ExternalAlbum)a_o;
		Value val;
		
		if(column == PIXBUF_COLUMN) {
			var pix = a.pixbuf;
			if(pix == null) {
				pix = App.covers.get_album_art_from_key(a.artist, a.album);
				if(pix == null)
					pix = App.icons.DEFAULT_ALBUM_ART_PIXBUF;
			}
				
			val = pix;
		}
		else if(column == MARKUP_COLUMN) {
			string artist, album;
			
			album = ellipsize(a.album, 25);
			//if(a.album.length > 25)
			//	album = a.album.normalize().substring(0, 22) + "...";
			//else
			//	album = a.album;
			
			if(a.show_artist) {
				artist = ellipsize(a.artist, 25);
				//if(a.artist.length > 25)
				//	artist = a.artist.normalize().substring(0, 22) + "...";
				//else
				//	artist = a.artist;
			}
			else {
				artist = "";
			}
			
			album = Markup.escape_text(album);
			artist = Markup.escape_text(artist);
			val = TEXT_MARKUP.printf(album, artist);
		}
		else if(column == TOOLTIP_COLUMN) {
			string album = Markup.escape_text(a.album);
			string album_artist = Markup.escape_text(a.artist);
			
			val = TOOLTIP_MARKUP.printf (album, album_artist);
		}
		else {
			val = a;
		}
		
		return val;
	}
	
	int compare_func(GLib.Object o_a, GLib.Object o_b) {
		ExternalAlbum a = (ExternalAlbum)o_a;
		ExternalAlbum b = (ExternalAlbum)o_b;
		
		if(a.artist == b.artist) {
			return advanced_string_compare(a.album, b.album);
		}
		else {
			return advanced_string_compare(a.artist, b.artist);
		}
	}
	
	int advanced_string_compare(string a, string b) {
		if(a == "" && b != "")
			return 1;
		else if(a != "" && b == "")
			return -1;
		else if(a == b)
			return 0;
		
		return (a > b) ? 1 : -1;
	}
}

