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

public class Store.AlbumView : Box {
	Store.StoreView storeView;
	Store.store store;
	private Store.Release release;
	private LinkedList<Store.Track> tracksListList;
	private LinkedList<Store.Release> similarReleasesList;
	
	private Image albumArt;
	private Gtk.Label albumName;
	private Gtk.Label albumArtist;
	//private TagLabel purchase;
	private Gtk.Label releaseDate;
	private Gtk.Label producer;
	private Box priceFlags;
	Button buyButton;
	private VBox rightButtons;
	private Gtk.Label description;
	private Box tags; 
	private Store.TrackList trackList;
	private Store.ObjectList similarReleases;
	
	public AlbumView(Store.StoreView view, Store.store s, Release r) {
		storeView = view;
		store = s;
		release = r;
		tracksListList = new LinkedList<Store.Track>();
		similarReleasesList = new LinkedList<Store.Release>();
		
		buildUI();
		
		setAlbum(release);
	}
	
	public void buildUI() {
		VBox allDetails = new VBox(false, 0);
		HBox topRow = new HBox(false, 0);
		VBox topInfo = new VBox(false, 0);
		
		albumArt = new Image();
		albumName = new Gtk.Label("");
		albumArtist = new Gtk.Label("");
		releaseDate = new Gtk.Label("");
		producer = new Gtk.Label("");
		priceFlags = new HBox(false, 5);
		buyButton = new Button.with_label("Buy Album");
		rightButtons = new VBox(false, 0);
		description = new Gtk.Label("");
		tags = new Box(Orientation.HORIZONTAL, 9);
		trackList = new Store.TrackList(storeView, TrackListType.ALBUM_TRACKS);
		similarReleases = new Store.ObjectList(storeView, 40, Orientation.VERTICAL);
		
		//HBox topInfoSplit = new HBox(false, 0);
		//topInfo.pack_start(BeatBox.UI.wrap_alignment(albumName, 6, 0, 0, 0), false, false, 0);
		//topInfo.pack_start(albumArtist, false, false, 0);
		
		//topRow.pack_start(albumArt, false, false, 0);
		//topRow.pack_start(topInfoSplit, true, true, 0);
		
		albumArt.xalign = 0.0f;
		albumName.xalign = 0.0f;
		albumArtist.xalign = 0.0f;
		releaseDate.xalign = 0.0f;
		producer.xalign = 0.0f;
		
		albumName.ellipsize = Pango.EllipsizeMode.END;
		albumArtist.ellipsize = Pango.EllipsizeMode.END;
		releaseDate.ellipsize = Pango.EllipsizeMode.END;
		producer.ellipsize = Pango.EllipsizeMode.END;
		
		albumName.set_line_wrap(true);
		releaseDate.set_line_wrap(true);
		producer.set_line_wrap(true);
		
		description.set_line_wrap(true);
		description.yalign = 0.0f;
		description.xalign = 0.0f;
		
		buyButton.margin_left = 6;
		
		priceFlags.pack_end(buyButton, false, false, 0);
		
		/* make some 'category' labels */
		var similarReleasesLabel = new Gtk.Label("");
		similarReleasesLabel.xalign = 0.0f;
		similarReleasesLabel.set_markup("<span weight=\"bold\" size=\"larger\">Similar Releases</span>");
		
		// Now the track list
		var album_songs_holder = new BeatBox.StyledBox("Track List", "white");
		trackList.get_style_context().add_class("AlbumSongList");
		album_songs_holder.set_widget(trackList);
		
		var similars_holder = new BeatBox.StyledBox("Similar Albums", "white");
		similarReleases.get_style_context().add_class("AlbumSongList");
		similars_holder.set_widget(similarReleases);
		
		// set minimal size for main widgets
		//description.set_size_request(100, 600);
		//trackList.set_size_request(-1, 250);
		//similarReleases.set_size_request(160, -1);
		
		var middle = new Box(Orientation.HORIZONTAL, 0);
		var left_side = new Box(Orientation.VERTICAL, 0);
		var right_side = new Box(Orientation.VERTICAL, 0);
		
		middle.pack_start(left_side, false, false, 0);
		middle.pack_start(right_side, true, true, 0);
		
		left_side.pack_start(albumArt, false, false, 0);
		left_side.pack_start(BeatBox.UI.wrap_alignment(releaseDate, 0, 0, 0, 12), false, false, 0);
		left_side.pack_start(BeatBox.UI.wrap_alignment(producer, 0, 0, 0, 12), false, false, 0);
		left_side.pack_start(BeatBox.UI.wrap_alignment(similars_holder, 0, 0, 0, 12), false, false, 0);
		
		right_side.pack_start(BeatBox.UI.wrap_alignment(album_songs_holder, 0, 12, 0, 18), false, false, 0);
		right_side.pack_start(BeatBox.UI.wrap_alignment(priceFlags, 6, 12, 0, 18), false, false, 0);
		
		left_side.set_size_request(200, -1);
		
		set_orientation(Orientation.VERTICAL);
		pack_start(BeatBox.UI.wrap_alignment(albumName, 18, 0, 0, 18), false, false, 0);
		pack_start(BeatBox.UI.wrap_alignment(middle, 6, 0, 0, 6), true, true, 0);
		
		show_all();
		
		/*viewArtist.button_press_event.connect( (event) => {
			var newView = new ArtistView(storeView, storeView.store, release.artist);
			storeView.setView(newView);
			newView.populate();
			
			return false;
		});*/
		
		this.size_allocate.connect(resized);
	}
	
