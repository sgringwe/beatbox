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

public class BeatBox.SongSummarySection : Box {
	Gtk.Image coverArt;
	Label meta_title;
	Label meta_artist;
	Label meta_album;
	Label meta_year;
	Button loveMedia;
	Button banMedia;
	RatingWidget rating;
	StyledBox lyrics_holder;
	Label lyrics;
	StyledBox album_songs_holder;
	MusicList album_songs;
	Label summary_text;
	
	static CssProvider style_provider;
	private const string WIDGET_STYLESHEET = """
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
	
	public SongSummarySection() {
		set_orientation(Orientation.HORIZONTAL);
		
		if(style_provider == null) {
			style_provider = new CssProvider();
			try  {
				style_provider.load_from_data (WIDGET_STYLESHEET, -1);
			} catch (Error e) {
				warning("Couldn't load style provider.\n");
			}
		}
		
		build_ui();
		
		show_all();
		set_no_show_all(true);
		set_visible(App.playback.current_media != null);
		
		App.playback.media_played.connect(media_played);
		App.playback.playback_stopped.connect(playback_stopped);
		App.library.medias_updated.connect(medias_updated);
		App.info.lyrics.lyrics_fetched.connect(lyrics_fetched);
		App.info.lastfm.login_returned.connect(login_returned_lastfm);
		App.info.lastfm.logged_out.connect(logged_out_lastfm);
		size_allocate.connect(size_allocate_signal);
		App.info.track_info_updated.connect(update_summary);
		App.info.album_info_updated.connect(update_summary);
		App.info.album_info_updated.connect(update_album_songs);
		App.info.artist_info_updated.connect(update_summary);
	}
	
	void build_ui() {
		// First add the metadata stuff coverart, song, artist, album
		var left_side = new Box(Orientation.VERTICAL, 0);
		var metadata = new Box(Orientation.HORIZONTAL, 0);
		var meta_labels = new Box(Orientation.VERTICAL, 0);
		
		coverArt = new Gtk.Image();
		meta_title = new Label("");
		meta_artist = new Label("");
		meta_album = new Label("");
		Box rate_box = new Box(Orientation.HORIZONTAL, 0);
		loveMedia = new Button();
		banMedia = new Button();
		rating = new RatingWidget(false, IconSize.MENU, false, null);
		meta_year = new Label("");
		summary_text = new Label("");
		lyrics = new Label("");
		
		rate_box.pack_start(rating, false, false, 0);
		rate_box.pack_start(loveMedia, false, false, 0);
		rate_box.pack_start(banMedia, false, false, 0);
		
		metadata.pack_start(coverArt, false, false, 0);
		metadata.pack_start(UI.wrap_alignment(meta_labels, 0, 0, 0, 6), false, false, 0);
		meta_labels.pack_start(meta_title, false, false, 0);
		meta_labels.pack_start(meta_artist, false, false, 0);
		meta_labels.pack_start(meta_album, false, false, 0);
		meta_labels.pack_start(meta_year, false, false, 0);
		meta_labels.pack_start(rate_box, false, false, 0);
		
		coverArt.xalign = 0.0f;
		meta_title.xalign = 0.0f;
		meta_artist.xalign = 0.0f;
		meta_album.xalign = 0.0f;
		meta_year.xalign = 0.0f;
		summary_text.xalign = 0.0f;
		lyrics.xalign = 0.0f;
		coverArt.yalign = 0.0f;
		meta_title.yalign = 0.0f;
		meta_artist.yalign = 0.0f;
		meta_album.yalign = 0.0f;
		meta_year.yalign = 0.0f;
		summary_text.yalign = 0.0f;
		lyrics.yalign = 0.0f;
		meta_title.set_line_wrap(true);
		meta_artist.set_line_wrap(true);
		meta_album.set_line_wrap(true);
		summary_text.set_line_wrap(true);
		lyrics.set_line_wrap(true);
		coverArt.set_size_request (Icons.ALBUM_VIEW_IMAGE_SIZE, Icons.ALBUM_VIEW_IMAGE_SIZE);
		loveMedia.set_no_show_all(true);
		banMedia.set_no_show_all(true);
		loveMedia.relief = ReliefStyle.NONE;
		banMedia.relief = ReliefStyle.NONE;
		var lastfm_love_icon = App.icons.LASTFM_LOVE.render (IconSize.MENU);
		var lastfm_ban_icon = App.icons.LASTFM_BAN.render (IconSize.MENU);
		loveMedia.set_image(new Image.from_pixbuf(lastfm_love_icon));
		banMedia.set_image(new Image.from_pixbuf(lastfm_ban_icon));
		
		rating.rating_changed.connect(rating_changed);
		loveMedia.clicked.connect(loveButtonClicked);
		banMedia.clicked.connect(banButtonClicked);
		
		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);
		drag_motion.connect(drag_motion_signal);
		drag_leave.connect(drag_leave_signal);
		drag_data_received.connect(drag_received);
		
		// Now the album list on left side under metadata
		album_songs_holder = new StyledBox("Album Songs", "white");
		var tvs = new TreeViewSetup(MusicColumn.ARTIST, SortType.ASCENDING, TreeViewSetup.Hint.NOW_PLAYING);
		album_songs = new MusicList(tvs);
		album_songs.is_mixed = true;
		album_songs.set_sort_column_id(tvs.sort_column_id, tvs.sort_direction);
		album_songs.get_style_context().add_class("AlbumSongList");
		//album_songs.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		var scroll = new ScrolledWindow(null, null);
		scroll.add(album_songs);
		scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		scroll.set_size_request(-1, 160);
		album_songs_holder.set_widget(scroll);
		
		// And lastly the lyrics box
		lyrics_holder = new StyledBox("", "black");
		lyrics.get_style_context().add_class("white_text");
		lyrics.get_style_context().add_class("padding");
		lyrics.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		var lyrics_scroll = new ScrolledWindow(null, null);
		var lyrics_eb = new EventBox();
		lyrics_eb.get_style_context().add_class("black");
		lyrics_eb.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		lyrics_eb.add(lyrics);
		lyrics_scroll.add_with_viewport(lyrics_eb);
		lyrics_scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		lyrics_holder.set_size_request(300, -1);
		lyrics_holder.set_widget(lyrics_scroll);
		
		left_side.pack_start(metadata, false, true, 0);
		left_side.pack_start(UI.wrap_alignment(summary_text, 6, 0, 0, 6), true, true, 0);
		left_side.pack_start(UI.wrap_alignment(album_songs_holder, 6, 0, 0, 6), true, true, 0);
		
		pack_start(UI.wrap_alignment(left_side, 0, 0, 0, 0), true, true, 0);
		pack_end(UI.wrap_alignment(lyrics_holder, 0, 0, 0, 12), false, true, 0);
	}
	
	void login_returned_lastfm(bool success) {
		update_sensitivities();
	}
	
	void logged_out_lastfm() {
		update_sensitivities();
	}
	
	void media_played(Media m, Media? old) {
		update_contents();
		
		set_visible(true);
		App.info.lyrics.fetch_lyrics(m.artist, m.album_artist, m.title);
	}
	
	void playback_stopped(Media? was_playing) {
		set_visible(false);
	}
	
	void lyrics_fetched(Lyrics l) {
		Media m = App.playback.current_media;
		if(m != null && m.title == l.title && m is Song) {
			((Song)m).lyrics = l.content;
			update_lyrics();
		}
	}
	
	void medias_updated(Collection<Media> ids) {
		update_contents();
	}
	
	void rating_changed(int new_rating) {
		App.playback.current_media.rating = new_rating;
		App.library.update_media(App.playback.current_media, false, true, true);
	}
	
	void loveButtonClicked() {
		App.actions.lastfm_love.activate();
	}
	
	void banButtonClicked() {
		App.actions.lastfm_ban.activate();
		
		// Clearly we should skip this song...
		App.playback.request_next();
	}
	
	bool is_valid_image_type(string type) {
		var typeDown = type.down();
		
		return (typeDown.has_suffix(".jpg") || typeDown.has_suffix(".jpeg") ||
				typeDown.has_suffix(".png"));
	}
	
	bool drag_motion_signal(Gdk.DragContext context, int x, int y, uint time) {
		drag_highlight(coverArt);
		coverArt.show();
		coverArt.set_from_pixbuf(App.icons.DROP_ALBUM_PIXBUF);
		
		return false;
	}
	
	void drag_leave_signal(Gdk.DragContext context, uint time) {
		drag_unhighlight(coverArt);
		update_cover_art();
	}
	
	void drag_received(Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint info, uint timestamp) {
		if(App.playback.current_media == null || App.playback.current_media.isTemporary)
			return;
		
		bool success = true;
		
		foreach(string uri in data.get_uris()) {
			
			if(is_valid_image_type(uri) && App.playback.current_media != null) {
				message("Saving dragged album art as image\n");
				App.covers.save_album_locally(App.playback.current_media, uri);
			}
			else {
				message("Dragged album art is not valid image\n");
			}
			
			Gtk.drag_finish (context, success, false, timestamp);
			return;
		}
    }
	
	void update_sensitivities() {
		bool media_playing = App.playback.current_media != null;
		var lastfm_elements_visible = App.settings.lastfm.session_key != "";
		
		loveMedia.set_visible(lastfm_elements_visible);
		banMedia.set_visible(lastfm_elements_visible);
		
		set_visible(media_playing);
	}
	
	void update_contents() {
		Media m = App.playback.current_media;
		if(m == null) {
			return;
		}
		
		var title = "<span size=\"xx-large\">" + Markup.escape_text(m.title) + "</span>";
		var artist = ((m.artist != "" && m.artist != _("Unknown Artist")) ? ("<span size=\"x-large\">" + Markup.escape_text(m.artist) + "</span>") : "");
		var album = ((m.album != "" && m.album != _("Unknown Album")) ? ("<span size=\"large\">" + Markup.escape_text(m.album) + "</span>") : "");
		var year = ((m.year != 0) ? ("<span size =\"medium\">" + m.year.to_string() + "</span>") : "");
		
		meta_title.set_markup(title);
		meta_artist.set_markup(artist);
		meta_album.set_markup(album);
		meta_year.set_markup(year);
		rating.set_rating((int)m.rating);
		
		update_cover_art();
		update_album_songs();
		update_summary();
		update_lyrics();
		
		update_sensitivities();
	}
	
	void update_cover_art() {
		if(App.playback.current_media == null) {
			return;
		}

		var coverart_pixbuf = App.covers.get_album_art_from_key(App.playback.current_media.album_artist, App.playback.current_media.album);

		if(coverart_pixbuf != null) {
			coverArt.set_from_pixbuf(coverart_pixbuf);
		}
		else {
			coverArt.set_from_pixbuf(App.covers.DEFAULT_COVER_SHADOW);
		}
	}
	
	void update_album_songs() {
		if(App.playback.current_media == null)
			return;
		
		Media current_media = App.playback.current_media;
		
		// Don't change the list if still in same album. Otherwise we lose temps.
		//var old = album_songs.get_media_from_index(0);
		//if(old != null && old.album_artist = current_media.album_artist && old.album == current_media.album)
		//	return;
		
		var results = new LinkedList<Media>();
		App.library.do_search (App.library.song_library.medias(), out results, null, null, null, null,
	                  album_songs.get_hint(), "", current_media.album_artist, current_media.album);
	    
	    var table = new GLib.HashTable<int, Media>(null, null);
	    foreach(var m in results)
			table.set((int)table.size(), m);
		
		// Try filling in missing songs w/ album info's tracks
		if(App.info.current_album != null) {
			var fillers = new LinkedList<Media>();
			
			// TODO: Fixme
			//find_filler_songs(table, App.info.current_album.tracks(), ref fillers);
			foreach(var media in fillers)
				table.set((int)table.size(), media);
		}
		
		album_songs.set_table(table);
		album_songs_holder.set_visible(table.size() > 1);
	}
	
	/*void find_filler_songs(HashTable<int, Media> in_library, Collection<Media> tests, ref LinkedList<Media> fillers) {
		foreach(Media test in tests) {
			bool found_match = false;
			
			for(int i = 0; i < in_library.size(); ++i) {
				Media s = in_library.get(i);
				if(test.track == s.track) {
					found_match = true;
					break;
				}
			}
			
			if(!found_match)
				fillers.add(test);
		}
	}*/
	
	void size_allocate_signal(Allocation all) {
		update_lyrics();
	}
	
	void update_lyrics() {
		Media m = App.playback.current_media;
		if(m == null)
			return;
		
		lyrics.set_label(m.lyrics);
		bool show_lyrics = m.lyrics != null && m.lyrics != "" && get_allocated_width() > 800;
		lyrics_holder.set_visible(show_lyrics);
	}
	
	void update_summary() {
		bool have_title_info = 	App.info.current_track != null && !String.is_empty(App.info.current_track.short_desc);
		bool have_album_info = 	App.info.current_album != null && !String.is_empty(App.info.current_album.short_desc);
		bool have_artist_info = App.info.current_artist != null && !String.is_empty(App.info.current_artist.short_desc);
		
		var whole_summary = "";
		if(have_title_info) {
			whole_summary += App.info.current_track.short_desc;
		}
		if(have_album_info) {
			if(have_title_info)
				whole_summary += "\n\n";
			
			whole_summary += App.info.current_album.short_desc;
		}
		if(have_artist_info) {
			if(have_title_info || have_album_info)
				whole_summary += "\n\n";
			
			whole_summary += App.info.current_artist.short_desc;
		}
		
		summary_text.set_visible(have_title_info || have_album_info || have_artist_info);
		summary_text.set_markup(String.remove_html(whole_summary));
	}
}
