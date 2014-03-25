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


#if USE_GRANITE_DECORATED_WINDOW
public class BeatBox.PopupListView : Granite.Widgets.DecoratedWindow {
#else
public class BeatBox.PopupListView : Gtk.Window {
#endif

	public const int MIN_SIZE = 400;
	
	SourceView view_wrapper;

	Gtk.Label album_label;
	Gtk.Label artist_label;
	BeatBox.RatingWidget rating;

	MusicList list;

	public PopupListView (SourceView parent_wrapper) {
#if USE_GRANITE_DECORATED_WINDOW
        base ("", "album-list-view", "album-list-view");
#else

#endif
		this.view_wrapper = parent_wrapper;

		set_size_request (MIN_SIZE, MIN_SIZE);
		set_default_size (MIN_SIZE, MIN_SIZE);

        // Make the window squared
        this.size_allocate.connect ( (alloc) => {
    		int width = alloc.width;
    		int height = alloc.height;

            int size = (width > height) ? width : height;

    		set_size_request (size, size);
        });

		set_transient_for (App.window);
		destroy_with_parent = true;
		set_skip_taskbar_hint (true);
		set_resizable(false);

#if !USE_GRANITE_DECORATED_WINDOW
		window_position = Gtk.WindowPosition.CENTER_ON_PARENT;

		// window stuff
		set_decorated(false);
		set_has_resize_grip(false);

		// close button
		var close = new Gtk.Button ();
        get_style_context ().add_class ("album-list-view");
		close.get_style_context().add_class("close-button");
		close.set_image (Icons.render_image ("window-close-symbolic", Gtk.IconSize.MENU));
		close.hexpand = close.vexpand = false;
		close.halign = Gtk.Align.START;
		close.set_relief(Gtk.ReliefStyle.NONE);
		close.clicked.connect( () =>  { this.hide(); });
#else
        // Don't destroy the window
		this.delete_event.connect (hide_on_delete);

        // Hide titlebar (we want to set a title, but not showing it!)
        this.show_title = false;
#endif
		// album artist/album labels
		album_label = new Label ("");
		artist_label = new Label ("");

		// Apply special style: Level-2 header
		UI.apply_style_to_label (album_label, UI.TextStyle.H2);

		album_label.ellipsize = Pango.EllipsizeMode.END;
		artist_label.ellipsize = Pango.EllipsizeMode.END;

		album_label.set_line_wrap (false);
		artist_label.set_line_wrap (false);
		
		album_label.set_max_width_chars (30);
		artist_label.set_max_width_chars (30);

		album_label.margin_left = album_label.margin_right = 12;
		artist_label.margin_bottom = 12;

		// add actual list
		var tvs = new TreeViewSetup(MusicColumn.ARTIST, SortType.ASCENDING, TreeViewSetup.Hint.ALBUM_LIST);
		list = new MusicList(tvs);
		list.set_sort_column_id(tvs.sort_column_id, tvs.sort_direction);
        var list_scrolled = new Gtk.ScrolledWindow (null, null);
        list_scrolled.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        list_scrolled.add (list);

		// Rating widget
		rating = new BeatBox.RatingWidget (true, IconSize.MENU, true);
		// customize rating
		rating.set_star_spacing (16);
		rating.margin_top = rating.margin_bottom = 16;

		// Add everything
		var vbox = new Box(Orientation.VERTICAL, 0);

#if !USE_GRANITE_DECORATED_WINDOW
		vbox.pack_start (close, false, false, 0);
#endif

		vbox.pack_start (album_label, false, true, 0);
		vbox.pack_start (artist_label, false, true, 0);
		vbox.pack_start (list_scrolled, true, true, 0);
		vbox.pack_start (rating, false, true, 0);

		add(vbox);

		rating.rating_changed.connect(rating_changed);
        App.library.medias_updated.connect (update_album_rating);
#if !USE_GRANITE_DECORATED_WINDOW
		/* Make window draggable */
		UI.make_window_draggable (this);
#endif
	}


