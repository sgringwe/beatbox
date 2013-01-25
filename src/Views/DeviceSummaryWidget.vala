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

public class BeatBox.DeviceSummaryWidget : Box {
	Device dev;
	
	Granite.Widgets.HintedEntry deviceName;
	Switch syncAtStart;
	
	CheckButton syncMusic;
	CheckButton syncPodcasts;
	//CheckButton syncAudiobooks;
	ComboBox musicDropdown;
	ComboBox podcastDropdown;
	//ComboBox audiobookDropdown;
	ListStore musicList;
	ListStore podcastList;
	//ListStore audiobookList;
	
	StyledContentBox top_portion;
	Gtk.Image deviceImage;
	SpaceWidget spaceWidget;
	
	int music_index;
	int podcast_index;
	//int audiobook_index;
	int other_index;
	
	public DeviceSummaryWidget(Device d) {
		this.dev = d;
		
		buildUI();
	}
	
	public void buildUI() {
		// options at top
		deviceName = new Granite.Widgets.HintedEntry(_("Device Name"));
		syncAtStart = new Gtk.Switch();
		syncMusic = new CheckButton();
		syncPodcasts = new CheckButton();
		//syncAudiobooks = new CheckButton();
		musicDropdown = new ComboBox();
		podcastDropdown = new ComboBox();
		//audiobookDropdown = new ComboBox();
		musicList = new ListStore(3, typeof(GLib.Object), typeof(string), typeof(Gdk.Pixbuf));
		podcastList = new ListStore(3, typeof(GLib.Object), typeof(string), typeof(Gdk.Pixbuf));
		//audiobookList = new ListStore(3, typeof(GLib.Object), typeof(string), typeof(Gdk.Pixbuf));
		
		//get_style_context().add_class (Granite.STYLE_CLASS_CONTENT_VIEW);
		
		top_portion = new StyledContentBox();
		deviceImage = new Gtk.Image.from_gicon(dev.get_icon(), IconSize.DIALOG);
		spaceWidget = new SpaceWidget(dev.get_capacity());
		
		Label deviceNameLabel = new Label(_("Device Name:"));
		Label autoSyncLabel = new Label(_("Automatically sync when plugged in:"));
		Label syncOptionsLabel = new Label(_("Sync:"));
		
		var content = new Box(Orientation.VERTICAL, 10);
		
		setupLists();

		music_index = spaceWidget.add_item(_("Music"), 0, SpaceWidget.ItemColor.BLUE);
		podcast_index = spaceWidget.add_item(_("Podcasts"), 0, SpaceWidget.ItemColor.PURPLE);
		//audiobook_index = spaceWidget.add_item("Audiobooks", 0.0, SpaceWidget.ItemColor.GREEN);
		other_index = spaceWidget.add_item(_("Other"), 0, SpaceWidget.ItemColor.ORANGE);
		
		refreshSpaceWidget();
		
		// device name box
		var deviceNameBox = new Box(Orientation.HORIZONTAL, 6);
		deviceNameBox.homogeneous = true;
		deviceNameBox.pack_start(deviceNameLabel, false, true, 0);
		deviceNameBox.pack_start(deviceName, false, true, 0);
		
		// auto sync box
		var autoSyncBox = new Box(Orientation.HORIZONTAL, 6);
		autoSyncBox.homogeneous = true;
		autoSyncBox.pack_start(autoSyncLabel, false, true, 0);
		autoSyncBox.pack_start(UI.wrap_alignment(syncAtStart, 0, 0, 0, 0), false, true, 0);
		
		// sync options box
		var musicBox = new Box(Orientation.HORIZONTAL, 6);
		musicBox.pack_start(syncMusic, false, false, 0);
		musicBox.pack_start(musicDropdown, false, false, 0);
		
		var podcastBox = new Box(Orientation.HORIZONTAL, 6);
		podcastBox.pack_start(syncPodcasts, false, false, 0);
		podcastBox.pack_start(podcastDropdown, false, false, 0);
		
		//var audiobookBox = new Box(Orientation.HORIZONTAL, 6);
		//audiobookBox.pack_start(syncAudiobooks, false, false, 0);
		//audiobookBox.pack_start(audiobookDropdown, false, false, 0);
		
		var syncOptionsBox = new Box(Orientation.VERTICAL, 0);
		syncOptionsBox.pack_start(musicBox, false, false, 0);
		if(dev.supports_podcasts()) 	syncOptionsBox.pack_start(podcastBox, false, false, 0);
		//if(dev.supports_audiobooks()) 	syncOptionsBox.pack_start(audiobookBox, false, false, 0);
		
		var syncHBox = new Box(Orientation.HORIZONTAL, 6);
		syncHBox.homogeneous = true;
		syncHBox.pack_start(syncOptionsLabel, false, true, 0);
		syncHBox.pack_start(syncOptionsBox, false, true, 0);
		
		// create bottom section
		//var syncBox = new Box(Orientation.VERTICAL, 0);
		//var syncButtonBox = new VButtonBox();
		//syncButtonBox.set_layout(ButtonBoxStyle.END);
		//syncButtonBox.pack_end(syncButton, false, false, 0);
		//syncBox.pack_end(syncButton, false, false, 0);
		
		//var bottomBox = new Box(Orientation.HORIZONTAL, 0);
		//bottomBox.pack_start(deviceImage, false, true, 0);
		//bottomBox.pack_start(spaceWidgetScroll, true, true, 0);
		//bottomBox.pack_start(syncButtonBox, false, false, 0);
		
		// put it all together
		content.pack_start(deviceNameBox, false, true, 0);
		content.pack_start(autoSyncBox, false, true, 0);
		content.pack_start(syncHBox, false, true, 0);
		top_portion.set_content(UI.wrap_alignment(content, 15, 10, 10, 10));
		
		this.set_orientation(Orientation.VERTICAL);
		set_border_width(0);
		
		this.pack_start(top_portion, true, true, 0);
		this.pack_end(spaceWidget, false, true, 0);
		
		//add_with_viewport(content_plus_spacewidget);//wrap_alignment(content, 15, 10, 10, 10));
		
		deviceNameLabel.xalign = 1.0f;
		deviceName.halign = Align.START;
		if(dev.getDisplayName() != "")
			deviceName.set_text(dev.getDisplayName());
			
		autoSyncLabel.xalign = 1.0f;
		syncAtStart.halign = Align.START;
		
		syncOptionsLabel.yalign = 0.0f;
		syncOptionsLabel.xalign = 1.0f;
		syncOptionsBox.halign = Align.START;
		
		//set_policy(PolicyType.AUTOMATIC, PolicyType.NEVER);
		
		refreshLists();
		
		// set initial values
		syncAtStart.active = dev.get_preferences().sync_when_mounted;
		syncMusic.active = dev.get_preferences().sync_music;
		syncPodcasts.active = dev.get_preferences().sync_podcasts;
		//syncAudiobooks.active = dev.get_preferences().sync_audiobooks;
		
		if(dev.get_preferences().sync_all_music)
			musicDropdown.set_active(0);
		else {
			bool success = musicDropdown.set_active_id(dev.get_preferences().music_playlist);
			if(!success) {
				//App.window.doAlert("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().music_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
				dev.get_preferences().music_playlist = "";
				dev.get_preferences().sync_all_music = true;
				musicDropdown.set_active(0);
			}
		}
		if(dev.get_preferences().sync_all_podcasts)
			podcastDropdown.set_active(0);
		else {
			bool success = podcastDropdown.set_active_id(dev.get_preferences().podcast_playlist);
			if(!success) {
				//App.window.doAlert("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().podcast_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
				dev.get_preferences().podcast_playlist = "";
				dev.get_preferences().sync_all_podcasts = true;
				podcastDropdown.set_active(0);
			}
		}
		/*if(dev.get_preferences().sync_all_audiobooks)
			audiobookDropdown.set_active(0);
		else {
			bool success = audiobookDropdown.set_active_id(dev.get_preferences().audiobook_playlist);
			if(!success) {
				//App.window.doAlert("Missing Sync Playlist", "The playlist named <b>" + dev.get_preferences().audiobook_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
				dev.get_preferences().audiobook_playlist = "";
				dev.get_preferences().sync_all_audiobooks = true;
				audiobookDropdown.set_active(0);
			}
		}*/
		
		// hop onto signals to save preferences
		syncAtStart.notify["active"].connect(savePreferences);
		syncMusic.toggled.connect(savePreferences);
		syncPodcasts.toggled.connect(savePreferences);
		//syncAudiobooks.toggled.connect(savePreferences);
		musicDropdown.changed.connect(savePreferences);
		podcastDropdown.changed.connect(savePreferences);
		//audiobookDropdown.changed.connect(savePreferences);
		
		deviceName.changed.connect(deviceNameChanged);
		spaceWidget.sync_clicked.connect(syncClicked);
		dev.sync_finished.connect(sync_finished);
		
		show_all();
	}
	
