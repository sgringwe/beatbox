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

public class BeatBox.MusicList : GenericList {

	//for header column chooser
	CheckMenuItem columnNumber;
	CheckMenuItem columnTrack;
	CheckMenuItem columnTitle;
	CheckMenuItem columnLength;
	CheckMenuItem columnArtist;
	CheckMenuItem columnAlbum;
	CheckMenuItem columnGenre;
	CheckMenuItem columnYear;
	CheckMenuItem columnBitRate;
	CheckMenuItem columnRating;
	CheckMenuItem columnPlayCount;
	CheckMenuItem columnSkipCount;
	CheckMenuItem columnDateAdded;
	CheckMenuItem columnLastPlayed;
	CheckMenuItem columnBPM;

	//for media list right click
	Gtk.Menu mediaMenuActionMenu;
	Gtk.MenuItem mediaEditMedia;
	Gtk.MenuItem mediaFileBrowse;
	Gtk.MenuItem mediaMenuQueue;
	Gtk.MenuItem mediaMenuNewPlaylist;
	Gtk.MenuItem mediaMenuAddToPlaylist; // make menu on fly
	RatingMenuItem mediaRateMedia;
	Gtk.MenuItem mediaRemove;
	Gtk.MenuItem importToLibrary;
	Gtk.MenuItem mediaScrollToCurrent;

	/**
	 * for sort_id use 0+ for normal, -1 for auto, -2 for none
	 */
	public MusicList(TreeViewSetup tvs) {
		var types = new GLib.List<Type>();
		types.append(typeof(int)); // id
		types.append(typeof(GLib.Icon)); // icon
		types.append(typeof(int)); // #
		types.append(typeof(int)); // track
		types.append(typeof(string)); // title
		types.append(typeof(int)); // length
		types.append(typeof(string)); // artist
		types.append(typeof(string)); // album
		types.append(typeof(string)); // genre
		types.append(typeof(int)); // year
		types.append(typeof(int)); // bitrate
		types.append(typeof(int)); // rating
		types.append(typeof(int)); // plays
		types.append(typeof(int)); // skips
		types.append(typeof(int)); // date added
		types.append(typeof(int)); // last played
		types.append(typeof(int)); // bpm
		types.append(typeof(int)); // pulser};
		base(types, tvs, new Song(""));
		
		//last_search = "";
		//timeout_search = new LinkedList<string>();
		//showing_all = true;
		//removing_medias = false;


		buildUI();
	}

