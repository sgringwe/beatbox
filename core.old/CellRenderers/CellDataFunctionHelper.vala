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

using Gtk;
using Gdk;

public class BeatBox.CellDataFunctionHelper : GLib.Object {
	FastList view;
	public bool is_mixed;
	int icon_column;
	
	private Pixbuf _canvas;
	private Pixbuf? not_starred;
	private Pixbuf? starred;
	
	public CellDataFunctionHelper(FastList view, bool is_mixed, int icon_column, Gdk.Pixbuf? starred, Gdk.Pixbuf? not_starred) {
		this.view = view;
		this.is_mixed = is_mixed;
		this.icon_column = icon_column;
		this.starred = starred;
		this.not_starred = not_starred;
		
		if(starred != null && not_starred != null)
			_canvas = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, starred.width * 5, starred.height);
	}
	
	public void toggleColumnFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);
		
		bool check = val.get_boolean();
		
		((CellRendererToggle)cell).active = check;
	}
	
	/** For spinner/unique icon on each row **/
	public void iconDataFunc(CellLayout layout, CellRenderer renderer, TreeModel model, TreeIter iter) {
		bool showIndicator = false;
		Media s = view.get_media_from_index((int)iter.user_data);
		
		if(s == null)
			return;
		else
			showIndicator = s.showIndicator;

		if(renderer is CellRendererPixbuf) {
			Value? icon;
			model.get_value (iter, icon_column, out icon); // ICON column is same for all

			/* Themed icon */
			(renderer as CellRendererPixbuf).follow_state = true;
			(renderer as CellRendererPixbuf).gicon = (icon as GLib.Icon);

			renderer.visible = !showIndicator;
			renderer.width = showIndicator ? 0 : 16;
		}
		if(renderer is CellRendererSpinner) {
			if(showIndicator) {
				((CellRendererSpinner)renderer).active = true;
			}
				
			renderer.visible = showIndicator;
			renderer.width = showIndicator ? 16 : 0;
		}
	}
	
	// for Track, Year, #, Plays, Skips. Simply shows nothing if less than 1.
	public void intelligentTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Media s = view.get_media_from_index((int)iter.user_data);
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);
		
		if(s == null || val.get_int() <= 0) {
			((CellRendererText)cell).text = "";
			return;
		}
		
		string text = val.get_int().to_string();
		if(s.isTemporary && is_mixed)
			((CellRendererText)cell).markup = "<i>" + text + "</i>";
		else
			((CellRendererText)cell).text = text;
	}
	
	public void stringTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Media s = view.get_media_from_index((int)iter.user_data);
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);
		
		if(s == null || val.get_string() == null) {
			((CellRendererText)cell).text = "";
			return;
		}
		
		if(s.isTemporary && is_mixed)
			((CellRendererText)cell).markup = "<i>" + Markup.escape_text(val.get_string()) + "</i>";
		else
			((CellRendererText)cell).text = val.get_string();
	}
	
	// for Bitrate. BeatBox.App.nd 'kbps'
	public void bitrateTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);
		
		if(val.get_int() <= 0)
			((CellRendererText)cell).markup = "";
		else
			((CellRendererText)cell).markup = val.get_int().to_string() + _(" kbps");
	}
	
	// turns int of seconds into pretty length mm:ss format
	public void lengthTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Media s = view.get_media_from_index((int)iter.user_data);
		if(s == null || s.length <= 0) {
			((CellRendererText)cell).text = "";
			return;
		}
		
		string text = (s.length / 60).to_string() + ":" + (((s.length % 60) >= 10) ? (s.length % 60).to_string() : ("0" + (s.length % 60).to_string()));
		
		if(s.isTemporary && is_mixed)
			((CellRendererText)cell).markup = "<i>" + text + "</i>";
		else
			((CellRendererText)cell).text = text;
	}
	
	// turns seconds since Jan 1, 1970 into date format
	public void dateTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);
		
		if(val.get_int() <= 0)
			((CellRendererText)cell).markup = "";
		else {
			var t = Time.local(val.get_int());
			string rv = t.format("%m/%e/%Y %l:%M %p");
			((CellRendererText)cell).markup = rv;
		}
	}
	
	// turns int of seconds into pretty length mm:ss format
	public void priceTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Media s = view.get_media_from_index((int)iter.user_data);
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);
		
		string price = val.get_string();
		if(s == null || price == null) {
			((CellRendererText)cell).text = "N/A";
			return;
		}
		
		if(s.isTemporary && is_mixed)
			((CellRendererText)cell).markup = "<i>" + price + "</i>";
		else
			((CellRendererText)cell).text = price;
	}
	
	public void ratingTreeViewFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Value val;
		tree_model.get_value(iter, tvc.sort_column_id, out val);
		
		if(val.get_int() == 0 || starred == null || not_starred == null) {
			((CellRendererPixbuf)cell).pixbuf = null;
		}
		else {
			_canvas.fill((uint) 0xffffff00);
			
			/* generate the canvas image */
			for (int i = 0; i < 5; i++) {
				if (i < val.get_int()) {
					starred.copy_area(0, 0, starred.width, starred.height, _canvas, i * starred.width, 0);
				}
			}
			
			((CellRendererPixbuf)cell).pixbuf = _canvas;
		}
	}
}
