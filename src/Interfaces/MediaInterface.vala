/*
 * MediaInterface.vala
 * ===================
 * Interface to various types of media, abstracting access to
 * basic information.
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

using GLib;

namespace Beatbox {

	public static const string MEDIA_ATTRIBUTE_URI 			= "uri";
	public static const string MEDIA_ATTRIBUTE_FILE_SIZE 	= "file_size";
	public static const string MEDIA_ATTRIBUTE_LENGTH		= "length";
	public static const string MEDIA_ATTRIBUTE_TITLE		= "title";
	public static const string MEDIA_ATTRIBUTE_ARTIST 		= "artist";
	public static const string MEDIA_ATTRIBUTE_ALBUM		= "album";
	public static const string MEDIA_ATTRIBUTE_ALBUM_ARTIST	= "album_artist";
	public static const string MEDIA_ATTRIBUTE_GENRE		= "genre";

	public static const string MEDIA_ATTRIBUTE_PLAY_COUNT	= "play_count";
	public static const string MEDIA_ATTRIBUTE_SKIP_COUNT	= "skip_count";
	public static const string MEDIA_ATTRIBUTE_DATE_ADDED	= "date_added";
	public static const string MEDIA_ATTRIBUTE_LAST_PLAYED	= "last_played";
	public static const string MEDIA_ATTRIBUTE_RATING		= "rating";

	public interface MediaInterface : GLib.Object {

		// TODO: More types of media.
		public enum Type {
			MUSIC
		}

		public abstract Type 	get_media_type();

		public abstract string 	get_uri();
		public abstract uint	get_file_size();
		public abstract uint	get_length();
		public abstract string	get_title();
		public abstract string	get_artist();
		public abstract string	get_album();
		public abstract string	get_album_artist();
		public abstract	string	get_genre();

		public abstract uint		get_play_count();
		public abstract uint		get_skip_count();
		public abstract DateTime	get_date_added();
		public abstract DateTime	get_last_played();
		public abstract uint		get_rating();

		public abstract string?	get_attribute(string name);
	}
}