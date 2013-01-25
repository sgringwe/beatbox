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

public class BeatBox.TreeViewSetup : GLib.Object {
	
	// TODO: Fixme. I am a duplicate of DuplicateList.CHECKBOX_COLUMN_TITLE
	// for core dependency reasons
	public static const string CHECKBOX_COLUMN_TITLE = "";
	
	public static const int MUSIC_COLUMN_COUNT = 19;
	public static const int DUPLICATE_COLUMN_COUNT = 19;
	public static const int PODCAST_COLUMN_COUNT = 12;
	public static const int RADIO_COLUMN_COUNT = 6;
	
	public static const int ID_WIDTH = 10;
	public static const int ICON_WIDTH = 24;
	public static const int NUMBER_WIDTH = 40;
	public static const int TRACK_WIDTH = 60;
	public static const int TITLE_WIDTH = 220;
	public static const int ALBUM_VIEW_TITLE_WIDTH = 300;
	public static const int LENGTH_WIDTH = 75;
	public static const int ARTIST_WIDTH = 170;
	public static const int ALBUM_WIDTH = 200;
	public static const int GENRE_WIDTH = 100;
	public static const int YEAR_WIDTH = 50;
	public static const int BITRATE_WIDTH = 85;
	public static const int RATING_WIDTH = 90;
	public static const int PLAYS_WIDTH = 65;
	public static const int SKIPS_WIDTH = 65;
	public static const int DATE_ADDED_WIDTH = 130;
	public static const int LAST_PLAYED_WIDTH = 130;
	public static const int BPM_WIDTH = 50;
	public static const int PULSER_WIDTH = 40;
	public static const int COMMENT_WIDTH = 70;
	public static const int STATION_WIDTH = 300;
	
	public enum Hint {
		MUSIC,
		PODCAST,
		AUDIOBOOK,
		STATION,
		SIMILAR,
		QUEUE,
		HISTORY,
		PLAYLIST,
		SMART_PLAYLIST,
		CDROM,
		DEVICE_AUDIO,
		DEVICE_PODCAST,
		DEVICE_AUDIOBOOK,
		ALBUM_LIST,
		DUPLICATES,
		NOW_PLAYING,
		FILES_NOT_FOUND;
	}
	
	Hint hint;
	public int sort_column_id; // Index of sort column
	public Gtk.SortType sort_direction; // ASCENDING, DESCENDING
	GLib.List<TreeViewColumn> _columns;
	
	public TreeViewSetup(int sort_col, SortType sort_dir, Hint hint) {
		this.hint = hint;
		sort_column_id = sort_col;
		sort_direction = sort_dir;
		
		create_default_columns ();
	}
	
	public Hint get_hint() {
		return hint;
	}
	
	public void set_hint(Hint hint) {
		this.hint = hint;
		if(!is_valid_setup())
			create_default_columns ();
	}
	