	void refreshSpaceWidget() {
		uint64 media_size = 0; uint64 podcast_size = 0; /*double audiobook_size = 0.0;*/
		
		foreach(var m in dev.get_songs()) {
			media_size += m.file_size;
		}
		foreach(var m in dev.get_podcasts()) {
			podcast_size += m.file_size;
		}
		//foreach(int i in dev.get_audiobooks()) {
		//	audiobook_size += (double)(App.library.media_from_id(i).file_size);
		//}
		
		spaceWidget.update_item_size(music_index, media_size);
		spaceWidget.update_item_size(podcast_index, podcast_size);
		//spaceWidget.update_item_size(audiobook_index, audiobook_size);
		spaceWidget.update_item_size(other_index, dev.get_used_space() - media_size - podcast_size);
	}
	
	void setupLists() {
		musicDropdown.set_model(musicList);
		podcastDropdown.set_model(podcastList);
		//audiobookDropdown.set_model(audiobookList);
		
		musicDropdown.set_id_column(1);
		podcastDropdown.set_id_column(1);
		//audiobookDropdown.set_id_column(1);
		
		musicDropdown.set_row_separator_func(rowSeparatorFunc);
		podcastDropdown.set_row_separator_func(rowSeparatorFunc);
		//audiobookDropdown.set_row_separator_func(rowSeparatorFunc);
		
		var music_cell = new CellRendererPixbuf();
		musicDropdown.pack_start(music_cell, false);
		musicDropdown.add_attribute(music_cell, "pixbuf", 2);
		podcastDropdown.pack_start(music_cell, false);
		podcastDropdown.add_attribute(music_cell, "pixbuf", 2);
		//audiobookDropdown.pack_start(music_cell, false);
		//audiobookDropdown.add_attribute(music_cell, "pixbuf", 2);
		
		var cell = new CellRendererText();
		cell.ellipsize = Pango.EllipsizeMode.END;
		musicDropdown.pack_start(cell, true);
		musicDropdown.add_attribute(cell, "text", 1);
		podcastDropdown.pack_start(cell, true);
		podcastDropdown.add_attribute(cell, "text", 1);
		//audiobookDropdown.pack_start(cell, true);
		//audiobookDropdown.add_attribute(cell, "text", 1);
		
		musicDropdown.popup.connect(refreshLists);
		podcastDropdown.popup.connect(refreshLists);
		//audiobookDropdown.popup.connect(refreshLists);
		
		musicDropdown.set_button_sensitivity(SensitivityType.ON);
		podcastDropdown.set_button_sensitivity(SensitivityType.ON);
		//audiobookDropdown.set_button_sensitivity(SensitivityType.ON);
	}
	
