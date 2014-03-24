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

public class BeatBox.SongArtistSection : Box {
	Label artist_section_label;
	Label top_tracks_label;
	Label similar_artists;
	Label artist_tags;
	//Label top_albums_label;
	StyledBox artist_top_songs_holder;
	MusicList artist_top_songs;
	StyledBox artist_top_albums_holder;
	ExternalAlbumGrid artist_top_albums;
	StyledArtistImages artist_images;
	
	static CssProvider style_provider;
	private const string WIDGET_STYLESHEET = """
        .AlbumSongList {
			/*background-color: rgba(0, 0, 0, 0);*/
			padding: 0;
			/*box-shadow: 10px 10px rgba(0, 0, 0, 0.4);*/
		}
		
    """;
	
	public SongArtistSection() {
		set_orientation(Orientation.VERTICAL);
		
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
		set_visible(App.playback.current_media != null && App.playback.current_media is Song);
		
		App.playback.media_played.connect(media_played);
		App.playback.playback_stopped.connect(playback_stopped);
		App.library.medias_updated.connect(medias_updated);
		App.info.artist_info_updated.connect(update_artist_section);
		App.info.lastfm.top_artist_songs_retrieved.connect(top_artist_songs_retrieved);
		App.info.lastfm.top_artist_albums_retrieved.connect(top_artist_albums_retrieved);
	}
	
	void build_ui() {
		var hbox = new Box(Orientation.HORIZONTAL, 0);
		var left_side = new Box(Orientation.VERTICAL, 0);
		var right_side = new Box(Orientation.VERTICAL, 0);
		
		artist_section_label = new Label("");
		top_tracks_label = new Label("");
		similar_artists = new Label("");
		artist_tags = new Label("");
		
		artist_section_label.set_markup("<span size=\"x-large\"><b>" + _("Artist") + "</b></span>");
		artist_section_label.xalign = 0.0f;
		
		artist_top_songs_holder = new StyledBox("Top Songs", "white");
		var tvs = new TreeViewSetup(MusicColumn.NUMBER, SortType.ASCENDING, TreeViewSetup.Hint.NOW_PLAYING);
		tvs.set_column_visible(MusicColumn.NUMBER, true);
		tvs.set_column_visible(MusicColumn.TRACK, false);
		artist_top_songs = new MusicList(tvs);
		artist_top_songs.is_mixed = true;
		artist_top_songs.set_sort_column_id(tvs.sort_column_id, tvs.sort_direction);
		artist_top_songs.get_style_context().add_class("AlbumSongList");
		artist_top_songs.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		var scroll = new ScrolledWindow(null, null);
		scroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		scroll.add(artist_top_songs);
		artist_top_songs_holder.set_widget(scroll);
		artist_top_songs_holder.set_size_request(-1, 180);
		
		artist_top_albums_holder = new StyledBox("Top albums", "white");
		artist_top_albums = new ExternalAlbumGrid();
		artist_top_albums.column_spacing = 0;
		artist_top_albums.item_padding = 0;
		artist_top_albums.spacing = 0;
		artist_top_albums.get_style_context().add_class("AlbumSongList");
		artist_top_albums.get_style_context().add_provider(style_provider, STYLE_PROVIDER_PRIORITY_APPLICATION);
		var scroll2 = new ScrolledWindow(null, null);
		scroll2.add(artist_top_albums);
		scroll2.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		artist_top_albums_holder.set_widget(scroll2);
		artist_top_albums_holder.set_size_request(175, 400);
		artist_top_albums.item_chosen.connect(artist_top_albums_chosen);
		
		artist_images = new StyledArtistImages(get_style_context());
		var scroll3 = new ScrolledWindow(null, null);
		scroll3.add_with_viewport(artist_images);
		scroll3.set_policy(PolicyType.AUTOMATIC, PolicyType.NEVER);
		
		top_tracks_label.xalign = 0.0f;
		similar_artists.xalign = 0.0f;
		artist_tags.xalign = 0.0f;
		top_tracks_label.yalign = 0.0f;
		similar_artists.yalign = 0.0f;
		artist_tags.yalign = 0.0f;
		top_tracks_label.set_line_wrap(true);
		similar_artists.set_line_wrap(true);
		artist_tags.set_line_wrap(true);
		top_tracks_label.set_markup("<b>%s</b>".printf(_("Top Tracks")));
		
		left_side.pack_start(artist_top_albums_holder, true, true, 0);
		
		right_side.pack_start(artist_top_songs_holder, false, true, 0);
		right_side.pack_start(UI.wrap_alignment(similar_artists, 6, 0, 0, 1), false, true, 0);
		right_side.pack_start(UI.wrap_alignment(artist_tags, 6, 0, 0, 1), false, true, 0);
		right_side.pack_end(scroll3, false, true, 0);
		
		hbox.pack_start(left_side, false, true, 0);
		hbox.pack_end(UI.wrap_alignment(right_side, 0, 0, 0, 12), true, true, 0);
		
		pack_start(UI.wrap_alignment(artist_section_label, 6, 0, 6, 0), false, true, 0);
		pack_start(hbox, false, true, 0);
	}
	
