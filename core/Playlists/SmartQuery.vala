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

public class BeatBox.SmartQuery : Object {
	public enum Field {
		ALBUM,
		ARTIST,
		BITRATE,
		COMMENT,
		COMPOSER,
		DATE_ADDED,
		DATE_RELEASED,
		GENRE,
		GROUPING,
		LAST_PLAYED,
		LENGTH,
		MEDIATYPE,
		PLAY_COUNT,
		RATING,
		SKIP_COUNT,
		TITLE,
		YEAR;
		
		public string to_string() {
			switch (this) {
				case ALBUM:
					return _("Album");
				case ARTIST:
					return _("Artist");
				case BITRATE:
					return _("Bitrate");
				case COMMENT:
					return _("Comment");
				case COMPOSER:
					return _("Composer");
				case DATE_ADDED:
					return _("Date Added");
				case DATE_RELEASED:
					return _("Date Released");
				case GENRE:
					return _("Genre");
				case GROUPING:
					return _("Grouping");
				case LAST_PLAYED:
					return _("Last Played");
				case LENGTH:
					return _("Length");
				case MEDIATYPE:
					return _("Media Type");
				case PLAY_COUNT:
					return _("Play Count");
				case RATING:
					return _("Rating");
				case SKIP_COUNT:
					return _("Skip Count");
				case TITLE:
					return _("Title");
				case YEAR:
					return _("Year");
				default:
					return "FIXME";
			}
		}
		
		public static Field[] all() {
			return {	ALBUM,
						ARTIST,
						BITRATE,
						COMMENT,
						COMPOSER,
						DATE_ADDED,
						DATE_RELEASED,
						GENRE,
						GROUPING,
						LAST_PLAYED,
						LENGTH,
						MEDIATYPE,
						PLAY_COUNT,
						RATING,
						SKIP_COUNT,
						TITLE,
						YEAR };
		}
		
		// Helpers
		public bool is_string() {
			return (this == Field.ALBUM ||
					this == Field.ARTIST ||
					this == Field.COMMENT ||
					this == Field.COMPOSER ||
					this == Field.GENRE ||
					this == Field.GROUPING ||
					this == Field.TITLE);
		}
		
		public bool is_int() {
			return (this == Field.BITRATE ||
					this == Field.YEAR ||
					this == Field.RATING ||
					this == Field.PLAY_COUNT ||
					this == Field.SKIP_COUNT ||
					this == Field.LENGTH);
		}
		
		public bool is_time() {
			return (this == Field.DATE_ADDED ||
					this == Field.DATE_RELEASED ||
					this == Field.LAST_PLAYED);
		}
		
		public bool is_type() {
			return (this == Field.MEDIATYPE);
		}
	}
	
	public enum Comparator {
		IS,
		IS_EXACTLY,
		IS_NOT,
		IS_AT_LEAST,
		IS_AT_MOST,
		IS_WITHIN,
		IS_BEFORE,
		CONTAINS,
		DOES_NOT_CONTAIN;
		
		public string to_string() {
			switch (this) {
				case IS:
					return _("is");
				case IS_EXACTLY:
					return _("is exactly");
				case IS_NOT:
					return _("is not");
				case IS_AT_LEAST:
					return _("is at least");
				case IS_AT_MOST:
					return _("is at most");
				case IS_WITHIN:
					return _("is within");
				case IS_BEFORE:
					return _("is before");
				case CONTAINS:
					return _("contains");
				case DOES_NOT_CONTAIN:
					return _("does not contain");
				default:
					return "FIXME";
			}
		}
		
		public static Comparator[] all() {
			return {	IS,
						IS_EXACTLY,
						IS_NOT,
						IS_AT_LEAST,
						IS_AT_MOST,
						IS_WITHIN,
						IS_BEFORE,
						CONTAINS,
						DOES_NOT_CONTAIN };
		}
	}
	
	public Field field { get; set; }
	public Comparator comparator { get; set; }
	public string string_value { get; set; }
	public int int_value { get; set; }
	
	string string_down;
	
	public SmartQuery() {
		field = Field.ALBUM;
		comparator = Comparator.IS;
		string_value = "";
		int_value = 0;
	}
	
