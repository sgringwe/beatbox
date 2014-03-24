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
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

using Gtk;
using Granite.Widgets;
using Gee;

public abstract class BeatBox.SourceView : Box, View {
	/* MAIN WIDGETS (VIEWS) */
	ScrolledWindow 		 list_scroll    { get; private set; }
	ScrolledWindow		 album_scroll	{ get; private set; }
	public GenericList	 list_view      { get; protected set; }
	public GenericGrid	 album_view		{ get; protected set; }
	public EmbeddedAlert error_box      { get; protected set; }
	public Welcome       welcome_screen { get; protected set; }
	public PopupListView popup			{ get; protected set; }
	public Widget		 custom_widget	{ get; protected set; }

	private Notebook view_container; // Wraps all the internal views for super fast switching

	public enum SourceViewType {
		LIST    = 1,
		GRID	= 2,
		ERROR   = 3, // For error boxes
		WELCOME = 4, // For welcome screens
		NONE    = 5  // Custom views
	}

	public TreeViewSetup.Hint hint { get; protected set; }
	public int relative_id { get; protected set; }
	public TreeViewSetup tvs { get; protected set; }
	public string media_representation { get; protected set; }

	//public int index { get { return App.window.mainViews.page_num(this); } }
	public bool is_current_wrapper {
		get {
			return (App.window.get_current_view() == this);
		}
	}


	/* UI PROPERTIES */
	public bool have_list_view       { get { return list_view != null;      } }
	public bool have_album_view		 { get { return album_view != null;		} }
	public bool have_error_box       { get { return error_box != null;      } }
	public bool have_welcome_screen  { get { return welcome_screen != null; } }
	public bool have_custom_widget 	 { get { return custom_widget != null;	} }
	
	public bool have_media { get { return media_count > 0; } }
	protected Collection<Media> original_medias;
	HashTable<int, int> current_medias; // rowid, int
	
	Gee.HashMap<string, Album> album_keys; // helper

	/**
	 * MEDIA DATA
	 *
	 * These data structures hold information about the media shown in the views.
	 **/

	// ALL the media. Data source.
	protected Mutex in_update;
	public int media_count { get { return (list_view != null) ? (int)list_view.get_table().size() : 0; } }
	protected string last_search = "";
	protected string _artist_filter = "";
	protected string _album_filter = "";
	protected string _genre_filter = "";

	// Stops from searching unnecesarilly when changing b/w 0 words and search.
	private bool showing_all { get { return list_view.get_visible_table().size() == list_view.get_table().size(); } }
	public int showing_media_count { get { return (list_view != null) ? (int)list_view.get_visible_table().size() : 0; } }
	bool initialized;
	
	public string album_filter {
		get {
			return _album_filter;
		}
		set {
			if(_album_filter != value) {
				_album_filter = value;
				
				re_search();
			}
		}
	}
	
	public string artist_filter {
		get {
			return _artist_filter;
		}
		set {
			if(_artist_filter != value) {
				_artist_filter = value;
				
				re_search();
			}
		}
	}
	
	public string genre_filter {
		get {
			return _genre_filter;
		}
		set {
			if(_genre_filter != value) {
				_genre_filter = value;
				
				re_search();
			}
		}
	}
	
	public SourceView (Collection<Media> the_medias, TreeViewSetup tvs) {
		initialized = false;
		
		this.hint = tvs.get_hint();
		this.tvs = tvs;
		this.original_medias = the_medias;
		
		current_medias = new HashTable<int, int>(null, null); // rowid, int
		album_keys = new HashMap<string, Album>(null, null);
		
		_album_filter = "";
		_artist_filter = "";
		_genre_filter = "";
		
		set_orientation(Orientation.VERTICAL);
		
		// Setup container
		view_container = new Notebook ();
		view_container.show_tabs = false;
		view_container.show_border = false;
		this.pack_start (view_container, true, true, 0);

		initialized = true;
	}
	
