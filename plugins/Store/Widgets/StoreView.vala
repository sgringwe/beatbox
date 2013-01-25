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

using Gtk;
using Gee;
using Granite;

public class Store.StoreView : Box, BeatBox.View {
	public Store.store store;
	
	public bool loaded;
	
	public int index;
	public int max;
	
	string current_search;
	
	public Store.HomeView homeView;
	Store.SearchResultsView searchPage;
	Widget current_view;
	
	BeatBox.StyledContentBox styler;
	Button home_button;
	BeatBox.NavigationArrows nav_arrows;
	Button basket_button;
	Box container;
	
	public StoreView() {
		store = new Store.store();
		
		loaded = false;
		
		index = 0;
		max = 0;
		
		buildUI();
	}
	
	public void buildUI() {
		styler = new BeatBox.StyledContentBox();
		home_button = new Button();
		nav_arrows = new BeatBox.NavigationArrows();
		basket_button = new Button.with_label("Basket");
		container = new Box(Orientation.HORIZONTAL, 0);
		
		home_button.image = BeatBox.App.icons.GO_HOME.render_image(IconSize.MENU, null, 0);
		home_button.get_style_context().add_class("raised");
		
		HButtonBox top_box = new HButtonBox();
		top_box.set_layout(ButtonBoxStyle.START);
		top_box.set_spacing (6);
		top_box.pack_start(home_button, false, false, 0);
		top_box.pack_start(nav_arrows, false, false, 0);
		top_box.pack_end(basket_button, false, false, 0);
		
		(top_box as Gtk.ButtonBox).set_child_secondary(basket_button, true);
		(top_box as Gtk.ButtonBox).set_child_non_homogeneous(home_button, true);
		
		top_box.margin_top = 3;
		home_button.margin_left = nav_arrows.margin_left = basket_button.margin_right = 6;
		
		var combiner = new Box(Orientation.VERTICAL, 0);
		combiner.pack_start(top_box, false, true, 0);
		combiner.pack_start(container, true, true, 0);
		
		homeView = new HomeView(this, store);
		setView(homeView);
		
		//styler.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		styler.set_content(combiner);
		
		pack_start(styler, true, true, 0);
		
		show_all();
		
		home_button.clicked.connect(homeButtonClicked);
		// nav arrows
	}
	
	public void homeButtonClicked() {
		homeView = new HomeView(this, store);
		setView(homeView);
		homeView.populate();
	}
	
	private void* searchtracks_thread_function () {
		var search = new LinkedList<Store.Track>();
		
		foreach(var track in store.searchTracks(1, 20, current_search, null))
			search.add(track);
		
		Idle.add( () => { 
			foreach(var track in search)
				searchPage.addTrack(track);
				
			return false;
		});
		
		return null;
	}
	
	private void* searchartists_thread_function () {
		var search = new LinkedList<Store.Artist>();
		
		foreach(var artist in store.searchArtists(1, 10, current_search, null))
			search.add(artist);
		
		Idle.add( () => { 
			foreach(var artist in search)
				searchPage.addArtist(artist);
				
			return false;
		});
		
		return null;
	}
	
	private void* searchreleases_thread_function () {
		var search = new LinkedList<Store.Release>();
		
		foreach(var rel in store.searchReleases(1, 10, current_search, null))
			search.add(rel);
		
		Idle.add( () => { 
			foreach(var rel in search)
				searchPage.addRelease(rel);
				
			return false;
		});
		
		return null;
	}
	
	public void setView(Widget w) {
		current_view.destroy();
		current_view = w;
		container.pack_start(w, true, true, 0);
	}
	
	// TODO: Use operations manager api
	public bool progressNotification() {
		/*double progress = (double)((double)index)/((double)max);
		lm.lw.progressNotification(null, progress);
		
		if(progress >= 0.0 && progress <= 1.0)
			Timeout.add(25, progressNotification);*/
			
		return false;
	}
	
	/** Implement view interface **/
	public BeatBox.View.ViewType get_view_type() {
		return BeatBox.View.ViewType.STORE;
	}
	
	public Object? get_object() {
		return store;
	}
	
	public Gdk.Pixbuf get_view_icon() {
		return BeatBox.App.icons.render_icon("web-browser", IconSize.MENU);
	}
	
	public string get_view_name() {
		return _("Music Store");
	}
	
	public Gtk.Menu? get_context_menu() {
		return null;
	}
	
	public bool can_receive_drop() {
		return false;
	}
	
	public void drag_received(Gtk.SelectionData data) {
		
	}
	
	public GLib.List<BeatBox.View> get_sub_views() {
		return new GLib.List<BeatBox.View>(); // Does that mean our views will be duplicated to? if so, we'll have 2 versions floating around
	}
	
	public void set_as_current_view () {
		show_all();
		
		if(!loaded) {
			homeButtonClicked();
			
			loaded = true;
		}
	}
	
	public void unset_as_current_view() {
		// Nothing to do
	}
	
	public SideTreeCategory get_sidetree_category() {
		return SideTreeCategory.PLUGIN;
	}
	
	// Search
	public bool supports_search() {
		return true;
	}
	
	public int requested_search_timeout() {
		return 0;
	}
	
	public void search_activated(string search) {
		current_search = search;
		searchPage = new SearchResultsView(this, store);
		setView(searchPage);
		
		try {
			new Thread<void*>.try (null, searchtracks_thread_function);
			new Thread<void*>.try (null, searchartists_thread_function);
			new Thread<void*>.try (null, searchreleases_thread_function);
		}
		catch (Error err) {
			warning ("Could not create thread to get populate ArtistView: %s", err.message);
		}
	}
	
	public void search_changed(string search) {
		//lw.set_active_view(songs_view);
		//songs_view.search_activated(search);
	}
	
	public GLib.List<Gtk.MenuItem>? get_search_menu(string search) {
		return null;
	}
	
	public bool supports_view_selector() {
		return false;
	}
	
	public void view_selection_changed(int option) {
		
	}
	
	// Playback
	public bool can_set_as_current_list() {
		return false;
	}
	
	public void set_as_current_list(BeatBox.Media? m) {
		// Nothing to do
	}
	
	public void play_first_media () {
		//lw.set_active_view(songs_view);
		//songs_view.play_first_media();
	}
	
	// General
	public string? get_statusbar_text() {
		return null;
	}
	
	public void reset_view() {
		
	}
}
