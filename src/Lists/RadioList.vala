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

public class BeatBox.RadioList : GenericList {

	//for header column chooser
	CheckMenuItem columnRating;
	CheckMenuItem columnStation;
	CheckMenuItem columnGenre;

	//for media list right click
	Gtk.Menu mediaMenuActionMenu;
	Gtk.MenuItem mediaEditMedia;
	Gtk.MenuItem mediaRemove;
	RatingMenuItem mediaRateMedia;

	/**
	 * for sort_id use 0+ for normal, -1 for auto, -2 for none
	 */
	// FIXME: Wrapper.Hint the_hint is no longer necessary
	public RadioList(TreeViewSetup tvs) {
		var types = new GLib.List<Type>();
		types.append(typeof(int)); // id
		types.append(typeof(GLib.Icon)); // icon
		types.append(typeof(string)); // station
		types.append(typeof(string)); // genre
		types.append(typeof(int)); // rating
		types.append(typeof(int)); // pulser
		base(types, tvs, new Station(""));
		
		//last_search = "";
		//timeout_search = new LinkedList<string>();
		//showing_all = true;
		//removing_medias = false;

		buildUI();
	}

	public override void update_sensitivities() {
		mediaRemove.set_visible(true);
		mediaRemove.set_label(_("Remove Station"));
	}

	public void buildUI() {
		add_columns();
		
		set_compare_func(view_compare_func);
        set_search_func(view_search_func);
        set_value_func(view_value_func);
		
		button_press_event.connect(viewClick);
		button_release_event.connect(viewClickRelease);

		// column chooser menu
		columnStation = new CheckMenuItem.with_label(_("Station"));
		columnGenre = new CheckMenuItem.with_label(_("Genre"));
		columnRating = new CheckMenuItem.with_label(_("Rating"));
		updateColumnVisibilities();
		columnChooserMenu.append(columnStation);
		columnChooserMenu.append(columnGenre);
		columnChooserMenu.append(columnRating);
		columnStation.toggled.connect(columnMenuToggled);
		columnGenre.toggled.connect(columnMenuToggled);
		columnRating.toggled.connect(columnMenuToggled);
		columnChooserMenu.show_all();


		//media list right click menu
		mediaMenuActionMenu = new Gtk.Menu();
		mediaEditMedia = new Gtk.MenuItem.with_label(_("Edit Station"));
		mediaRemove = new Gtk.MenuItem.with_label(_("Remove Station"));
		mediaRateMedia = new RatingMenuItem();
		mediaMenuActionMenu.append(mediaEditMedia);
		mediaMenuActionMenu.append(mediaRateMedia);
		mediaMenuActionMenu.append(new SeparatorMenuItem());
		mediaMenuActionMenu.append(mediaRemove);
		mediaEditMedia.activate.connect(mediaMenuEditClicked);
		mediaRemove.activate.connect(mediaRemoveClicked);
		mediaRateMedia.activate.connect(mediaRateMediaClicked);

		update_sensitivities();
	}
	
	public void rearrangeColumns(LinkedList<string> correctOrder) {
		move_column_after(get_column(6), get_column(7));
		//debug("correctOrder.length = %d, get_columns.length() = %d\n", correctOrder.size, (int)get_columns().length());
		/* iterate through get_columns and if a column is not in the
		 * same location as correctOrder, move it there.
		*/
		for(int index = 0; index < get_columns().length(); ++index) {
			//debug("on index %d column %s originally moving to %d\n", index, get_column(index).title, correctOrder.index_of(get_column(index).title));
			if(get_column(index).title != correctOrder.get(index)) {
				move_column_after(get_column(index), get_column(correctOrder.index_of(get_column(index).title)));
			}
		}
	}

	public void cellTitleEdited(string path, string new_text) {
		/*int rowid;
		debug("done!\n");
		if((rowid = list_model.getRowidFromPath(path)) != 0) {
			App.library.media_from_id(rowid).title = new_text;

			App.library.update_media(App.library.media_from_id(rowid), true);
		}
		cellTitle.editable = false; */
	}

