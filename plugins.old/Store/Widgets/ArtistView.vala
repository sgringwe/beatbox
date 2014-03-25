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

public class Store.ArtistView : Box {
	Store.StoreView storeView;
	Store.store store;
	private Store.Artist artist;
	private LinkedList<Store.Track> topTracksList;
	private LinkedList<Store.Release> releasesList;
	
	private Image artistImage;
	private Gtk.Label artistName;
	private Gtk.Label upDown;
	private Gtk.Label bio;
	private Store.ObjectList releases;
	private Store.TrackList topTracks;
	
	public ArtistView(Store.StoreView view, Store.store s, Artist a) {
		storeView = view;
		store = s;
		artist = a;
		topTracksList = new LinkedList<Store.Track>();
		releasesList = new LinkedList<Store.Release>();
		
		buildUI();
		
		setArtist(artist);
	}
	
	private void buildUI() {
		VBox allDetails = new VBox(false, 0);
		var topInfo = new Box(Orientation.VERTICAL, 0);
		var topRow = new Box(Orientation.HORIZONTAL, 0);
		artistImage = new Image();
		artistName = new Gtk.Label("");
		upDown = new Gtk.Label("");
		bio = new Gtk.Label("");
		releases = new Store.ObjectList(storeView, 40, Orientation.VERTICAL);
		topTracks = new Store.TrackList(storeView, TrackListType.ARTIST_TRACKS);
		
		artistName.xalign = 0.0f;
		artistName.ellipsize = Pango.EllipsizeMode.END;
		
		bio.xalign = bio.yalign = 0.0f;
		bio.set_line_wrap(true);
		
		//topInfo.pack_start(BeatBox.UI.wrap_alignment(artistName, 0, 0, 0, 6), false, true, 0);
		//topInfo.pack_start(BeatBox.UI.wrap_alignment(bio, 0, 0, 0, 6), true, true, 0);
		
		//topRow.pack_start(artistImage, false, true, 0);
		//topRow.pack_start(topInfo, true, true, 0);
		
		// Now the track list
		var songs_holder = new BeatBox.StyledBox("Top Tracks", "white");
		topTracks.get_style_context().add_class("AlbumSongList");
		songs_holder.set_widget(topTracks);
		
		var albums_holder = new BeatBox.StyledBox("Albums", "white");
		releases.get_style_context().add_class("AlbumSongList");
		albums_holder.set_widget(releases);
		
		/* make some 'category' labels */
		var releasesLabel = new Gtk.Label("");
		var topTracksLabel = new Gtk.Label("");
		
		releasesLabel.xalign = 0.0f;
		topTracksLabel.xalign = 0.0f;
		releasesLabel.set_markup("<span weight=\"bold\" size=\"larger\">Releases</span>");
		topTracksLabel.set_markup("<span weight=\"bold\" size=\"larger\">Top Tracks</span>");
		
		var left_side = new Box(Orientation.VERTICAL, 0);
		var right_side = new Box(Orientation.VERTICAL, 0);
		
		left_side.pack_start(BeatBox.UI.wrap_alignment(artistName, 0, 0, 0, 6), false, false, 0);
		left_side.pack_start(BeatBox.UI.wrap_alignment(bio, 0, 0, 0, 6), false, false, 0);
		left_side.pack_start(BeatBox.UI.wrap_alignment(songs_holder, 18, 0, 0, 6), false, false, 0);
		
		right_side.pack_start(BeatBox.UI.wrap_alignment(artistImage, 0, 0, 0, 6), false, false, 0);
		right_side.pack_start(BeatBox.UI.wrap_alignment(albums_holder, 12, 0, 0, 0), false, false, 0);
		
		
		// set minimal size for main widgets
		//releases.set_size_request(200, -1);
		right_side.set_size_request(200, -1);
		//topTracks.set_size_request(-1, 250);
		
		set_orientation(Orientation.HORIZONTAL);
		pack_start(BeatBox.UI.wrap_alignment(left_side, 18, 0, 0, 18), true, true, 0);
		pack_start(BeatBox.UI.wrap_alignment(right_side, 18, 18, 0, 18), false, false, 0);
		
		show_all();
	}
	
	public void populate() {
		try {
			new Thread<void*>.try (null, setartist_thread_function);
			new Thread<void*>.try (null, gettracks_thread_function);
			new Thread<void*>.try (null, getreleases_thread_function);
			storeView.index = 0;
			storeView.max = 5; // must get to 6 for progress bar to turn off
			storeView.progressNotification();
		}
		catch (Error err) {
			warning ("Could not create thread to get populate ArtistView: %s", err.message);
		}
	}
	
	private void* setartist_thread_function () {
		Store.Artist a = store.getArtist(artist.artistID);
		a.image = Store.store.getPixbuf(a.imagePath, 200, 200);
		
		++storeView.index;
		Idle.add( () => { 
			setArtist(a); 
			++storeView.index;
			return false; 
		});
		
		return null;
	}
	
	private void* gettracks_thread_function () {
		var tracks = new GLib.List<BeatBox.Media>();
		foreach(var track in artist.getTopTracks(1, 12))
			tracks.append(track);
			
		++storeView.index;
		
		Idle.add( () => { 
			topTracks.add_medias(tracks);
			
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	private void* getreleases_thread_function () {
		foreach(var rel in artist.getReleases(1, 5, "album", 100)) {
			rel.image = Store.store.getPixbuf(rel.imagePath, 100, 100);
			releasesList.add(rel);
		}
			
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var rel in releasesList)
				releases.addItem(rel);
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	public void setArtist(Store.Artist artist) {
		this.artist = artist;
		
		var artist_info = BeatBox.App.info.get_artist_info(artist.name);
		var artist_label = "<span size=\"xx-large\">" + Markup.escape_text(artist.name) + "</span>";
		var bio_lab = ((artist_info != null && !BeatBox.String.is_empty(artist_info.short_desc)) ? ("<span size =\"medium\">" + BeatBox.String.remove_html(artist_info.short_desc) + "</span>") : "");
		
		artistName.set_markup(artist_label);
		bio.set_markup(bio_lab);
		
		//if(artist.image == null)
		//	artist.image = Store.store.getPixbuf(artist.imagePath, 200, 200);
			
		if(artist.image != null) {
			artistImage.set_from_pixbuf(artist.image);
		}
		// TODO: Default artist image
		
	}
	
	public void addTopTrack(Store.Track track) {
		var to_add = new GLib.List<BeatBox.Media>();
		to_add.append(track);
		topTracks.add_medias(to_add);
	}
	
	public void addRelease(Store.Release release) {
		releases.addItem(release);
	}
	
	public void addSimilarArtist(Store.Artist artist) {
		
	}
	
	public void addTag(Store.Tag tag) {
		
	}
}
