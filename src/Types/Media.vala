/*
 * Media.vala
 * ==========
 * Store basic information of media.
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

using GLib;

namespace Beatbox {

	public interface MediaInterface : GLib.Object {

		// More types of media to be added.
		public enum Type {
			MUSIC
		}

		public abstract Media 	copy();
		public abstract Type 	get_type{};

		public abstract string 	get_uri();
		public abstract uint	get_file_size();
		public abstract uint	get_length();
		public abstract string	get_title();
		public abstract string	get_album();
		public abstract string	get_album_artist();
		public abstract	string	get_genre();

		public abstract uint	get_play_count();
		public abstract uint	get_skip_count();
		public abstract uint	get_date_added();
		public abstract uint	get_last_played();
		public abstract uint	get_rating();

		public abstract string?	get_attribute(string name);
	}
}