	protected void pack_widgets() {
		if (have_error_box) {
			view_container.append_page (error_box);
		}

		if (have_welcome_screen) {
			view_container.append_page (welcome_screen);
		}

		if (have_list_view) {
			list_scroll = new ScrolledWindow(null, null);
			list_scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
			list_scroll.add(list_view);
			view_container.append_page (list_scroll);
			
			// Must do this after, so genericlist can setup vadjustment listeners
			list_view.set_parent_wrapper (this);
			
			// Set sort data from saved session
			list_view.set_sort_column_id(tvs.sort_column_id, tvs.sort_direction);
		}
		
		if(have_album_view) {
			album_scroll = new ScrolledWindow(null, null);
			album_scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
			album_scroll.add(album_view);
			view_container.append_page (album_scroll);
			
			// Must do this after, so genericgrid can setup vadjustment listeners
			album_view.set_parent_wrapper (this);
			
			popup = new PopupListView(this);
		}
	}

	// We only check for white space at the moment
	private bool get_is_valid_search_string (string s) {
		if (s.length < 1)
			return true;

		int white_space = 0;
		unichar c;

		for (int i = 0; s.get_next_char (ref i, out c);)
			if (c.isspace())
				++ white_space;

		if (white_space == s.length) {
			debug ("STRING '%s' IS WHITESPACE", s);
			return false;
		}

		return true;
	}
	
	/**
	 * Convenient visibility method
	 */
	protected void set_active_view (SourceViewType type, out bool successful = null) {
		int view_index = -1;
		
		// Find position in notebook
		switch (type) {
			case SourceViewType.LIST:
				if (have_list_view)
					view_index = view_container.page_num (list_scroll);
				break;
			case SourceViewType.GRID:
				if (have_album_view) {
					view_index = view_container.page_num (album_scroll);
				}
				break;
			case SourceViewType.ERROR:
				if (have_error_box)
					view_index = view_container.page_num (error_box);
				break;
			case SourceViewType.WELCOME:
				if (have_welcome_screen)
					view_index = view_container.page_num (welcome_screen);
				break;
		}

		// i.e. we're not switching the view if it is not available
		if (view_index < 0) {
			successful = false;
			return;
		}

		// Set view as current
		view_container.set_current_page (view_index);

		// Update BeatBox's toolbar widgets
		if(visible)
			update_library_window_widgets ();

		successful = true;
	}

	/**
	 * This method ensures that the view switcher and search box are sensitive/insensitive when they have to.
	 * It also selects the proper view switcher item based on the current view.
	 */
	protected void update_library_window_widgets () {
		if (!is_current_wrapper)
			return;
		
		App.window.update_sensitivities ();
	}
	
	protected abstract void set_default_warning();
	
	void set_search_warning () {
		if(!have_error_box)
			return;
		
		error_box.set_alert (_("No Results"), _("Your search query returned no results."), null, false, Gtk.MessageType.INFO);
	}
	
	protected void check_have_media () {
		if(have_media) {
			if(list_view.get_visible_table().size() > 0) {
				if(App.window.get_current_view_selection() == 0 || !have_album_view) {
					set_active_view(SourceViewType.LIST);
				}
				else {
					set_active_view(SourceViewType.GRID);
				}
			}
			else {
				set_search_warning ();
				set_active_view(SourceViewType.ERROR);
			}
		}
		else {
			if(hint == TreeViewSetup.Hint.MUSIC || hint == TreeViewSetup.Hint.PODCAST || hint == TreeViewSetup.Hint.STATION) {
				set_active_view(SourceViewType.WELCOME);
			}
			else {
				set_default_warning ();
				set_active_view(SourceViewType.ERROR);
			}
		}
	}

	public void set_statusbar_info() {
		if (!is_current_wrapper)
			return;

		if(showing_media_count == 0) {
			App.window.set_statusbar_info(hint, 0, 0, 0);
			return;
		}

		uint count = 0;
		uint total_time = 0;
		uint64 total_size = 0;
		foreach(Media media in list_view.get_visible_table().get_values()) {
			count ++;
			total_time += media.length;
			total_size += media.file_size;
		}

		App.window.set_statusbar_info(hint, count, total_size, total_time);
	}
	
	public void re_search() {
		if(have_list_view)
			list_view.do_search(null);
		if(have_album_view)
			album_view.do_search(null);
			
		update_library_window_widgets();
	}
	
	public void clear_filters () {
		_album_filter = "";
		_artist_filter = "";
		_genre_filter = "";
		
		re_search();
	}


