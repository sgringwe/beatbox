/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player and Granite Library
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 * Granite Library:      http://www.launchpad.net/granite
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
 * NOTES: The iters returned are child model iters. To work with any function
 * except for add, you need to to use convertToFilter(child iter);
 */

using Gtk;
using Gdk;

public enum BeatBox.SideBarColumn {
	COLUMN_OBJECT,
	COLUMN_WIDGET,
	COLUMN_VISIBLE,
	COLUMN_PIXBUF,
	COLUMN_TEXT,
	COLUMN_CLICKABLE,
	COLUMN_DRAGGABLE,
	COLUMN_DROPPABLE,
	COLUMN_IS_SELECTABLE_PARENT // whether or not to show the row even with no children
}
	
public class BeatBox.SideBar : Gtk.TreeView {
	public TreeStore tree;
	public TreeModelFilter filter;
	
	SideBarRenderer side_renderer;
	
	TreeIter? selectedIter;
	TreeIter? highlight_iter;
	
	public bool autoExpanded;
	
	public signal void clickable_clicked(TreeIter iter);
	public signal void true_selection_change(TreeIter selected);
	public signal void true_drag_received(TreeIter iter, Gtk.SelectionData data);
	
	public SideBar() {
		tree = new TreeStore(9, typeof(GLib.Object), typeof(Widget), typeof(bool), 
								typeof(Gdk.Pixbuf), typeof(string), typeof(Gdk.Pixbuf), 
								typeof(bool), typeof(bool), typeof(bool));
		filter = new TreeModelFilter(tree, null);
		set_model(filter);
		
		TreeViewColumn col = new TreeViewColumn();
		col.title = "display";
		this.insert_column(col, 0);
		
		// add the ultimate renderer
		side_renderer = new SideBarRenderer();
		col.pack_start(side_renderer, true);
		col.set_cell_data_func(side_renderer, sideBarFiller);
		col.expand = true;
		
		this.set_headers_visible(false);
		this.set_show_expanders(false);
		filter.set_visible_column(SideBarColumn.COLUMN_VISIBLE);
		this.set_grid_lines(TreeViewGridLines.NONE);
		this.name = "SidebarContent";
		
		this.get_selection().changed.connect(selectionChange);
		this.button_press_event.connect(sideBarClick);
		
		// drag and drop
		//var entry = Gtk.TargetEntry("text/uri", 0, 0);
		
		//TargetEntry te1 = { "text/uri-list", 0, 0 };
		TargetEntry te1 = { "text/uri-list", TargetFlags.SAME_APP, 0 };
		//drag_source_set(this, Gdk.ModifierType.BUTTON1_MASK, { te1 }, Gdk.DragAction.COPY);
		Gtk.drag_dest_set(this, DestDefaults.ALL, { te1 }, Gdk.DragAction.COPY);
		//drag_dest_add_uri_targets(this);
		//enable_model_drag_dest({te1}, Gdk.DragAction.COPY);
				
		drag_motion.connect(drag_motion_signal);
		drag_leave.connect(drag_leave_signal);
		//drag_drop.connect(drag_drop_signal);
		drag_data_received.connect(drag_received);
		
	}
	
	// For the sidebar
	public void sideBarFiller(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
		SideBarRenderer side_rend = (SideBarRenderer)renderer;
		TreePath path = model.get_path(iter);
		
		side_rend.model = model;
		side_rend.iter = iter;
		side_rend.expanded = is_row_expanded(path);
		side_rend.highlight = (iter == highlight_iter);
	}
	
