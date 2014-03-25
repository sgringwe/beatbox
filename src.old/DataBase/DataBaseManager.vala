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

using SQLHeavy;
using Gee;

public class BeatBox.DataBaseManager : GLib.Object, BeatBox.DatabaseInterface {
	SQLHeavy.Database _db;
	
	LinkedList<DatabaseTransactionFiller> periodic_transactions;
	LinkedList<DatabaseTransactionFiller> transaction_queue;
	Transaction transaction;// the current sql transaction
	
	// App.database represents the default database, but plugins may want to use this
	// file on their own database, so allow for that.
	public DataBaseManager() {
		periodic_transactions = new LinkedList<DatabaseTransactionFiller>();
		transaction_queue = new LinkedList<DatabaseTransactionFiller>();
		
		// First make sure that the folder that the database will be in exists
		var user_database_folder = GLib.File.new_for_path(GLib.Path.build_filename(Environment.get_user_data_dir(), "beatbox"));
		if(!user_database_folder.query_exists()) {
			try {
				user_database_folder.make_directory_with_parents(null);
			}
			catch(GLib.Error err) {
				critical("Could not create beatbox folder in data directory: %s\n", err.message);
			}
		}
		
		// Open the database
		try {
			_db = new VersionedDatabase (GLib.Path.build_filename(user_database_folder.get_path(), "beatbox.db"), Build.SCHEMA_DIR);
		}
		catch (SQLHeavy.Error err) {
			critical("Could not load database: %s", err.message);
		}
		
		// Some settings
        // disable synchronized commits for performance reasons ... this is not vital
        _db.synchronous = SQLHeavy.SynchronousMode.from_string("OFF");
        //_db.sql_executed.connect ((sql) => { stdout.printf("SQL: %s \n", sql); });
        
		// Every 15 seconds, do the periodic saves
		Timeout.add(15000, periodic_save);
	}
	
	public QueryResult execute(string statement) {
		QueryResult? rv = null;
		
		try {
			Query query = new Query(_db, statement);
			rv = query.execute();
		}
		catch (SQLHeavy.Error err) {
			warning("Could not execute statement '%s': %s\n", statement, err.message);
		}
		
		return rv;
	}
	
	// These functions must have mutual exclusion
	// This is the entrance function
	public void queue_transaction(DatabaseTransactionFiller db_filler) {
		if(transaction == null) {
			begin_transaction(db_filler);
		}
		else {
			transaction_queue.offer(db_filler);
		}
	}
	
	// TODO: Thread this
	void begin_transaction(DatabaseTransactionFiller db_filler) {
		try {
			if(db_filler.pre_transaction_execute != null && db_filler.pre_transaction_execute != "") {
				_db.execute(db_filler.pre_transaction_execute);
			}
			
			transaction = _db.begin_transaction();
			db_filler.filler(ref transaction, db_filler);
			transaction.commit();
		} catch(SQLHeavy.Error err) {
			warning("Could not commit transaction: %s \n", err.message);
		}
		
		transaction = null;
		
		if(transaction_queue.size > 0) {
			begin_transaction(transaction_queue.poll());
		}
		else {
			transactions_finished();
		}
	}
	
	void transactions_finished() {
		transaction = null;
	}
	
	public void add_periodic_transaction(DatabaseTransactionFiller periodic_filler) {
		periodic_transactions.add(periodic_filler);
	}
	
	bool periodic_save() {
		debug("Doing periodic save");
		
		foreach(var filler in periodic_transactions) {
			queue_transaction(filler);
		}
		
		return true;
	}
}