	/**
	============================================================================
	                                  DATA STUFF
	 When x_medias is called, it decides whether or not to do the operation in
	 syncronous or asyncronous fashion. If this is the current wrapper, syncronous.
	 Otherwise asyncronous is used by waiting until the player is idle. The following
	 methods have sync and async options:
	 * add_medias
	 * update_medias
	 * remove_medias
	 * set_media
	============================================================================
	*/
	
	public void add_medias (Collection<Media> add) {
		if(true || is_current_wrapper) {
			add_medias_sync(add);
		}
		else {
			add_medias_async(add);
		}
	}
	
	private async void add_medias_async (Collection<Media> add) {
        var priority = Priority.DEFAULT_IDLE;
        Idle.add_full (priority, () => {
            add_medias_sync(add);
            return false;
        });
    }
	
	protected void add_medias_sync (Collection<Media> add) {
		if(!have_list_view && !have_album_view)
			return;
		
		in_update.lock (); // mutual exclusion
		Collection<Media> to_add = new LinkedList<Media>();
		if(hint == TreeViewSetup.Hint.MUSIC || hint == TreeViewSetup.Hint.PODCAST || hint == TreeViewSetup.Hint.STATION) { // See if it matches our type
			App.library.do_search (add, out to_add, null, null, null, null, hint, "");
		}
		else if(hint == TreeViewSetup.Hint.SMART_PLAYLIST) { // See if it matches rules
			to_add = App.playlists.playlist_from_id(relative_id).analyze(add);
		}
		
		// Add all that should be added
		var to_add_list = new GLib.List<Media>();
		var to_add_grid = new GLib.List<Album>();
		Album alb;
		foreach(var m in to_add) {
			if(current_medias.get(m.rowid) == 0) {
				current_medias.set(m.rowid, 1);
				string key = App.library.album_key(m);
				
				if(have_list_view) {
					to_add_list.append(m);
				}
				
				if(have_album_view) {
					if((alb = album_keys.get(key)) == null) {
						alb = new Album(m.album_artist, m.album);
						album_keys.set(key, alb);
						to_add_grid.append(alb);
					}
					alb.add_media(m);
				}
			}
		}
		
		if(have_list_view)
			list_view.add_medias(to_add_list);
		if(have_album_view)
			album_view.add_objects(to_add_grid);
		
		in_update.unlock ();
		
		update_library_window_widgets ();
		set_statusbar_info ();
		check_have_media ();
	}
	
	public void update_medias (Collection<Media> to_update, bool metadata_changed) {
		if(true || is_current_wrapper) {
			update_medias_sync(to_update, metadata_changed);
		}
		else {
			update_medias_async(to_update, metadata_changed);
		}
	}
	
	private async void update_medias_async (Collection<Media> to_update, bool metadata_changed) {
        var priority = Priority.DEFAULT_IDLE;
        Idle.add_full (priority, () => {
            update_medias_sync (to_update, metadata_changed);
            return false;
        });
    }
	
