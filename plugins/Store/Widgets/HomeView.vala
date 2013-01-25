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

public class Store.HomeView : Box {
	Store.store store;
	Store.StoreView storeView;
	
	HBox allItems;
	Store.ObjectList tagList;
	Store.ObjectList artistList;
	Store.ObjectList releaseList;
	Store.TrackList trackList;
	Store.ReleaseRotator releaseRotator;
	Store.IconView topRock;
	
	public HomeView(StoreView storeView, Store.store store) {
		this.storeView = storeView;
		this.store = store;
		
		buildUI();
	}
	
	private void buildUI() {
		allItems = new HBox(false, 0);
		VBox leftItems = new VBox(false, 0);
		VBox centerItems = new VBox(false, 0);
		
		tagList = new ObjectList(storeView, 30, Orientation.VERTICAL);
		artistList = new ObjectList(storeView, 40, Orientation.VERTICAL);
		releaseList = new ObjectList(storeView, 100, Orientation.HORIZONTAL);
		trackList = new TrackList(storeView, TrackListType.TOP_TRACKS);
		releaseRotator = new ReleaseRotator(storeView);
		topRock = new IconView(storeView);
		
		/* category labels */
		var genresLabel = new Gtk.Label("");
		var artistsLabel = new Gtk.Label("");
		var tracksLabel = new Gtk.Label("");
		var rockLabel = new Gtk.Label("");
		
		genresLabel.xalign = 0.0f;
		artistsLabel.xalign = 0.0f;
		tracksLabel.xalign = 0.0f;
		rockLabel.xalign = 0.0f;
		
		genresLabel.set_markup("<span weight=\"bold\" size=\"larger\">Popular Genres</span>");
		artistsLabel.set_markup("<span weight=\"bold\" size=\"larger\">Top Artists</span>");
		tracksLabel.set_markup("<span weight=\"bold\" size=\"larger\">Top Tracks</span>");
		rockLabel.set_markup("<span weight=\"bold\" size=\"larger\">New Rock Releases</span>");
		
		var genres_holder = new BeatBox.StyledBox("Genres", "white");
		tagList.get_style_context().add_class("AlbumSongList");
		genres_holder.set_widget(tagList);
		
		var top_artists_holder = new BeatBox.StyledBox("Top Artists", "white");
		top_artists_holder.set_widget(artistList);
		
		var top_albums_holder = new BeatBox.StyledBox("Hot This Week", "white");
		releaseList.get_style_context().add_class("AlbumSongList");
		var scroll = new ScrolledWindow(null, null);
		scroll.add_with_viewport(releaseList);
		scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.NEVER);
		top_albums_holder.set_widget(scroll);
		
		var top_songs_holder = new BeatBox.StyledBox("Popular Songs", "white");
		top_songs_holder.set_widget(trackList);
		
		leftItems.pack_start(genres_holder, false, true, 0);
		leftItems.pack_start(BeatBox.UI.wrap_alignment(top_artists_holder, 18, 0, 0, 0), false, true, 0);
		
		centerItems.pack_start(BeatBox.UI.wrap_alignment(top_albums_holder, 0, 0, 0, 0), false, true, 0);
		centerItems.pack_start(BeatBox.UI.wrap_alignment(top_songs_holder, 10, 0, 0, 0), false, true, 0);
		//centerItems.pack_start(BeatBox.UI.wrap_alignment(rockLabel, 40, 0, 0, 0), false, true, 0);
		//centerItems.pack_start(BeatBox.UI.wrap_alignment(topRock, 10, 0, 0, 0), false, true, 0);
		
		pack_start(BeatBox.UI.wrap_alignment(leftItems, 18, 0, 0, 18), false, true, 0);
		pack_start(BeatBox.UI.wrap_alignment(centerItems, 18, 18, 0, 18), true, true, 0);
		
		leftItems.set_size_request(200, -1);
		releaseRotator.set_size_request(-1, 200);
		trackList.set_size_request(-1, 300);
		topRock.set_size_request(-1, 200);
		
		
		show_all();
		
	}
	
	public void populate() {
		try {
			new Thread<void*>.try (null, getartists_thread_function);
			new Thread<void*>.try (null, getreleases_thread_function);
			new Thread<void*>.try (null, gettracks_thread_function);
			new Thread<void*>.try (null, gettoprock_thread_function);
			new Thread<void*>.try (null, getgenres_thread_function);

			storeView.max = 6;
			storeView.index = 0;
			storeView.progressNotification();
		}
		catch (Error err) {
			warning ("Could not create thread to get populate ArtistView: %s", err.message);
		}
	}
	
	private void* getartists_thread_function () {
		var tops = new LinkedList<Artist>();
		
		foreach(var art in store.topArtistsForPeriod(1, 15, "week", null))
			tops.add(art);
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var art in tops)
				artistList.addItem(art);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	private void* getreleases_thread_function () {
		var tops = new LinkedList<Release>();
		
		foreach(var rel in store.topReleasesForPeriod(1, 10, "week", null, 100)) {
			rel.image = Store.store.getPixbuf(rel.imagePath, 100, 100);
			tops.add(rel);
		}
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var rel in tops)
				releaseList.addItem(rel);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	private void* gettracks_thread_function () {
		var tops = new GLib.List<Track>();
		
		foreach(var track in store.topTracksForPeriod(1, 20, "week", null))
			tops.append(track);
		
		++storeView.index;
		
		Idle.add( () => { 
			trackList.add_medias(tops);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	private void* gettoprock_thread_function () {
		var rock = new LinkedList<Release>();
		
		foreach(var rel in store.topReleasesForTags(1, 20, "rock", "week")) {
			rel.image = Store.store.getPixbuf(rel.imagePath, 100, 100);
			rock.add(rel);
		}
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var rel in rock)
				topRock.addItem(rel);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	private void* getgenres_thread_function () {
		var gens = new LinkedList<Tag>();
		
		gens.add( new Tag.with_values("pop", "Pop", "") );
		gens.add( new Tag.with_values("rock", "Rock", "") );
		gens.add( new Tag.with_values("electronic", "Electronic", "") );
		gens.add( new Tag.with_values("jazz", "Jazz", "") );
		gens.add( new Tag.with_values("alternative-indie", "Alternative/Indie", "") );
		gens.add( new Tag.with_values("country", "Country", "") );
		gens.add( new Tag.with_values("grunge", "Grunge", "") );
		gens.add( new Tag.with_values("2000s", "2000's", "") );
		gens.add( new Tag.with_values("reggae", "Reggae", "") );
		gens.add( new Tag.with_values("new-age", "New Age", "") );
		gens.add( new Tag.with_values("instrumental", "Instrumental", "") );
		gens.add( new Tag.with_values("soundtrack", "Soundtrack", "") );
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var tag in gens)
				tagList.addItem(tag);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
}