	/* Convenient add/remove/edit methods */
	public TreeIter addItem(TreeIter? parent, TreeIter? before, GLib.Object? o, Widget? w, 
							Gdk.Pixbuf? pixbuf, string text, Gdk.Pixbuf? clickable,
							bool draggable, bool droppable,
							bool is_selectable_parent) {
		TreeIter iter;
		
		if(before == null)
			tree.append(out iter, parent);
		else
			tree.insert_before(out iter, parent, before);
		
		tree.set(iter,  SideBarColumn.COLUMN_OBJECT, o,
						SideBarColumn.COLUMN_WIDGET, w,
						SideBarColumn.COLUMN_VISIBLE, true,
						SideBarColumn.COLUMN_PIXBUF, pixbuf,
						SideBarColumn.COLUMN_TEXT, text,
						SideBarColumn.COLUMN_CLICKABLE, clickable, 
						SideBarColumn.COLUMN_DRAGGABLE, draggable, 
						SideBarColumn.COLUMN_DROPPABLE, droppable,
						SideBarColumn.COLUMN_IS_SELECTABLE_PARENT, is_selectable_parent);
		
		if(parent != null) {
			tree.set(parent, SideBarColumn.COLUMN_VISIBLE, true);
		}
		else if(!is_selectable_parent) {
			tree.set(iter, SideBarColumn.COLUMN_VISIBLE, false);
		}
		
		expand_all();
		return iter;
	}
	
	public bool removeItem(TreeIter iter) {
		TreeIter parent;
		if(tree.iter_parent(out parent, iter)) {
			bool show_no_children = false;
			tree.get(parent, SideBarColumn.COLUMN_IS_SELECTABLE_PARENT, out show_no_children);
			if(tree.iter_n_children(parent) > 1 || show_no_children)
				tree.set(parent, SideBarColumn.COLUMN_VISIBLE, true);
			else
				tree.set(parent, SideBarColumn.COLUMN_VISIBLE, false);
		}
		
		//Widget w;
		//tree.get(iter, SideBarColumn.COLUMN_WIDGET, out w);
		//w.destroy();
		
		// destroy child row widgets as well
		//TreeIter current;
		//if(tree.iter_children(out current, iter)) {
		//	do {
				//tree.get(current, SideBarColumn.COLUMN_WIDGET, out w);
				//w.destroy();
		//	}
		//	while(tree.iter_next(ref current));
		//}
		
		return tree.remove(ref iter);
	}
	
	// input MUST be a child iter
	public void setVisibility(TreeIter it, bool val) {
		bool was = false;
		tree.get(it, SideBarColumn.COLUMN_VISIBLE, out was);
		tree.set(it, SideBarColumn.COLUMN_VISIBLE, val);
		
		if(val && !was) {
			expand_row(filter.get_path(convertToFilter(it)), true);
		}
	}
	
	public void setName(TreeIter it, string name) {
		TreeIter iter = it;
		
		tree.set(iter, SideBarColumn.COLUMN_TEXT, name);
	}
	
	// parent should be filter iter
	public bool setNameFromObject(TreeIter parent, GLib.Object o, string name) {
		TreeIter realParent = convertToChild(parent);
		TreeIter pivot;
		tree.iter_children(out pivot, realParent);
		
		do {
			GLib.Object tempO;
			tree.get(pivot, 0, out tempO);
			
			if(tempO == o) {
				tree.set(pivot, SideBarColumn.COLUMN_TEXT, name);
				return true;
			}
			else if(!tree.iter_next(ref pivot)) {
				return false;
			}
			
		} while(true);
	}
	
	public TreeIter? getSelectedIter() {
		TreeModel mod;
		TreeIter sel;
		
		if(this.get_selection().get_selected(out mod, out sel)) {
			return sel;
		}
		
		return null;
	}
	
	public void setSelectedIter(TreeIter iter) {
		if(iter == selectedIter) {
			return;
		}
		
		this.get_selection().changed.disconnect(selectionChange);
		get_selection().unselect_all();
		
		get_selection().select_iter(iter);
		this.get_selection().changed.connect(selectionChange);
		selectedIter = iter;
		
		true_selection_change(iter);
	}
	
	public bool expandItem(TreeIter iter, bool expanded) {
		TreePath path = filter.get_path(iter);
		
		if(path.get_depth() != 1)
			return false;
		
		return this.expand_row(path, false);
	}
	