	private void update_medias_sync (Collection<Media> to_update, bool metadata_changed) {
		if(!have_list_view && !have_album_view)
			return;
			
		// for large updates (lots of media), go with "refresh" style.
		// this is faster, but refreshes the table losing selections
		if(to_update.size > 500) {
			remove_medias_sync (to_update);
			add_medias_sync (to_update);
		}
		
		// otherwise, do slower but smoother update
		else {
			in_update.lock ();
			
			Collection<Media> should_be = new LinkedList<Media>();
			if(hint == TreeViewSetup.Hint.SMART_PLAYLIST) {
				should_be = App.playlists.playlist_from_id(relative_id).analyze(to_update);
			}
			else if(hint == TreeViewSetup.Hint.MUSIC || hint == TreeViewSetup.Hint.PODCAST || hint == TreeViewSetup.Hint.STATION) {
				App.library.do_search (to_update, out should_be, null, null, null, null, hint);
			}
			else {
				should_be = to_update;
			}
			
			var to_add = new HashTable<Media, int>(null, null);
			var to_remove = new HashTable<Media, int>(null, null);
			
			// add elements that should be here
			foreach(var m in should_be) {
				if(current_medias.get(m.rowid) == 0) {
					to_add.set(m, 1);
				}
			}

			// remove elements
			foreach(Media m in to_update) {
				if(!should_be.contains(m)) {
					to_remove.set(m, 1);
				}
			}
			
			// if some additions or removals, combine existing, added, and new to make the new table
			if(to_remove.size() > 0 || to_add.size() > 0) {
				var new_list = new HashTable<int, Media>(null, null);
				var new_grid = new HashTable<int, Album>(null, null);
				
				// reset album_keys
				album_keys = new HashMap<string, Album>(null, null);
				Album alb;
				foreach(var m in list_view.get_table().get_values()) {
					if(to_remove.get(m) == 0) {
						current_medias.set(m.rowid, 1);
						string key = App.library.album_key(m);
						
						if(have_list_view) {
							new_list.set((int)new_list.size(), m);
						}
						
						if(have_album_view) {
							if((alb = album_keys.get(key)) == null) {
								alb = new Album(m.album_artist, m.album);
								album_keys.set(key, alb);
								new_grid.set((int)new_grid.size(), alb);
							}
							alb.add_media(m);
						}
					}
					else {
						current_medias.set(m.rowid, 0);
					}
				}
				foreach(var m in to_add.get_keys()) {
					if(current_medias.get(m.rowid) == 0) {
						current_medias.set(m.rowid, 1);
						string key = App.library.album_key(m);
						
						if(have_list_view) {
							new_list.set((int)new_list.size(), m);
						}
						
						if(have_album_view) {
							if((alb = album_keys.get(key)) == null) {
								alb = new Album(m.album_artist, m.album);
								album_keys.set(key, alb);
								new_grid.set((int)new_grid.size(), alb);
							}
							alb.add_media(m);
						}
					}
				}
				
				if(have_list_view) {
					if(to_remove.size() > 0 || to_add.size() > 0) {
						list_view.set_table(new_list, true);
					}
					else {
						list_view.resort(true);
					}
				}
				if(have_album_view) {
					album_view.set_table(new_grid, true);
				}
			}
			else {
				if(have_list_view)
					list_view.resort (true);
			}

			in_update.unlock ();
		}
		
		update_library_window_widgets ();
		set_statusbar_info ();
		check_have_media ();
	}
	
	public void remove_medias (Collection<Media> to_remove) {
		if(is_current_wrapper) {
			remove_medias_sync(to_remove);
		}
		else {
			remove_medias_async(to_remove);
		}
	}
	
	private async void remove_medias_async (Collection<Media> to_remove) {
        var priority = Priority.DEFAULT_IDLE;
        Idle.add_full (priority, () => {
            remove_medias_sync(to_remove);
            return false;
        });
    }
	
	private void remove_medias_sync (Collection<Media> to_remove) {
		if(!have_list_view && !have_album_view)
			return;
		
		in_update.lock ();
		
		var list_remove = new GLib.HashTable<Media, int>(null, null);
		var grid_remove = new GLib.HashTable<Object, int>(null, null);
		
		Album alb;
		foreach(Media m in to_remove) {
			current_medias.set(m.rowid, 0);
			string key = App.library.album_key(m);
			
			if(have_list_view) {
				list_remove.set(m, 1);
			}
			
			if(have_album_view) {
				if((alb = album_keys.get(key)) != null) {
					grid_remove.set(alb, 1);
					album_keys.unset(key);
				}
			}
		}

		// Now update the views to reflect the changes
		if(have_list_view)
			list_view.remove_medias(list_remove);
		if(have_album_view)
			album_view.remove_objects(grid_remove);
		
		in_update.unlock();
		
		update_library_window_widgets ();
		set_statusbar_info ();
		check_have_media ();
	}
	
	public void set_media (Collection<Media> new_media, bool update_grid = false) {
		if(true || is_current_wrapper) {
			set_media_sync(new_media, update_grid);
		}
		else {
			set_media_async(new_media, update_grid);
		}
	}
	
	private async void set_media_async (Gee.Collection<Media> new_media, bool update_grid = false) {
        int priority = Priority.DEFAULT_IDLE;

        // Populate playlists in order
        priority += relative_id;

        // lower priority
        if (hint == TreeViewSetup.Hint.SMART_PLAYLIST || hint == TreeViewSetup.Hint.PLAYLIST)
            priority += 10;

        Idle.add_full (priority, () => {
            set_media_sync (new_media);
            return false;
        });
    }