	public SmartQuery.with_info(Field field, Comparator comparator, string val, int int_val) {
		this.field = field;
		this.comparator = comparator;
		this.string_value = val;
		this.int_value = int_val;
	}
	
	// To avoid duplicate operations, do them now before testing
	public void prepare_for_tests() {
		string_down = string_value.down();
	}
	
	public bool test_media(Media m) {
		if(field.is_string())
			return test_string(m);
		else if(field.is_int())
			return test_int(m);
		else if(field.is_time())
			return test_time(m);
		else if(field.is_type())
			return test_type(m);
		
		return false;
	}
	
	// Assumes prepare_for_tests was called
	bool test_string(Media m) {
		string compare_to = "";
		
		if(field == SmartQuery.Field.ALBUM)
			compare_to = m.album.down();
		else if(field == SmartQuery.Field.ARTIST)
			compare_to = m.artist.down();
		else if(field == SmartQuery.Field.COMPOSER)
			compare_to = m.composer.down();
		else if(field == SmartQuery.Field.COMMENT)
			compare_to = m.comment.down();
		else if(field == SmartQuery.Field.GENRE)
			compare_to = m.genre.down();
		else if(field == SmartQuery.Field.GROUPING)
			compare_to = m.grouping.down();
		else if(field == SmartQuery.Field.TITLE)
			compare_to = m.title.down();
		else
			return false;
		
		if(comparator == Comparator.IS)
			return string_down == compare_to;
		else if(comparator == Comparator.CONTAINS)
			return (string_down in compare_to);
		else if(comparator == Comparator.DOES_NOT_CONTAIN)
			return !(string_down in compare_to);
	
		return false;
	}
	
	bool test_int(Media m) {
		uint compare_to = 0;
		
		if(field == SmartQuery.Field.BITRATE)
			compare_to = m.bitrate;
		if(field == SmartQuery.Field.PLAY_COUNT)
			compare_to = m.play_count;
		else if(field == SmartQuery.Field.SKIP_COUNT)
			compare_to = m.skip_count;
		else if(field == SmartQuery.Field.YEAR)
			compare_to = m.year;
		else if(field == SmartQuery.Field.LENGTH)
			compare_to = m.length;
		else if(field == SmartQuery.Field.RATING)
			compare_to = m.rating;
		else
			return false;
		
		if(comparator == Comparator.IS_EXACTLY)
			return int_value == compare_to;
		else if(comparator == Comparator.IS_AT_MOST)
			return (compare_to <= int_value);
		else if(comparator == Comparator.IS_AT_LEAST)
			return (compare_to >= int_value);
		
		return false;
	}
	
	bool test_time(Media m) {
		var now = new DateTime.now_local();
		DateTime? compare_to = null;
		
		if(field == SmartQuery.Field.DATE_ADDED)
			compare_to = new DateTime.from_unix_local(m.date_added);
		else if(field == SmartQuery.Field.DATE_RELEASED)
			compare_to = new DateTime.from_unix_local(m.date_released);
		else if(field == SmartQuery.Field.LAST_PLAYED) {
			if(m.last_played == 0)	return false;
			compare_to = new DateTime.from_unix_local(m.last_played);
		}
		else
			return false;
		
		compare_to = compare_to.add_days(int_value);
		if(comparator == Comparator.IS_EXACTLY)
			return (now.get_day_of_year() == compare_to.get_day_of_year() && now.get_year() == compare_to.get_year());
		else if(comparator == Comparator.IS_WITHIN)
			return compare_to.compare(now) > 0;
		else if(comparator == Comparator.IS_BEFORE)
			return now.compare(compare_to) > 0;
		
		return false;
	}
	
	bool test_type(Media m) {
		int compare_to = 0;
		
		if(field == SmartQuery.Field.MEDIATYPE)
			compare_to = m.media_type;
		else
			return false;
			
		if(comparator == Comparator.IS)
			return compare_to == int_value;
		else if(comparator == Comparator.IS_NOT)
			return compare_to != int_value;
		
		return false;
	}
}
