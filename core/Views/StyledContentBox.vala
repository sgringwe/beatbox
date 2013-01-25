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
using Gee;

public class BeatBox.StyledContentBox : ScrolledWindow {
	static CssProvider style_provider;
	private const string WIDGET_STYLESHEET = """
        .NowPlayingPage {
			background-image: -gtk-gradient (linear,
                                               left top, left bottom,
                                               from (shade (#ffffff, 1.05)),
                                               to (#ffffff));
            border: 0;
            -unico-outer-stroke-style: none;
        }
        
        .AlbumSongList {
			/*background-color: rgba(0, 0, 0, 0);*/
			padding: 0;
			/*box-shadow: 10px 10px rgba(0, 0, 0, 0.4);*/
		}
		
		.AlbumSongList row:selected {
			/*background-image: -gtk-gradient (linear,
			                                 left top,
			                                 left bottom,
			                                 from (shade (@selected_bg_color, 1.20)),
			                                 to (shade (@selected_bg_color, 0.98)));*/
		}
		
		.gray {
			background-image: -gtk-gradient (linear,
                                             left top, 
                                             left bottom,
                                             from (shade (#d5d3d1, 1.00)),
                                             to (shade (#d5d3d1, 0.95)));
		}
		
		.black {
			background-image: -gtk-gradient (linear,
                                               left top, left bottom,
                                               from (shade (#383838, 1.05)),
                                               to (#383838));
		}
		.padding {
			padding: 6px;
		}
		
		.white {
			background-image: -gtk-gradient (linear,
                                               left top, left bottom,
                                               from (shade (#f8f8f8, 1.05)),
                                               to (#f8f8f8));
		}
		
		.pure_white {
			background-color: #fff;
			background-image: none;
		}
		
		.white_text {
			color: shade(#f0f0f0, 1.01);
			text-shadow: 1 1 0 alpha(#f8f8f8, 0.3);
		}
		""";
	
	EventBox ebox;
	
	public StyledContentBox() {
		ebox = new EventBox();
		Viewport vp = new Viewport(null, null);
		
		// Apply styling
		if(style_provider == null) {
			style_provider = new CssProvider();
			try  {
				style_provider.load_from_data (WIDGET_STYLESHEET, -1);
			} catch (Error e) {
				stderr.printf ("\nNowPlayingPage: Couldn't load style provider.\n");
			}
		}
		
		set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		vp.get_style_context().add_class("NowPlayingPage");
		vp.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
        ebox.get_style_context().add_class("NowPlayingPage");
		ebox.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		vp.set_shadow_type(ShadowType.NONE);
		
		vp.add(ebox);
		add(vp);
	}
	
	public void set_content(Widget w) {
		ebox.add(w);
	}
}