	protected void set_media_sync (Collection<Media> new_media, bool update_grid = false) {
		update_grid = true;
		if(have_list_view || have_album_view) {
			in_update.lock ();
			
			current_medias = new HashTable<int, int>(null, null); // rowid, int
			var media_list = new HashTable<int, Media>(null, null);
			var album_list = new HashTable<int, Album>(null, null);
			
			if(have_album_view) {
				album_keys = new Gee.HashMap<string, Album>();
			}
			
			Album alb;
			foreach(var m in new_media) {
				string key = App.library.album_key(m);
				current_medias.set(m.rowid, 1);
				
				if(have_list_view) {
					media_list.set((int)media_list.size(), m);
				}
				
				if(have_album_view) {
					if((alb = album_keys.get(key)) == null) {
						alb = new Album(m.album_artist, m.album);
						album_keys.set(key, alb);
						album_list.set((int)album_list.size(), alb);
					}
					alb.add_media(m);
				}
			}
			
			if(have_list_view)
				list_view.set_table(media_list);
			if(have_album_view)
				album_view.set_table(album_list);
			
			in_update.unlock ();
			
			set_statusbar_info ();
			check_have_media ();
			update_library_window_widgets ();
			
		}
	}
	
	/** The following functions are required by View interface, but are
	 * specific to the type of sourceview. Therefore, we require all specific
	 * sourceviews to implement them and that counts as us implementing View **/
	public abstract View.ViewType get_view_type();
	public abstract Object? get_object();
	public abstract Gdk.Pixbuf get_view_icon();
	public abstract string get_view_name();
	public abstract Gtk.Menu? get_context_menu();
	public abstract bool can_receive_drop();
	public abstract void drag_received(Gtk.SelectionData data);
	public abstract SideTreeCategory get_sidetree_category();
	protected abstract void pre_set_as_current_view();
	
	/** These functions are also required by View interface, but are the same
	 * for all sourceviews and are therefore implemented here **/
	public GLib.List<View> get_sub_views() {
		return new GLib.List<View>(); // No sources have sub views
	}
	
	public void set_as_current_view () {
		pre_set_as_current_view();
		
		update_library_window_widgets ();
		set_statusbar_info ();
		check_have_media ();
		
		if(have_list_view)
			list_view.scroll_to_current_media (false);
		
		// TODO: ABSTRACT THIS
		if(hint == TreeViewSetup.Hint.DUPLICATES) {
			DuplicateSourceView dvw = (DuplicateSourceView)this;
			dvw.update_visibilities();
		}
	}
	
	public void unset_as_current_view() {
		// Nothing to do
	}
	
	// Search
	public bool supports_search() {
		return have_media;
	}
	
	public int requested_search_timeout() {
		return 0;
	}
	
	public void search_activated(string search) {
		play_first_media();
	}
	
	public void search_changed(string search) {
		var new_search = search.down();

		if (get_is_valid_search_string (new_search)) {
			//if(App.window.search_suggester.get_listen_for_search())
				clear_filters ();
		
			if(have_list_view)
				list_view.do_search(new_search);
			if(have_album_view)
				album_view.do_search(new_search);

			last_search = new_search;
			set_statusbar_info ();
			check_have_media ();
		}
	}
	
	public GLib.List<Gtk.MenuItem>? get_search_menu(string search) {
		var new_search = search.down();

		if (get_is_valid_search_string (new_search)) {
			return SourceViewSearchSuggestions.get_suggestions(this, list_view.get_table().get_values(), new_search);
		}
		
		return null;
	}
	
	public bool supports_view_selector() {
		return have_media && have_album_view;
	}
	
	public void view_selection_changed(int option) {
		if(option == 0) {
			set_active_view(SourceViewType.LIST);
		}
		else if(option == 1) {
			set_active_view(SourceViewType.GRID);
		}
	}
	
	// Playback
	public bool can_set_as_current_list() {
		return true;
	}
	
	public void set_as_current_list(Media? m) {
		list_view.set_as_current_list(m);
	}
	
	public void play_first_media () {
		if (!have_list_view || !have_media) {
			App.playback.stop_playback();
			return;
		}
		
		list_view.set_as_current_list(list_view.get_media_from_index(0));
		
		warning("Is below necessary?");
		App.playback.play_media (App.playback.media_from_playback_list_index(0), false);

		if(!App.playback.playing) {
			App.playback.play();
		}
	}
	
	// General
	public string? get_statusbar_text() {
		return null;
	}
	
	public void reset_view() {
		
	}
}
