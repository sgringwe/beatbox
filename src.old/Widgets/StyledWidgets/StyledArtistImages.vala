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
using Gtk;

public class BeatBox.StyledArtistImages : EventBox {
	const string api = "YOFT4SZFVZLZZ1SVT";
	const int HEIGHT = 128;
	const int MAX_IMAGES = 15;
	static CssProvider style_provider;
	
	string current_artist;
	LinkedList<string> image_urls;
	LinkedList<Gdk.Pixbuf> images;
	Gdk.Pixbuf canvas;
	
	private const string WIDGET_STYLESHEET = """
        .NowPlayingView {
			background-image: -gtk-gradient (linear,
                                               left top, left bottom,
                                               from (shade (#ffffff, 1.05)),
                                               to (#ffffff));
        }
        
        .AlbumSongList {
			background-color: rgba(0, 0, 0, 0);
			padding: 0;
			/*box-shadow: 10px 10px rgba(0, 0, 0, 0.4);*/
		}
		
		.pure_white {
			background-color: #fff;
			background-image: none;
		}
    """;
	
	public StyledArtistImages(Gtk.StyleContext? context) {
		image_urls = new LinkedList<string>();
		images = new LinkedList<Gdk.Pixbuf>();
		
		// Add the notebook to the viewport
		if(style_provider == null) {
			style_provider = new CssProvider();
			try  {
				style_provider.load_from_data (WIDGET_STYLESHEET, -1);
			} catch (GLib.Error e) {
				stderr.printf ("\nStyledArtistImage: Couldn't load style provider.\n");
			}
		}
		
        get_style_context().add_class("pure_white");
		get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		
		/*Gdk.RGBA color = context.get_background_color(Gtk.StateFlags.NORMAL);
		override_background_color(Gtk.StateFlags.NORMAL, color);
        override_background_color(Gtk.StateFlags.ACTIVE, color);
        override_background_color(Gtk.StateFlags.PRELIGHT, color);
		*/
		width_request = -1;
		height_request = HEIGHT;
		//set_above_child(true);
        //set_visible_window(false);
		
		canvas = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, 1, 1);
		canvas.fill((uint) 0x00000000);
		
		draw.connect(exposeEvent);
	}
	
	public void clear() {
		image_urls = new LinkedList<string>();
		images = new LinkedList<Gdk.Pixbuf>();
		current_artist = "";
		
		update_canvas();
	}
	
	bool exposeEvent(Cairo.Context cairo) {
        Allocation al;
        get_allocation(out al);
		
		Gdk.cairo_set_source_pixbuf(cairo, canvas, 0, 0);
        cairo.paint();

        return true;
    }
	
	public void fetch_images(string artist) {
		if(artist.down() == current_artist.down()) {
			message("Not refetching artist images for song with same artist tag\n");
			return;
		}
		
		current_artist = artist;
		
		image_urls = new LinkedList<string>();
		images = new LinkedList<Gdk.Pixbuf>();
		
		try {
			new Thread<void*>.try (null, fetch_thread_function);
		} catch(Error err) {
			warning ("Could not create thread to load artist pixbuf's: %s", err.message);
		}
	}
	
	private void* fetch_thread_function () {
		var url = "http://developer.echonest.com/api/v4/artist/images?api_key=" + api + "&name=" + 
				  BeatBox.LastFMCore.fix_for_url(current_artist) + "&format=xml&start=0&results=15";
		
		message("Parsing artist images at %s\n", url);
		Xml.Doc* doc = Xml.Parser.parse_file(url);
		parse_doc(doc);
		
		Idle.add( () => {
			load_pixbufs.begin();
			
			return false;
		});
		
		return null;
	}
	
	void update_canvas() {
		if(images.size > 0) {
			int total_width = 0;
			var scaled_images = new LinkedList<Gdk.Pixbuf>();
			foreach(var pix in images) {
				//var scaled_pix = pix.scale_simple((int)((double)pix.width * (double)(70.0 / (double)pix.height)), 70, Gdk.InterpType.BILINEAR);
				total_width += pix.width;
				scaled_images.add(pix);
			}
			
			width_request = total_width + (6 * (scaled_images.size - 1));
			height_request = HEIGHT;
			
			canvas = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, width_request, height_request);
			canvas.fill((uint) 0x00000000);
			
			int x = 0;
			foreach(var pix in scaled_images) {
				pix.copy_area(0, 0, pix.width, pix.height, canvas, x, 0);
				x += pix.width + 6;
			}
		}
		else {
			width_request = -1;
			height_request = HEIGHT;
			
			canvas = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, 1, 1);
			canvas.fill((uint) 0x00000000);
		}
		
		queue_draw();
	}
	
	void parse_doc(Xml.Doc* doc) {
		if (doc == null) {
            return;
        }

        // Get the root node.
        Xml.Node* root = doc->get_root_element ();
        if (root == null) {
            delete doc;
            return;
        }
        
        // Let's parse those nodes
        parse_node (root, "");
        
        // Free the document
        delete doc;
	}
	
	private void parse_node (Xml.Node* node, string parent) {
        // Loop over the passed node's children
        for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
            // Spaces between tags are also nodes, discard them
            if (iter->type != Xml.ElementType.ELEMENT_NODE) {
                continue;
            }
			
            string node_name = iter->name;
            string node_content = iter->get_content ();
            
            if(parent == "imagesimage") {
				if(node_name == "url") {
					image_urls.add(node_content);
				}
			}
			
            // Followed by its children nodes
            parse_node (iter, parent + node_name);
        }
    }
    
	async void load_pixbufs() {
		images = new LinkedList<Gdk.Pixbuf>();
		
		foreach(var url in image_urls) {
			uri_to_pixbuf(url);
		}
	}
	
	async void uri_to_pixbuf(string image_uri) {
		GLib.File file = GLib.File.new_for_uri(image_uri);
		if(file == null) {
			stdout.printf("Could not read image_uri as file\n");
			return;
		}
		
		FileInputStream filestream;
		Gdk.Pixbuf? pix = null;
		
		/*try {
			filestream = yield file.read_async();
			pix = yield new Gdk.Pixbuf.from_stream_at_scale_async(filestream, -1, HEIGHT, true);
		} catch(GLib.Error err) {
			debug("Failed to load artist image from %s: %s\n", image_uri, err.message);
		}*/
		
		if(pix != null && current_artist != "") {
			images.add(pix);
			update_canvas();
		}
	}
}
