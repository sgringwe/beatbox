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
using Gtk;

public class Store.ObjectList : EventBox {
	Store.StoreView storeView;
	HashMap<int, Object> object_map;
	Orientation item_orientation;
	int image_size;
	int max_chars;
	
	Box content;
	
	public ObjectList(Store.StoreView view, int image_size, Orientation orient, int max_chars = 20) {
		storeView = view;
		object_map = new HashMap<int, Object>();
		
		if(orient == Orientation.HORIZONTAL)
			item_orientation = Orientation.VERTICAL;
		else
			item_orientation = Orientation.HORIZONTAL;
		
		this.image_size = image_size;
		this.max_chars = max_chars;
		
		content = new Box(orient, 6);
		
		get_style_context().add_class("white");
		
		add(content);
		
		show_all();
	}
	
	public void addItem(Object obj) {
		Box to_add = new Box(item_orientation, 6);
		
		if(obj is Store.Tag) {
			Tag tag = (Tag)obj;
			//object_map.set(tag.tagID, tag);
			//Store.Tag tag = (Store.Tag)obj;
			//store.set(iter, 0, tag, 1, tag.tagID, 2, tag.text);
			
			Tag artist = (Tag)obj;
			
			Gtk.Label lab = new Gtk.Label("");
			set_proper_label_props(ref lab);
			lab.set_markup("<a href=\"%s\" title=\"%s\">%s</a>".printf("tag/" + tag.tagID, Markup.escape_text(tag.text), Markup.escape_text(tag.text)));
			to_add.pack_start(lab, true, true, 0);
			
			lab.activate_link.connect(url_handler);
			
		}
		else if(obj is Store.Artist) {
			Artist artist = (Artist)obj;
			
			object_map.set(artist.artistID, artist);
			
			if(artist.image != null) {
				var scaled_down = artist.image.scale_simple(image_size, image_size, Gdk.InterpType.BILINEAR);
				var image = new ClickableImage(scaled_down, "artist/" + artist.artistID.to_string());
				to_add.pack_start(image, false, false, 0);
				
				image.activated.connect(url_handler);
			}
			
			Gtk.Label lab = new Gtk.Label("");
			set_proper_label_props(ref lab);
			lab.set_markup("<a href=\"%s\" title=\"%s\">%s</a>".printf("artist/" + artist.artistID.to_string(), 
																		Markup.escape_text(artist.name),
																		Markup.escape_text(BeatBox.String.ellipsize(artist.name, max_chars))));
			to_add.pack_start(lab, true, true, 0);
			
			lab.activate_link.connect(url_handler);
		}
		else {
			Release release = (Release)obj;
			
			object_map.set(release.releaseID, release);
			object_map.set(release.artist.artistID, release.artist);
			
			if(release.image != null) {
				var scaled_down = release.image.scale_simple(image_size, image_size, Gdk.InterpType.BILINEAR);
				var image = new ClickableImage(scaled_down, "release/" + release.releaseID.to_string());
				to_add.pack_start(image, false, false, 0);
				
				image.activated.connect(url_handler);
			}
			
			Box label_box = new Box(Orientation.VERTICAL, 0);
			
			Gtk.Label lab = new Gtk.Label("");
			set_proper_label_props(ref lab);
			lab.set_markup("<a href=\"%s\" title=\"%s\">%s</a>".printf("release/" + release.releaseID.to_string(), 
																			Markup.escape_text(release.title),
																			Markup.escape_text(BeatBox.String.ellipsize(release.title, max_chars))));
			label_box.pack_start(lab, true, true, 0);
			lab.activate_link.connect(url_handler);
			
			if(release.artist != null) {
				Gtk.Label art_lab = new Gtk.Label("");
				set_proper_label_props(ref art_lab);
				art_lab.set_markup("<a href=\"%s\" title=\"%s\">%s</a>".printf("artist/" + release.artist.artistID.to_string(), 
																				Markup.escape_text(release.artist.name),
																				Markup.escape_text(BeatBox.String.ellipsize(release.artist.name, max_chars))));
				label_box.pack_start(art_lab, true, true, 0);
				art_lab.activate_link.connect(url_handler);
			}
			
			to_add.pack_start(label_box);
		}
		
		to_add.show_all();
		content.pack_start(to_add, false, false, 0);
	}
	
	void set_proper_label_props(ref Gtk.Label label) {
		label.xalign = 0.0f;
		label.yalign = 0.0f;
		label.set_line_wrap(true);
	}
	
	bool url_handler(string url) {
		if(url.has_prefix("artist/")) {
			int art_id = int.parse(url.replace("artist/", ""));
			Artist art = (Artist)object_map.get(art_id);
			
			var newView = new ArtistView(storeView, storeView.store, art);
			storeView.setView(newView);
			newView.populate();
		}
		else if(url.has_prefix("release/")) {
			int release_id = int.parse(url.replace("release/", ""));
			Release rel = (Release)object_map.get(release_id);
			
			if(rel == null)
				message("rel is null");
			else if(rel.artist == null)
				message("rel.artist is null");
			
			var newView = new AlbumView(storeView, storeView.store, rel);
			storeView.setView(newView);
			newView.populate();
		}
		else if(url.has_prefix("tag/")) {
			string tag_id = url.replace("tag/", "");
			
			var newView = new TagView(storeView, storeView.store, tag_id);
			storeView.setView(newView);
			newView.populate();
		}
		
		return true;
	}
}
