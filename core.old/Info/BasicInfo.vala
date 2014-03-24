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

public class BeatBox.BasicInfo : Object {
	static string TAG_SEPARATOR = "<tag_separator>";
	static string URL_SEPARATOR = "<url_separator>";
	protected static string VALUE_SEPARATOR = "<value_separator>";
	
	public Collection<string> tags { get; set; }
	public Collection<InfoURL> more_info_urls { get; set; }
	public string full_desc { get; set; }
	public string short_desc { get; set; }
	public string merged_desc { get; set; }
	
	protected BasicInfo() {
		tags = new LinkedList<string>();
		more_info_urls = new LinkedList<InfoURL>();
	}
	
	protected void merge_basic_info(BasicInfo other) {
		foreach(var tag in other.tags) {
			if(!tags.contains(tag)) {
				tags.add(tag);
			}
		}
		
		foreach(var more_info_url in other.more_info_urls) {
			more_info_urls.add(more_info_url);
		}
		
		if(String.is_empty(full_desc)) {
			full_desc = other.full_desc;
		}
		if(String.is_empty(short_desc)) {
			short_desc = other.short_desc;
		}
		
		if(String.is_empty(merged_desc)) {
			merged_desc = !String.is_empty(other.full_desc) ? other.full_desc : other.short_desc;
		}
		else {
			bool has_full = !String.is_empty(other.full_desc);
			bool has_short = !String.is_empty(other.short_desc);
			string? to_append = has_full ? other.full_desc : (has_short ? other.short_desc : null);
			
			if(to_append != null) {
				merged_desc += "\n\n" + to_append;
			}
		}
	}
	
	public void load_tags(string tags_string) {
		string[] tag_array = tags_string.split(TAG_SEPARATOR, 0);
		
		for(int index = 0; index < tag_array.length - 1; ++index) {
			tags.add(tag_array[index]);
		}
	}
	
	public void load_more_info_urls(string more_info_urls_string) {
		string[] more_info_urls_array = more_info_urls_string.split(URL_SEPARATOR, 0);
				
		for(int index = 0; index < more_info_urls_array.length - 1; ++index) {
			string[] url_values = more_info_urls_array[index].split(VALUE_SEPARATOR, 0);
			
			InfoURL info_url = new InfoURL();
			info_url.uri = url_values[0];
			info_url.title = url_values[1];
			// TODO: What to do about pixbuf?
			more_info_urls.add(info_url);
		}
	}
	
	public string get_tags_string() {
		string rv = "";
		
		foreach(string tag in tags) {
			rv += tag + VALUE_SEPARATOR;
		}
		
		return rv;
	}
	
	public string get_more_info_urls_string() {
		string rv = "";
		
		foreach(var info_url in more_info_urls) {
			rv += info_url.uri + VALUE_SEPARATOR + info_url.title + URL_SEPARATOR;
		}
		
		return rv;
	}
}
