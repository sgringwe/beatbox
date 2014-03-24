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

public class BeatBox.SmartPlaylist : BasePlaylist {
	public enum Conditional {
		ANY,
		ALL
	}
	
	public Conditional conditional { get; set; }
	public bool limit { get; set; }
	public int limit_amount { get; set; }
	
	public bool is_up_to_date { get; set; }
	public bool viewWrapper_is_up_to_date { get; set; }
	LinkedList<Media> medias;
	
	public Collection<SmartQuery> queries;
	
	public SmartPlaylist() {
		name = "";
		conditional = Conditional.ALL;
		queries = new LinkedList<SmartQuery>();
		limit = false;
		limit_amount = 50;
		viewWrapper_is_up_to_date = false;
		is_up_to_date = false;
	}
	
	public void queries_from_string(string q) {
		string[] queries_in_string = q.split("<query_seperator>", 0);
		
		int index;
		for(index = 0; index < queries_in_string.length - 1; index++) {
			string[] pieces_of_query = queries_in_string[index].split("<value_seperator>", 0);
			
			SmartQuery sq = new SmartQuery();
			sq.field = (SmartQuery.Field)int.parse(pieces_of_query[0]);
			sq.comparator = (SmartQuery.Comparator)int.parse(pieces_of_query[1]);
			sq.string_value = pieces_of_query[2];
			
			// legacy support for old way
			if(pieces_of_query.length >= 4)
				sq.int_value = int.parse(pieces_of_query[3]);
			else
				sq.int_value = int.parse(sq.string_value);
			
			queries.add(sq);
		}
	}
	
	public string queries_to_string() {
		string rv = "";
		
		foreach(SmartQuery q in queries) {
			rv += ((int)q.field).to_string() + "<value_seperator>" + ((int)q.comparator).to_string() + "<value_seperator>" + 
					q.string_value  + "<value_seperator>" + q.int_value.to_string() + "<query_seperator>";
		}
		
		return rv;
	}
	
	public override Collection<Media> analyze(Collection<Media> to_test) {
		//if(is_up_to_date) {
		//	return medias;
		//}
		
		// Prepare queries
		foreach(SmartQuery q in queries) {
			q.prepare_for_tests();
		}
		
		LinkedList<Media> rv = new LinkedList<Media>();
		foreach(Media m in to_test) {
			bool success = false;
			
			foreach(SmartQuery q in queries) {
				q.prepare_for_tests();
				
				success = q.test_media(m);
				if(!success && conditional == Conditional.ALL) // 1 failure, don't add
					break;
				if(success && conditional == Conditional.ANY) // 1 success, add it
					break;
			}
			
			if(success)
				rv.add(m);
				
			if(limit && limit_amount <= rv.size)
				break;
		}
		
		is_up_to_date = true;
		medias = rv;
		
		return rv;
	}
	
	public override GPod.Playlist get_gpod_playlist() {
		GPod.Playlist rv = new GPod.Playlist(name, false);
		
		return rv;
	}
	
