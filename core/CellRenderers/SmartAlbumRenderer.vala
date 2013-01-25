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

public class BeatBox.SmartAlbumRenderer : CellRendererText {

    /* icon property set by the tree column */
    public Gdk.Pixbuf icon { get; set; }
    public Media m;
    public int top; // first row of consecutive songs of album
    public int bottom; // last row of consecutive songs of album
    public int current; // current row of consecutive songs of album

    public SmartAlbumRenderer () {
        //this.icon = new Gdk.Pixbuf();
    }

    /* get_size method, always request a 50x50 area */
    public override void get_size (Widget widget, Gdk.Rectangle? cell_area,
                                   out int x_offset, out int y_offset,
                                   out int width, out int height)
    {
        x_offset = 0;
        y_offset = 0;
        width = -1;
        height = -1;
    }

    /* render method */
    public override void render (Cairo.Context ctx, Widget widget,
                                 Gdk.Rectangle background_area,
                                 Gdk.Rectangle cell_area,
                                 CellRendererState flags)
    {
        if (icon != null) {
			int art_start = 1; // the row that art starts
            var index = current - top;
			Gdk.Pixbuf slice = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, icon.width, background_area.height);
			slice.fill (0x00000000);
			var remaining_height = (icon.height - ((index - art_start) * background_area.height));
			
			/*if(index == 0) {
				Gdk.cairo_rectangle (ctx, background_area);
				int width = background_area.width;
				int height = background_area.height;
				int x = background_area.x;
				int y = background_area.y;
				
				var buffer_surface = new Granite.Drawing.BufferSurface (width, height);
				
				// First paint part of art
				icon.copy_area (0, (index * background_area.height) + ( (index != 0) ? extra_space : 0), 
								icon.width, (remaining_height < background_area.height) ? remaining_height - extra_space : background_area.height, 
								slice, 0, 0);
				var middle = (background_area.width < icon.width) ? 
								background_area.x : (background_area.x + (background_area.width - icon.width) / 2);
				
				Gdk.cairo_set_source_pixbuf (buffer_surface.context, slice, middle, background_area.y + ( (index == 0) ? -extra_space : 0));
				buffer_surface.context.paint();
				
				// Now draw shadow
				buffer_surface.context.rectangle (0, 0, width, 1);
				buffer_surface.context.set_source_rgba (0, 0, 0, 0.8);
				buffer_surface.context.fill();
				buffer_surface.fast_blur(2, 3);
				buffer_surface.context.paint();
				Gdk.cairo_set_source_pixbuf (ctx, buffer_surface.load_to_pixbuf(), x, y);
			}
			
			else */
			
			if(index == 0) {
				text = m.album;// = CellDataFunctionHelper.validate_markup(m.album);
				base.render(ctx, widget, background_area, cell_area, flags);
			}
			/*else if(index == 1) {
				if(m.year != 0)
					markup = "<span size=\"x-small\">" + m.year.to_string() + "</span>";
				else
					markup = "";
				
				base.render(ctx, widget, background_area, cell_area, flags);
			}*/
			else if(remaining_height > 0) {
				Gdk.cairo_rectangle (ctx, background_area);
				icon.copy_area (0, ((index - art_start) * background_area.height)/* + ( ((index - art_start) != 0) ? extra_space : 0)*/, 
								icon.width, (remaining_height < background_area.height) ? remaining_height/* - extra_space */: background_area.height, 
								slice, 0, 0);
				var middle = (background_area.width < icon.width) ? 
								background_area.x : (background_area.x + (background_area.width - icon.width) / 2);
				
				Gdk.cairo_set_source_pixbuf (ctx, slice, middle, background_area.y/* + ( ((index - art_start) == 0) ? -extra_space : 0)*/);
			}
			
			/*if(remaining_height > 0) {
				Gdk.cairo_rectangle (ctx, background_area);
				icon.copy_area (0, (index * background_area.height) + ( (index != 0) ? extra_space : 0), 
								icon.width, (remaining_height < background_area.height) ? remaining_height - extra_space : background_area.height, 
								slice, 0, 0);
				var middle = (background_area.width < icon.width) ? 
								background_area.x : (background_area.x + (background_area.width - icon.width) / 2);
				
				Gdk.cairo_set_source_pixbuf (ctx, slice, middle, background_area.y + ( (index == 0) ? -extra_space : 0));
			}
			else if(-remaining_height < background_area.height) { // first row after image
				text = m.album;// = CellDataFunctionHelper.validate_markup(m.album);
				base.render(ctx, widget, background_area, cell_area, flags);
			}
			else if(-remaining_height < background_area.height * 2) { // second row after image
				if(m.year != 0)
					markup = "<span size=\"x-small\">" + m.year.to_string() + "</span>";
				else
					markup = "";
				
				base.render(ctx, widget, background_area, cell_area, flags);
			}
			else if(-remaining_height < background_area.height * 3) { // second row after image
				// rating goes here
			}*/
		}
		else {
			text = m.album;
			base.render(ctx, widget, background_area, cell_area, flags);
		}
		
		ctx.fill();
    }
}
