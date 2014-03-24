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

public class BeatBox.FastGrid : IconView {
	protected const int PIXBUF_COLUMN = 0;
	protected const int MARKUP_COLUMN = 1;
	protected const int TOOLTIP_COLUMN = 2;
	protected const int ALBUM_COLUMN = 3;
	
	FastGridModel fm;
	HashTable<int, GLib.Object> table; // is not the same object as showing.
	HashTable<int, GLib.Object> showing; // should never point to table.
	
	/* sortable stuff */
	public delegate int SortCompareFunc (GLib.Object a, GLib.Object b);
	private unowned SortCompareFunc compare_func;
	
	// search stuff
	string last_search;
	public delegate void ViewSearchFunc (string search, HashTable<int, GLib.Object> table, ref HashTable<int, GLib.Object> showing);
	private unowned ViewSearchFunc search_func;
	
	public FastGrid (GLib.Object default_value) {
		table = new HashTable<int, GLib.Object>(null, null);
		showing = new HashTable<int, GLib.Object>(null, null);
		fm = new FastGridModel(default_value);
		
		last_search = "";
		
		margin = 12;
		item_width = IconsInterface.ALBUM_VIEW_IMAGE_SIZE;
		
		set_pixbuf_column(PIXBUF_COLUMN);
		set_markup_column(MARKUP_COLUMN);
		set_tooltip_column(TOOLTIP_COLUMN);
		
		set_table(table);
		set_model(fm);
	}
	
	/** Should not be manipulated by client */
	public HashTable<int, GLib.Object> get_table() {
		return table;
	}
	
	/** Should not be manipulated by client */
	public HashTable<int, GLib.Object> get_visible_table() {
		return showing;
	}
	
	public int get_index_from_iter(TreeIter iter) {
		return (int)iter.user_data;
	}
	
	public GLib.Object get_object_from_index(int index) {
		return showing.get(index);
	}
	
	protected GLib.List<Object> get_selected_objects() {
		var rv = new GLib.List<Object>();
		
		foreach(TreePath path in get_selected_items()) {
			Object o = get_object_from_index(int.parse(path.to_string()));
			rv.append(o);
		}
		
		return rv;
	}
	
	public void set_value_func(FastGridModel.ValueReturnFunc func) {
		fm.set_value_func(func);
	}
	
	public void set_table (HashTable<int, GLib.Object> table, bool do_resort = true) {
		this.table = table;
		
		if(do_resort)
			resort(); // this also calls search
		else
			do_search(null);
	}
	
	// If a GLib.Object is in objects but not in table, will just ignore
	// TODO: FIXME FOR GENERIC OBJECT. MAYBE ADD INTERFACE WITH GET_KEY()?
	public void remove_objects (HashTable<GLib.Object, int> objects) {
		int index = 0;
		var new_table = new HashTable<int, GLib.Object>(null, null);
		for(int i = 0; i < table.size(); ++i) {
			GLib.Object o;
			
			// create a new table. if not in objects, and is in table, add it.
			if((o = table.get(i)) != null && objects.get(o) != 1) {
				new_table.set(index++, o);
			}
		}
		
		// no need to resort, just removing
		set_table(new_table, false);
		//get_selection().unselect_all();
	}
	
	// Does NOT check for duplicates
	public void add_objects (List<GLib.Object> objects) {
		// skip calling set_table and just do it ourselves (faster)
		foreach(var o in objects) {
			table.set((int)table.size(), o);
		}
		
		// resort the new songs in. this will also call do_search
		resort ();
	}
	
	public void set_search_func (ViewSearchFunc func) {
		search_func = func;
	}
	
	public void do_search (string? search) {
		if(search_func == null)
			return;
		
		var old_size = showing.size();
		
		showing.remove_all();
		if(search != null)
			last_search = search;
		
		//if(last_search == "") {
		//	for(int i = 0; i < table.size(); ++i) {
		//		showing.set(i, table.get(i));
		//	}
		//}
		//else {
			search_func(last_search, table, ref showing);
		//}
		
		if(showing.size() == old_size) {
			fm.set_table(showing);
			queue_draw();
		}
		else if(old_size == 0) { // if first population, just do normal
			set_model(null);
			fm.set_table(showing);
			set_model(fm);
		}
		else if(old_size > showing.size()) { // removing
			while(fm.iter_n_children(null) > showing.size()) {
				TreeIter iter;
				fm.iter_nth_child(out iter, null, fm.iter_n_children(null) - 1);
				fm.remove(iter);
			}
			
			fm.set_table(showing);
			queue_draw();
		}
		else if(showing.size() > old_size) { // adding
			TreeIter iter;
			
			while(fm.iter_n_children(null) < showing.size()) {
				fm.append(out iter);
			}
			
			fm.set_table(showing);
			queue_draw();
		}
	}
	
	public void redraw_row (int row_index) {
		fm.update_row (row_index);
	}
	
	/** Sorting is done in the treeview, not the model. That way the whole
	 * table is sorted and ready to go and we do not need to resort every
	 * time we repopulate/search the model
	**/
	public void set_compare_func (SortCompareFunc func) {
		compare_func = func;
	}
	
	public void resort () {
		quicksort(0, (int)(table.size() - 1));
		do_search (null);
	}
	
	void swap (int a, int b) {
		GLib.Object temp = table.get(a);
		table.set(a, table.get(b));
		table.set(b, temp);
	}
	
	public void quicksort (int start, int end) {
		GLib.Object pivot = table.get((start+end)/2);
		int i = start;
		int j = end;
		
		while(i <= j) {
			while(i < end && compare_func (table.get(i), pivot) < 0) ++i;
			while(j > start && compare_func (table.get(j), pivot) > 0) --j;
			if(i <= j) {
				swap(i, j);
				++i; --j;
			}
		}
		
		if(start < j)	quicksort (start, j);
		if(i < end)		quicksort (i, end);
	}
}
