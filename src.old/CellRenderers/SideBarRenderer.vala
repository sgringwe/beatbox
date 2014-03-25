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

public class BeatBox.SideBarRenderer : CellRenderer {
	public TreeModel model;
	public TreeIter iter;
	public bool expanded;
	public bool highlight;
	public static int EXPANDER_SIZE = 8;
	public static int DEPTH_INDENT_SIZE = 8;
	public static int PIXBUF_SIZE = 18;
	
	public SideBarRenderer() {
		expanded = false;
	}
	
	public override void get_size(Widget widget, Rectangle? cell_area, out int x_offset, out int y_offset, out int width, out int height) {
		x_offset = 0;
		y_offset = 0;
		width = -1;
		int dumby;
		widget.create_pango_layout("Test").get_pixel_size(out dumby, out height);
		height += 4; // 1 px extra on each side for the text
	}
	
	public override void render(Cairo.Context context, Widget widget, Rectangle background_area, Rectangle cell_area, CellRendererState flags) {
		Gdk.cairo_rectangle (context, background_area);
		context.clip();
		
		StateFlags state;
		RGBA rgba;
		Pango.Layout layout; // for text to draw
		Pixbuf pix;
		string text;
		int children;
		int depth;
		Pixbuf clickable;
		bool rtl; // right to left
		
		model.get(iter, SideBarColumn.COLUMN_PIXBUF, out pix, SideBarColumn.COLUMN_TEXT, out text, SideBarColumn.COLUMN_CLICKABLE, out clickable);
		TreePath path = model.get_path(iter);
		depth = path.get_depth();
		layout = widget.create_pango_layout(text);
		children = model.iter_n_children(iter);
		
		int flag = flags & Gtk.CellRendererState.SELECTED;
		state = (flag != 0 && depth != 1) ? StateFlags.SELECTED : StateFlags.NORMAL;
		
		rgba = widget.get_style_context().get_color (state);
		rtl = widget.get_direction() == Gtk.TextDirection.RTL;
		
		// Draw a blank space for each level of indent
		double start_x = depth * DEPTH_INDENT_SIZE;
		double start_y = cell_area.y + 2;
		if(rtl)
			start_x = cell_area.width - start_x;
		
		// Draw picture if it is not level 1
		if(depth != 1 && pix != null) {
			context.move_to(start_x, start_y);
			int image_y = (cell_area.height - pix.height > 0) ? ((cell_area.height - pix.height)/2) : 0;
			Gdk.cairo_set_source_pixbuf(context, pix, (int)start_x, cell_area.y + image_y);
			context.paint();
			
			start_x += rtl ? -20.0 : 20.0; // for rtl, move to the left. otherwise move to right
		}
		
		// Draw text
		context.set_source_rgba (rgba.red, rgba.green, rgba.blue, rgba.alpha);
		
		if(depth > 1)
			layout.set_text(text, text.length);
		else
			layout.set_markup("<b>" + text + "</b>", -1);
			
		if(rtl)
			layout.set_alignment(Pango.Alignment.RIGHT);
		
		Pango.Rectangle ink;
		Pango.Rectangle extents;
		layout.get_extents(out ink, out extents);
		Pango.extents_to_pixels(ink, extents);
		
		context.move_to(rtl ? (start_x - extents.width + 10) : start_x, start_y);
		Pango.cairo_show_layout(context, layout);
		context.fill();
		
		// If it is supposed to be highlighted, draw the highlight
		if(highlight) {
			draw_highlight(context, background_area.x, background_area.y, 
							background_area.width, background_area.height);
		}
		
		// Draw the expander
		if(depth == 1 && children > 0) {
			int far_right = cell_area.x + cell_area.width;
			
			if(expanded)
				widget.get_style_context().set_state(StateFlags.ACTIVE);
			else
				widget.get_style_context().set_state(StateFlags.NORMAL);
			
			widget.get_style_context().render_expander(context, rtl ? cell_area.x : far_right - EXPANDER_SIZE,
		                                           cell_area.y + 8 / 2, 8.0, 8.0);
		}
		                         
		                         
		context.fill();
	}
	
	void draw_highlight(Cairo.Context context, double x, double y, double width, double height) {
		double aspect        = 1.0;     /* aspect ratio */
		double corner_radius = (height * 2) / 10.0;   /* and corner curvature radius */

		double radius = corner_radius / aspect;
		double degrees = 3.14 / 180.0;

		context.new_sub_path();
		context.arc (x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees);
		context.arc (x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees);
		context.arc (x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees);
		context.arc (x + radius, y + radius, radius, 180 * degrees, 270 * degrees);
		context.close_path();
		
		context.set_source_rgba (0.0, 0.3, 1.0, 0.1);
		context.fill_preserve ();
		context.set_source_rgb (0.0, 0.0, 1);
		context.set_line_width (3.0);
		context.stroke ();
	}
}
