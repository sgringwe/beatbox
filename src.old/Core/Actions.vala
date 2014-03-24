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

public class BeatBox.Actions : BeatBox.ActionsInterface {
	//PreferencesWindow prefs;
	
	// TODO: Do an eq_closed event
	EqualizerWindow? eq;
	
	DuplicateSourceView? duplicates_view;
	
	public Actions() {
		initialize_actions();
	}
	
	private void initialize_actions() {
		create_playlist = new Gtk.Action("create_playlist", _("Create Playlist"), _("Create a new Playlist"), null);
		create_smart_playlist = new Gtk.Action("create_smart_playlist", _("Create Smart Playlist"), _("Create a new Smart Playlist"), null);
		import_playlist = new Gtk.Action("import_playlist", _("Import Playlist"), _("Import playlist from file"), null);
		import_station = new Gtk.Action("import_station", _("Import Station"), _("Import station from file"), null);
		add_podcast_feed = new Gtk.Action("add_podcast_feed", _("Add RSS Feed"), _("Add a new RSS Podcast Feed to your library"), null);
		refresh_podcasts = new Gtk.Action("refresh_podcasts", _("Download new Episodes"), _("Download new Podcast Episodes"), null);
		show_preferences = new Gtk.Action("show_preferences", _("Preferences"), _("Preferences"), null);
		show_equalizer = new Gtk.Action("show_equalizer", _("Equalizer"), _("Equalizer"), null);
		next = new Gtk.Action("next", _("Next"), _("Next"), null);
		play_pause = new Gtk.Action("play_pause", _("Play/Pause"), _("Play/Pause"), null);
		previous = new Gtk.Action("previous", _("Previous"), _("Previous"), null);
		lastfm_ban = new Gtk.Action("lastfm_ban", _("Ban"), _("Love"), null);
		lastfm_love = new Gtk.Action("lastfm_love", _("Love"), _("Love"), null);
		show_duplicates = new Gtk.Action("show_duplicates", _("Show Duplicates"), _("Show Duplicates"), null);
		hide_duplicates = new Gtk.Action("hide_duplicates", _("Hide Duplicates"), _("Hide Duplicates"), null);
		exit = new Gtk.Action("exit", _("Exit"), _("Exit"), null);
		
		create_playlist.set_gicon(App.icons.PLAYLIST.get_gicon());
		create_smart_playlist.set_gicon(App.icons.SMART_PLAYLIST.get_gicon());
		show_preferences.set_stock_id(Gtk.Stock.PREFERENCES);
		show_duplicates.set_stock_id(Gtk.Stock.COPY);
		hide_duplicates.set_stock_id(Gtk.Stock.COPY);
		lastfm_ban.set_gicon(App.icons.LASTFM_BAN.get_gicon());
		lastfm_love.set_gicon(App.icons.LASTFM_LOVE.get_gicon());
		
		show_equalizer.set_sensitive(true);
		
		show_duplicates.set_visible(true);
		hide_duplicates.set_visible(false);
		
		create_playlist.activate.connect(create_playlist_activate);
		create_smart_playlist.activate.connect(create_smart_playlist_activate);
		import_playlist.activate.connect(import_playlist_activate);
		import_station.activate.connect(import_station_activate);
		add_podcast_feed.activate.connect(add_podcast_feed_activate);
		refresh_podcasts.activate.connect(refresh_podcasts_activate);
		show_preferences.activate.connect(show_preferences_activate);
		show_equalizer.activate.connect(show_equalizer_activate);
		next.activate.connect(next_activate);
		play_pause.activate.connect(play_pause_activate);
		previous.activate.connect(previous_activate);
		lastfm_ban.activate.connect(lastfm_ban_activate);
		lastfm_love.activate.connect(lastfm_love_activate);
		show_duplicates.activate.connect(show_duplicates_activate);
		hide_duplicates.activate.connect(hide_duplicates_activate);
		exit.activate.connect(exit_activate);
		
		App.playback.media_played.connect(media_played);
		App.playback.playback_played.connect(playback_played);
		App.playback.playback_paused.connect(playback_paused);
		App.playback.playback_stopped.connect(playback_stopped);
		App.operations.operation_started.connect(operation_started);
		App.operations.operation_finished.connect(operation_finished);
	}
	