	public void set_playlist_properties(GPod.Playlist rv) {
		foreach(var sq in queries) {
			rv.splr_add_new(-1);
			
			unowned GPod.SPLRule? rule = rv.splrules.rules.nth_data(rv.splrules.rules.length() - 1);
			
			SmartQuery.Field field = sq.field;
			var comparator = sq.comparator;
			if(field == SmartQuery.Field.ALBUM) {
				rule.field = GPod.SPLField.ALBUM;
				rule.@string = sq.string_value;
			}
			else if(field == SmartQuery.Field.ARTIST) {
				rule.field = GPod.SPLField.ARTIST;
				rule.@string = sq.string_value;
			}
			else if(field == SmartQuery.Field.COMPOSER) {
				rule.field = GPod.SPLField.COMPOSER;
				rule.@string = sq.string_value;
			}
			else if(field == SmartQuery.Field.COMMENT) {
				rule.field = GPod.SPLField.COMMENT;
				rule.@string = sq.string_value;
			}
			else if(field == SmartQuery.Field.GENRE) {
				rule.field = GPod.SPLField.GENRE;
				rule.@string = sq.string_value;
			}
			else if(field == SmartQuery.Field.GROUPING) {
				rule.field = GPod.SPLField.GROUPING;
				rule.@string = sq.string_value;
			}
			else if(field == SmartQuery.Field.TITLE) {
				rule.field = GPod.SPLField.SONG_NAME;
				rule.@string = sq.string_value;
			}
			else if(field == SmartQuery.Field.BITRATE) {
				rule.field = GPod.SPLField.BITRATE;
				rule.fromvalue = (uint64)sq.int_value;
				rule.tovalue = (uint64)sq.int_value;
				rule.tounits = 1;
				rule.fromunits = 1;
			}
			else if(field == SmartQuery.Field.PLAY_COUNT) {
				rule.field = GPod.SPLField.PLAYCOUNT;
				rule.fromvalue = (uint64)sq.int_value;
				rule.tovalue = (uint64)sq.int_value;
				rule.tounits = 1;
				rule.fromunits = 1;
			}
			else if(field == SmartQuery.Field.SKIP_COUNT) {
				rule.field = GPod.SPLField.SKIPCOUNT;
				rule.fromvalue = (uint64)sq.int_value;
				rule.tovalue = (uint64)sq.int_value;
				rule.tounits = 1;
			}
			else if(field == SmartQuery.Field.YEAR) {
				rule.field = GPod.SPLField.YEAR;
				rule.fromvalue = (uint64)sq.int_value;
				rule.tovalue = (uint64)sq.int_value;
				rule.tounits = 1;
				rule.fromunits = 1;
			}
			else if(field == SmartQuery.Field.LENGTH) {
				rule.field = GPod.SPLField.TIME;
				rule.fromvalue = (uint64)sq.int_value * 1000;
				rule.tovalue = (uint64)sq.int_value * 1000;
				rule.tounits = 1;
				rule.fromunits = 1;
			}
			else if(field == SmartQuery.Field.RATING) {
				rule.field = GPod.SPLField.RATING;
				rule.fromvalue = (uint64)sq.int_value * 20;
				rule.tovalue = (uint64)sq.int_value * 20;
				rule.tounits = 1;//20;
				rule.fromunits = 1;//20;
			}
			else if(field == SmartQuery.Field.DATE_ADDED) {
				rule.field = GPod.SPLField.DATE_ADDED;
				rule.fromvalue = (uint64)sq.int_value * 60 * 60 * 24;
				rule.tovalue = (uint64)sq.int_value * 60 * 60 * 24;
				rule.tounits = 1;//60 * 60 * 24;
				rule.fromunits = 1;//60 * 60 * 24;
			}
			else if(field == SmartQuery.Field.LAST_PLAYED) {
				rule.field = GPod.SPLField.LAST_PLAYED;
				rule.fromvalue = (uint64)sq.int_value * 60 * 60 * 24;
				rule.tovalue = (uint64)sq.int_value * 60 * 60 * 24;
				rule.tounits = 1;//60 * 60 * 24;
				rule.fromunits = 1;//60 * 60 * 24;
			}
			else if(field == SmartQuery.Field.DATE_RELEASED) {
				// no equivelant
			}
			else if(field == SmartQuery.Field.MEDIATYPE) {
				rule.field = GPod.SPLField.VIDEO_KIND;
				
				if(sq.int_value == (int)MediaType.SONG) {
					rule.fromvalue = 0x00000001;
					rule.tovalue = 0x00000001;;
				}
				else if(sq.int_value == (int)MediaType.PODCAST) {
					rule.fromvalue = 0x00000006;
					rule.tovalue = 0x00000006;
				}
				else if(sq.int_value == (int)MediaType.AUDIOBOOK) {
					rule.fromvalue = 0x00000008;
					rule.tovalue = 0x00000008;
				}
			}
			
			// set action type
			if(comparator == SmartQuery.Comparator.IS) {
				if(field == SmartQuery.Field.MEDIATYPE)
					rule.action = GPod.SPLAction.BINARY_AND;
				else
					rule.action = GPod.SPLAction.IS_STRING;
			}
			else if(comparator == SmartQuery.Comparator.IS_NOT) {
				if(field == SmartQuery.Field.MEDIATYPE)
					rule.action = GPod.SPLAction.NOT_BINARY_AND;
				else
					rule.action = GPod.SPLAction.IS_NOT_INT;
			}
			else if(comparator == SmartQuery.Comparator.CONTAINS) {
				rule.action = GPod.SPLAction.CONTAINS;
			}
			else if(comparator == SmartQuery.Comparator.DOES_NOT_CONTAIN) {
				rule.action = GPod.SPLAction.DOES_NOT_CONTAIN;
			}
			else if(comparator == SmartQuery.Comparator.IS_EXACTLY) {
				rule.action = GPod.SPLAction.IS_INT;
			}
			else if(comparator == SmartQuery.Comparator.IS_AT_MOST) {
				rule.action = GPod.SPLAction.IS_LESS_THAN;
				rule.fromvalue += 1;
				rule.tovalue += 1;
			}
			else if(comparator == SmartQuery.Comparator.IS_AT_LEAST) {
				rule.action = GPod.SPLAction.IS_GREATER_THAN;
				rule.fromvalue -= 1;
				rule.tovalue -= 1;
			}
			else if(comparator == SmartQuery.Comparator.IS_WITHIN) {
				rule.action = GPod.SPLAction.IS_GREATER_THAN;
			}
			else if(comparator == SmartQuery.Comparator.IS_BEFORE) {
				rule.action = GPod.SPLAction.IS_LESS_THAN;
			}
			
			stdout.printf("in smartplaylist  has rule and string %s\n", rule.@string);
		}
		
		rv.splpref.checkrules = (uint8)rv.splrules.rules.length();
		rv.splpref.checklimits = (uint8)0;
		rv.splrules.match_operator = (conditional == Conditional.ANY) ? GPod.SPLMatch.OR : GPod.SPLMatch.AND;
		rv.splpref.liveupdate = 1;
		rv.is_spl = true;
	}
}
