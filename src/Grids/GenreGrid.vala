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

public class BeatBox.GenreGrid : GenericGrid {
	
	public GenreGrid(TreeViewSetup tvs, int rel_id) {
		base(lm, tvs, rel_id);
		
		set_compare_func(compare_func);
		set_value_func(val_func);
		set_search_func(grid_search_func);
		
		button_release_event.connect(button_release);
		drag_begin.connect(on_drag_begin);
		drag_data_get.connect(on_drag_data_get);
		drag_end.connect(on_drag_end);
	}
	
	protected override void updateTreeViewSetup() {
		
	}
	
	protected override void update_sensitivities() {
		
	}
	
	bool button_release(Gdk.EventButton ev) {
		if(ev.button == 1) {
			TreePath path;
			CellRenderer cell;

			get_item_at_pos((int)ev.x, (int)ev.y, out path, out cell);
			
			if(path == null)
				return false;
			
			Genre gen = (Genre)get_object_from_index(int.parse(path.to_string()));
			parent_wrapper.grid_genre_filter = gen.get_genre();
			parent_wrapper.selector.selected = 0;
			parent_wrapper.re_search();
			parent_wrapper.set_statusbar_info();
		}
		
		return false;
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
			Genre g = (Genre)get_object_from_index(int.parse(path.to_string()));
			foreach(var m in g.get_medias())
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
			Genre m = (Genre)table.get(i);
			
			if(search in m.get_genre().down()) {
				show.set(show_index++, table.get(i));
			}
		}
	}
	
	/***********************************************
	 * Grid value func. Returns markup and pix based on Album
	 * ********************************************/
	string TEXT_MARKUP = "<span weight='medium' size='10500'>%s\n</span><span foreground=\"#999\">%s</span>";
	string TOOLTIP_MARKUP = "<span weight='bold' size='10500'>%s</span>";
	Value val_func (int row, int column, GLib.Object a_o) {
		Genre a = (Genre)a_o;
		Value val;
		
		if(column == PIXBUF_COLUMN) {
			val = a.get_pixbuf();
		}
		else if(column == MARKUP_COLUMN) {
			string genre;
			
			if(a.get_genre().length > 30)
				genre = a.get_genre().substring(0, 27) + "...";
			else
				genre = a.get_genre();
			
			string plural = (a.count() > 1) ? "s" : "";
			val = TEXT_MARKUP.printf(genre.replace("&", "&amp;"), a.count().to_string() + " " + parent_wrapper.media_representation + plural);
		}
		else if(column == TOOLTIP_COLUMN) {
			val = TOOLTIP_MARKUP.printf (a.get_genre().replace("&", "&amp;"));
		}
		else {
			val = a;
		}
		
		return val;
	}
	
	int compare_func(GLib.Object o_a, GLib.Object o_b) {
		Genre a = (Genre)o_a;
		Genre b = (Genre)o_b;
		
		if(a.get_genre() == b.get_genre()) {
			return a.count() - b.count();
		}
		else {
			return advanced_string_compare(a.get_genre(), b.get_genre());
		}
	}
	
	int advanced_string_compare(string a, string b) {
		if(a == "" && b != "")
			return 1;
		else if(a != "" && b == "")
			return -1;
		
		return (a > b) ? 1 : -1;
	}
}