	// TODO: Translate these column names. This requires removing string
	// comparisions to find what column it is throughout. 
	// TODO: Make nice add_new_column(string title, bool visible, int fixed_width) func
	// TODO: Use const int values
	void create_default_columns () {
		_columns = new GLib.List<TreeViewColumn>();
		
		/* initial column state */
		if(hint == TreeViewSetup.Hint.PODCAST || hint == TreeViewSetup.Hint.DEVICE_PODCAST) {
			add_new_column("id", ID_WIDTH, false);
			add_new_column(" ", ICON_WIDTH, true);
			add_new_column("Episode", TRACK_WIDTH, false);
			add_new_column("Name", TITLE_WIDTH, true);
			add_new_column("Length", LENGTH_WIDTH, true);
			add_new_column("Artist", ARTIST_WIDTH, true);
			add_new_column("Podcast", ALBUM_WIDTH, true);
			add_new_column("Date", LAST_PLAYED_WIDTH, true);
			add_new_column("Category", GENRE_WIDTH, false);
			add_new_column("Comment", COMMENT_WIDTH, true);
			add_new_column("Rating", RATING_WIDTH, false);
			add_new_column("Pulser", PULSER_WIDTH, false);
		}
		else if(hint == TreeViewSetup.Hint.AUDIOBOOK || hint == TreeViewSetup.Hint.DEVICE_AUDIOBOOK) {
			
		}
		else if(hint == TreeViewSetup.Hint.STATION) {
			add_new_column("id", ID_WIDTH, false);
			add_new_column(" ", ICON_WIDTH, true);
			add_new_column("Station", STATION_WIDTH, true);
			add_new_column("Genre", GENRE_WIDTH, true);
			add_new_column("Rating", RATING_WIDTH, true);
			add_new_column("Pulser", PULSER_WIDTH, false);
		}
		else if(hint == TreeViewSetup.Hint.ALBUM_LIST) { // same as normal music list, but most are hidden
			add_new_column("id", ID_WIDTH, false);
			add_new_column(" ", ICON_WIDTH, true);
			add_new_column("#", NUMBER_WIDTH, (hint == TreeViewSetup.Hint.QUEUE || hint == TreeViewSetup.Hint.HISTORY || hint == TreeViewSetup.Hint.PLAYLIST));
			add_new_column("Track", TRACK_WIDTH, false);
			add_new_column("Title", ALBUM_VIEW_TITLE_WIDTH, true);
			add_new_column("Length", LENGTH_WIDTH, true);
			add_new_column("Artist", ARTIST_WIDTH, false);
			add_new_column("Album", ALBUM_WIDTH, false);
			add_new_column("Genre", GENRE_WIDTH, false);
			add_new_column("Year", YEAR_WIDTH, false);
			add_new_column("Bitrate", BITRATE_WIDTH, false);
			add_new_column("Rating", RATING_WIDTH, false);
			add_new_column("Plays", PLAYS_WIDTH, false);
			add_new_column("Skips", SKIPS_WIDTH, false);
			add_new_column("Date Added", DATE_ADDED_WIDTH, false);
			add_new_column("Last Played", LAST_PLAYED_WIDTH, false);
			add_new_column("BPM", BPM_WIDTH, false);
			add_new_column("Pulser", PULSER_WIDTH, false);
		}
		else if(hint == TreeViewSetup.Hint.NOW_PLAYING) { // same as normal music list, but most are hidden and is not very wide
			add_new_column("id", ID_WIDTH, false);
			add_new_column(" ", ICON_WIDTH, true);
			add_new_column("#", NUMBER_WIDTH, (hint == TreeViewSetup.Hint.QUEUE || hint == TreeViewSetup.Hint.HISTORY || hint == TreeViewSetup.Hint.PLAYLIST));
			add_new_column("Track", TRACK_WIDTH, true);
			add_new_column("Title", TITLE_WIDTH, true);
			add_new_column("Length", LENGTH_WIDTH, true);
			add_new_column("Artist", ARTIST_WIDTH, false);
			add_new_column("Album", ALBUM_WIDTH, false);
			add_new_column("Genre", GENRE_WIDTH, false);
			add_new_column("Year", YEAR_WIDTH, false);
			add_new_column("Bitrate", BITRATE_WIDTH, false);
			add_new_column("Rating", RATING_WIDTH, false);
			add_new_column("Plays", PLAYS_WIDTH, false);
			add_new_column("Skips", SKIPS_WIDTH, false);
			add_new_column("Date Added", DATE_ADDED_WIDTH, false);
			add_new_column("Last Played", LAST_PLAYED_WIDTH, false);
			add_new_column("BPM", BPM_WIDTH, false);
			add_new_column("Pulser", PULSER_WIDTH, false);
		}
		else if(hint == TreeViewSetup.Hint.DUPLICATES) {
			add_new_column("id", ID_WIDTH, false);
			add_new_column(CHECKBOX_COLUMN_TITLE, 30, true);
			add_new_column(" ", ICON_WIDTH, true);
			add_new_column("#", NUMBER_WIDTH, false);
			add_new_column("Track", TRACK_WIDTH, false);
			add_new_column("Title", TITLE_WIDTH, true);
			add_new_column("Length", LENGTH_WIDTH, true);
			add_new_column("Artist", ARTIST_WIDTH, true);
			add_new_column("Album", ALBUM_WIDTH, true);
			add_new_column("Genre", GENRE_WIDTH, false);
			add_new_column("Year", YEAR_WIDTH, false);
			add_new_column("Bitrate", BITRATE_WIDTH, true);
			add_new_column("Rating", RATING_WIDTH, false);
			add_new_column("Plays", PLAYS_WIDTH, false);
			add_new_column("Skips", SKIPS_WIDTH, false);
			add_new_column("Date Added", DATE_ADDED_WIDTH, false);
			add_new_column("Last Played", LAST_PLAYED_WIDTH, false);
			add_new_column("BPM", BPM_WIDTH, false);
			add_new_column("Pulser", PULSER_WIDTH, false);
		}
		else {
			add_new_column("id", ID_WIDTH, false);
			add_new_column(" ", ICON_WIDTH, true);
			add_new_column("#", NUMBER_WIDTH, (hint == TreeViewSetup.Hint.QUEUE || hint == TreeViewSetup.Hint.HISTORY || hint == TreeViewSetup.Hint.PLAYLIST));
			add_new_column("Track", TRACK_WIDTH, false);
			add_new_column("Title", TITLE_WIDTH, true);
			add_new_column("Length", LENGTH_WIDTH, true);
			add_new_column("Artist", ARTIST_WIDTH, true);
			add_new_column("Album", ALBUM_WIDTH, true);
			add_new_column("Genre", GENRE_WIDTH, true);
			add_new_column("Year", YEAR_WIDTH, false);
			add_new_column("Bitrate", BITRATE_WIDTH, false);
			add_new_column("Rating", RATING_WIDTH, false);
			add_new_column("Plays", PLAYS_WIDTH, false);
			add_new_column("Skips", SKIPS_WIDTH, false);
			add_new_column("Date Added", DATE_ADDED_WIDTH, false);
			add_new_column("Last Played", LAST_PLAYED_WIDTH, false);
			add_new_column("BPM", BPM_WIDTH, false);
			add_new_column("Pulser", PULSER_WIDTH, false);
		}
		
		for(uint index = 0; index < _columns.length(); ++index) {
			TreeViewColumn tvc = _columns.nth_data(index);
			
			if(tvc.title != " " && tvc.title != "Rating"/* && tvc.title != DuplicateList.CHECKBOX_COLUMN_TITLE*/) {
				CellRendererText crtext = new CellRendererText();
				tvc.pack_start(crtext, true);
				tvc.set_attributes(crtext, "text", index);
			}
			else if(tvc.title == " ") {
				CellRendererPixbuf crpix = new CellRendererPixbuf();
				tvc.pack_start(crpix, true);
				CellRendererSpinner crspin = new CellRendererSpinner();
				tvc.pack_start(crspin, true);
				
				tvc.set_attributes(crpix, "gicon", index);
				
				tvc.set_attributes(crspin, "pulse", _columns.length() - 1);
				crspin.active = true;
				
			}
			else {
				CellRendererPixbuf crpix = new CellRendererPixbuf();
				tvc.pack_start(crpix, true);
				tvc.set_attributes(crpix, "pixbuf", index);
			}
				
			
			tvc.resizable = true;
			tvc.reorderable = true;
			tvc.clickable = true;
			tvc.sort_column_id = (int)index;
			tvc.set_sort_indicator(false);
			tvc.sizing = Gtk.TreeViewColumnSizing.FIXED;
		}
	}
	
