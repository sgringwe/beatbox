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

public class BeatBox.PodcastLibrary : BaseLibrary {
	const string LOAD_PODCASTS_QUERY = "SELECT rowid,* FROM 'podcasts'";
	
	Podcast ref_podcast = new Podcast("");
	public override string key { get { return ref_podcast.key; } }
	public override string name { get { return _("Podcasts"); } }
	
	File _default_folder;
	public override File? default_folder { 
		get { return _default_folder; }
	}
	
	File _folder;
	public override File folder { 
		get { 
			return _folder;
		}
		set {
			App.settings.main.podcast_folder = value.get_path();
			_folder = value;
		}
	}
	public override bool uses_local_folder { get { return true; } }
	public override Type media_type { get { return typeof(Podcast); } }
	
	PreferencesSection section;
	public override PreferencesSection? preferences_section { 
		get {
			section = new PodcastPreferences();
			return section;
		}
	}
	
	public PodcastLibrary() {
		_default_folder = File.new_for_path(Path.build_path("/", Environment.get_home_dir(), "Podcasts"));
		_folder = File.new_for_path(App.settings.main.podcast_folder);
		
		load_from_database();
	}
	
	void load_from_database() {
		message("Loading podcasts...");
		try {
			var results = App.database.execute(LOAD_PODCASTS_QUERY);
			if(results == null) {
				warning("Could not load podcasts from database");
				return;
			}
			
			for (; !results.finished; results.next() ) {
				Podcast p = new Podcast(results.fetch_string(1));
				
				p.rowid = results.fetch_int(0);
				p.file_size = (uint)results.fetch_int(2);
				p.title = results.fetch_string(3);
				p.artist = results.fetch_string(4);
				p.composer = results.fetch_string(5);
				p.album_artist = results.fetch_string(6);
				p.album = results.fetch_string(7);
				p.grouping = results.fetch_string(8);
				p.genre = results.fetch_string(9);
				p.comment = results.fetch_string(10);
				p.lyrics = results.fetch_string(11);
				p.has_embedded = (results.fetch_int(13) == 1);
				p.year = (uint)results.fetch_int(14);
				p.track = (uint)results.fetch_int(15);
				p.track_count = (uint)results.fetch_int(16);
				p.album_number = (uint)results.fetch_int(17);
				p.album_count = (uint)results.fetch_int(18);
				p.bitrate = (uint)results.fetch_int(19);
				p.length = (uint)results.fetch_int(20);
				p.samplerate = (uint)results.fetch_int(21);
				p.rating = (uint)results.fetch_int(22);
				p.play_count = (uint)results.fetch_int(23);
				p.skip_count = (uint)results.fetch_int(24);
				p.date_added = (uint)results.fetch_int(25);
				p.last_played = (uint)results.fetch_int(26);
				p.last_modified = (uint)results.fetch_int(27);
				//p.mediatype = (MediaType)results.fetch_int(28);
				//p.podcast_rss = results.fetch_string(29);
				//p.podcast_url = results.fetch_string(30);
				//p.podcast_date = results.fetch_int(31);
				//p.is_new_podcast = (results.fetch_int(32) == 1) ? true : false;
				//p.resume_pos = results.fetch_int(33);
				p.is_video = (results.fetch_int(34) == 1) ? true : false;
				
				//lock(_medias) {
					App.library.assign_id_to_media(p);
					_medias.set (p.rowid, p);
				//}
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error loading podcasts: %s", err.message);
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
			Query query = transaction.prepare ("""INSERT INTO 'podcasts' ('rowid', 'uri', 'file_size', 'title', 'artist', 'composer', 'album_artist',
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
			stdout.printf("Could not save podcasts: %s \n", err.message);
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
			Query query = transaction.prepare("""UPDATE 'podcasts' SET uri=:uri, file_size=:file_size, title=:title, artist=:artist,
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
			stdout.printf("Could not update podcasts: %s \n", err.message);
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
			Query query = transaction.prepare("DELETE FROM 'podcasts' WHERE uri=:uri");
			
			foreach(var s in removed) {
				query.set_string(":uri", s.uri);
				query.execute();
			}
		}
		catch (SQLHeavy.Error err) {
			stdout.printf("Could not remove podcasts from db: %s\n", err.message);
		}
	}
	
	public override Media import_tags_to_media(Gst.DiscovererInfo info) {
		Podcast p = new Podcast(info.get_uri());
		
		try {
			string title = "";
			string artist, composer, album_artist, album, grouping, genre, comment, lyrics;
			uint track, track_count, album_number, album_count, bitrate, rating;
			double bpm;
			GLib.Date? date = GLib.Date();
			
			// get title, artist, album artist, album, genre, comment, lyrics strings
			if(info.get_tags().get_string(Gst.TAG_TITLE, out title))
				p.title = title;
			if(info.get_tags().get_string(Gst.TAG_ARTIST, out artist))
				p.artist = artist;
			
			if(info.get_tags().get_string(Gst.TAG_ALBUM, out album))
				p.album = album;
			if(info.get_tags().get_string(Gst.TAG_GENRE, out genre))
				p.genre = genre;
			if(info.get_tags().get_string(Gst.TAG_COMMENT, out comment))
				p.comment = comment;
			
			
			if(info.get_tags().get_uint(Gst.TAG_USER_RATING, out rating))
				p.rating = (int)((rating > 0 && rating <= 5) ? rating : 0);
			
			p.length = get_length(p.uri);
			
			// load embedded art
			if(p.artist == null || p.artist == "") p.artist = "Unknown Artist";
			if(p.album == null)	p.album = "";
			
			import_art(info, p);
			
			p.date_added = (int)time_t();
			
			// get the size
			p.file_size = (int)(File.new_for_uri(info.get_uri()).query_info("*", FileQueryInfoFlags.NONE).get_size());
			
		}
		catch (GLib.Error e) {
			warning ("GStreamerTagger error: %s", e.message);
		}
		finally {
			if(p.title == null || p.title == "") {
				string[] paths = info.get_uri().split("/", 0);
				p.title = paths[paths.length - 1];
			}
			if(p.artist == null || p.artist == "") p.artist = "Unknown Artist";
			if(p.album == null) p.album = "";
			
			/*if(p.genre.down().contains("podcast") || p.length > 9000) {// OVER 9000!!!!! aka 15 minutes
				p.mediatype = MediaType.PODCAST;
				if(info.get_video_streams().length() > 0)
					p.is_video = true;
			}*/
		}
		
		return p;
	}
	
	void import_art(Gst.DiscovererInfo info, Media s) {
		if(App.covers.get_album_art_from_key(s.album_artist, s.album) != null) {
			debug("not loading embedded art since album already has art (%s)\n", s.album);
			return;
		}
		
		if(info != null && info.get_tags() != null) {
			try {
				Gst.Buffer buf = null;
				Gdk.Pixbuf? rv = null;
				int i;
				
				// choose the best image based on image type
				for(i = 0; ; ++i) {
					Gst.Buffer buffer;
					Gst.Value? value = null;
					string media_type;
					Gst.Structure caps_struct;
					int imgtype;
					
					value = info.get_tags().get_value_index(Gst.TAG_IMAGE, i);
					if(value == null)
						break;
					
					buffer = value.get_buffer();
					if (buffer == null) {
						//stdout.printf("apparently couldn't get image buffer\n");
						continue;
					}
					
					caps_struct = buffer.caps.get_structure(0);
					media_type = caps_struct.get_name();
					if (media_type == "text/uri-list") {
						//stdout.printf("ignoring text/uri-list image tag\n");
						continue;
					}
					
					caps_struct.get_enum ("image-type", typeof(Gst.TagImageType), out imgtype);
					if (imgtype == Gst.TagImageType.UNDEFINED) {
						if (buf == null) {
							buf = buffer;
						}
					} else if (imgtype == Gst.TagImageType.FRONT_COVER) {
						buf = buffer;
						break;
					} else if(buf == null) {
						buf = buffer;
					}
				}
				
				if(buf == null) {
					debug("Could not find emedded art for %s\n", info.get_uri());
					return;
				}
				
				// now that we have the buffer we want, load it into the pixbuf
				Gdk.PixbufLoader loader = new Gdk.PixbufLoader();
				try {
					if (!loader.write(buf.data)) {
						debug("Pixbuf loader doesn't like the data");
						loader.close();
						return;
					}
				}
				catch(GLib.Error err) {
					loader.close();
					return;
				}
				
				try {
					loader.close();
				}
				catch(GLib.Error err) {}
				
				rv = loader.get_pixbuf();
                
                App.covers.save_album_art_in_cache(s, rv);
                App.covers.set_album_art(s, rv, false);
                
				debug("Loaded embedded art from %s\n", info.get_uri());
			}
			catch(GLib.Error err) {
				warning("Failed to import album art from %s\n", info.get_uri());
			}
		}
	}
	
	uint get_length(string uri) {
		uint rv = 0;
		TagLib.File tag_file = new TagLib.File(File.new_for_uri(uri).get_path());
		
		if(tag_file != null && tag_file.audioproperties != null) {
			rv = tag_file.audioproperties.length;
		}
		
		return rv;
	}
	
	public override Collection<SmartPlaylist> get_default_smart_playlists() {
		var rv = new LinkedList<SmartPlaylist>();
		
		SmartPlaylist sp = new SmartPlaylist();
		
		sp.name = _("Unheard Podcasts");
		sp.conditional = SmartPlaylist.Conditional.ALL;
		sp.limit = false;
		sp.limit_amount = 50;
		sp.queries.add(new SmartQuery.with_info(SmartQuery.Field.MEDIATYPE, SmartQuery.Comparator.IS, "", MediaType.PODCAST));
		sp.queries.add(new SmartQuery.with_info(SmartQuery.Field.PLAY_COUNT, SmartQuery.Comparator.IS_EXACTLY, "", 0));
		rv.add(sp);
		
		return rv;
	}
}
