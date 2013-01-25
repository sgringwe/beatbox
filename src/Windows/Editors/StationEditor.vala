/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

using Gtk;
using Gee;
using Granite;

public class BeatBox.StationEditor : Object, MediaEditorInterface {
	private Box horiz; // separates text with numerical editors
	private Box textVert; // separates text editors
	private Box numerVert; // separates numerical editors
	
	private HashMap<string, FieldEditor> fields;// a hashmap with each property and corresponding editor
	
	public StationEditor() {
		fields = new HashMap<string, FieldEditor>();
	}
	
	public Collection<FieldEditor> get_fields() {
		return fields.values;
	}
	
	public Viewport get_metadata_view(Collection<Media> originals) {
		Viewport rv = new Viewport(null, null);
		fields = new HashMap<string, FieldEditor>();
		Media sum = originals.to_array()[0].copy();
		
		/** find what these stations have what common, and keep those values **/
		foreach(Media s in originals) {
			if(s.title != sum.title) // station name
				sum.title = "";
			if(s.genre != sum.genre) // category
				sum.genre = "";
			if(s.rating != sum.rating)
				sum.rating = 0;
		}
		
		fields.set("Station", new FieldEditorImpl.for_string(_("Station"), sum.title));
		fields.set("Genre", new FieldEditorImpl.for_string(_("Genre"), sum.genre));
		fields.set("Rating", new FieldEditorImpl.for_rating(_("Rating"), (int)sum.rating));
		
		horiz = new Box(Orientation.HORIZONTAL, 0);
		textVert = new Box(Orientation.VERTICAL, 0);
		numerVert = new Box(Orientation.VERTICAL, 0);
		
		textVert.pack_start(fields.get("Station"), false, true, 0);
		textVert.pack_start(fields.get("Genre"), false, true, 5);
		
		fields.get("Station").set_width_request(300);
		fields.get("Genre").set_width_request(300);
		
		numerVert.pack_start(fields.get("Rating"), false, true, 5);
		
		horiz.pack_start(UI.wrap_alignment(textVert, 0, 30, 0, 0), false, true, 0);
		horiz.pack_end(numerVert, false, true, 0);
		rv.add(horiz);
		
		return rv;
	}
	
	public HashMap<string, Viewport> get_extra_views() {
		var rv = new HashMap<string, Viewport>();
		
		return rv;
	}
	
	public void change_media(Media sum) {
		fields.get("Station").set_value(sum.title);
		fields.get("Genre").set_value(sum.genre);
		fields.get("Rating").set_value((int)sum.rating);
	}
	
	public void save_medias(Collection<Media> medias) {
		foreach(Media s in medias) {
			if(fields.get("Station").checked())
				s.title = fields.get("Station").get_value().get_string();
			if(fields.get("Genre").checked())
				s.genre = fields.get("Genre").get_value().get_string();
			if(fields.get("Rating").checked())
				s.rating = fields.get("Rating").get_value().get_int();
		}
		
		App.library.station_library.update_medias(medias, true, true, true);
	}
}
