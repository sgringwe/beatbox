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

using Gee;
using Gtk;


public abstract class BeatBox.GenericGrid : FastGrid {
	protected SourceView parent_wrapper;

	// Share popover across multiple grid views. For speed and memory saving
	private static PopupListView? _popup_list_view = null;
	protected PopupListView popup_list {
		get {
			if (_popup_list_view == null) {
				debug ("Creating Grid view popup");
				_popup_list_view = new PopupListView (this.parent_wrapper);

				_popup_list_view.focus_out_event.connect ( () => {
					if (popup_list.visible && App.window.has_focus) {
						popup_list.show_all ();
						popup_list.present ();
					}
					return false;
				});
			}

			return _popup_list_view;
		}
	}

    protected Gdk.Pixbuf default_art;

	// For shuffle
	protected int old_sort_col;
	protected SortType old_sort_dir;
	
	protected TreeViewSetup tvs;
	public int relative_id;
	protected bool is_current_list;
	
	protected bool scrolled_recently;
	protected bool dragging;

	// To select which columns are showing
	protected Gtk.Menu columnChooserMenu;
	
	public signal void import_requested(LinkedList<Media> to_import);
	
	private const string WIDGET_STYLESHEET = "*:selected{background-color:@transparent;}";

	private const int ITEM_PADDING = 0;
	private const int MIN_SPACING = 12;
	private const int ITEM_WIDTH = Icons.ALBUM_VIEW_IMAGE_SIZE;

