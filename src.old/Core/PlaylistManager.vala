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
using SQLHeavy;

public class BeatBox.PlaylistManager : GLib.Object, BeatBox.PlaylistInterface {
	private const string LOAD_SMART_PLAYLISTS_QUERY = "SELECT rowid,* FROM 'smart_playlists'";
	private const string LOAD_STATIC_PLAYLISTS_QUERY = "SELECT rowid,* FROM 'playlists'";
	
	HashMap<int, BasePlaylist> _playlists;
	
	public PlaylistManager() {
		_playlists = new HashMap<int, BasePlaylist>();
	}
	
	public void load_playlists_from_db() {
		message("Loading playlists from database...");
		load_smart_playlists_from_db();
		load_static_playlists_from_db();
	}
	
	void load_smart_playlists_from_db() {
		try {
			var results = App.database.execute(LOAD_SMART_PLAYLISTS_QUERY);
			if(results == null) {
				warning("Could not fetch smart playlists from database");
				return;
			}
			
			for (; !results.finished; results.next() ) {
				SmartPlaylist p = new SmartPlaylist();
				
				p.id = results.fetch_int(0);
				p.name = results.fetch_string(1);
				p.conditional = (SmartPlaylist.Conditional)results.fetch_int(2);
				p.queries_from_string(results.fetch_string(3));
				p.limit = ( results.fetch_int(4) == 1) ? true : false;
				p.limit_amount = results.fetch_int(5);
				
				lock(_playlists) {
					_playlists.set (p.id, p);
				}
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error loading smart playlists: %s", err.message);
		}
	}
	
	void load_static_playlists_from_db() {
		//load all playlists from db
		var playlists_added = new LinkedList<string>();
		
		try {
			var results = App.database.execute(LOAD_STATIC_PLAYLISTS_QUERY);
			if(results == null) {
				warning("Could not fetch static playlists from database");
				return;
			}
			
			for (; !results.finished; results.next() ) {
				StaticPlaylist p = new StaticPlaylist.with_info(results.fetch_int(0), results.fetch_string(1));
				p.medias_from_string(results.fetch_string(2), App.library);
					
				if(!playlists_added.contains(p.name)) {
					lock (_playlists) {
						_playlists.set(p.id, p);
					}
					
					playlists_added.add(p.name);
				}
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error loading playlists: %s", err.message);
		}
	}
	
	public int playlist_count() {
		return _playlists.size;
	}
	
	public Collection<BasePlaylist> playlists() {
		return _playlists.values;
	}
	
	public HashMap<int, BasePlaylist> playlist_hash() {
		return _playlists;
	}
	
	public BasePlaylist playlist_from_id(int id) {
		return _playlists.get(id);
	}
	
	public BasePlaylist? playlist_from_name(string name) {
		BasePlaylist[] cached_playlists;
		BasePlaylist? rv = null;
		
		lock(_playlists) {
			cached_playlists = _playlists.values.to_array();
		}
		
		for(int i = 0; i < cached_playlists.length; ++i) {
			BasePlaylist p = cached_playlists[i];
			if(p.name == name) {
				rv = p;
				break;
			}
		}
		
		return rv;
	}
	
	public int add_playlist(BasePlaylist p) {
		int top_index = 0;
		foreach(int i in _playlists.keys) {
			if(i > top_index)
				top_index = i;
		}
		
		lock (_playlists) {
			p.id = top_index + 1;
			_playlists.set(p.id, p);
		}
		
		playlist_added(p);
		add_db_function(p);
		
		return p.id;
	}
	
	public void update_playlist(BasePlaylist p) {
		playlist_changed(p);
		
		update_db_function(p);
	}
	
	public void remove_playlist(int id) {
		BasePlaylist removed;
		
		lock (_playlists) {
			_playlists.unset(id, out removed);
		}
		
		playlist_removed(removed);
		
		remove_db_function(removed);
	}
	
	/** Add files to library operation **/
	public void add_playlist_to_library(Library library, string playlist_name, LinkedList<File> files) {
		if(!App.operations.doing_ops) {
			PlaylistOperation op = new PlaylistOperation(library, add_playlist_to_library_start_sync, add_playlist_to_library_start_async, 
															add_playlist_to_library_cancel, _("Adding playlist to Library"));
			
			StaticPlaylist p = new StaticPlaylist();
			string extra = "";
			while(App.playlists.playlist_from_name(playlist_name + extra) != null)
				extra += "_";
			p.name = playlist_name + extra;
			
			op.files = files;
			op.playlist = p;
			op.finished_func = add_playlist_to_library_finished;
			App.operations.queue_operation(op);
		}
		else {
			warning("User tried to add files to library while doing operations");
		}
	}
	
	private void add_playlist_to_library_start_sync (Operation op) {
		var playlist_op = ((PlaylistOperation)op);
		App.operations.current_status = _("Importing %s to Library...").printf("<b>" + Markup.escape_text(playlist_op.playlist.name) + "</b>");
	}

	private void add_playlist_to_library_start_async (Operation op) {
		var internals = new LinkedList<Media>();
		var externals = new LinkedList<GLib.File>();
		
		foreach(File f in ((PlaylistOperation)op).files) {
			Media s;
			if( (s = App.library.media_from_file(f.get_uri())) != null)
				internals.add(s);
			else
				externals.add(f);
		}
		
		((PlaylistOperation)op).playlist.add_medias(internals);
		App.files.import_files(externals);
	}
	
	private void add_playlist_to_library_cancel(Operation op) {
		// Cancellation is instant
	}
	
	private void add_playlist_to_library_finished(Operation op) {
		PlaylistOperation playlist_op = (PlaylistOperation)op;
		
		playlist_op.playlist.add_medias(playlist_op.imports);
		App.playlists.add_playlist(playlist_op.playlist);
		
		App.library.medias_imported(playlist_op.library, playlist_op.import_type, playlist_op.imports, playlist_op.failed_imports);
		
		App.library.recheck_files_not_found_async();
	}
	
	/** Database Stuff.
	 * 
	 * Smart playlists and normal playlists are saved differently
	*/
	void add_db_function(BasePlaylist added) {
		DatabaseTransactionFiller db_filler = new DatabaseTransactionFiller();
		db_filler.data = added;
		db_filler.filler = add_to_db_filler;
		
		App.database.queue_transaction(db_filler);
	}
	
	void add_to_db_filler(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler) {
		BasePlaylist added = (BasePlaylist)db_filler.data;
		
		try {
			if(added is StaticPlaylist) {
				StaticPlaylist p = (StaticPlaylist)added;
				
				Query query = transaction.prepare ("INSERT INTO 'playlists' ('rowid', 'name', 'medias') VALUES (:rowid, :name, :medias);");
				query.set_int(":rowid", p.id);
				query.set_string(":name", p.name);
				query.set_string(":medias", p.medias_to_string());
				query.execute();
			}
			else {
				SmartPlaylist p = (SmartPlaylist)added;
				
				Query query = transaction.prepare ("INSERT INTO 'smart_playlists' ('rowid', 'name', 'and_or', 'queries', 'limit_results', 'limit_amount') VALUES (:rowid, :name, :and_or, :queries, :limit_results, :limit_amount);");
				query.set_int(":rowid", p.id);
				query.set_string(":name", p.name);
				query.set_int(":and_or", p.conditional);
				query.set_string(":queries", p.queries_to_string());
				query.set_int(":limit_results", ( p.limit ) ? 1 : 0);
				query.set_int(":limit_amount", p.limit_amount);
				query.execute();
			}
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not add playlist: %s \n", err.message);
		}
	}
	
	void update_db_function(BasePlaylist updates) {
		DatabaseTransactionFiller db_filler = new DatabaseTransactionFiller();
		db_filler.data = updates;
		db_filler.filler = update_in_db_filler;
		
		App.database.queue_transaction(db_filler);
	}
	
	void update_in_db_filler(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler) {
		BasePlaylist updated = (BasePlaylist)db_filler.data; 
		
		try {
			if(updated is StaticPlaylist) {
				StaticPlaylist p = (StaticPlaylist)updated;
				
				Query query = transaction.prepare("UPDATE 'playlists' SET name=:name, medias=:medias WHERE rowid=:rowid");
				query.set_int(":rowid", p.id);
				query.set_string(":name", p.name);
				query.set_string(":medias", p.medias_to_string());
				message("setting playlist %d %s to have %s", p.id, p.name, p.medias_to_string());
				query.execute();
			}
			else {
				SmartPlaylist p = (SmartPlaylist)updated;
				
				Query query = transaction.prepare("UPDATE 'smart_playlists' SET name=:name, and_or=:and_or, queries=:queries, limit_results=:limit_results, limit_amount=:limit_amount WHERE rowid=:rowid");
				query.set_int(":rowid", p.id);
				query.set_string(":name", p.name);
				query.set_int(":and_or", p.conditional);
				query.set_string(":queries", p.queries_to_string());
				query.set_int(":limit_results", ( p.limit ) ? 1 : 0);
				query.set_int(":limit_amount", p.limit_amount);
				query.execute();
			}
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not update playlist: %s \n", err.message);
		}
	}
	
	void remove_db_function(BasePlaylist removed) {
		DatabaseTransactionFiller db_filler = new DatabaseTransactionFiller();
		db_filler.data = removed;
		db_filler.filler = remove_from_db_filler;
		
		App.database.queue_transaction(db_filler);
	}
	
	void remove_from_db_filler(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler) {
		BasePlaylist removed = (BasePlaylist)db_filler.data; 
		
		try {
			if(removed is StaticPlaylist) {
				Query query = transaction.prepare("DELETE FROM 'playlists' WHERE rowid=:rowid");
				query.set_int(":rowid", removed.id);
				query.execute();
			}
			else {
				Query query = transaction.prepare("DELETE FROM 'smart_playlists' WHERE rowid=:rowid");
				query.set_int(":rowid", removed.id);
				query.execute();
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not remove songs from db: %s\n", err.message);
		}
	}
}