	void add_new_column(string title, int width, bool visible) {
		var col = new TreeViewColumn();
		
		col.set_title(title);
		col.set_fixed_width(width);
		col.set_visible(visible);
		
		_columns.append(col);
	}
	
	public void set_column_visible(int index, bool val) {
		_columns.nth_data(index).visible = val;
	}
	
	public string sort_direction_to_string() {
		if(sort_direction == SortType.ASCENDING)
			return "ASCENDING";
		else
			return "DESCENDING";
	}
	
	public void set_sort_direction_from_string(string dir) {
		if(dir == "ASCENDING")
			sort_direction = SortType.ASCENDING;
		else
			sort_direction = SortType.DESCENDING;
	}
	
	public GLib.List<TreeViewColumn> get_columns() {
		var rv = new GLib.List<TreeViewColumn>();
		foreach(var tvc in _columns)
			rv.append(tvc);
			
		return rv;
	}
	
	public void set_columns(GLib.List<TreeViewColumn> cols) {
		_columns = new GLib.List<TreeViewColumn>();
		foreach(var tvc in cols)
			_columns.append(tvc);
	}
	
	public void import_columns(string cols) {
		string[] col_strings = cols.split("<column_seperator>", 0);
		_columns = new GLib.List<TreeViewColumn>();
		
		int index;
		for(index = 0; index < col_strings.length - 1; ++index) { /* the '-1' because col_strings has blank column at end */
			string[] pieces_of_column = col_strings[index].split("<value_seperator>", 0);
			
			TreeViewColumn tvc;
			if(pieces_of_column[0] != " " && pieces_of_column[0] != "Rating")
				tvc = new Gtk.TreeViewColumn.with_attributes(pieces_of_column[0], new Gtk.CellRendererText(), "text", index, null);
			else if(pieces_of_column[0] == " ") {
				tvc = new TreeViewColumn();
				tvc.set_title(" ");
				tvc.set_fixed_width(24);
				tvc.set_visible(true);
				
				CellRendererPixbuf crpix = new CellRendererPixbuf();
				tvc.pack_start(crpix, true);
				CellRendererSpinner crSpin = new CellRendererSpinner();
				tvc.pack_start(crSpin, true);
				
				tvc.set_attributes(crpix, "gicon", index);
				tvc.set_attributes(crSpin, "pulse", col_strings.length - 2); // -2 because col_strings has blank column at end
				crSpin.active = true;
			}
			else {
				tvc = new Gtk.TreeViewColumn.with_attributes(pieces_of_column[0], new Gtk.CellRendererPixbuf(), "pixbuf", index, null);
			}
			
			tvc.resizable = true;
			tvc.reorderable = true;
			tvc.clickable = true;
			tvc.sort_column_id = index;
			tvc.set_sort_indicator(false);
			tvc.sizing = Gtk.TreeViewColumnSizing.FIXED;
			
			tvc.fixed_width = int.parse(pieces_of_column[1]);
			tvc.visible = (int.parse(pieces_of_column[2]) == 1);
			
			_columns.append(tvc);
		}
		
		/*if(!is_valid_setup ()) {
			warning("Invalid treeview setup found. Creating a new one!\n");
			create_default_columns ();
		}*/
		
	}
	
