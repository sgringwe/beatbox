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

public class BeatBox.FastList : TreeView {
	public static const int OPTIMAL_COLUMN = -2;
	FastListModel fm;
	List<Type> columns;
	HashTable<int, Media> table; // is not the same object as showing.
	HashTable<int, Media> showing; // should never point to table.
	
	/* sortable stuff */
	public delegate int SortCompareFunc (int sort_column_id, Gtk.SortType sort_direction, Media a, Media b);
	protected int sort_column_id;
	protected SortType sort_direction;
	private unowned SortCompareFunc compare_func;
	
	// search stuff
	string last_search;
	public delegate void ViewSearchFunc (string search, HashTable<int, Media> table, ref HashTable<int, Media> showing);
	private unowned ViewSearchFunc search_func;
	
	public signal void rows_reordered();
	
	public FastList (List<Type> types, Media default_value) {
		columns = types.copy();
		table = new HashTable<int, Media>(null, null);
		showing = new HashTable<int, Media>(null, null);
		fm = new FastListModel(types, default_value);
		
		sort_column_id = OPTIMAL_COLUMN;
		sort_direction = SortType.ASCENDING;
		last_search = "";
		
		fm.reorder_requested.connect(reorder_requested);
		
		set_table(table);
		set_model(fm);
	}
	
	/** Should not be manipulated by client */
	public HashTable<int, Media> get_table() {
		return table;
	}
	
	/** Should not be manipulated by client */
	public HashTable<int, Media> get_visible_table() {
		return showing;
	}
	
	public int get_index_from_iter(TreeIter iter) {
		return (int)iter.user_data;
	}
	
	public Media get_media_from_index(int index) {
		return showing.get(index);
	}
	
	public GLib.List<Media> get_selected_medias() {
		var rv = new GLib.List<Media>();
		TreeModel temp;
		
		foreach(TreePath path in get_selection().get_selected_rows(out temp)) {
			Media m = get_media_from_index(int.parse(path.to_string()));
			rv.append(m);
		}
		
		return rv;
	}
	
	public void set_value_func(FastListModel.ValueReturnFunc func) {
		fm.set_value_func(func);
	}
	
	public void set_table (HashTable<int, Media> table, bool do_resort = true) {
		this.table = table;
		
		if(do_resort)
			resort(); // this also calls search
		else
			do_search(null);
	}
	
	// If a Media is in objects but not in table, will just ignore
	public void remove_medias (HashTable<Media, int> objects) {
		int index = 0;
		var new_table = new HashTable<int, Media>(null, null);
		for(int i = 0; i < table.size(); ++i) {
			Media o;
			
			// create a new table. if not in objects, and is in table, add it.
			if((o = table.get(i)) != null && objects.get(o) != 1) {
				new_table.set(index++, o);
			}
		}
		
		// no need to resort, just removing
		set_table(new_table, false);
		get_selection().unselect_all();
	}
	
	// Does NOT check for duplicates
	public void add_medias (List<Media> objects) {
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
		warning("begin do_search");
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
		
		if(old_size == 0) {
			set_model(null);
			fm.set_table(showing);
			set_model(fm);
		} else {
			fm.set_table(showing);
			queue_draw();
		}

		//if(showing.size() == old_size) {
		//	fm.set_table(showing);
		//	queue_draw();
		//}
		//else if(old_size == 0) { // if first population, just do normal
		//	set_model(null);
		//	fm.set_table(showing);
		//	set_model(fm);
		//}
		//else if(old_size > showing.size()) { // removing
		//	while(fm.iter_n_children(null) > showing.size()) {
		//		TreeIter iter;
		//		fm.iter_nth_child(out iter, null, fm.iter_n_children(null) - 1);
		//		fm.remove(iter);
		//	}
		//	
		//	fm.set_table(showing);
		//	queue_draw();
		//}
		//else if(showing.size() > old_size) { // adding
		//	TreeIter iter;
		//	
		//	while(fm.size() < showing.size())
		//		fm.append(out iter);
		//	
		//	fm.set_table(showing);
		//	queue_draw();
		//}
		warning("end do_search");
	}
	
	public void redraw_row (int row_index) {
		fm.update_row (row_index);
	}
	
	/** Sorting is done in the treeview, not the model. That way the whole
	 * table is sorted and ready to go and we do not need to resort every
	 * time we repopulate/search the model
	**/
	public void set_sort_column_id (int sort_column_id, SortType order) {
		fm.set_sort_column_id(sort_column_id, order); // The model will then go back to us at reorder_requested
	}
	
	public void get_sort_column_id (out int sort_column, out SortType order) {
		sort_column = sort_column_id;
		order = sort_direction;
	}
	
	void reorder_requested (int column, Gtk.SortType direction) {
		if(column == sort_column_id && direction == sort_direction) {
			return;
		}
		
		sort_column_id = column;
		sort_direction = direction;
		
		quicksort(0, (int)(table.size() - 1));
		do_search(null);
		
		// Let it be known the row order changed
		rows_reordered();
	}
	
	public void resort (bool threaded = false) {
		if(threaded) {
			try {
				new Thread<void*>.try (null, () => {
					quicksort(0, (int)(table.size() - 1));
					
					Idle.add( () => { do_search (null); return false; });
					
					return null;
				});
			}
			catch(Error err) {}
		}
		else {
			quicksort(0, (int)(table.size() - 1));
			do_search (null);
		}
	}
	
	public void set_compare_func (SortCompareFunc func) {
		compare_func = func;
	}
	
	void swap (int a, int b) {
		Media temp = table.get(a);
		table.set(a, table.get(b));
		table.set(b, temp);
	}
	
	public void quicksort (int start, int end) {
		Media pivot = table.get((start+end)/2);
		int i = start;
		int j = end;
		
		while(i <= j) {
			while(i < end && compare_func (sort_column_id, sort_direction, table.get(i), pivot) < 0) ++i;
			while(j > start && compare_func (sort_column_id, sort_direction, table.get(j), pivot) > 0) --j;
			if(i <= j) {
				swap(i, j);
				++i; --j;
			}
		}
		
		if(start < j)	quicksort (start, j);
		if(i < end)		quicksort (i, end);
	}
}
