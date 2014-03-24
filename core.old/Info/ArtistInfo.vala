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

// TODO: We need to save similar_artists data somehow in database
public class BeatBox.ArtistInfo : BasicInfo {
	public string artist { get; set; }
	public Collection<ArtistInfo> similar_artists { get; set; }
	public string photo_uri { get; set; }
	
	public ArtistInfo() {
		similar_artists = new LinkedList<ArtistInfo>();
	}
	
	public void merge_info(ArtistInfo other) {
		merge_basic_info(other);
		
		// merge artist info for ones we already have and add artist info for those we don't
		foreach(var other_sim in other.similar_artists) {
			bool already_have_sim = false;
			
			foreach(var sim in similar_artists) {
				if(other_sim.artist == sim.artist) {
					sim.merge_info(other_sim);
					already_have_sim = true;
					break;
				}
			}
			
			if(!already_have_sim) {
				similar_artists.add(other_sim);
			}
		}
		
		if(String.is_empty(photo_uri)) {
			photo_uri = other.photo_uri;
		}
	}
	
	public void load_similar_artists(string sim_artists_string) {
		/*string[] sim_strings = sim_string.split("<similar_seperator>", 0);
				
		for(index = 0; index < sim_strings.length - 1; ++index) {
			string[] sim_values = sim_strings[index].split("<value_seperator>", 0);
			
			LastFM.ArtistInfo sim = new LastFM.ArtistInfo.with_artist_and_url(sim_values[0], sim_values[1]);
			a.addSimilarArtist(sim);
		}*/
	}
	
	public string get_similar_artists_string() {
		return "";
	}
}