	private void create_playlist_activate() {
		var pnw = new PlaylistNameWindow(new StaticPlaylist());
		pnw.playlist_saved.connect( (p) => {
			App.playlists.add_playlist(p);
		});
	}
	
	private void create_smart_playlist_activate() {
		var spe = new SmartPlaylistEditor(new SmartPlaylist());
		spe.playlist_saved.connect( (sp) => {
			App.playlists.add_playlist(sp);
		});
	}
	
	private void import_playlist_activate() {
		import_playlist_or_station("Playlist");
	}
	
	private void import_station_activate() {
		import_playlist_or_station("Station");
	}
	
	private void add_podcast_feed_activate() {
		AddPodcastWindow apw = new AddPodcastWindow();
		apw.show();
	}
	
	private void refresh_podcasts_activate() {
		App.podcasts.find_new_podcasts();
	}
	
	public override void show_set_library_folder_dialog(Library library) {
		File? folder = null;
		var file_chooser = new Gtk.FileChooserDialog (_("Choose %s Folder").printf(library.name), App.window,
								  Gtk.FileChooserAction.SELECT_FOLDER,
								  Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
								  Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
		file_chooser.set_local_only(true);
		if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
			folder = File.new_for_path(file_chooser.get_filename());
		}
		file_chooser.destroy ();
		
		// If different folder chosen, or we have no songs anyways, do set.
		if(folder != null && (folder != library.folder || library.media_count() == 0)) {
			App.window.confirm_set_library_folder(library, folder);
		}
	}
	
	public override void show_import_folders_dialog(Library library) {
		GLib.SList<File> folders = new GLib.SList<File>();
		var file_chooser = new Gtk.FileChooserDialog (_("Import %s").printf(library.name), App.window,
								  Gtk.FileChooserAction.SELECT_FOLDER,
								  Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
								  Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
		file_chooser.set_local_only(true);
		file_chooser.set_select_multiple(true); // allow user to select multiple folders

		if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
			folders = file_chooser.get_files();
		}
		file_chooser.destroy ();
		
		bool tried_import_from_music_folder = false;
		var final_folders = new Gee.LinkedList<File>();
		if(folders.length() > 0) {
			foreach(var folder in folders) {
				if(!folder.get_path().has_prefix(App.settings.main.music_folder)) {
					final_folders.add(folder);
				}
				else {
					tried_import_from_music_folder = true;
				}
			}
			
			if(final_folders.size > 0 && library.folder.query_exists()) {
				library.add_folders(final_folders);
			}
			else if(!library.folder.query_exists()) {
				App.window.doAlert(_("Import Failed"), _("Your library's %s folder could not be found. Please make sure your %s folder is mounted before importing.").printf(library.name, library.name));
			}
		}
		if(tried_import_from_music_folder && final_folders.size > 0) {
			App.window.doAlert(_("Doing Partial Import"), _("Some of the folders you selected to import are already in your %s Folder. Please rescan instead.").printf(library.name));
		}
	}
	
	// TODO: Don't allow showing more than 1 prefs window
	private void show_preferences_activate() {
		var prefs = new PreferencesWindow();
		prefs.present();
	}
	
	private void show_equalizer_activate() {
		if(eq != null && eq is Gtk.Window) {
			warning("Just showing current equalizer instead of creating new one");
			return;
		}
		
		eq = new EqualizerWindow();
		eq.show_all();
	}
	
	public override void destroy_equalizer() {
		eq.destroy();
		eq = null;
	}
	
	private void next_activate() {
		App.playback.request_next();
	}
	
	private void play_pause_activate() {
		if(App.playback.playing) {
			App.playback.pause();
		}
		else {
			App.playback.play();
		}
	}
	
	private void previous_activate() {
		App.playback.request_previous();
	}
	
	private void lastfm_ban_activate() {
		App.info.lastfm.ban_track(App.playback.current_media.title, App.playback.current_media.artist);
	}
	