	bool rowSeparatorFunc(TreeModel model, TreeIter iter) {
		string sep = "";
		model.get(iter, 1, out sep);
		
		return sep == "<separator_item_unique_name>";
	}
	
	void deviceNameChanged() {
		dev.setDisplayName(deviceName.get_text());
	}
	
	void savePreferences() {
		var pref = dev.get_preferences();
		
		pref.sync_when_mounted = syncAtStart.active;
		pref.sync_music = syncMusic.active;
		pref.sync_podcasts = syncPodcasts.active;
		//pref.sync_audiobooks = syncAudiobooks.active;
		
		pref.sync_all_music = musicDropdown.get_active() == 0;
		pref.sync_all_podcasts = podcastDropdown.get_active() == 0;
		//pref.sync_all_audiobooks = audiobookDropdown.get_active() == 0;
		
		pref.music_playlist = musicDropdown.get_active_id();
		pref.podcast_playlist = podcastDropdown.get_active_id();
		//pref.audiobook_playlist = audiobookDropdown.get_active_id();
		
		musicDropdown.sensitive = syncMusic.active;
		podcastDropdown.sensitive = syncPodcasts.active;
		//audiobookDropdown.sensitive = syncAudiobooks.active;
	}
	
	public bool allMediasSelected() {
		return false;
	}
	
