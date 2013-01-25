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
 */

using Gtk;

public enum Store.TrackListType {
	TOP_TRACKS,
	ARTIST_TRACKS,
	ALBUM_TRACKS
}

public enum TrackListColumn {
	ID,
	ICON,
	NUMBER,
	TRACK,
	TITLE,
	ARTIST,
	ALBUM,
	GENRE,
	YEAR,
	BITRATE,
	LENGTH,
	PRICE,
	PULSER
}

public class Store.TrackList : BeatBox.FastList {
	Store.StoreView storeView;
	TrackListType type;
	int alreadyResized;
	
	protected BeatBox.CellDataFunctionHelper cellHelper;
	protected GLib.Icon playing_icon;
	
	BeatBox.Media? being_buffered;
	
	public signal void stream_requested(Track track);
	public signal void purchase_requested(Track track);
	
	public TrackList(Store.StoreView view, TrackListType type) {
		var types = new GLib.List<Type>();
		types.append(typeof(int)); // id
		types.append(typeof(GLib.Icon)); // icon
		types.append(typeof(int)); // #
		types.append(typeof(int)); // track
		types.append(typeof(string)); // title
		types.append(typeof(string)); // artist
		types.append(typeof(string)); // album
		types.append(typeof(string)); // genre
		types.append(typeof(int)); // year
		types.append(typeof(int)); // bitrate
		types.append(typeof(int)); // length
		types.append(typeof(string)); // price
		types.append(typeof(int)); // pulser};
		base(types, new Store.Track(0));
		
		storeView = view;
		this.type = type;
		alreadyResized = 0;
		
		buildUI();
		
		set_compare_func(view_compare_func);
        set_search_func(view_search_func);
        set_value_func(view_value_func);
	}
	