	public GLib.Object? getObject(TreeIter iter) {
		GLib.Object o;
		filter.get(iter, SideBarColumn.COLUMN_OBJECT, out o);
		return o;
	}
	
	public Widget? getWidget(TreeIter iter) {
		Widget w;
		tree.get(iter, SideBarColumn.COLUMN_WIDGET, out w);
		return w;
	}
	
	public TreeIter? getIterFromObject(TreeIter parent, GLib.Object o) {
		TreeIter realParent = parent;//convertToChild(parent);
		TreeIter pivot;
		tree.iter_children(out pivot, realParent);
		
		do {
			GLib.Object tempO;
			tree.get(pivot, 0, out tempO);
			
			if(tempO == o) {
				return pivot;
			}
			else if(!tree.iter_next(ref pivot)) {
				return null;
			}
			
		} while(true);
	}
	
	public Widget? getSelectedWidget() {
		TreeModel m;
		TreeIter iter;
		
		if(!this.get_selection().get_selected(out m, out iter)) { // user has nothing selected, reselect last selected
			//if(iter == null)
				return null;
		}
		
		Widget w;
		m.get(iter, SideBarColumn.COLUMN_WIDGET, out w);
		return w;
	}
	
	public Object? getSelectedObject() {
		TreeModel m;
		TreeIter iter;
		
		if(!this.get_selection().get_selected(out m, out iter)) { // user has nothing selected, reselect last selected
			//if(iter == null)
				return null;
		}
		
		Object o;
		m.get(iter, SideBarColumn.COLUMN_OBJECT, out o);
		return o;
	}
	
	/* stops user from selecting the root nodes */
	public void selectionChange() {
		TreeModel model;
		TreeIter pending;
		
		if(!this.get_selection().get_selected(out model, out pending)) { // user has nothing selected, reselect last selected
			if(selectedIter != null) {
				this.get_selection().select_iter(selectedIter);
			}
			
			return;
		}
		
		// TODO: This is the cause of the error messages that are spit out. 
		// We need to get a path/iter that belongs to filter or model,
		// not to this temp model that we got from above.
		TreePath temp_path = model.get_path(pending);
		
		TreeIter filt_iter;
		if(!filter.get_iter(out filt_iter, temp_path)) {
			warning("Could not get iter from selected path");
			return;
		}
		
		bool is_selectable_parent = false;
		model.get(filt_iter, SideBarColumn.COLUMN_IS_SELECTABLE_PARENT, out is_selectable_parent);
		
		if(temp_path.get_depth() == 1 && !is_selectable_parent) {
			this.get_selection().unselect_all();
			if(selectedIter != null)
				this.get_selection().select_iter(selectedIter);
		}
		else if(pending != selectedIter) {
			selectedIter = filt_iter;
			true_selection_change(selectedIter);
		}
	}
	
	/* click event functions */
	private bool sideBarClick(Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			// select one based on mouse position
			TreeIter iter;
			TreePath path;
			TreeViewColumn column;
			int cell_x;
			int cell_y;
			
			this.get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);
			if(path == null)
				return false;
			if(!filter.get_iter(out iter, path))
				return false;
			