	void update_contents() {
		Media m = App.playback.current_media;
		if(m == null) {
			return;
		}
		
		update_artist_section();
		update_sensitivities();
	}
	
	void update_artist_section() {
		if(App.playback.current_media == null)
			return;
		
		artist_section_label.set_markup("<span size=\"x-large\"><b>" + Markup.escape_text(App.playback.current_media.artist) + "</b></span>");
		
		if(App.info.current_artist != null) {
			
			// TODO: Fixme
			
			/*var sim_artists = App.info.current_artist.similarArtists();
			string label = "";
			foreach(var sim_art in sim_artists) {
				label += "<a href=\"" + sim_art.url.replace("&", "&amp;") + "\">" + Markup.escape_text(sim_art.name) + "</a>, ";
			}
			
			// Remove trailing ','
			if(label.length > 2)
				label = label.substring(0, label.length - 2);
			
			similar_artists.set_markup(("<b>%s: </b>").printf(_("Similar Artists")) + label);
			similar_artists.set_visible(sim_artists.size > 1);*/
			
			/*var tags = App.info.current_artist.tags();
			label = "";
			foreach(var tag in tags) {
				label += "<a href=\"" + tag.url + "\">" + Markup.escape_text(tag.tag) + "</a>, ";
			}
			
			// Remove trailing ','
			if(label.length > 2)
				label = label.substring(0, label.length - 2);
			
			artist_tags.set_markup(("<b>%s: </b>").printf(_("Popular Tags")) + label);
			artist_tags.set_visible(tags.size > 1);*/
		}
		else {
			similar_artists.set_visible(false);
			artist_tags.set_visible(false);
		}
	}
	
	void media_played(Media m, Media? old) {
		update_contents();
		
		// TODO: Fixme
		/*if(old == null || old.album_artist != m.album_artist) {
			artist_images.clear();
			artist_images.fetch_images(m.album_artist);
			App.info.lastfm.fetch_top_artist_songs();
			App.info.lastfm.fetch_top_artist_albums();
			artist_top_songs_holder.set_visible(false);
			artist_top_albums_holder.set_visible(false);
			
			set_visible(false);
		}*/
	}
	
	void playback_stopped(Media? was_playing) {
		set_visible(false);
	}
	
	void medias_updated(Collection<Media> ids) {
		update_contents();
	}
	
	void top_artist_songs_retrieved(HashTable<int, Media> songs) {
		artist_top_songs.set_table(songs);
		artist_top_songs_holder.set_visible(songs.size() > 0);
		
		update_sensitivities();
	}
	
	void top_artist_albums_retrieved(HashTable<int, ExternalAlbum> albums) {
		artist_top_albums.set_table(albums);
		artist_top_albums_holder.set_visible(albums.size() > 0);
		
		update_sensitivities();
	}
	
	void artist_top_albums_chosen(GLib.Object o) {
		ExternalAlbum a = (ExternalAlbum)o;
		
		try {
			GLib.AppInfo.launch_default_for_uri (a.url, null);
		}
		catch(Error err) {
			stdout.printf("Couldn't open the similar media's last fm page: %s\n", err.message);
		}
	}
	
	void update_sensitivities() {
		bool media_playing = App.playback.current_media != null;
		bool song_playing = media_playing && App.playback.current_media is Song;
		bool have_artist_top_songs = (artist_top_songs.get_table().size() > 0);
		bool have_artist_top_albums = (artist_top_albums.get_table().size() > 0);
		
		set_visible(song_playing && (have_artist_top_songs || have_artist_top_albums));
	}
}