	public void buildUI() {
		//set_headers_clickable(true);
		set_headers_visible(false);
		set_fixed_height_mode(true);
		set_rules_hint(true);
		set_reorderable(false);
		
		cellHelper = new BeatBox.CellDataFunctionHelper(this, false, TrackListColumn.ICON, null, null);
		
		playing_icon = BeatBox.App.icons.MEDIA_PLAY_SYMBOLIC.get_gicon ();
		
		insert_column_with_attributes(-1, "id", new CellRendererText()); //0
		insert_column_with_data_func(-1, " ", new CellRendererPixbuf(), cellHelper.iconDataFunc); //1
		insert_column_with_data_func(-1, "#", new CellRendererText(), cellHelper.intelligentTreeViewFiller); //2
		insert_column_with_data_func(-1, "#", new CellRendererText(), cellHelper.intelligentTreeViewFiller); //3 //Track and # column is never mixed so we can have same title
		insert_column_with_data_func(-1, "Title", new CellRendererText(), cellHelper.stringTreeViewFiller); //4
		insert_column_with_data_func(-1, "Artist", new CellRendererText(), cellHelper.stringTreeViewFiller); //5
		insert_column_with_data_func(-1, "Album", new CellRendererText(), cellHelper.stringTreeViewFiller); //6
		insert_column_with_data_func(-1, "Genre", new CellRendererText(), cellHelper.stringTreeViewFiller); //7
		insert_column_with_data_func(-1, "Year", new CellRendererText(), cellHelper.intelligentTreeViewFiller); //8
		insert_column_with_data_func(-1, "Bitrate", new CellRendererText(), cellHelper.intelligentTreeViewFiller); //9
		insert_column_with_data_func(-1, "Length", new CellRendererText(), cellHelper.lengthTreeViewFiller); //10
		insert_column_with_data_func(-1, "Price", new CellRendererText(), cellHelper.priceTreeViewFiller); //11
		insert_column_with_attributes(-1, "Pulser", new CellRendererText()); //12
		
		get_column(TrackListColumn.ICON).fixed_width = BeatBox.TreeViewSetup.ICON_WIDTH;
		get_column(TrackListColumn.NUMBER).fixed_width = BeatBox.TreeViewSetup.NUMBER_WIDTH;
		get_column(TrackListColumn.TRACK).fixed_width = BeatBox.TreeViewSetup.NUMBER_WIDTH;
		get_column(TrackListColumn.TITLE).fixed_width = BeatBox.TreeViewSetup.TITLE_WIDTH;
		get_column(TrackListColumn.ARTIST).fixed_width = BeatBox.TreeViewSetup.ARTIST_WIDTH;
		get_column(TrackListColumn.ALBUM).fixed_width = BeatBox.TreeViewSetup.ALBUM_WIDTH;
		get_column(TrackListColumn.GENRE).fixed_width = BeatBox.TreeViewSetup.GENRE_WIDTH;
		get_column(TrackListColumn.YEAR).fixed_width = BeatBox.TreeViewSetup.YEAR_WIDTH;
		get_column(TrackListColumn.BITRATE).fixed_width = BeatBox.TreeViewSetup.BITRATE_WIDTH;
		get_column(TrackListColumn.LENGTH).fixed_width = BeatBox.TreeViewSetup.LENGTH_WIDTH - 10;
		get_column(TrackListColumn.PRICE).fixed_width = BeatBox.TreeViewSetup.YEAR_WIDTH + 10;
		
		get_column(TrackListColumn.ID).visible = false;
		get_column(TrackListColumn.ICON).visible = true;
		get_column(TrackListColumn.NUMBER).visible = false;
		get_column(TrackListColumn.TRACK).visible = false;
		get_column(TrackListColumn.TITLE).visible = true;
		get_column(TrackListColumn.ARTIST).visible = true;
		get_column(TrackListColumn.ALBUM).visible = false;
		get_column(TrackListColumn.GENRE).visible = false;
		get_column(TrackListColumn.YEAR).visible = false;
		get_column(TrackListColumn.BITRATE).visible = false;
		get_column(TrackListColumn.LENGTH).visible = true;
		get_column(TrackListColumn.PRICE).visible = false;
		get_column(TrackListColumn.PULSER).visible = false;
		
		// initialize columns
		int index = 0;
		foreach(var tvc in get_columns()) {
			if(tvc.title == " ") {
				tvc.clear();
				
				CellRendererPixbuf crpix = new CellRendererPixbuf();
				tvc.pack_start(crpix, true);
				CellRendererSpinner crspin = new CellRendererSpinner();
				tvc.pack_start(crspin, true);
				
				tvc.set_attributes(crpix, "gicon", index);
				tvc.set_attributes(crspin, "pulse", get_columns().length() - 1);
				crspin.active = true;
				
				tvc.set_cell_data_func(tvc.get_cells().nth_data(0), cellHelper.iconDataFunc);
				tvc.set_cell_data_func(tvc.get_cells().nth_data(1), cellHelper.iconDataFunc);
			}
			
			if(tvc.title == "Title") {
				tvc.sizing = Gtk.TreeViewColumnSizing.AUTOSIZE;
				tvc.expand = true;
			}
			else {
				tvc.sizing = Gtk.TreeViewColumnSizing.FIXED;
			}
			
			tvc.resizable = false;
			tvc.reorderable = false;
			tvc.clickable = true;
			tvc.sort_column_id = (int)index;
			tvc.set_sort_indicator(false);
			
			++index;
		}
		
		if(type == TrackListType.ALBUM_TRACKS) {
			get_column(TrackListColumn.ARTIST).visible = false;
			get_column(TrackListColumn.PRICE).visible = true;
			set_sort_column_id(TrackListColumn.TRACK , Gtk.SortType.ASCENDING);
		}
		else if(type == TrackListType.ARTIST_TRACKS) {
			get_column(TrackListColumn.ARTIST).visible = false;
			set_sort_column_id(TrackListColumn.NUMBER , Gtk.SortType.ASCENDING);
		}
		else if(type == TrackListType.TOP_TRACKS) {
			set_sort_column_id(TrackListColumn.NUMBER , Gtk.SortType.ASCENDING);
		}
		
		button_press_event.connect(view_click);
		row_activated.connect(row_activated_signal);
		
		show_all();
		
		BeatBox.App.playback.media_played.connect(media_played);
	}
	
	void media_played(BeatBox.Media m, BeatBox.Media? old) {
		if(being_buffered != null) {
			being_buffered.showIndicator = false;
			being_buffered = null;
			queue_draw();
		}
	}
	
	bool view_click(Gdk.EventButton event) {
		if(event.type == Gdk.EventType.BUTTON_PRESS && event.button == 1) {
			stdout.printf("Track list clicked\n");
		}
		
		return false;
	}
	
	 void row_activated_signal(TreePath path, TreeViewColumn column) {
		BeatBox.Media m = get_selected_medias().nth_data(0);
		var track = (Store.Track)m;
		
		// Show the spinner to denote that the track is buffering
		m.showIndicator = true;
		get_column(TrackListColumn.ICON).visible = false; // this shows spinner for some reason
		get_column(TrackListColumn.ICON).visible = true; // this shows spinner for some reason
		queue_draw();
		
		// this spins the spinner for the current media being imported
		being_buffered = m;
		Timeout.add(100, pulser);
		
		// Start thread to load and play track
		try {
			new Thread<void*>.try (null, take_action);
		}
		catch (Error err) {
			warning ("Could not create thread to have fun: %s", err.message);
		}
	}
	
	bool pulser() {
		if(being_buffered == null) {
			return false;
		}
		else {
			being_buffered.pulseProgress++;
			
			queue_draw();
			
			return true;
		}
	}
	
	public void* take_action () {
		BeatBox.Media m = get_selected_medias().nth_data(0);
		if(m == null)
			return null;
			
		m.uri = ((Store.Track)m).getPreviewLink();
		message("preview link is %s", m.uri);
		
		Idle.add( () => {
			BeatBox.App.playback.play_media(m, false);
			if(!BeatBox.App.playback.playing)
				BeatBox.App.playback.play();
			return false;
		});
		
		return null;
	}
	