	 void sortColumnChanged() {
		updateTreeViewSetup();
	}

	 void modelRowsReordered(TreePath path, TreeIter? iter, void* new_order) {
		/*if(TreeViewSetup.Hint == "queue") {
			App.library.clear_queue();

			TreeIter item;
			for(int i = 0; list_model.get_iter_from_string(out item, i.to_string()); ++i) {
				int id;
				list_model.get(item, 0, out id);

				App.library.queue_media_by_id(id);
			}
		}*/
		
		// TODO: FIXME
		//if(is_current_view) {
		//	set_as_current_list(0, false);
		//}

		if(!scrolled_recently) {
			scroll_to_current_media(false);
		}
	}

	public void updateColumnVisibilities() {
		int index = 0;
		foreach(TreeViewColumn tvc in get_columns()) {
			if(tvc.title == "Station")
				columnStation.active = get_column(index).visible;
			else if(tvc.title == "Genre")
				columnGenre.active = get_column(index).visible;
			else if(tvc.title == "Rating")
				columnRating.active = get_column(index).visible;

			++index;
		}
	}
	
	/* button_press_event */
	bool viewClick(Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) { //right click
			mediaMenuActionMenu.show_all();

			int set_rating = -1;
			foreach(Media m in get_selected_medias()) {
				if(set_rating == -1)
					set_rating = (int)m.rating;
				else if(set_rating != m.rating) {
					set_rating = 0;
					break;
				}
			}
			mediaRateMedia.rating_value = set_rating;
			
			MediaType type = MediaType.ITEM;
			foreach(Media m in get_selected_medias()) {
				if(type == MediaType.ITEM) {
					type = m.media_type;
				}
				else if(type != m.media_type) {
					type = MediaType.ITEM;
					break;
				}
			}
			mediaEditMedia.label = _("Edit %s").printf(type.to_string((int)get_selected_medias().length()));
			
			mediaMenuActionMenu.popup (null, null, null, 3, get_current_event_time());

			TreeSelection selected = get_selection();
			selected.set_mode(SelectionMode.MULTIPLE);
			if(selected.count_selected_rows() > 1)
				return true;
			else
				return false;
		}
		else if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			//TreeIter iter;
			TreePath path;
			TreeViewColumn column;
			int cell_x;
			int cell_y;

			get_path_at_pos((int)event.x, (int)event.y, out path, out column, out cell_x, out cell_y);

			//if(!list_model.get_iter(out iter, path))
			//	return false;