	public void refreshLists() {
		string musicString = musicDropdown.get_active_id();
		string podcastString = podcastDropdown.get_active_id();
		//string audiobookString = audiobookDropdown.get_active_id();
		
		TreeIter iter;
		musicList.clear();
		podcastList.clear();
		//audiobookList.clear();
		
		/* add entire library options */
		musicList.append(out iter);
		musicList.set(iter, 0, null, 1, _("All Music"), 2, App.icons.MUSIC.render(IconSize.MENU));
		podcastList.append(out iter);
		podcastList.set(iter, 0, null, 1, _("All Podcasts"), 2, App.icons.PODCAST.render(IconSize.MENU));
		//audiobookList.append(out iter);
		//audiobookList.set(iter, 0, null, 1, "All Audiobooks");//, 2, App.icons.audiobook_icon.render(IconSize.MENU, audiobookDropdown.get_style_context()));
		
		/* add separator */
		musicList.append(out iter);
		musicList.set(iter, 0, null, 1, "<separator_item_unique_name>");
		podcastList.append(out iter);
		podcastList.set(iter, 0, null, 1, "<separator_item_unique_name>");
		//audiobookList.append(out iter);
		//audiobookList.set(iter, 0, null, 1, "<separator_item_unique_name>");
		
		/* add all playlists */
		var smart_playlist_pix = App.icons.SMART_PLAYLIST.render(IconSize.MENU, null);
		var playlist_pix = App.icons.PLAYLIST.render(IconSize.MENU, null);
		
		foreach(var p in App.playlists.playlists()) {
			var pix = (p is StaticPlaylist) ? playlist_pix : smart_playlist_pix;
			//bool music, podcasts, audiobooks;
			//test_media_types(App.library.medias_from_smart_playlist(p.rowid), out music, out podcasts, out audiobooks);
			
			//if(music) {
				musicList.append(out iter);
				musicList.set(iter, 0, p, 1, p.name, 2, pix);
			//}
			//if(podcasts) {
				podcastList.append(out iter);
				podcastList.set(iter, 0, p, 1, p.name, 2, pix);
			//}
			//if(audiobooks) {
				//audiobookList.append(out iter);
				//audiobookList.set(iter, 0, p, 1, p.name, 2, pix);
			//}
		}
		
		if(!musicDropdown.set_active_id(musicString))
			musicDropdown.set_active(0);
		if(!podcastDropdown.set_active_id(podcastString))
			podcastDropdown.set_active(0);
		//if(!audiobookDropdown.set_active_id(audiobookString))
		//	audiobookDropdown.set_active(0);
		
		message("setting sensitivity\n");
		musicDropdown.sensitive = dev.get_preferences().sync_music;
		podcastDropdown.sensitive = dev.get_preferences().sync_podcasts;
		//audiobookDropdown.sensitive = dev.get_preferences().sync_audiobooks;
	}
	
	/*void test_media_types(Gee.Collection<int> items, out bool music, out bool podcasts, out bool audiobooks) {
		music = false;
		podcasts = false;
		audiobooks = false;
		
		if(items.size == 0) {
			music = true; podcasts = true; audiobooks = true;
			return;
		}
		
		foreach(int i in items) {
			if(!music && App.library.media_from_id(i).mediatype == 0)
				music = true;
			if(!podcasts && App.library.media_from_id(i).mediatype == 1)
				podcasts = true;
			if(!audiobooks && App.library.media_from_id(i).mediatype == 2)
				audiobooks = true;
		}
	}*/
	
