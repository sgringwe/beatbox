// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * Copyright (c) 2012 BeatBox Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 * 
 * The BeatBox project hereby grant permission for non-gpl compatible GStreamer
 * plugins to be used and distributed together with GStreamer and BeatBox. This
 * permission is above and beyond the permissions granted by the GPL license
 * BeatBox is covered by.
 */

namespace BeatBox.String {

    /**
     * Compares two strings. Used extensively in the views for sorting.
     * @return 1 if a > b. -1 if b > a
     */
    public int compare (string a, string b) {
        if (a == "" && b != "")
            return 1;

        if (a != "" && b == "")
            return -1;

        return (a > b) ? 1 : -1;
    }

    /**
     * @return 'true' if text consists enterely of white space.
     */
    public bool is_empty (string? text) {
        if (text == null)
            return true;

        return text.strip ().length == 0;
    }
    
    /** Removes unwanted html formatting text and keeps only the content.
     * Example: '<b>Test</b>' becomes 'Test'
    */
    string remove_html(string s) {
		if(s == null || s == "")
			return "";
		
		string rv = s;
		Regex r;
		
		try {
			r = new Regex("<.*?>");
			rv = r.replace(s, s.length, 0, "");
		} catch(RegexError err) {
			warning("Regex error: %s. Could not remove html tags.\n", err.message);
		}
		
		return rv;
	}
	
	public string ellipsize(string str, int limit) {
		if(str.char_count() > limit)
			return str.substring(
					str.index_of_nth_char(0), 
					str.index_of_nth_char(limit - 3)) + "...";
		else
			return str;
	}

	public void kmp_generate_table(string pattern, int[] table)
	{
		if(pattern.length > table.length) {
			warning("size of given array is too small.");
			return ;
		}
		table[0] = -1;
		int j = -1;
		for(int i = 1; i < pattern.length; i++) {
			while(j >= 0 && pattern[j + 1].tolower() !=  pattern[i].tolower()) 
				j = table[j];
			if(pattern[j + 1].tolower() == pattern[i].tolower()) j++;
			table[i] = j;
		}
	}

	public bool kmp_is_match(string s, string pattern, int[] table)
	{
		int j = -1;
		for(int i = 0; i < s.length; i++) {
			while(j >= 0 && pattern[j + 1].tolower() != s[i].tolower()) 
				j = table[j];
			if(pattern[j + 1].tolower() == s[i].tolower()) j++;
			if(j == pattern.length - 1) return true;
		}
		return false;
	}
}