	public bool is_valid_setup() {
		bool rv = true;
		if(hint == TreeViewSetup.Hint.PODCAST || hint == TreeViewSetup.Hint.DEVICE_PODCAST) {
			if(_columns.length() != PODCAST_COLUMN_COUNT) {
				rv = false;
			}
		}
		/*else if((hint == TreeViewSetup.Hint.AUDIOBOOK || hint == TreeViewSetup.Hint.DEVICE_AUDIOBOOK) && 
		_columns.length() != AUDIOBOOK_) {
			return false;
		}*/
		else if(hint == TreeViewSetup.Hint.STATION) {
			if(_columns.length() != RADIO_COLUMN_COUNT) {
				rv = false;
			}
		}
		else if(_columns.length() != MUSIC_COLUMN_COUNT) {
			rv = false;
		}
		
		if(!rv) {
			warning("Invalid treeview setup found. Creating a new one!%u %d %d\n", _columns.length(), PODCAST_COLUMN_COUNT, RADIO_COLUMN_COUNT);
			create_default_columns ();
			return false;
		}
		
		return true;
	}
	
	public string columns_to_string() {
		string rv = "";
		
		// Find the last column that is visible. This column will use a sane
		// default width, since gtk treeview likes to make it super wide
		// which results in horizontal scrolling
		var default_columns = new TreeViewSetup(sort_column_id, sort_direction, hint).get_columns();
		string last_visible_column = "NO_MATCH";
		int default_width_for_last_visible = 70; // 70 is a sane default width
		for(int i = (int)_columns.length() - 1; i >= 0; --i) {
			var default_tvc = default_columns.nth_data(i);
			
			if(_columns.nth_data(i).visible) {
				last_visible_column = default_tvc.title;
				default_width_for_last_visible = default_tvc.fixed_width;
				break;
			}
		}
		
		foreach(TreeViewColumn tvc in _columns) {
			int width_to_use = tvc.width;
			
			if(tvc.title == last_visible_column) {
				width_to_use = default_width_for_last_visible;
			}
			else if(width_to_use < 10) {
				width_to_use = tvc.fixed_width;
			}
			
			rv += tvc.title + "<value_seperator>" + width_to_use.to_string() + "<value_seperator>" + ( (tvc.visible) ? "1" : "0" ) + "<column_seperator>";
		}
		
		return rv;
	}
	
	// TODO: FIXME from sort_column to sort_column_id
	public GPod.PlaylistSortOrder get_gpod_sortorder() {
		warning("FIXME");
		/*if(sort_column == "#")
			return GPod.PlaylistSortOrder.MANUAL;
		else if(sort_column == "Track" || sort_column == "Episode")
			return GPod.PlaylistSortOrder.TRACK_NR;
		else if(sort_column == "Title" || sort_column == "Name")
			return GPod.PlaylistSortOrder.TITLE;
		else if(sort_column == "Length")
			return GPod.PlaylistSortOrder.TIME;
		else if(sort_column == "Artist")
			return GPod.PlaylistSortOrder.ARTIST;
		else if(sort_column == "Album")
			return GPod.PlaylistSortOrder.ALBUM;
		else if(sort_column == "Genre")
			return GPod.PlaylistSortOrder.GENRE;
		else if(sort_column == "Bitrate")
			return GPod.PlaylistSortOrder.BITRATE;
		else if(sort_column == "Year")
			return GPod.PlaylistSortOrder.YEAR;
		else if(sort_column == "Date")
			return GPod.PlaylistSortOrder.RELEASE_DATE;
		else if(sort_column == "Date Added")
			return GPod.PlaylistSortOrder.TIME_ADDED;
		else if(sort_column == "Plays")
			return GPod.PlaylistSortOrder.PLAYCOUNT;
		else if(sort_column == "Last Played")
			return GPod.PlaylistSortOrder.TIME_PLAYED;
		else if(sort_column == "BPM")
			return GPod.PlaylistSortOrder.BPM;
		else if(sort_column == "Rating")
			return GPod.PlaylistSortOrder.RATING;
		else if(sort_column == "Comments")
			return GPod.PlaylistSortOrder.DESCRIPTION;
		else*/
			return GPod.PlaylistSortOrder.MANUAL;
	}
}