	void sync_finished(bool success) {
		refreshSpaceWidget();
		spaceWidget.set_sync_button_sensitive(true);
	}
	
	public void syncClicked() {
		var list = new Gee.LinkedList<Media>();
		var pref = dev.get_preferences();
		
		if(pref.sync_music) {
			Collection<Media> songs_to_add = new LinkedList<Media>();
			
			if(pref.sync_all_music) {
				songs_to_add = App.library.song_library.medias();
			}
			else {
				BasePlaylist p = App.playlists.playlist_from_name(pref.music_playlist);
				
				if(p != null) {
					songs_to_add = p.analyze(App.library.song_library.medias());
				}
				else {
					App.window.doAlert(_("Sync Failed"), _("The playlist named %s is used to sync device %s, but could not be found.").printf("<b>" + pref.music_playlist + "</b>", "<b>" + dev.getDisplayName() + "</b>"));
					
					pref.music_playlist = "";
					pref.sync_all_music = true;
					musicDropdown.set_active(0);
					return;
				}
			}
			
			foreach(Media s in songs_to_add) {
				if(!s.isTemporary)
					list.add(s);
			}
		}
		if(pref.sync_podcasts) {
			Collection<Media> podcasts_to_add = new LinkedList<Media>();
			
			if(pref.sync_all_podcasts) {
				podcasts_to_add = App.library.podcast_library.medias();
			}
			else {
				BasePlaylist p = App.playlists.playlist_from_name(pref.podcast_playlist);
				
				if(p != null) {
					podcasts_to_add = p.analyze(App.library.podcast_library.medias());
				}
				else {
					App.window.doAlert(_("Sync Failed"), _("The playlist named %s is used to sync device %s, but could not be found.").printf("<b>" + pref.podcast_playlist + "</b>", "<b>" + dev.getDisplayName() + "</b>"));
					pref.podcast_playlist = "";
					pref.sync_all_podcasts = true;
					musicDropdown.set_active(0);
					return;
				}
			}
		}
		/*if(pref.sync_audiobooks) {
			if(pref.sync_all_audiobooks) {
				foreach(var s in App.library.media()) {
					if(s.mediatype == 2 && !s.isTemporary)
						list.add(s.rowid);
				}
			}
			else {
				GLib.Object p = App.library.playlist_from_name(pref.audiobook_playlist);
				if(p == null)
					p = App.library.smart_playlist_from_name(pref.audiobook_playlist);
				
				if(p != null) {
					if(p is Playlist) {
						foreach(int i in ((Playlist)p).medias()) {
							if(App.library.media_from_id(i).mediatype == 2)
								list.add(i);
						}
					}
					else {
						foreach(int i in ((SmartPlaylist)p).analyze(lm)) {
							if(App.library.media_from_id(i).mediatype == 2)
								list.add(i);
						}
					}
				}
				else {
					App.window.doAlert("Sync Failed", "The playlist named <b>" + pref.audiobook_playlist + "</b> is used to sync device <b>" + dev.getDisplayName() + "</b>, but could not be found.");
					pref.audiobook_playlist = "";
					pref.sync_all_audiobooks = true;
					musicDropdown.set_active(0);
					return;
				}
			}
		}*/
		
		bool fits = dev.will_fit(list);
		if(!fits) {
			App.window.doAlert(_("Cannot Sync"), _("Cannot sync device with selected sync settings. Not enough space on disk") +"\n");
		}
		else if(dev.is_syncing()) {
			App.window.doAlert(_("Cannot Sync"), _("Device is already being synced."));
		}
		else {
			var found = new LinkedList<Media>();
			var not_found = new LinkedList<Media>();
			App.library.medias_from_name(dev.get_medias(), ref found, ref not_found);
			
			if(not_found.size > 0) { // hand control over to SWD
				SyncWarningDialog swd = new SyncWarningDialog(dev, list, not_found);
				swd.show();
			}
			else {
				spaceWidget.set_sync_button_sensitive(false);
				dev.sync_medias(list);
			}
		}
	}
}