	public GenericGrid(SourceView parent_wrapper, TreeViewSetup tvs, GLib.Object default_value) {
		base(default_value);

        set_parent_wrapper (parent_wrapper);
		this.tvs = tvs;
		
		// Change background color
		var style_provider = new CssProvider();

        try  {
            style_provider.load_from_data (WIDGET_STYLESHEET, -1);
        } catch (Error e) {
            warning ("Couldn't load style provider: %s", e.message);
        }

        get_style_context ().add_provider (style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		
		item_width = ITEM_WIDTH;
		item_padding = ITEM_PADDING;
        set_layout_spacing (MIN_SPACING);

		// drag source
		TargetEntry te = { "text/uri-list", TargetFlags.SAME_APP, 0};
		drag_source_set(this, Gdk.ModifierType.BUTTON1_MASK, { te }, Gdk.DragAction.COPY);
		//enable_model_drag_source(Gdk.ModifierType.BUTTON1_MASK, {te}, Gdk.DragAction.COPY);
		
		//row_activated.connect(row_activated_signal);
		//rows_reordered.connect(updateTreeViewSetup);
		App.playback.current_cleared.connect(current_cleared);
		//App.library.media_played.connect(media_played);
		//App.library.medias_updated.connect(medias_updated);


		this.add_events (Gdk.EventMask.POINTER_MOTION_MASK);
		//this.motion_notify_event.connect (on_motion_notify);
		//this.scroll_event.connect (on_scroll_event);

		//this.button_press_event.connect (on_button_press);
		this.button_release_event.connect (on_button_release);

        // For smart spacing...
		int MIN_N_ITEMS = 2; // we will allocate horizontal space for at least two items
		int TOTAL_ITEM_WIDTH = ITEM_WIDTH + 2 * ITEM_PADDING;
		int TOTAL_MARGIN = MIN_N_ITEMS * (MIN_SPACING + ITEM_PADDING);
		int MIDDLE_SPACE = MIN_N_ITEMS * MIN_SPACING;
		parent_wrapper.set_size_request (MIN_N_ITEMS * TOTAL_ITEM_WIDTH + TOTAL_MARGIN + MIDDLE_SPACE, -1);
	}

	public void set_parent_wrapper(SourceView parent) {
		this.parent_wrapper = parent;
		//hadjustment.changed.connect(on_resize);
		//vadjustment.value_changed.connect(view_scroll);
	}
	
	public abstract void update_sensitivities();
	
	/** TreeViewColumn header functions. Has to do with sorting and
	 * remembering column widths/sort column/sort direction between
	 * sessions.
	**/
	protected abstract void updateTreeViewSetup();
	
	
	void current_cleared() {
		is_current_list = false;
	}
	
	/***************************************
	 * Simple setters and getters
	 * *************************************/
	public void set_hint(TreeViewSetup.Hint hint) {
		tvs.set_hint(hint);
	}
	
	public TreeViewSetup.Hint get_hint() {
		return tvs.get_hint();
	}
	
	public void set_relative_id(int id) {
		this.relative_id = id;
	}
	
	public int get_relative_id() {
		return relative_id;
	}
	
	public bool get_is_current_list() {
		return is_current_list;
	}

    public abstract void item_activated_handler (Object? selected);

	private bool on_button_release (Gdk.EventButton ev) {
		if (ev.type == Gdk.EventType.BUTTON_RELEASE && ev.button == 1) {
			TreePath? path;
			CellRenderer cell;

			this.get_item_at_pos ((int)ev.x, (int)ev.y, out path, out cell);

			if (path != null)
		        item_activated_handler (get_selected_objects().nth_data (0));
		    else
		        item_activated_handler (null);
		}

		return false;
	}

	private inline void set_pointer (int x, int y) {
		TreePath? path;
		CellRenderer cell;

		this.get_item_at_pos (x, y, out path, out cell);

		if (path == null) // blank area
			this.get_window ().set_cursor (null);
		else
			this.get_window ().set_cursor (new Gdk.Cursor (Gdk.CursorType.HAND1));

	}

	private bool on_motion_notify (Gdk.EventMotion ev) {
		set_pointer ((int)ev.x, (int)ev.y);
		return false;
	}

	private bool on_scroll_event (Gdk.EventScroll ev) {
		set_pointer ((int)ev.x, (int)ev.y);
		return false;
	}



	/**
	 * Smart spacing
	 */

	Mutex setting_size;
	int last_width = 0;
	int resize_priority_offset = 0;

	private void on_resize () {
		Timeout.add (200, () => {
			compute_spacing (get_current_width());
			resize_priority_offset = 0;
			return false;
		});
	}
	
	private int get_current_width () {
        return (int)get_hadjustment ().page_size;
    }

	private void compute_spacing (int new_width) {
		if (new_width != get_current_width() || !visible || new_width == last_width)
			return;
		
		last_width = new_width;
		
		int TOTAL_WIDTH = new_width;
		int TOTAL_ITEM_WIDTH = ITEM_WIDTH + 2 * ITEM_PADDING;

		// Calculate the number of columns
		float n = (float)(TOTAL_WIDTH - MIN_SPACING) / (float)(TOTAL_ITEM_WIDTH + MIN_SPACING);
		int n_columns = Numeric.lowest_int_from_float (n);

		if (n_columns < 1) {
			return;
		}

		this.set_columns (n_columns);

		// We don't want to adjust the spacing if the row is not full
		if (this.get_table ().size () < n_columns) {
			return;
		}

		// You're not supposed to understand this.
		float spacing = (float)(TOTAL_WIDTH - n_columns * (ITEM_WIDTH + 1) - 2 * n_columns * ITEM_PADDING) / (float)(n_columns + 1);
		int new_spacing = Numeric.int_from_float (spacing);

		if (new_spacing < 0) {
			return;
		}

		if (TOTAL_WIDTH < 750)
			-- new_spacing;

		// apply new spacing
		set_layout_spacing (new_spacing);
	}

    /**
     * Sets the spacing between rows, columns, as well as the margin.
     */
	private void set_layout_spacing (int spacing) {
        if (spacing < 0)
            return;

        int item_offset = ITEM_PADDING / columns;
        int item_spacing = spacing - ((item_offset > 0) ? item_offset : 1);

        set_column_spacing (item_spacing);
        set_row_spacing (item_spacing);

        int margin_width = spacing + ITEM_PADDING;
        margin_left = margin_width;
       // margin_right = 0;
    }
}
