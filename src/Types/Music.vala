/*
 * Music.vala
 * ==========
 * Music type of media, previously named Song.
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

using GLib;

namespace Beatbox {

	public class Music : GLib.Object, MediaInterface {

		private HashTable<string, string> properties;

		public Music() {
			properties = new HashTable<string, string>(str_hash, str_equal);
			set_default();
		}

		public void set_default() {
			properties.remove_all();

			properties.set(MEDIA_ATTRIBUTE_URI, 			"");
			properties.set(MEDIA_ATTRIBUTE_FILE_SIZE, 		"0");
			properties.set(MEDIA_ATTRIBUTE_LENGTH, 			"0");
			properties.set(MEDIA_ATTRIBUTE_TITLE, 			"Unknown Title");
			properties.set(MEDIA_ATTRIBUTE_ARTIST,			"Unknown Artist");
			properties.set(MEDIA_ATTRIBUTE_ALBUM, 			"Unknown Album");
			properties.set(MEDIA_ATTRIBUTE_ALBUM_ARTIST, 	"");
			properties.set(MEDIA_ATTRIBUTE_GENRE, 			"");
			properties.set(MEDIA_ATTRIBUTE_PLAY_COUNT,		"0");
			properties.set(MEDIA_ATTRIBUTE_SKIP_COUNT, 		"0");
			properties.set(MEDIA_ATTRIBUTE_DATE_ADDED, 		"0");
			properties.set(MEDIA_ATTRIBUTE_LAST_PLAYED, 	"0");
			properties.set(MEDIA_ATTRIBUTE_RATING, 			"0");
		}

		public MediaInterface.Type get_media_type() {
			return Type.MUSIC;
		}

		public string get_uri() {
			return properties.get(MEDIA_ATTRIBUTE_URI);
		}

		public uint get_file_size() {
			return int.parse(properties.get(MEDIA_ATTRIBUTE_FILE_SIZE));
		}

		public uint get_length() {
			return int.parse(properties.get(MEDIA_ATTRIBUTE_LENGTH));
		}

		public string get_title() {
			return properties.get(MEDIA_ATTRIBUTE_TITLE);
		}

		public string get_artist() {
			return properties.get(MEDIA_ATTRIBUTE_ARTIST);
		}
		
		public string get_album() {
			return properties.get(MEDIA_ATTRIBUTE_ALBUM);
		}

		public string get_album_artist() {
			return properties.get(MEDIA_ATTRIBUTE_ALBUM_ARTIST);
		}

		public string get_genre() {
			return properties.get(MEDIA_ATTRIBUTE_GENRE);
		}

		public uint get_play_count() {
			return int.parse(properties.get(MEDIA_ATTRIBUTE_PLAY_COUNT));
		}

		public uint get_skip_count() {
			return int.parse(properties.get(MEDIA_ATTRIBUTE_SKIP_COUNT));
		}

		public DateTime get_date_added() {
			return new DateTime.from_unix_utc(
				int.parse(properties.get(MEDIA_ATTRIBUTE_DATE_ADDED)));
		}

		public DateTime get_last_played() {
			return new DateTime.from_unix_utc(
				int.parse(properties.get(MEDIA_ATTRIBUTE_LAST_PLAYED)));
		}

		public uint get_rating() {
			return int.parse(properties.get(MEDIA_ATTRIBUTE_RATING));
		}

		public string? get_attribute(string name) {
			return properties.get(name);
		}
	}
}