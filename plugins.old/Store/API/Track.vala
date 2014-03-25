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
 */

using Gee;

public class Store.Track : BeatBox.Preview, Store.SearchResult {
	public int trackID;
	public string version;
	public bool explicitContent;
	public string isrc;
	public string url;
	
	public Store.Artist store_artist;
	public Store.Release store_release;
	public Store.Price price;
	
	public string search_type { get; set; }
	public string search_change { get; set; }
	public int search_rank { get; set; }
	public double search_score { get; set; }
	
	public Track(int track_id) {
		base("");
		
		this.rowid = BeatBox.Media.PREVIEW_ROWID; // beatbox id
		this.trackID = track_id; //7digital id
		price = new Store.Price();
	}
	
	public string? getPreviewLink() {
		var rv = "";
		
		var params = new HashMap<string, string>();
		params.set("trackid", trackID.to_string());
		params.set("redirect", "false");
		
		Xml.Node* node = Store.store.query("GET", "track/preview", params, false);
		if(node == null)
			return rv;
		
		if(node->name == "url")
			rv = node->get_content();
			
		delete node;
		
		return rv;
	}
}
