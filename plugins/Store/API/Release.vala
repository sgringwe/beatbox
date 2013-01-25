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
using Xml;

public class Store.Release : GLib.Object, Store.SearchResult {
	public int releaseID;
	public string title;
	public string version;
	public string type;
	public int barcode;
	public int year;
	public bool explicitContent;
	public Store.Artist artist;
	public string imagePath;
	public string url;
	public GLib.Time releaseDate;
	public string addedDate;
	public Store.Price price;
	public bool availableDrmFree;
	public LinkedList<Store.Format> formats;
	public Store.Label label;
	public Gdk.Pixbuf image;
	
	public string search_type { get; set; }
	public string search_change { get; set; }
	public int search_rank { get; set; }
	public double search_score { get; set; }
	
	public Release(int id) {
		releaseID = id;
		
		formats = new LinkedList<Store.Format>();
		price = new Store.Price();
	}
	
	public LinkedList<Store.Release> getSimilar(int page, int pageSize, int imagesize) {
		var rv = new LinkedList<Store.Release>();
		
		var params = new HashMap<string, string>();
		params.set("page", page.to_string());
		params.set("pageSize", pageSize.to_string());
		params.set("releaseid", releaseID.to_string());
		params.set("imagesize", imagesize.to_string());
		
		Xml.Node* node = Store.store.query("GET", "release/recommend", params, false);
		if(node == null)
			return rv;
        
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "recommendedItem") {
				Store.Release toAdd = Store.XMLParser.parseRelease(iter->children);
				
				if(toAdd != null)
					rv.add(toAdd);
			}
		}
		
		delete node;
		
		return rv;
	}
	
	public LinkedList<Store.Track> getTracks() {
		var rv = new LinkedList<Store.Track>();
		
		var params = new HashMap<string, string>();
		params.set("pageSize", "50");
		params.set("releaseid", releaseID.to_string());
		
		Xml.Node* node = Store.store.query("GET", "release/tracks", params, false);
		if(node == null)
			return rv;
        
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "track") {
				Store.Track toAdd = Store.XMLParser.parseTrack(iter);
				
				if(toAdd != null)
					rv.add(toAdd);
			}
		}
		
		delete node;
		
		return rv;
	}
	
	public LinkedList<Store.Tag> getTags() {
		var rv = new LinkedList<Store.Tag>();
		
		var params = new HashMap<string, string>();
		params.set("releaseid", releaseID.to_string());
		
		Xml.Node* node = Store.store.query("GET", "release/tags", params, false);
		if(node == null)
			return rv;
        
		for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
			if (iter->type != ElementType.ELEMENT_NODE) {
				continue;
			}
			
			if(iter->name == "tag") {
				Store.Tag toAdd = Store.XMLParser.parseTag(iter);
				
				if(toAdd != null)
					rv.add(toAdd);
			}
		}
		
		delete node;
		
		return rv;
	}
}