	private void lastfm_love_activate() {
		App.info.lastfm.love_track(App.playback.current_media.title, App.playback.current_media.artist);
	}
	
	private void show_duplicates_activate() {
		RemoveDuplicatesDialog rdd = new RemoveDuplicatesDialog();
		rdd.duplicates_found.connect(duplicates_found);
	}
	
	void duplicates_found(Gee.HashMap<Media, Gee.Collection<Media>> dups) {
		duplicates_view = new DuplicateSourceView();
		duplicates_view.set_dups(dups);
		
		App.window.add_view(duplicates_view);
		App.window.set_active_view(duplicates_view);
		
		show_duplicates.set_visible(false);
		hide_duplicates.set_visible(true);
	}
	
	private void hide_duplicates_activate() {
		App.window.remove_view(duplicates_view);
		
		duplicates_view = null;
		show_duplicates.set_visible(true);
		hide_duplicates.set_visible(false);
	}
	
	private void exit_activate() {
		App.window.destroy();
	}
	
	// These functions update the sensitivities of the various actions
	void media_played(Media m, Media? old) {
		var lastfm_elements_visible = App.settings.lastfm.session_key != "";
		// TODO: Listen to lastfm login event
		lastfm_ban.set_sensitive(lastfm_elements_visible);
		lastfm_love.set_sensitive(lastfm_elements_visible);
	}
	
	void playback_played() {
		play_pause.set_label(_("Pause")); // TODO: Set image, description
	}
	
	void playback_paused() {
		play_pause.set_label(_("Play")); // TODO Set image, description
	}
	
	void playback_stopped(Media? was_playing) {
		playback_paused();
		
		lastfm_ban.set_sensitive(false);
		lastfm_love.set_sensitive(false);
	}
	
	void operation_started() {
		import_playlist.set_sensitive(false);
		import_station.set_sensitive(false);
		add_podcast_feed.set_sensitive(false);
		refresh_podcasts.set_sensitive(false);
	}
	
	void operation_finished() {
		bool folderSet = (App.settings.main.music_folder != "");
		
		import_playlist.set_sensitive(folderSet);
		import_station.set_sensitive(true);
		add_podcast_feed.set_sensitive(true);
		refresh_podcasts.set_sensitive(true);
	}
	
	private void import_playlist_or_station(string to_import) {
		string file = "";
		string name = "";
		var file_chooser = new Gtk.FileChooserDialog (_("Import %s").printf(to_import), App.window,
								  Gtk.FileChooserAction.OPEN,
								  Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
								  Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
		
		// filters for .m3u and .pls
		var m3u_filter = new Gtk.FileFilter();
		m3u_filter.add_pattern("*.m3u");
		m3u_filter.set_filter_name("MPEG Version 3.0 Extended (*.m3u)");
		file_chooser.add_filter(m3u_filter);
		
		var pls_filter = new Gtk.FileFilter();
		pls_filter.add_pattern("*.pls");
		pls_filter.set_filter_name("Shoutcast Playlist Version 2.0 (*.pls)");
		file_chooser.add_filter(pls_filter);
		
		if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
			file = file_chooser.get_filename();
			name = file.slice(file.last_index_of("/", 0) + 1, file.last_index_of(".", 0));
		}
		
		file_chooser.destroy ();
		
		var files = new Gee.LinkedList<File>();
		var stations = new Gee.LinkedList<Media>();
		bool success = false;
		
		if(file != "") {
			if(file.has_suffix(".m3u")) {
				success = PlaylistUtils.parse_paths_from_m3u(file, ref files, ref stations);
			}
			else if(file.has_suffix(".pls")) {
				success = PlaylistUtils.parse_paths_from_pls(file, ref files, ref stations);
			}
			else {
				success = false;
				App.window.doAlert(_("Invalid Playlist"), _("Unrecognized playlist file. Import failed."));
				return;
			}
		}
		
		if(success) {
			if(files.size > 0) {
				// TODO: Which library to add to?
				App.playlists.add_playlist_to_library(App.library.song_library, name, files);
			}
			if(stations.size > 0) {
				App.library.station_library.add_medias(stations);
			}
		}
	}
}