	void resized(Allocation rec) {
		description.set_size_request(rec.width - 40, -1);
	}
	
	public void populate() {
		try {
			new Thread<void*>.try (null, setalbum_thread_function);
			new Thread<void*>.try (null, gettracks_thread_function);
			new Thread<void*>.try (null, getsimilarreleases_thread_function);
			new Thread<void*>.try (null, getalbuminfo_thread_function);

			storeView.max = 5;
			storeView.index = 0;
			storeView.progressNotification();
		}
		catch (Error err) {
			warning ("Could not create thread to get populate ArtistView: %s", err.message);
		}
	}
	
	private void* setalbum_thread_function () {
		Store.Release r = store.getRelease(release.releaseID, 200);
		r.image = Store.store.getPixbuf(r.imagePath, 200, 200);
		
		++storeView.index;
		
		Idle.add( () => { 
			setAlbum(r); 
			++storeView.index;
			
            try {
			    new Thread<void*>.try (null, gettaglabels_thread_function);
            }
            catch (Error e) {
                critical ("Couldn't get tags: %s", e.message);
            }
			
			return false; 
		});
		
		return null;
	}
	
	public void* gettracks_thread_function () {
		var tracks = new GLib.List<BeatBox.Media>();
		foreach(var track in release.getTracks())
			tracks.append(track);
		
		++storeView.index;
		
		Idle.add( () => { 
			trackList.add_medias(tracks);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	private void* getsimilarreleases_thread_function () {
		foreach(var rel in release.getSimilar(1, 5, 100)) {
			rel.image = Store.store.getPixbuf(rel.imagePath, 100, 100);
			similarReleasesList.add(rel);
		}
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var rel in similarReleasesList)
				similarReleases.addItem(rel);
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	private void* gettaglabels_thread_function () {
		var labels = new LinkedList<Store.TagLabel>();
		
		foreach(var format in release.formats) {
			if(format.fileFormat.down().contains("mp3")) {
				labels.insert(0, new TagLabel(format.fileFormat, "blue", format, false));
				labels.insert(0, new TagLabel(format.bitrate.to_string() + "kbps", "blue", format, false));
				
				if(format.drmFree)
					labels.insert(0, new TagLabel("DRM Free", "blue", format, false));
			}
		}
		
		if(labels.size == 0 && release.formats.size > 0) {
			Format format = release.formats.get(0);
			
			labels.insert(0, new TagLabel(format.fileFormat, "blue", format, false));
			labels.insert(0, new TagLabel(format.bitrate.to_string() + "kbps", "blue", format, false));
			
			if(format.drmFree)
				labels.insert(0, new TagLabel("DRM Free", "blue", format, false));
		}
		
		if(release.price != null && !release.price.formattedPrice.contains("0.00")) {
			labels.insert(0, new TagLabel(release.price.formattedPrice, "blue", release.price, false));
		}
		
		++storeView.index;
		
		Idle.add( () => { 
			foreach(var lab in labels) {
				priceFlags.pack_end(lab, false, false, 0);
				lab.show_all();
			}
				
			++storeView.index;
			return false;
		});
		
		return null;
	}
	
	private void* getalbuminfo_thread_function () {
		/* first get album description */
		/*LastFM.AlbumInfo album = new LastFM.AlbumInfo.basic();
		
		string artist_s = release.artist.name;
		string album_s = release.title;
		
		// fetch album info now. only save if still on current song
		//if(!storeView.lm.album_info_exists(album_s + " by " + artist_s)) {
			
			album = new LastFM.AlbumInfo.with_info(artist_s, album_s);
			stdout.printf("fetched album\n");
			if(album != null) {
				//storeView.lm.save_album(album);
				stdout.printf("saved album\n");
			}
			*/
		//}
		//else {
		//	album = storeView.lm.get_album(album_s + " by " + artist_s);
		//}
		
		/* now get the 7digital tags */
		var tags = new LinkedList<Store.Tag>();
		foreach(var tag in release.getTags())
			tags.add(tag);
		
		Idle.add( () => {
			/*if(album != null && album.summary != null && album.summary.length > 200) { 
				setDescription(album.summary);
				//description.set_size_request(-1, 100);
			}*/
			
			foreach(var tag in tags) {
				stdout.printf("tag added: %s\n", tag.text);
				//this.tags.pack_start(new TagLabel(tag.text, "blue", tag, true), false, false, 0);
			}
			
			return false;
		});
		
		return null;
	}
	
	public void setAlbum(Store.Release release) {
		this.release = release;
		
		BeatBox.AlbumInfo? album_info = null;
		if(release.artist != null)
			album_info = BeatBox.App.info.get_album_info(release.artist.name, release.title);
		
		var album = "<span size=\"xx-large\">" + Markup.escape_text(release.title) + "</span>";
		var artist = ((release.artist != null && release.artist.name != "" && release.artist.name != _("Unknown Artist")) ? 
						("<span size=\"x-large\">" + Markup.escape_text(release.artist.name) + "</span>") : "");
		var release_date = "Released <span size=\"medium\">" + release.releaseDate.format("%B %e, %Y") + "</span>";
		var prod = ((release.label != null && release.label.name != null) ? ("<span size =\"small\">" + release.label.name + "</span>") : "");
		var desc = ((album_info != null && !BeatBox.String.is_empty(album_info.short_desc)) ? ("<span size =\"medium\">" + BeatBox.String.remove_html(album_info.short_desc) + "</span>") : "");
		
		albumName.set_markup(_("%s  by  %s").printf(album, artist));
		//albumArtist.set_markup(artist);
		releaseDate.set_markup(release_date);
		producer.set_markup(prod);
		
		//if(release.image == null)
		//	release.image = Store.store.getPixbuf(release.imagePath, 200, 200);
		
		if(release.image != null) {
			albumArt.set_from_pixbuf(BeatBox.App.covers.add_shadow_to_album_art(release.image, false, true));
		}
		else
			albumArt.set_from_pixbuf(BeatBox.App.covers.DEFAULT_COVER_SHADOW);
	}
	
	public void setDescription(string desc) {
		description.set_markup(desc);
	}
	
	// TODO: Rid of this
	public void addTrack(Store.Track track) {
		var to_add = new GLib.List<BeatBox.Media>();
		to_add.append(track);
		trackList.add_medias(to_add);
	}
	
	public void addSimilarRelease(Store.Release release) {
		similarReleases.addItem(release);
	}
}
