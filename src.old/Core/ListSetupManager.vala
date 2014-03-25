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

public class BeatBox.ListSetupManager : GLib.Object, ListSetupInterface {
	HashMap<string, TreeViewSetup> setups;
	
	public ListSetupManager() {
		setups = new HashMap<string, TreeViewSetup>();
		
		// Initialize some critical setups. They will be overwritten if data exists
		add_setup(MUSIC_KEY, new TreeViewSetup(MusicColumn.ARTIST, Gtk.SortType.ASCENDING, TreeViewSetup.Hint.MUSIC));
		add_setup(PODCAST_KEY, new TreeViewSetup(PodcastColumn.ARTIST, Gtk.SortType.ASCENDING, TreeViewSetup.Hint.PODCAST));
		add_setup(STATION_KEY, new TreeViewSetup(RadioColumn.GENRE, Gtk.SortType.ASCENDING, TreeViewSetup.Hint.STATION));
		add_setup(SIMILAR_KEY, new TreeViewSetup(MusicColumn.NUMBER, Gtk.SortType.ASCENDING, TreeViewSetup.Hint.SIMILAR));
		add_setup(QUEUE_KEY, new TreeViewSetup(MusicColumn.NUMBER, Gtk.SortType.ASCENDING, TreeViewSetup.Hint.QUEUE));
		add_setup(HISTORY_KEY, new TreeViewSetup(MusicColumn.NUMBER, Gtk.SortType.ASCENDING, TreeViewSetup.Hint.HISTORY));
		
		load_setups();
		
		// setup periodic saves of device prefereneces
		DatabaseTransactionFiller setups_filler = new DatabaseTransactionFiller();
		setups_filler.filler = periodic_setups_filler;
		setups_filler.pre_transaction_execute = "DELETE FROM 'list_setups'";
		App.database.add_periodic_transaction(setups_filler);
	}
	
	// If there is already a setup there, we can't overwrite it or we
	// will end up with random lists having random setups
	public bool add_setup(string key, TreeViewSetup setup) {
		if(setups.get(key) != null) {
			warning("Invalid attempt to add a second setup with key %s.", key);
			return false;
		}
		
		setups.set(key, setup);
		
		return true;
	}
	
	public TreeViewSetup? get_setup(string key) {
		return setups.get(key);
	}
	
	public bool remove_setup(string key) {
		return setups.unset(key);
	}
	
	// DB STUFF
	void load_setups() {
		try {
			var results = App.database.execute("SELECT rowid,* FROM 'list_setups'");
			if(results == null) {
				warning("Could not load list setups from database");
				return;
			}
			
			for (; !results.finished; results.next() ) {
				string key = results.fetch_string(1);
				int hint_int = results.fetch_int(2);
				int sort_column_id = results.fetch_int(3);
				
				TreeViewSetup setup = new TreeViewSetup(sort_column_id, Gtk.SortType.ASCENDING, (TreeViewSetup.Hint)hint_int);
				
				setup.set_sort_direction_from_string(results.fetch_string(4));
				setup.import_columns(results.fetch_string(5));
				
				lock(setups) {
					setups.set (key, setup);
				}
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error loading list setups: %s", err.message);
		}
	}
	
	void periodic_setups_filler(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler) {
		try {
			SQLHeavy.Query query = transaction.prepare ("INSERT INTO 'list_setups' ('key', 'hint', 'sort_column_id', 'sort_direction', 'columns') VALUES (:key, :hint, :sort_column_id, :sort_direction, :columns);");
			
			foreach(var entry in setups.entries) {
				query.set_string(":key", entry.key);
				query.set_int(":hint", (int)entry.value.get_hint());
				query.set_int(":sort_column_id", entry.value.sort_column_id);
				query.set_string(":sort_direction", entry.value.sort_direction_to_string());
				query.set_string(":columns", entry.value.columns_to_string());
				
				query.execute();
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error saving list setups: %s", err.message);
		}
	}
}
