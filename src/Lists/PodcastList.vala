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

public class BeatBox.PodcastList : GenericList {
    
    
	public TreeViewSetup podcast_setup { set; get; }

	//for header column chooser
	CheckMenuItem columnEpisode; // episode
	CheckMenuItem columnName; // name
	CheckMenuItem columnLength;
	CheckMenuItem columnArtist;
	CheckMenuItem columnPodcast;
	CheckMenuItem columnDate;
	CheckMenuItem columnRating;
	CheckMenuItem columnComments;
	CheckMenuItem columnCategory;

	//for media list right click
	Gtk.Menu mediaMenuActionMenu;
	Gtk.MenuItem mediaEditMedia;
	Gtk.MenuItem mediaFileBrowse;
	Gtk.MenuItem mediaMenuQueue;
	Gtk.MenuItem mediaMenuNewPlaylist;
	Gtk.MenuItem mediaMenuAddToPlaylist; // make menu on fly
	RatingMenuItem mediaRateMedia;
	Gtk.MenuItem mediaRemove;
	Gtk.MenuItem mediaSaveLocally;
	Gtk.MenuItem importToLibrary;

	public PodcastList(TreeViewSetup tvs) {
		var types = new GLib.List<Type>();
		types.append(typeof(int)); // id
		types.append(typeof(GLib.Icon)); // icon
		types.append(typeof(int)); // episode (track)
		types.append(typeof(string)); // name (title)
		types.append(typeof(int)); // length
		types.append(typeof(string)); // artist
		types.append(typeof(string)); // album
		types.append(typeof(int)); // date
		types.append(typeof(string)); // category (genre)
		types.append(typeof(string)); // comment
		types.append(typeof(int)); // rating
		types.append(typeof(int)); // pulser
		base(types, tvs, new Podcast(""));
		
		//last_search = "";
		//timeout_search = new LinkedList<string>();
		//showing_all = true;
		//removing_medias = false;

		buildUI();
	}

	public override void update_sensitivities() {
		mediaMenuActionMenu.show_all();

		if(get_hint() == TreeViewSetup.Hint.PODCAST) {
			mediaRemove.set_visible(true);
			mediaRemove.set_label(_("Remove from Library"));
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == TreeViewSetup.Hint.DEVICE_PODCAST) {
			mediaRemove.set_visible(false);
			mediaRemove.set_label("TODO: Remove from device");
			importToLibrary.set_visible(true);
			mediaSaveLocally.set_visible(false);
			mediaMenuAddToPlaylist.set_visible(false);
			mediaMenuNewPlaylist.set_visible(false);
		}
		else {
			mediaRemove.set_visible(false);
		}
	}

