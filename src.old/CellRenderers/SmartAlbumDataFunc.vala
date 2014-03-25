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

public class BeatBox.SmartAlbumDataFunc : GLib.Object {
	FastList view;
	
	public SmartAlbumDataFunc(FastList view) {
		this.view = view;
	}
	
	// for Smart album column
	public void smartAlbumFiller(TreeViewColumn tvc, CellRenderer cell, TreeModel tree_model, TreeIter iter) {
		Media m = view.get_media_from_index((int)iter.user_data);
		
		((SmartAlbumRenderer)cell).m = m;
		
		if(BeatBox.App.covers.get_album_art_from_media(m) != null) {
			int top; int bottom; int current; int range;
			
			current = (int)iter.user_data;
			for(top = current; top >= 0; --top) {
				if(view.get_media_from_index(top).album != m.album) {
					++top;
					break;
				}
				else if(top == 0) {
					break;
				}
			}
			for(bottom = current; bottom < view.get_visible_table().size(); ++bottom) {
				if(view.get_media_from_index(bottom).album != m.album) {
					--bottom;
					break;
				}
			}
			range = (bottom - top) + 1;
			//stdout.printf("range is %d, top is %d, bottom is %d, current is %d\n", range, top, bottom, current);
			
			// We have enough space to draw art
			if(range >= 9) {
				((SmartAlbumRenderer)cell).icon = BeatBox.App.covers.get_album_art_from_media(m);
				((SmartAlbumRenderer)cell).top = top;
				((SmartAlbumRenderer)cell).bottom = bottom;
				((SmartAlbumRenderer)cell).current = current;
				cell.xalign = 0.5f;
			}
			else {
				((SmartAlbumRenderer)cell).icon = null;
				cell.xalign = 0f;
			}
		}
		else {
			cell.xalign = 0f;
			((SmartAlbumRenderer)cell).icon = null;
		}
	}
}