	Value view_value_func (int row, int column, BeatBox.Media s) {
		Value val;
		
		if(column == TrackListColumn.ID)
			val = s.rowid;
		else if(column == TrackListColumn.ICON) {
			if(BeatBox.App.playback.current_media != null && BeatBox.App.playback.current_media == s)
				val = playing_icon;
			else if(s.unique_status_image != null)
				val = s.unique_status_image;
			else
				val = Value(typeof(GLib.Icon));
		}
		else if(column == TrackListColumn.NUMBER)
			val = (int)(row + 1);
		else if(column == TrackListColumn.TRACK)
			val = (int)s.track;
		else if(column == TrackListColumn.TITLE)
			val = s.title;
		else if(column == TrackListColumn.ARTIST)
			val = s.artist;
		else if(column == TrackListColumn.ALBUM)
			val = s.album;
		else if(column == TrackListColumn.GENRE)
			val = s.genre;
		else if(column == TrackListColumn.YEAR)
			val = (int)s.year;
		else if(column == TrackListColumn.BITRATE)
			val = (int)s.bitrate;
		else if(column == TrackListColumn.LENGTH)
			val = (int)s.length;
		else if(column == TrackListColumn.PRICE) {
			Store.Track track = (Store.Track)s;
			val = track.price.formattedPrice;
		}
		else
			val = (int)s.pulseProgress;
		
		return val;
	}
	
	/** **************************************************
	 * View search. All lists use same search algorithm 
	 * *************************************************/
	protected void view_search_func (string search, HashTable<int, BeatBox.Media> table, ref HashTable<int, BeatBox.Media> show) {
		int show_index = 0;
		for(int i = 0; i < table.size(); ++i) {
			BeatBox.Media m = table.get(i);
			show.set(show_index++, m);
		}
		
		/*for(int i = 0; i < table.size(); ++i) {
			Media m = table.get(i);
			
			if(search in m.artist.down() || search in m.album_artist.down() ||
			search in m.album.down() || search in m.title.down() ||
			search in m.genre.down()) {
				if(parent_wrapper != null) {
					if((m.album_artist.down() == parent_wrapper.artist_filter.down() || parent_wrapper.artist_filter == "") &&
					(m.album.down() == parent_wrapper.album_filter.down() || parent_wrapper.album_filter == "") &&
					(m.genre.down() == parent_wrapper.genre_filter.down() || parent_wrapper.genre_filter == "")) {
						show.set(show_index++, table.get(i));
					}
				}
				else {
					show.set(show_index++, table.get(i));
				}
			}
		}*/
	}
	
	int view_compare_func (int col, Gtk.SortType dir, BeatBox.Media a_media, BeatBox.Media b_media) {
		int rv = 0;
		
		if(col == TrackListColumn.NUMBER) {
			Store.Track a_track = (Store.Track)a_media;
			Store.Track b_track = (Store.Track)b_media;
			
			rv = a_track.search_rank - b_track.search_rank;
		}
		else if(col == TrackListColumn.TRACK) {
			if(a_media.track == b_media.track)
				rv = advanced_string_compare(a_media.uri, b_media.uri);
			else
				rv = (int)((int)a_media.track - (int)b_media.track);
		}
		else if(col == TrackListColumn.TITLE) {
			rv = advanced_string_compare(a_media.title.down(), b_media.title.down());
		}
		else if(col == TrackListColumn.LENGTH) {
			rv = (int)(a_media.length - b_media.length);
		}
		else if(col == TrackListColumn.ARTIST) {
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
		else if(col == TrackListColumn.ALBUM) {
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
		else if(col == TrackListColumn.GENRE) {
			rv = advanced_string_compare(a_media.genre.down(), b_media.genre.down());
		}
		else if(col == TrackListColumn.YEAR) {
			rv = (int)(a_media.year - b_media.year);
		}
		else if(col == TrackListColumn.BITRATE) {
			rv = (int)(a_media.bitrate - b_media.bitrate);
		}
		// price
		else {
			rv = 0;
		}
		
		//if(rv == 0 && col != TrackListColumn.ARTIST && col != TrackListColumn.ALBUM)
		//	rv = advanced_string_compare(a_media.uri, b_media.uri);

		if(sort_direction == SortType.DESCENDING)
			rv = (rv > 0) ? -1 : 1;

		return rv;
	}
	
	/************************************************
	 * Used by all views to sort list
	 * ******************************************/
	protected int advanced_string_compare(string a, string b) {
		if(a == "" && b != "")
			return 1;
		else if(a != "" && b == "")
			return -1;
		else if(a == b)
			return 0;
		
		return (a > b) ? 1 : -1;
	}
}
