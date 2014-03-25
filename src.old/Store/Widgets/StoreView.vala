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

public class Store.StoreView : VBox {
	public Store.store store;
	
	public BeatBox.LibraryManager lm;
	public BeatBox.LibraryWindow lw;
	public bool isInitialized;
	bool isCurrentView;
	
	public int index;
	public int max;
	
	public Store.HomeView homeView;
	Store.SearchResultsView searchPage;
	Widget current_view;
	
	Toolbar topPanel;
	ToolButton homeButton;
	HBox container;
	
	public StoreView(BeatBox.LibraryManager lm, BeatBox.LibraryWindow lw) {
		this.lm = lm;
		this.lw = lw;
		
		store = new Store.store();
		
		isCurrentView = false;
		isInitialized = false;
		
		index = 0;
		max = 0;
		
		buildUI();
	}
	
	public void buildUI() {
		topPanel = new Toolbar();
		homeButton = new ToolButton(null, "Home");
		container = new HBox(false, 0);
		
		topPanel.insert(homeButton, 0);
		
		pack_start(topPanel, false, true, 0);
		pack_start(container, true, true, 0);
		
		homeView = new HomeView(this, store);
		setView(homeView);
		
		show_all();
		
		homeButton.clicked.connect(homeButtonClicked);
		lw.searchField.activate.connect(searchFieldActivated);
	}
	
	public void setIsCurrentView(bool isit) {
		isCurrentView = isit;
	}
	
	public void homeButtonClicked() {
		homeView = new HomeView(this, store);
		setView(homeView);
		homeView.populate();
	}
	
	public void searchFieldActivated() {
		if(!isCurrentView)
			return;
		
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
	
	private void* searchtracks_thread_function () {
		var search = new LinkedList<Store.Track>();
		
		foreach(var track in store.searchTracks(lw.searchField.get_text(), 1))
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
		
		foreach(var artist in store.searchArtists(lw.searchField.get_text(), null, 1))
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
		
		foreach(var rel in store.searchReleases(lw.searchField.get_text(), 1))
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
		container.add(current_view);
	}
	
	public bool progressNotification() {
		double progress = (double)((double)index)/((double)max);
		lm.lw.progressNotification(null, progress);
		
		if(progress >= 0.0 && progress <= 1.0)
			Timeout.add(25, progressNotification);
			
		return false;
	}
}