    public void buildUI() {
		add_columns();
		
		set_compare_func(view_compare_func);
        set_search_func(view_search_func);
        set_value_func(view_value_func);

		button_press_event.connect(viewClick);
		button_release_event.connect(viewClickRelease);

		// column chooser menu
		columnEpisode = new CheckMenuItem.with_label("Episode");
		columnName = new CheckMenuItem.with_label("Name");
		columnLength = new CheckMenuItem.with_label("Length");
		columnArtist = new CheckMenuItem.with_label("Artist");
		columnPodcast = new CheckMenuItem.with_label("Podcast");
		columnDate = new CheckMenuItem.with_label("Date");
		columnRating = new CheckMenuItem.with_label("Rating");
		columnComments = new CheckMenuItem.with_label("Comment");
		columnCategory = new CheckMenuItem.with_label("Category");
		updateColumnVisibilities();
		columnChooserMenu.append(columnEpisode);
		columnChooserMenu.append(columnName);
		columnChooserMenu.append(columnLength);
		columnChooserMenu.append(columnArtist);
		columnChooserMenu.append(columnPodcast);
		columnChooserMenu.append(columnDate);
		columnChooserMenu.append(columnCategory);
		columnChooserMenu.append(columnComments);
		columnChooserMenu.append(columnRating);
		columnEpisode.toggled.connect(columnMenuToggled);
		columnName.toggled.connect(columnMenuToggled);
		columnLength.toggled.connect(columnMenuToggled);
		columnArtist.toggled.connect(columnMenuToggled);
		columnPodcast.toggled.connect(columnMenuToggled);
		columnDate.toggled.connect(columnMenuToggled);
		columnComments.toggled.connect(columnMenuToggled);
		columnCategory.toggled.connect(columnMenuToggled);
		columnRating.toggled.connect(columnMenuToggled);
		columnChooserMenu.show_all();


		//media list right click menu
		mediaMenuActionMenu = new Gtk.Menu();
		mediaEditMedia = new Gtk.MenuItem.with_label(_("Edit Podcast"));
		mediaFileBrowse = new Gtk.MenuItem.with_label(_("Show in File Browser"));
		mediaMenuQueue = new Gtk.MenuItem.with_label(_("Queue"));
		mediaMenuNewPlaylist = new Gtk.MenuItem.with_label(_("New Playlist"));
		mediaMenuAddToPlaylist = new Gtk.MenuItem.with_label(_("Add to Playlist"));
		mediaRemove = new Gtk.MenuItem.with_label(_("Remove Episode"));
		mediaSaveLocally = new Gtk.MenuItem.with_label(_("Download"));
		importToLibrary = new Gtk.MenuItem.with_label(_("Import to Library"));
		mediaRateMedia = new RatingMenuItem();
		mediaMenuActionMenu.append(mediaEditMedia);
		mediaMenuActionMenu.append(mediaFileBrowse);
		mediaMenuActionMenu.append(mediaSaveLocally);

		mediaMenuActionMenu.append(mediaRateMedia);

		mediaMenuActionMenu.append(new SeparatorMenuItem());
		mediaMenuActionMenu.append(mediaMenuQueue);
		mediaMenuActionMenu.append(mediaMenuNewPlaylist);
		mediaMenuActionMenu.append(mediaMenuAddToPlaylist);
		mediaMenuActionMenu.append(new SeparatorMenuItem());
		mediaMenuActionMenu.append(mediaRemove);
		mediaMenuActionMenu.append(importToLibrary);
		mediaEditMedia.activate.connect(mediaMenuEditClicked);
		mediaFileBrowse.activate.connect(mediaFileBrowseClicked);
		mediaSaveLocally.activate.connect(mediaSaveLocallyClicked);
		mediaMenuQueue.activate.connect(mediaMenuQueueClicked);
		mediaMenuNewPlaylist.activate.connect(mediaMenuNewPlaylistClicked);
		mediaRemove.activate.connect(mediaRemoveClicked);
		importToLibrary.activate.connect(importToLibraryClicked);
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
			if(tvc.title == "Episode")
				columnEpisode.active = get_column(index).visible;
			else if(tvc.title == "Name")
				columnName.active = get_column(index).visible;
			else if(tvc.title == "Length")
				columnLength.active = get_column(index).visible;
			else if(tvc.title == "Artist")
				columnArtist.active = get_column(index).visible;
			else if(tvc.title == "Podcast")
				columnPodcast.active = get_column(index).visible;
			else if(tvc.title == "Date")
				columnDate.active = get_column(index).visible;
			else if(tvc.title == "Rating")
				columnRating.active = get_column(index).visible;
			else if(tvc.title == "Comment")
				columnComments.active = get_column(index).visible;
			else if(tvc.title == "Category")
				columnCategory.active = get_column(index).visible;

			++index;
		}
	}

	/* button_press_event */
	bool viewClick(Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) { //right click
			/* create add to playlist menu */
			Gtk.Menu addToPlaylistMenu = new Gtk.Menu();
			foreach(BasePlaylist p in App.playlists.playlists()) {
				if(p is StaticPlaylist) {
					StaticPlaylist static_p = (StaticPlaylist)p;
					
					Gtk.MenuItem playlist = new Gtk.MenuItem.with_label(p.name);
					addToPlaylistMenu.append(playlist);

					playlist.activate.connect( () => {
						var to_add = new LinkedList<Media>();
						
						foreach(Media m in get_selected_medias()) {
							to_add.add(m);
						}
						static_p.add_medias(to_add);
						
						App.playlists.update_playlist(p);
					});
				}
			}

			addToPlaylistMenu.show_all();
			mediaMenuAddToPlaylist.submenu = addToPlaylistMenu;

			if(App.playlists.playlists().size == 0)
				mediaMenuAddToPlaylist.set_sensitive(false);
			else
				mediaMenuAddToPlaylist.set_sensitive(true);

			// if all medias are downloaded already, desensitize.
			// if half and half, change text to 'Download %external of %total'
			int external_count = 0;
			int temporary_count = 0;
			int total_count = 0;
			string podcast_folder = App.library.podcast_library.folder.get_uri();
			
			foreach(Media m in get_selected_medias()) {
				if(!m.uri.has_prefix(podcast_folder))
					++external_count;
				if(m.isTemporary)
					++temporary_count;

				++total_count;
			}

			if(external_count == 0)
				mediaSaveLocally.set_sensitive(false);
			else {
				mediaSaveLocally.set_sensitive(true);
				if(external_count != total_count)
					mediaSaveLocally.label = "Download " + external_count.to_string() + " of " + total_count.to_string() + " selected episodes";
				else
					mediaSaveLocally.label = "Download" + ((external_count > 1) ? (" " + external_count.to_string() + " episodes") : "");
			}

			if(temporary_count == 0)
				importToLibrary.set_sensitive(false);
			else {
				importToLibrary.set_sensitive(true);
				if(temporary_count != total_count)
					importToLibrary.label = "Import " + temporary_count.to_string() + " of " + total_count.to_string() + " selected episodes";
				else
					importToLibrary.label = "Import" + ((temporary_count > 1) ? (" " + temporary_count.to_string() + " episodes") : "");
			}

			//mediaMenuActionMenu.show_all();

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
			mediaEditMedia.label = _("Edit %s").printf(type.to_string(total_count));
			
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
		if(tvs == null || get_columns().length() != TreeViewSetup.PODCAST_COLUMN_COUNT)
			return;

		int sort_id = PodcastColumn.ARTIST;
		SortType sort_dir = Gtk.SortType.ASCENDING;
		get_sort_column_id(out sort_id, out sort_dir);

		if(sort_id < 0)
			sort_id = PodcastColumn.ARTIST;

		tvs.set_columns(get_columns());
		tvs.sort_column_id = sort_id;
		tvs.sort_direction = sort_dir;
	}

	/** When the column chooser popup menu has a change/toggle **/
	 void columnMenuToggled() {
		int index = 0;
		foreach(TreeViewColumn tvc in get_columns()) {
			if(tvc.title == "Episode")
				get_column(index).visible = columnEpisode.active;
			else if(tvc.title == "Name")
				get_column(index).visible = columnName.active;
			else if(tvc.title == "Length")
				get_column(index).visible = columnLength.active;
			else if(tvc.title == "Artist")
				get_column(index).visible = columnArtist.active;
			else if(tvc.title == "Podcast")
				get_column(index).visible = columnPodcast.active;
			else if(tvc.title == "Date")
				get_column(index).visible = columnDate.active;
			else if(tvc.title == "Rating")
				get_column(index).visible = columnRating.active;
			else if(tvc.title == "Comment")
				get_column(index).visible = columnComments.active;
			else if(tvc.title == "Category")
				get_column(index).visible = columnCategory.active;

			++index;
		}

		tvs.set_columns(get_columns());
	}

	 void mediaFileBrowseClicked() {
		int count = 0;
		foreach(Media m in get_selected_medias()) {
			try {
				var file = File.new_for_uri(m.uri);
				Gtk.show_uri(null, file.get_parent().get_uri(), 0);
			}
			catch(GLib.Error err) {
				debug("Could not browse media %s: %s\n", m.uri, err.message);
			}

			if(count > 10) {
				App.window.doAlert(_("Stopping File Browse"), _("Too many medias have already been opened in File Browser. Stopping any more openings."));
				return;
			}
		}
	}

	void mediaSaveLocallyClicked() {
		var toSave = new LinkedList<Media>();
		
		foreach(Media m in get_selected_medias()) {
			toSave.add(m);
		}
		
		App.podcasts.download_podcasts(toSave);
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

	 void mediaMenuNewPlaylistClicked() {
		StaticPlaylist p = new StaticPlaylist();
		
		var to_add = new LinkedList<Media>();
		foreach(Media m in get_selected_medias()) {
			to_add.add(m);
		}
		p.add_medias(to_add);
		
		PlaylistNameWindow pnw = new PlaylistNameWindow(p);
		pnw.playlist_saved.connect( (newP) => {
			App.playlists.add_playlist(p);
		});
	}

	 void mediaRemoveClicked() {
		LinkedList<Media> toRemove = new LinkedList<Media>();

		foreach(Media m in get_selected_medias()) {
			toRemove.add(m);
		}

		if(get_hint() == TreeViewSetup.Hint.PODCAST) {
			var dialog = new RemoveFilesDialog (toRemove, get_hint());

			dialog.remove_media.connect ( (delete_files) => {
				App.library.remove_medias (toRemove, delete_files);
			});
		}
	}

	void importToLibraryClicked() {
		var to_import = new LinkedList<Media>();
		
		foreach(Media m in get_selected_medias()) {
			to_import.add(m);
		}

		import_requested(to_import);
	}

	 void onDragDataGet(Gdk.DragContext context, Gtk.SelectionData selection_data, uint info, uint time_) {
		string[] uris = null;

		foreach(Media m in get_selected_medias()) {
			debug("adding %s\n", m.uri);
			uris += (m.uri);
		}

		if (uris != null)
			selection_data.set_uris(uris);
	}
	
	int view_compare_func (int col, Gtk.SortType dir, Media a_media, Media b_media) {
		int rv = 0;
		
		Podcast a = (Podcast)a_media;
		Podcast b = (Podcast)b_media;
		
		if(col == PodcastColumn.EPISODE) {
			if(a.episode == b.episode)
				rv = advanced_string_compare(a_media.uri, b_media.uri);
			else
				rv = (int)((int)a.episode - (int)b.episode);
		}
		else if(col == PodcastColumn.NAME) {
			rv = advanced_string_compare(a_media.title.down(), b_media.title.down());
		}
		else if(col == PodcastColumn.LENGTH) {
			rv = (int)(a_media.length - b_media.length);
		}
		else if(col == PodcastColumn.ARTIST) {
			if(a_media.artist.down() == b_media.artist.down()) {
				if(a.date_released == b.date_released) {
					rv = advanced_string_compare(a_media.uri, b_media.uri);
				}
				else {
					rv = (int)(b.date_released - a.date_released);
				}
			}
			else
				rv = advanced_string_compare(a_media.artist.down(), b_media.artist.down());
		}
		else if(col == PodcastColumn.PODCAST) {
			if(a_media.album.down() == b_media.album.down()) {
				if(a_media.artist.down() == b_media.artist.down()) {
					if(a.date_released == b.date_released) {
						rv = advanced_string_compare(a_media.uri, b_media.uri);
					}
					else {
						rv = (int)(b.date_released - a.date_released);
					}
				}
				else
					rv = advanced_string_compare(a_media.artist.down(), b_media.artist.down());
			}
			else
				rv = advanced_string_compare(a_media.album.down(), b_media.album.down());
		}
		else if(col == PodcastColumn.DATE) {
			rv = (int)(a.date_released - b.date_released);
		}
		else if(col == PodcastColumn.CATEGORY) {
			rv = advanced_string_compare(a_media.genre.down(), b_media.genre.down());
		}
		else if(col == PodcastColumn.RATING) {
			rv = (int)(a_media.rating - b_media.rating);
		}
		else {
			rv = 0;
		}
		
		if(rv == 0 && col != PodcastColumn.ARTIST && col != PodcastColumn.PODCAST)
			rv = advanced_string_compare(a_media.uri, b_media.uri);
		
		if(sort_direction == SortType.DESCENDING)
			rv = (rv > 0) ? -1 : 1;
		
		return rv;
	}
	
	Value view_value_func (int row, int column, Media s) {
		Value val;
		
		Podcast p = (Podcast)s;
		
		if(column == PodcastColumn.ROWID)
			val = (int)s.rowid;
		else if(column == PodcastColumn.ICON) {
			if(App.playback.media_active && App.playback.current_media == s)
				val = playing_icon;
			else if(s.unique_status_image != null) {
				val = s.unique_status_image;
			}
			else if(s.last_played == 0)
				val = new_podcast_icon;
			else if(!s.uri.has_prefix("http://")) {
				val = saved_locally_icon;
			}
			else {
				val = Value(typeof(GLib.Icon));
			}
		}
		else if(column == PodcastColumn.EPISODE)
			val = (int)p.episode;
		else if(column == PodcastColumn.NAME)
			val = s.title;
		else if(column == PodcastColumn.LENGTH)
			val = (int)s.length;
		else if(column == PodcastColumn.ARTIST)
			val = s.artist;
		else if(column == PodcastColumn.PODCAST)
			val = s.album;
		else if(column == PodcastColumn.DATE)
			val = (int)p.date_released;
		else if(column == PodcastColumn.CATEGORY)
			val = s.genre; // category
		else if(column == PodcastColumn.COMMENT)
			val = s.comment;
		else if(column == PodcastColumn.RATING)
			val = (int)s.rating;
		else
			val = (int)s.pulseProgress;
		
		return val;
	}
}

