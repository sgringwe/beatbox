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

public class BeatBox.AlbumGrid : GenericGrid {

	public AlbumGrid(SourceView parent_wrapper, TreeViewSetup tvs) {
		base(parent_wrapper, tvs, new Album("", ""));

		set_compare_func(compare_func);
		set_value_func(val_func);
		set_search_func(grid_search_func);

		drag_begin.connect(on_drag_begin);
		drag_data_get.connect(on_drag_data_get);
		drag_end.connect(on_drag_end);
		
        default_art = App.covers.DEFAULT_COVER_SHADOW;
	}
	
	protected override void updateTreeViewSetup() {
		
	}
	
	protected override void update_sensitivities() {
		
	}
	
	public override void item_activated_handler (Object? selected) {
        this.popup_list.set_parent_wrapper (this.parent_wrapper);

        if (selected != null) {
	        var alb = selected as Album;
	        return_if_fail (alb != null);
	        this.popup_list.set_items(alb);
	        this.popup_list.show_all();
        } else {
            this.popup_list.hide ();
        }
	}
	
	/** **********************************************************
	 * Drag and drop support. GenericView is a source for uris and can
	 * be dragged to a playlist in the sidebar. No support for reordering
	 * is implemented yet.
	***************************************************************/
	void on_drag_begin(Gtk.Widget sender, Gdk.DragContext context) {
		dragging = true;
		App.window.dragging_from_music = true;
		debug("drag begin\n");

		Gdk.drag_abort(context, Gtk.get_current_event_time());

		if(get_selected_items().length() == 1) {
			drag_source_set_icon_stock(this, Gtk.Stock.DND);
		}
		else if(get_selected_items().length() > 1) {
			drag_source_set_icon_stock(this, Gtk.Stock.DND_MULTIPLE);
		}
		else {
			return;
		}
	}
	
	void on_drag_data_get(Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_) {
		string[] uris = null;

		foreach(TreePath path in get_selected_items()) {
			Album a = (Album)get_object_from_index(int.parse(path.to_string()));
			foreach(var m in a.get_medias_sorted())
				uris += (m.uri);
		}

		if (uris != null)
			selection_data.set_uris(uris);
	}
	
	void on_drag_end(Gtk.Widget sender, Gdk.DragContext context) {
		dragging = false;
		App.window.dragging_from_music = false;

		debug("drag end\n");

		//unset_rows_drag_dest();
		Gtk.drag_dest_set(this,
						  Gtk.DestDefaults.ALL,
						  {},
						  Gdk.DragAction.COPY|
						  Gdk.DragAction.MOVE
						  );
	}
	
	/** **************************************************
	 * View search. All lists use same search algorithm 
	 * *************************************************/
	protected void grid_search_func (string search, HashTable<int, GLib.Object> table, ref HashTable<int, GLib.Object> show) {
		int show_index = 0;
		
		for(int i = 0; i < table.size(); ++i) {
			Album m = (Album)table.get(i);
			
			if(search in m.get_album_artist().down() || search in m.get_album().down()) {
				if((m.get_album_artist().down() == parent_wrapper.artist_filter.down() || parent_wrapper.artist_filter == "")) {
					show.set(show_index++, m);
				}
			}
		}
	}
	
	/***********************************************
	 * Grid value func. Returns markup and pix based on Album
	 * ********************************************/
	string TEXT_MARKUP = "%s\n%s";
	string TOOLTIP_MARKUP = "%s\n%s";
	Value val_func (int row, int column, GLib.Object a_o) {
		Album a = (Album)a_o;
		Value val;
		
		if(column == PIXBUF_COLUMN) {
			var pix = App.covers.get_album_art_from_key(a.get_album_artist(), a.get_album());
			if(pix == null)
				pix = default_art;
				
			val = pix;
		}
		else if(column == MARKUP_COLUMN) {
			string album_artist, album;
		
			album = ellipsize(a.get_album(), 30);
			//if(a.get_album().length > 30)
			//	album = a.get_album().normalize().substring(0, 27) + "...";
			//else
			//	album = a.get_album();

			album_artist = ellipsize(a.get_album_artist(), 25);
			//if(a.get_album_artist().length > 25)
			//	album_artist = a.get_album_artist().normalize().substring(0, 22) + "...";
			//else
			//	album_artist = a.get_album_artist();
			
			album = Markup.escape_text(album);
			album_artist = Markup.escape_text(album_artist);
			val = TEXT_MARKUP.printf(album, album_artist);
		}
		else if(column == TOOLTIP_COLUMN) {
			string album = Markup.escape_text(a.get_album());
			string album_artist = Markup.escape_text(a.get_album_artist());
			
			val = TOOLTIP_MARKUP.printf (album, album_artist);
		}
		else {
			val = a;
		}
		
		return val;
	}
	
	int compare_func(GLib.Object o_a, GLib.Object o_b) {
		Album a = (Album)o_a;
		Album b = (Album)o_b;
		
		if(a.get_album_artist() == b.get_album_artist()) {
			if(a.get_album() == b.get_album()) {
				return a.count() - b.count();
			}
			else {
				return advanced_string_compare(a.get_album(), b.get_album());
			}
		}
		else {
			return advanced_string_compare(a.get_album_artist(), b.get_album_artist());
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

