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

public class BeatBox.StationLibrary : BaseLibrary {
	const string LOAD_STATIONS_QUERY = "SELECT rowid,* FROM 'stations'";
	
	Station ref_station = new Station("");
	public override string key { get { return ref_station.key; } }
	public override string name { get { return _("Stations"); } }
	public override File? default_folder { get { return null; } }
	
	File _folder;
	public override File folder { 
		get { 
			return _folder;
		}
		set {
			_folder = value;
		}
	}
	public override bool uses_local_folder { get { return false; } }
	public override Type media_type { get { return typeof(Station); } }
	public override PreferencesSection? preferences_section { get { return null; } }
	
	public StationLibrary() {
		load_from_database();
	}
	
	void load_from_database() {
		message("Loading stations...");
		try {
			var results = App.database.execute(LOAD_STATIONS_QUERY);
			if(results == null) {
				warning("Could not load stations from database");
				return;
			}
			
			for (; !results.finished; results.next() ) {
				Station s = new Station(results.fetch_string(1));
				
				s.rowid = results.fetch_int(0);
				s.file_size = (uint)results.fetch_int(2);
				s.title = results.fetch_string(3);
				s.artist = results.fetch_string(4);
				s.composer = results.fetch_string(5);
				s.album_artist = results.fetch_string(6);
				s.album = results.fetch_string(7);
				s.grouping = results.fetch_string(8);
				s.genre = results.fetch_string(9);
				s.comment = results.fetch_string(10);
				s.lyrics = results.fetch_string(11);
				s.has_embedded = (results.fetch_int(13) == 1);
				s.year = (uint)results.fetch_int(14);
				s.track = (uint)results.fetch_int(15);
				s.track_count = (uint)results.fetch_int(16);
				s.album_number = (uint)results.fetch_int(17);
				s.album_count = (uint)results.fetch_int(18);
				s.bitrate = (uint)results.fetch_int(19);
				s.length = (uint)results.fetch_int(20);
				s.samplerate = (uint)results.fetch_int(21);
				s.rating = (uint)results.fetch_int(22);
				s.play_count = (uint)results.fetch_int(23);
				s.skip_count = (uint)results.fetch_int(24);
				s.date_added = (uint)results.fetch_int(25);
				s.last_played = (uint)results.fetch_int(26);
				s.last_modified = (uint)results.fetch_int(27);
				//s.mediatype = (MediaType)results.fetch_int(28);
				//s.podcast_rss = results.fetch_string(29);
				//s.podcast_url = results.fetch_string(30);
				//s.podcast_date = results.fetch_int(31);
				//s.is_new_podcast = (results.fetch_int(32) == 1) ? true : false;
				//s.resume_pos = results.fetch_int(33);
				s.is_video = (results.fetch_int(34) == 1) ? true : false;
				
				//lock(_medias) {
					App.library.assign_id_to_media(s);
					_medias.set (s.rowid, s);
				//}
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error loading stations: %s", err.message);
		}
	}
	
	public override void add_db_function(Collection<Media> added) {
		DatabaseTransactionFiller db_filler = new DatabaseTransactionFiller();
		db_filler.data = added;
		db_filler.filler = add_to_db_filler;
		
		App.database.queue_transaction(db_filler);
	}
	
	void add_to_db_filler(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler) {
		Collection<Media> added = (Collection<Media>)db_filler.data;
		
		try {
			Query query = transaction.prepare ("""INSERT INTO 'stations' ('rowid', 'uri', 'file_size', 'title', 'artist', 'composer', 'album_artist',
'album', 'grouping', 'genre', 'comment', 'lyrics', 'has_embedded', 'year', 'track', 'track_count', 'album_number', 'album_count',
'bitrate', 'length', 'samplerate', 'rating', 'playcount', 'skipcount', 'dateadded', 'lastplayed', 'lastmodified', 'mediatype', 'podcast_rss',
'podcast_url', 'podcast_date', 'is_new_podcast', 'resume_pos', 'is_video') 
VALUES (:rowid, :uri, :file_size, :title, :artist, :composer, :album_artist, :album, :grouping, 
:genre, :comment, :lyrics, :has_embedded, :year, :track, :track_count, :album_number, :album_count, :bitrate, :length, :samplerate, 
:rating, :playcount, :skipcount, :dateadded, :lastplayed, :lastmodified, :mediatype, :podcast_rss, :podcast_url, :podcast_date, :is_new_podcast,
:resume_pos, :is_video);""");
			
			foreach(Media s in added) {
				if(s.rowid > 0 && !s.isTemporary) {
					query.set_int(":rowid", (int)s.rowid);
					query.set_string(":uri", s.uri);
					query.set_int(":file_size", (int)s.file_size);
					query.set_string(":title", s.title);
					query.set_string(":artist", s.artist);
					query.set_string(":composer", s.composer);
					query.set_string(":album_artist", s.album_artist);
					query.set_string(":album", s.album);
					query.set_string(":grouping", s.grouping);
					query.set_string(":genre", s.genre);
					query.set_string(":comment", s.comment);
					query.set_string(":lyrics", s.lyrics);
					query.set_int(":has_embedded", s.has_embedded ? 1 : 0);
					query.set_int(":year", (int)s.year);
					query.set_int(":track", (int)s.track);
					query.set_int(":track_count", (int)s.track_count);
					query.set_int(":album_number", (int)s.album_number);
					query.set_int(":album_count", (int)s.album_count);
					query.set_int(":bitrate", (int)s.bitrate);
					query.set_int(":length", (int)s.length);
					query.set_int(":samplerate", (int)s.samplerate);
					query.set_int(":rating", (int)s.rating);
					query.set_int(":playcount", (int)s.play_count);
					query.set_int(":skipcount", (int)s.skip_count);
					query.set_int(":dateadded", (int)s.date_added);
					query.set_int(":lastplayed", (int)s.last_played);
					query.set_int(":lastmodified", (int)s.last_modified);
					query.set_int(":mediatype", 0);//s.mediatype);
					query.set_string(":podcast_rss", "");//s.podcast_rss);
					query.set_string(":podcast_url", "");//s.podcast_url);
					query.set_int(":podcast_date", 0);//s.podcast_date);
					query.set_int(":is_new_podcast", s.is_new_podcast ? 1 : 0);
					query.set_int(":resume_pos", s.resume_pos);
					query.set_int(":is_video", s.is_video ? 1 : 0);
					
					query.execute();
				}
			}
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not save stations: %s \n", err.message);
		}
	}
	
	public override void update_db_function(Collection<Media> updates) {
		DatabaseTransactionFiller db_filler = new DatabaseTransactionFiller();
		db_filler.data = updates;
		db_filler.filler = update_in_db_filler;
		
		App.database.queue_transaction(db_filler);
	}
	
	void update_in_db_filler(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler) {
		Collection<Media> updated = (Collection<Media>)db_filler.data; 
		
		try {
			Query query = transaction.prepare("""UPDATE 'stations' SET uri=:uri, file_size=:file_size, title=:title, artist=:artist,
composer=:composer, album_artist=:album_artist, album=:album, grouping=:grouping, genre=:genre, comment=:comment, lyrics=:lyrics, 
has_embedded=:has_embedded, year=:year, track=:track, track_count=:track_count, album_number=:album_number, 
album_count=:album_count,bitrate=:bitrate, length=:length, samplerate=:samplerate, rating=:rating, playcount=:playcount, skipcount=:skipcount, 
dateadded=:dateadded, lastplayed=:lastplayed, lastmodified=:lastmodified, mediatype=:mediatype, podcast_rss=:podcast_rss, podcast_url=:podcast_url,
podcast_date=:podcast_date, is_new_podcast=:is_new_podcast, resume_pos=:resume_pos, is_video=:is_video WHERE rowid=:rowid""");
			
			foreach(Media s in updated) {
				if(s.rowid != -2 && s.rowid > 0) {
					
					query.set_int(":rowid", (int)s.rowid);
					query.set_string(":uri", s.uri);
					query.set_int(":file_size", (int)s.file_size);
					query.set_string(":title", s.title);
					query.set_string(":artist", s.artist);
					query.set_string(":composer", s.composer);
					query.set_string(":album_artist", s.album_artist);
					query.set_string(":album", s.album);
					query.set_string(":grouping", s.grouping);
					query.set_string(":genre", s.genre);
					query.set_string(":comment", s.comment);
					query.set_string(":lyrics", s.lyrics);
					query.set_int(":has_embedded", s.has_embedded ? 1 : 0);
					query.set_int(":year", (int)s.year);
					query.set_int(":track", (int)s.track);
					query.set_int(":track_count", (int)s.track_count);
					query.set_int(":album_number", (int)s.album_number);
					query.set_int(":album_count", (int)s.album_count);
					query.set_int(":bitrate", (int)s.bitrate);
					query.set_int(":length", (int)s.length);
					query.set_int(":samplerate", (int)s.samplerate);
					query.set_int(":rating", (int)s.rating);
					query.set_int(":playcount", (int)s.play_count);
					query.set_int(":skipcount", (int)s.skip_count);
					query.set_int(":dateadded", (int)s.date_added);
					query.set_int(":lastplayed", (int)s.last_played);
					query.set_int(":lastmodified", (int)s.last_modified);
					query.set_int(":mediatype", 0);//s.mediatype);
					query.set_string(":podcast_rss", "");//s.podcast_rss);
					query.set_string(":podcast_url", "");//s.podcast_url);
					query.set_int(":podcast_date", 0);//s.podcast_date);
					query.set_int(":is_new_podcast", s.is_new_podcast ? 1 : 0);
					query.set_int(":resume_pos", s.resume_pos);
					query.set_int(":is_video", s.is_video ? 1 : 0);
					
					query.execute();
				}
			}
		}
		catch(SQLHeavy.Error err) {
			stdout.printf("Could not update stations: %s \n", err.message);
		}
	}
	
	public override void remove_db_function(Collection<Media> removed) {
		DatabaseTransactionFiller db_filler = new DatabaseTransactionFiller();
		db_filler.data = removed;
		db_filler.filler = remove_from_db_filler;
		
		App.database.queue_transaction(db_filler);
	}
	
	void remove_from_db_filler(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler) {
		Collection<Media> removed = (Collection<Media>)db_filler.data; 
		
		try {
			Query query = transaction.prepare("DELETE FROM 'stations' WHERE uri=:uri");
			
			foreach(var s in removed) {
				query.set_string(":uri", s.uri);
				query.execute();
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not remove stations from db: %s\n", err.message);
		}
	}
	
	public override Media import_tags_to_media(Gst.DiscovererInfo info) {
		Station s = new Station(info.get_uri());
		
		return s;
	}
	
	public override Collection<SmartPlaylist> get_default_smart_playlists() {
		return new LinkedList<SmartPlaylist>();
	}
}
