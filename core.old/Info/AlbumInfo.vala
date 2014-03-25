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

using Xml;

public class BeatBox.AlbumInfo : BasicInfo {
	public string album { get; set; }
	public string album_artist { get; set; }
	public string release_date { get; set; }
	public string art_uri { get; set; }
	// tracks, similar_albums
	
	public AlbumInfo() {
		
	}
	
	public void merge_info(AlbumInfo other) {
		merge_basic_info(other);
		
		if(String.is_empty(release_date)) {
			release_date = other.release_date;
		}
		if(String.is_empty(art_uri)) {
			art_uri = other.art_uri;
		}
	}
	
	public void load_similar_albums(string? sim_albums_string) {
		/*string[] sim_strings = sim_string.split("<similar_seperator>", 0);
				
		for(index = 0; index < sim_strings.length - 1; ++index) {
			string[] sim_values = sim_strings[index].split("<value_seperator>", 0);
			
			LastFM.ArtistInfo sim = new LastFM.ArtistInfo.with_artist_and_url(sim_values[0], sim_values[1]);
			a.addSimilarArtist(sim);
		}*/
	}
	
	public string get_similar_albums_string() {
		return "";
	}
}