	/**
	 * Resets the window
	 */
	public void reset () {
		// clear labels
		set_title ("");
		album_label.set_label ("");
		artist_label.set_label ("");

		// clear treeview and media list
        list.get_selection ().unselect_all (); // Unselect rows
        list.set_table (new HashTable<int, Media> (null, null));

		// Reset size request
		set_size (MIN_SIZE);
	}

    public void set_size (int size) {
        this.set_size_request (size, size);
    }


	public void set_parent_wrapper (SourceView parent_wrapper) {
		this.view_wrapper = parent_wrapper;
		this.list.set_parent_wrapper (parent_wrapper);
	}

	Mutex setting_media;

	//@param o Either Album, Artist, or Genre
	public void set_items(Object o) {
	    setting_media.lock ();

        reset ();

		Collection<Media> songs = new Gee.LinkedList<Media> ();

		if (o is Album) {
			var a = o as Album;
			songs = a.get_medias ();
			var album = a.get_album ();
			var artist = a.get_album_artist ();
			album_label.set_label (album);
			artist_label.set_label (artist);
       		set_title (_("%s by %s").printf (album, artist));
		}
		/*else if(o is Artist) {
			Artist a = (Artist)o;
			songs = a.get_medias();
			artist_label.set_markup("<span color=\"#ffffff\"><b>" + a.get_album_artist().replace("&", "&amp;") + "</b></span>");
			album_label.hide();
		}
		else { // if(o is Genre) {
			Genre g = (Genre)o;
			songs = g.get_medias();
			artist_label.set_markup("<span color=\"#ffffff\"><b>" + g.get_genre().replace("&", "&amp;") + "</b></span>");
			album_label.hide();
		}*/

		// decide rating. unless all are equal, show 0.
		var to_set = new HashTable<int, Media>(null, null);

        // FIXME: this is not ideal. Most of the time, we need to go from
        // a GLib.List or Gee.Collection to a HashTable in order to set the media,
        // so why on Earth isn't this internal to GenericList!!
        // SUGGESTION: GenericList :: set_media (Gee.Collection<Media> media);
		foreach (var m in songs) {
			to_set.set ((int)to_set.size(), m);
		}
		
		list.set_table(to_set);
        setting_media.unlock (); // UNLOCK

		// Set rating
		update_album_rating ();
	}

	void update_album_rating () {
		// We don't want to set the overall_rating as each media's rating.
		// See rating_changed() in case you want to figure out what would happen.
		rating.rating_changed.disconnect(rating_changed);

		// Use average rating for the album
		int total_rating = 0, n_media = 0;
		var media_list = list.get_table().get_values ();
		foreach (var media in media_list) {
			if (media == null)
				continue;
			n_media ++;
			total_rating += (int)media.rating;
		}

		float average_rating = (float)total_rating / (float)n_media;

		// fix approximation and set new rating
		rating.set_rating (Numeric.int_from_float (average_rating));

		// connect again ...
		rating.rating_changed.connect (rating_changed);
	}

	void rating_changed (int new_rating) {
		setting_media.lock ();

        var media_list = list.get_table().get_values ();
		var updated = new LinkedList<Media> ();
		foreach (var media in media_list) {
			if (media == null)
				continue;

			media.rating = (uint)new_rating;
			updated.add (media);
		}

		setting_media.unlock ();

		App.library.update_medias (updated, false, true, true);
	}

	public override void show_all () {

		// find window's location
		int x, y;
		Gtk.Allocation alloc;
		App.window.get_position (out x, out y);
		view_wrapper.get_allocation (out alloc);

		// move down to icon view's allocation
		x += App.window.get_sidebar_width();
		y += alloc.y;

		int window_width = 0;
		int window_height = 0;
		
		get_size (out window_width, out window_height);

		// center it on this icon view
		x += (alloc.width - window_width) / 2;
		y += (alloc.height - window_height) / 2 + 60;

		bool was_visible = visible;
		base.show_all ();

		if (!was_visible)
			move (x, y);

		present ();
	}
}