			/* don't unselect everything if multiple selected until button release
			 * for drag and drop reasons */
			if(get_selection().count_selected_rows() > 1) {
				if(get_selection().path_is_selected(path)) {
					if(((event.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
						((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
							get_selection().unselect_path(path);
					}
					return true;
				}
				else if(!(((event.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK)|
				((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK))) {
					return true;
				}

				return false;
			}
		}

		return false;
	}

	/* button_release_event */
	private bool viewClickRelease(Gtk.Widget sender, Gdk.EventButton event) {
		/* if we were dragging, then set dragging to false */
		if(dragging && event.button == 1) {
			dragging = false;
			return true;
		}
		else if(((event.state & Gdk.ModifierType.SHIFT_MASK) == Gdk.ModifierType.SHIFT_MASK) | ((event.state & Gdk.ModifierType.CONTROL_MASK) == Gdk.ModifierType.CONTROL_MASK)) {
			return true;
		}
		else {
			TreePath path;
			TreeViewColumn tvc;
			int cell_x;
			int cell_y;
			int x = (int)event.x;
			int y = (int)event.y;

			if(!(get_path_at_pos(x, y, out path, out tvc, out cell_x, out cell_y))) return false;
			get_selection().unselect_all();
			get_selection().select_path(path);
			return false;
		}
	}

	protected override void updateTreeViewSetup() {
		if(tvs == null || get_columns().length() != TreeViewSetup.RADIO_COLUMN_COUNT)
			return;

		int sort_id = RadioColumn.STATION;
		SortType sort_dir = Gtk.SortType.ASCENDING;
		get_sort_column_id(out sort_id, out sort_dir);

		if(sort_id < 0)
			sort_id = RadioColumn.STATION;
		
		tvs.set_columns(get_columns());
		tvs.sort_column_id = sort_id;
		tvs.sort_direction = sort_dir;
	}

	/** When the column chooser popup menu has a change/toggle **/
	 void columnMenuToggled() {
		int index = 0;
		foreach(TreeViewColumn tvc in get_columns()) {
			if(tvc.title == "Station")
				get_column(index).visible = columnStation.active;
			else if(tvc.title == "Genre")
				get_column(index).visible = columnGenre.active;
			else if(tvc.title == "Rating")
				get_column(index).visible = columnRating.active;

			++index;
		}

		App.window.setups.get_setup(ListSetupInterface.STATION_KEY).set_columns(get_columns());
	}
	
	void mediaRateMediaClicked() {
		var los = new LinkedList<Media>();
		int new_rating = mediaRateMedia.rating_value;
		
		foreach(Media m in get_selected_medias()) {
			m.rating = new_rating;
			los.add(m);
		}

		App.library.update_medias(los, false, true, true);
	}

	 void mediaRemoveClicked() {
		LinkedList<Media> toRemove = new LinkedList<Media>();

		foreach(Media m in get_selected_medias()) {
			toRemove.add(m);
		}

		if(get_hint() == TreeViewSetup.Hint.STATION) {
			var dialog = new RemoveFilesDialog (toRemove, get_hint());
			dialog.remove_media.connect ( (delete_files) => {
				App.library.remove_medias (toRemove, delete_files);
			});
		}
	}
	
	int view_compare_func (int col, Gtk.SortType dir, Media a_media, Media b_media) {
		int rv = 0;
		
		Station a = (Station)a_media;
		Station b = (Station)b_media;
		
		if(sort_column_id == RadioColumn.STATION) { // station
			if(a.name.down() == b.name.down()) {
				rv = advanced_string_compare(b_media.uri, a_media.uri);
			}
			else
				rv = advanced_string_compare(a.name.down(), b.name.down());
		}
		else if(sort_column_id == RadioColumn.GENRE) { // genre
			if(a_media.genre.down() == b_media.genre.down()) {
				if(a.name.down() == b.name.down()) {
					rv = advanced_string_compare(b_media.uri, a_media.uri);
				}
				else {
					rv = advanced_string_compare(a.name.down(), b.name.down());
				}
			}
			else
				rv = advanced_string_compare(a_media.genre.down(), b_media.genre.down());
		}
		
		else if(sort_column_id == RadioColumn.RATING) { // rating
			rv = (int)(a_media.rating - b_media.rating);
		}
		else {
			rv = 0;
		}
		
		if(rv == 0 && col != RadioColumn.STATION && col != RadioColumn.GENRE)
			rv = advanced_string_compare(a_media.uri, b_media.uri);
		
		if(sort_direction == SortType.DESCENDING)
			rv = (rv > 0) ? -1 : 1;
		
		return rv;
	}
	
	Value view_value_func (int row, int column, Media m) {
		Value val;
		Station s = (Station)m;
		
		if(column == 0)
			val = (int)s.rowid;
		else if(column == 1) {
			if(App.playback.media_active && App.playback.current_media == s)
				val = playing_icon;
			else if(s.unique_status_image != null)
				val = s.unique_status_image;
			else
				val = Value(typeof(GLib.Icon));
		}
		else if(column == 2)
			val = s.name;
		else if(column == 3)
			val = s.genre;
		else if(column == 4)
			val = (int)s.rating;
		else// if(column == 5)
			val = (int)s.pulseProgress;
		
		return val;
	}
}