	public override void update_sensitivities() {
		mediaMenuActionMenu.show_all();

		if(get_hint() == TreeViewSetup.Hint.MUSIC) {
			mediaRemove.set_visible(true);
			mediaRemove.set_label(_("Remove from Library"));
			columnNumber.set_active(false);
			columnNumber.set_visible(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == TreeViewSetup.Hint.SIMILAR) {
			mediaRemove.set_visible(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == TreeViewSetup.Hint.QUEUE) {
			mediaRemove.set_visible(true);
			mediaRemove.set_label(_("Remove from Queue"));
			mediaMenuQueue.set_visible(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == TreeViewSetup.Hint.HISTORY) {
			mediaRemove.set_visible(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == TreeViewSetup.Hint.PLAYLIST) {
			mediaRemove.set_visible(true);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == TreeViewSetup.Hint.SMART_PLAYLIST) {
			mediaRemove.set_visible(false);
			importToLibrary.set_visible(false);
		}
		else if(get_hint() == TreeViewSetup.Hint.DEVICE_AUDIO) {
			mediaEditMedia.set_visible(false);
			mediaRemove.set_visible(true);
			mediaRemove.set_label(_("Remove from Device"));
			mediaMenuQueue.set_visible(false);
			importToLibrary.set_visible(true);
			mediaMenuAddToPlaylist.set_visible(false);
			mediaMenuNewPlaylist.set_visible(false);
		}
		else if(get_hint() == TreeViewSetup.Hint.CDROM) {
			mediaEditMedia.set_visible(true);
			mediaRemove.set_visible(false);
			importToLibrary.set_visible(true);
			mediaMenuAddToPlaylist.set_visible(false);
			mediaMenuNewPlaylist.set_visible(false);
		}
		else {
			mediaRemove.set_visible(false);
		}
	}

	public void buildUI() {
		add_columns ();
		
		set_compare_func(view_compare_func);
        set_search_func(view_search_func);
        set_value_func(view_value_func);
        
		button_press_event.connect(viewClick);
		button_release_event.connect(viewClickRelease);

		// column chooser menu
		columnNumber = new CheckMenuItem.with_label(_("#"));
		columnTrack = new CheckMenuItem.with_label(_("Track"));
		columnTitle = new CheckMenuItem.with_label(_("Title"));
		columnLength = new CheckMenuItem.with_label(_("Length"));
		columnArtist = new CheckMenuItem.with_label(_("Artist"));
		columnAlbum = new CheckMenuItem.with_label(_("Album"));
		columnGenre = new CheckMenuItem.with_label(_("Genre"));
		columnYear = new CheckMenuItem.with_label(_("Year"));
		columnBitRate = new CheckMenuItem.with_label(_("Bitrate"));
		columnRating = new CheckMenuItem.with_label(_("Rating"));
		columnPlayCount = new CheckMenuItem.with_label(_("Plays"));
		columnSkipCount = new CheckMenuItem.with_label(_("Skips"));
		columnDateAdded = new CheckMenuItem.with_label(_("Date Added"));
		columnLastPlayed = new CheckMenuItem.with_label(_("Last Played"));
		columnBPM = new CheckMenuItem.with_label(_("BPM"));
		updateColumnVisibilities();
		columnChooserMenu.append(columnNumber);
		columnChooserMenu.append(columnTrack);
		columnChooserMenu.append(columnTitle);
		columnChooserMenu.append(columnLength);
		columnChooserMenu.append(columnArtist);
		columnChooserMenu.append(columnAlbum);
		columnChooserMenu.append(columnGenre);
		columnChooserMenu.append(columnYear);
		columnChooserMenu.append(columnBitRate);
		columnChooserMenu.append(columnRating);
		columnChooserMenu.append(columnPlayCount);
		columnChooserMenu.append(columnSkipCount);
		columnChooserMenu.append(columnDateAdded);
		columnChooserMenu.append(columnLastPlayed);
		columnChooserMenu.append(columnBPM);
		columnNumber.toggled.connect(columnMenuToggled);
		columnTrack.toggled.connect(columnMenuToggled);
		columnTitle.toggled.connect(columnMenuToggled);
		columnLength.toggled.connect(columnMenuToggled);
		columnArtist.toggled.connect(columnMenuToggled);
		columnAlbum.toggled.connect(columnMenuToggled);
		columnGenre.toggled.connect(columnMenuToggled);
		columnYear.toggled.connect(columnMenuToggled);
		columnBitRate.toggled.connect(columnMenuToggled);
		columnRating.toggled.connect(columnMenuToggled);
		columnPlayCount.toggled.connect(columnMenuToggled);
		columnSkipCount.toggled.connect(columnMenuToggled);
		columnDateAdded.toggled.connect(columnMenuToggled);
		columnLastPlayed.toggled.connect(columnMenuToggled);
		columnBPM.toggled.connect(columnMenuToggled);
		columnChooserMenu.show_all();

		//media list right click menu
		mediaMenuActionMenu = new Gtk.Menu();
		mediaEditMedia = new Gtk.MenuItem.with_label(_("Edit Song Info"));
		mediaFileBrowse = new Gtk.MenuItem.with_label(_("Show in File Browser"));
		mediaMenuQueue = new Gtk.MenuItem.with_label(_("Queue"));
		mediaMenuNewPlaylist = new Gtk.MenuItem.with_label(_("New Playlist"));
		mediaMenuAddToPlaylist = new Gtk.MenuItem.with_label(_("Add to Playlist"));
		mediaRemove = new Gtk.MenuItem.with_label(_("Remove Song"));
		importToLibrary = new Gtk.MenuItem.with_label(_("Import to Library"));
		mediaScrollToCurrent = new Gtk.MenuItem.with_label(_("Scroll to Current Song"));
		mediaRateMedia = new RatingMenuItem();
		mediaMenuActionMenu.append(mediaEditMedia);
		mediaMenuActionMenu.append(mediaFileBrowse);
		mediaMenuActionMenu.append(mediaRateMedia);
		mediaMenuActionMenu.append(new SeparatorMenuItem());
		mediaMenuActionMenu.append(mediaMenuQueue);
		mediaMenuActionMenu.append(mediaMenuNewPlaylist);
		mediaMenuActionMenu.append(mediaMenuAddToPlaylist);
		if(tvs.get_hint() != TreeViewSetup.Hint.DEVICE_AUDIO && tvs.get_hint() != TreeViewSetup.Hint.SMART_PLAYLIST) {
			mediaMenuActionMenu.append(new SeparatorMenuItem());
		}
		mediaMenuActionMenu.append(mediaRemove);
		mediaMenuActionMenu.append(importToLibrary);
		if(tvs.get_hint() != TreeViewSetup.Hint.CDROM) {
			mediaMenuActionMenu.append(new SeparatorMenuItem());
			mediaMenuActionMenu.append(mediaScrollToCurrent);
		}
		mediaEditMedia.activate.connect(mediaMenuEditClicked);
		mediaFileBrowse.activate.connect(mediaFileBrowseClicked);
		mediaMenuQueue.activate.connect(mediaMenuQueueClicked);
		mediaMenuNewPlaylist.activate.connect(mediaMenuNewPlaylistClicked);
		mediaRemove.activate.connect(mediaRemoveClicked);
		importToLibrary.activate.connect(importToLibraryClicked);
		mediaRateMedia.activate.connect(mediaRateMediaClicked);
		mediaScrollToCurrent.activate.connect(mediaScrollToCurrentRequested);
		row_activated.connect(row_activated_signal_event);
		
		set_headers_visible(tvs.get_hint() != TreeViewSetup.Hint.ALBUM_LIST &&
							tvs.get_hint() != TreeViewSetup.Hint.NOW_PLAYING);
		
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

	//void cellTitleEdited(string path, string new_text) {
		/*int rowid;
		debug("done!\n");
		if((rowid = list_model.getRowidFromPath(path)) != 0) {
			App.library.media_from_id(rowid).title = new_text;

			App.library.update_media(App.library.media_from_id(rowid), true);
		}
		cellTitle.editable = false; */
	//}

	/*void sortColumnChanged() {
		updateTreeViewSetup();
	}*/

	/*void modelRowsReordered(TreePath path, TreeIter? iter, void* new_order) {
		/*if(TreeViewSetup.Hint == "queue") {
			App.library.clear_queue();

			TreeIter item;
			for(int i = 0; list_model.get_iter_from_string(out item, i.to_string()); ++i) {
				int id;
				list_model.get(item, 0, out id);

				App.library.queue_media_by_id(id);
			}
		}*
		
		// TODO: FIXME
		//if(is_current_view) {
		//	set_as_current_list(0, false);
		//}

		if(!scrolled_recently) {
			scroll_to_current_media(false);
		}
	}*/

	public void updateColumnVisibilities() {
		int index = 0;
		foreach(TreeViewColumn tvc in get_columns()) {
			if(tvc.title == "#")
				columnNumber.active = get_column(index).visible;
			else if(tvc.title == "Track")
				columnTrack.active = get_column(index).visible;
			else if(tvc.title == "Title")
				columnTitle.active = get_column(index).visible;
			else if(tvc.title == "Length")
				columnLength.active = get_column(index).visible;
			else if(tvc.title == "Artist")
				columnArtist.active = get_column(index).visible;
			else if(tvc.title == "Album")
				columnAlbum.active = get_column(index).visible;
			else if(tvc.title == "Genre")
				columnGenre.active = get_column(index).visible;
			else if(tvc.title == "Year")
				columnYear.active = get_column(index).visible;
			else if(tvc.title == "Bitrate")
				columnBitRate.active = get_column(index).visible;
			else if(tvc.title == "Rating")
				columnRating.active = get_column(index).visible;
			else if(tvc.title == "Plays")
				columnPlayCount.active = get_column(index).visible;
			else if(tvc.title == "Skips")
				columnSkipCount.active = get_column(index).visible;
			else if(tvc.title == "Date Added")
				columnDateAdded.active = get_column(index).visible;
			else if(tvc.title == "Last Played")
				columnLastPlayed.active = get_column(index).visible;
			else if(tvc.title == "BPM")
				columnBPM.active = get_column(index).visible;

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
			int temporary_count = 0;
			int total_count = 0;
			foreach(Media m in get_selected_medias()) {
				if(m.isTemporary)
					++temporary_count;

				++total_count;
			}

			if(temporary_count == 0)
				importToLibrary.set_sensitive(false);
			else {
				importToLibrary.set_sensitive(true);
				if(temporary_count != total_count)
					importToLibrary.label = "Import " + temporary_count.to_string() + " of " + total_count.to_string() + " selected " + parent_wrapper.media_representation;
				else
					importToLibrary.label = "Import" + ((temporary_count > 1) ? (" " + temporary_count.to_string() + " " + parent_wrapper.media_representation + "s") : "");
			}
			
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
	
	void row_activated_signal_event(TreePath path, TreeViewColumn column) {
		if(tvs.get_hint() == TreeViewSetup.Hint.QUEUE) {
			Media m = get_selected_medias().nth_data(0);
			App.playback.unqueue_media(m);
		}
	}

	protected override void updateTreeViewSetup() {
		if(tvs == null || get_hint() == TreeViewSetup.Hint.ALBUM_LIST || get_columns().length() != TreeViewSetup.MUSIC_COLUMN_COUNT)
			return;

		int sort_id = MusicColumn.ARTIST;
		SortType sort_dir = Gtk.SortType.ASCENDING;
		get_sort_column_id(out sort_id, out sort_dir);

		if(sort_id < 0)
			sort_id = MusicColumn.ARTIST;
		
		tvs.set_columns(get_columns());
		tvs.sort_column_id = sort_id;
		tvs.sort_direction = sort_dir;
	}

	/** When the column chooser popup menu has a change/toggle **/
	public void columnMenuToggled() {
		int index = 0;
		foreach(TreeViewColumn tvc in get_columns()) {
			if(tvc.title == "Track")
				get_column(index).visible = columnTrack.active;
			else if(tvc.title == "#")
				get_column(index).visible = columnNumber.active;
			else if(tvc.title == "Title")
				get_column(index).visible = columnTitle.active;
			else if(tvc.title == "Length")
				get_column(index).visible = columnLength.active;
			else if(tvc.title == "Artist")
				get_column(index).visible = columnArtist.active;
			else if(tvc.title == "Album")
				get_column(index).visible = columnAlbum.active;
			else if(tvc.title == "Genre")
				get_column(index).visible = columnGenre.active;
			else if(tvc.title == "Year")
				get_column(index).visible = columnYear.active;
			else if(tvc.title == "Bitrate")
				get_column(index).visible = columnBitRate.active;
			else if(tvc.title == "Rating")
				get_column(index).visible = columnRating.active;
			else if(tvc.title == "Plays")
				get_column(index).visible = columnPlayCount.active;
			else if(tvc.title == "Skips")
				get_column(index).visible = columnSkipCount.active;
			else if(tvc.title == "Date Added")
				get_column(index).visible = columnDateAdded.active;
			else if(tvc.title == "Last Played")
				get_column(index).visible = columnLastPlayed.active;//add bpm, file size, file path
			else if(tvc.title == "BPM")
				get_column(index).visible = columnBPM.active;

			++index;
		}
		
		tvs.set_columns(get_columns());
	}
	
	void mediaFileBrowseClicked() {
		foreach(Media m in get_selected_medias()) {
			try {
				var file = File.new_for_uri(m.uri);
				Gtk.show_uri(null, file.get_parent().get_uri(), 0);
			}
			catch(GLib.Error err) {
				debug("Could not browse media %s: %s\n", m.uri, err.message);
			}

			return;
		}
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

		if(get_hint() == TreeViewSetup.Hint.MUSIC) {
			var dialog = new RemoveFilesDialog (toRemove, get_hint());
			dialog.remove_media.connect ( (delete_files) => {
				App.library.remove_medias (toRemove, delete_files);
			});
		}
		else if(get_hint() == TreeViewSetup.Hint.QUEUE) {
			foreach(Media m in toRemove) {
				App.playback.unqueue_media(m);
			}
		}
		else if(get_hint() == TreeViewSetup.Hint.DEVICE_AUDIO) {
			DeviceSourceView dvw = (DeviceSourceView)parent_wrapper;
			((Device)dvw.get_object()).remove_medias(toRemove);
		}
		
		if(get_hint() == TreeViewSetup.Hint.PLAYLIST) {
			BasePlaylist p = (StaticPlaylist)App.playlists.playlist_from_id(relative_id);
			
			((StaticPlaylist)p).remove_medias(toRemove);
			App.playlists.update_playlist(p);
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

	public void apply_style_to_view(CssProvider style) {
		get_style_context().add_provider(style, STYLE_PROVIDER_PRIORITY_APPLICATION);
	}
	
	int view_compare_func (int col, Gtk.SortType dir, Media a_media, Media b_media) {
		int rv = 0;
		
		if(col == MusicColumn.NUMBER) {
			rv = 1;//a.get_position() - b.get_position();
		}
		else if(col == MusicColumn.TRACK) {
			if(a_media.track == b_media.track)
				rv = advanced_string_compare(a_media.uri, b_media.uri);
			else
				rv = (int)((int)a_media.track - (int)b_media.track);
		}
		else if(col == MusicColumn.TITLE) {
			rv = advanced_string_compare(a_media.title.down(), b_media.title.down());
		}
		else if(col == MusicColumn.LENGTH) {
			rv = (int)(a_media.length - b_media.length);
		}
		else if(col == MusicColumn.ARTIST) {
			if(a_media.album_artist.down() == b_media.album_artist.down()) {
				if(a_media.album.down() == b_media.album.down()) {
					if(a_media.album_number == b_media.album_number) {
						if(a_media.track == b_media.track)
							rv = advanced_string_compare(a_media.uri, b_media.uri);
						else
							rv = (int)((sort_direction == SortType.ASCENDING) ? (int)((int)a_media.track - (int)b_media.track) : (int)((int)b_media.track - (int)a_media.track));
					}
					else
						rv = (int)((int)a_media.album_number - (int)b_media.album_number);
				}
				else
					rv = advanced_string_compare(a_media.album.down(), b_media.album.down());
			}
			else
				rv = advanced_string_compare(a_media.album_artist.down(), b_media.album_artist.down());
		}
		else if(col == MusicColumn.ALBUM) {
			if(a_media.album.down() == b_media.album.down()) {
				if(a_media.album_number == b_media.album_number) {
					if(a_media.track == b_media.track)
						rv = advanced_string_compare(a_media.uri, b_media.uri);
					else
						rv = (int)((sort_direction == SortType.ASCENDING) ? (int)((int)a_media.track - (int)b_media.track) : (int)((int)b_media.track - (int)a_media.track));
				}
				else
					rv = (int)((int)a_media.album_number - (int)b_media.album_number);

			}
			else {
				if(a_media.album == "")
					rv = 1;
				else
					rv = advanced_string_compare(a_media.album.down(), b_media.album.down());
			}
		}
		else if(col == MusicColumn.GENRE) {
			rv = advanced_string_compare(a_media.genre.down(), b_media.genre.down());
		}
		else if(col == MusicColumn.YEAR) {
			rv = (int)(a_media.year - b_media.year);
		}
		else if(col == MusicColumn.BITRATE) {
			rv = (int)(a_media.bitrate - b_media.bitrate);
		}
		else if(col == MusicColumn.RATING) {
			rv = (int)(a_media.rating - b_media.rating);
		}
		else if(col == MusicColumn.LAST_PLAYED) {
			rv = (int)(a_media.last_played - b_media.last_played);
		}
		else if(col == MusicColumn.DATE_ADDED) {
			rv = (int)(a_media.date_added - b_media.date_added);
		}
		else if(col == MusicColumn.PLAY_COUNT) {
			rv = (int)(a_media.play_count - b_media.play_count);
		}
		else if(col == MusicColumn.SKIP_COUNT) {
			rv = (int)(a_media.skip_count - b_media.skip_count);
		}
		else if(col == MusicColumn.BPM) {
			rv = (int)(a_media.bpm - b_media.bpm);
		}
		else {
			rv = 0;
		}
		
		//if(rv == 0 && col != MusicColumn.ARTIST && col != MusicColumn.ALBUM)
		//	rv = advanced_string_compare(a_media.uri, b_media.uri);

		if(sort_direction == SortType.DESCENDING)
			rv = (rv > 0) ? -1 : 1;

		return rv;
	}
	
	Value view_value_func (int row, int column, Media s) {
		Value val;
		
		if(column == MusicColumn.ROWID)
			val = s.rowid;
		else if(column == MusicColumn.ICON) {
			if(App.playback.current_media != null && App.playback.current_media == s)
				val = playing_icon;
			else if(tvs.get_hint() == TreeViewSetup.Hint.CDROM && !s.isTemporary)
				val = completed_icon;
			else if(s.unique_status_image != null)
				val = s.unique_status_image;
			else if(s is Podcast && s.last_played == 0)
				val = new_podcast_icon;
			else if(s is Podcast && !s.uri.has_prefix("http://"))
				val = saved_locally_icon;
			else
				val = Value(typeof(GLib.Icon));
		}
		else if(column == MusicColumn.NUMBER)
			val = (int)(row + 1);
		else if(column == MusicColumn.TRACK)
			val = (int)s.track;
		else if(column == MusicColumn.TITLE)
			val = s.title;
		else if(column == MusicColumn.LENGTH)
			val = (int)s.length;
		else if(column == MusicColumn.ARTIST)
			val = s.artist;
		else if(column == MusicColumn.ALBUM)
			val = s.album;
		else if(column == MusicColumn.GENRE)
			val = s.genre;
		else if(column == MusicColumn.YEAR)
			val = (int)s.year;
		else if(column == MusicColumn.BITRATE)
			val = (int)s.bitrate;
		else if(column == MusicColumn.RATING)
			val = (int)s.rating;
		else if(column == MusicColumn.PLAY_COUNT)
			val = (int)s.play_count;
		else if(column == MusicColumn.SKIP_COUNT)
			val = (int)s.skip_count;
		else if(column == MusicColumn.DATE_ADDED)
			val = (int)s.date_added;
		else if(column == MusicColumn.LAST_PLAYED)
			val = (int)s.last_played;
		else if(column == MusicColumn.BPM)
			val = (int)s.bpm;
		else// if(column == 17)
			val = (int)s.pulseProgress;
		
		return val;
	}
}