			if(overClickable(iter, column, (int)cell_x, (int)cell_y)) {
				clickable_clicked(iter);
			}
			else if(overExpander(iter, column, (int)cell_x, (int)cell_y)) {
				if(is_row_expanded(path))
					this.collapse_row(path);
				else
					this.expand_row(path, true);
			}
		}
		
		return false;
	}
	
	private bool overClickable(TreeIter iter, TreeViewColumn col, int x, int y) {
		/*Pixbuf pix;
		filter.get(iter, 5, out pix);
		
		if(pix == null)
			return false;
		
		int cell_x;
		int cell_width;
		col.cell_get_position(clickable_cell, out cell_x, out cell_width);
		
		if(x > cell_x && x < cell_x + cell_width)
			return true;*/
		
		return false;
	}
	
	private bool overExpander(TreeIter iter, TreeViewColumn col, int x, int y) {
		bool rv = false;
		if(filter.get_path(iter).get_depth() != 1)
			rv = false;
		else
			rv = true;
		
		return rv;
		/* for some reason, the pixbuf SOMETIMES takes space, somtimes doesn't so cope for that *
		int pixbuf_start;
		int pixbuf_width;
		col.cell_get_position(pix_cell, out pixbuf_start, out pixbuf_width);
		int text_start;
		int text_width;
		col.cell_get_position(text_cell, out text_start, out text_width);
		int click_start;
		int click_width;
		col.cell_get_position(clickable_cell, out click_start, out click_width);
		int total = text_start + text_width + click_width - pixbuf_start;
		
		if(x > total)
			return true;
		
		return false;*/
	}
	
	/* Helpers for child->filter, filter->child */
	public TreeIter? convertToFilter(TreeIter? child) {
		if(child == null)
			return null;
		
		TreeIter rv;
		
		if(filter.convert_child_iter_to_iter(out rv, child)) {
			return rv;
		}
		
		return null;
	}
	
	public TreeIter? convertToChild(TreeIter? filt) {
		if(filt == null)
			return null;
		
		TreeIter rv;
		filter.convert_iter_to_child_iter(out rv, filt);
		
		return rv;
	}
	
	bool drag_motion_signal(Gdk.DragContext context, int x, int y, uint time) {
		TreeIter iter;
		TreePath? path;
		TreeViewDropPosition pos;
		
		if(get_dest_row_at_pos (x, y, out path, out pos)) {
			if(!filter.get_iter(out iter, path))
				return false;
		
			bool droppable;
			filter.get(iter, SideBarColumn.COLUMN_DROPPABLE, out droppable);
			if(droppable) {
				pos = TreeViewDropPosition.INTO_OR_BEFORE;
				highlight_iter = iter;
			}
			else { // test if it's parent is droppable, and if so make that the highlight
				TreeIter parent;
				bool parent_droppable = false;
				
				if(filter.iter_parent(out parent, iter)) {
					filter.get(parent, SideBarColumn.COLUMN_DROPPABLE, out parent_droppable);
				}
				
				if(parent_droppable)
					highlight_iter = parent;
				else
					highlight_iter = null;
			}
		}
		else {
			highlight_iter = null;
		}
		
		queue_draw();
		
		return false;
	}
	
	void drag_leave_signal(Gdk.DragContext context, uint time) {
		highlight_iter = null;
		queue_draw();
	}
	
	void drag_received(Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint info, uint timestamp) {
		bool success = false;
		TreeIter? iter;
		TreePath? path;
		TreeViewColumn column;
		int cell_x;
		int cell_y;
		string text;
		
		// Get the path and iter from x,y and make sure this is a droppable path.
		if(get_path_at_pos(x, y, out path, out column, out cell_x, out cell_y)) {
			if(filter.get_iter(out iter, path)) {
				bool droppable;
				filter.get(iter, SideBarColumn.COLUMN_DROPPABLE, out droppable, SideBarColumn.COLUMN_TEXT, out text);
				if(droppable) {
					message("Drag dropped on hovered item %s\n", text);
					success = true;
					true_drag_received(iter, data);
				}
				else { // if parent is droppable, put drop on that
					TreeIter parent;
					bool parent_droppable = false;
					
					if(filter.iter_parent(out parent, iter)) {
						filter.get(parent, SideBarColumn.COLUMN_DROPPABLE, out parent_droppable, SideBarColumn.COLUMN_TEXT, out text);
					}
					
					if(parent_droppable) {
						message("Drag dropped on hovered item's parent %s\n", text);
						success = true;
						true_drag_received(parent, data);
					}
				}
			}
		}
		
		highlight_iter = null;
		queue_draw();
		
		Gtk.drag_finish (context, success, false, timestamp);
	}
	
}// END CLASS
