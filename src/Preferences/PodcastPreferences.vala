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

public class BeatBox.PodcastPreferences : GLib.Object, PreferencesSection {
	public PreferencesSectionCategory category { get { return PreferencesSectionCategory.LIBRARIES; } }
	public string title { get { return "Podcasts"; } }
	public Gdk.Pixbuf? icon { get { return null; } }
	public Widget widget { get { return content; } }
	
	Box content;
	FileChooserButton fileChooser;
	Button import;
	Button rescan;
	CheckButton downloadNewPodcasts;
	
	public PodcastPreferences() {
		content = new Box(Orientation.VERTICAL, 0);
		content.spacing = 10;
		
		var podcastLabel = new Label(_("Podcast Library Location"));
		fileChooser = new FileChooserButton(_("Podcast Folder"), FileChooserAction.SELECT_FOLDER);
		import = new Button.with_label(_("Import..."));
		rescan = new Button.with_label(_("Rescan"));
		
		var managementLabel = new Label(_("Library Management"));
		downloadNewPodcasts = new CheckButton.with_label(_("Automatically download new podcast episodes"));
		
		managementLabel.xalign = 0.0f;
		podcastLabel.xalign = 0.0f;
		podcastLabel.set_markup("<b>" + _("Podcast Library Location") + "</b>");
		managementLabel.set_markup("<b>" + _("Library Management") + "</b>");
		
		var button_box = new HButtonBox();
		button_box.set_layout(ButtonBoxStyle.END);
		button_box.pack_end(import, false, false, 0);
		button_box.pack_end(rescan, false, false, 0);
		
		fileChooser.set_current_folder(App.settings.main.podcast_folder);
		downloadNewPodcasts.set_active(App.settings.main.download_new_podcasts);
		
		content.pack_start(podcastLabel, false, true, 0);
		content.pack_start(UI.wrap_alignment(fileChooser, 0, 0, 0, 10), false, true, 0);
		content.pack_start(UI.wrap_alignment(button_box, 0, 0, 0, 10), false, true, 0);
		content.pack_start(managementLabel, false, true, 0);
		content.pack_start(UI.wrap_alignment(downloadNewPodcasts, 0, 0, 0, 10), false, true, 0);
		
		App.operations.operation_started.connect(operation_started);
		App.operations.operation_finished.connect(operation_finished);
		if (App.operations.doing_ops) {
			operation_started();
		}
		
		fileChooser.current_folder_changed.connect(file_chooser_set);
		import.clicked.connect(import_clicked);
		rescan.clicked.connect(rescan_clicked);
		downloadNewPodcasts.toggled.connect(download_new_podcasts_toggled);
	}
	
	void download_new_podcasts_toggled() {
		App.settings.main.download_new_podcasts = downloadNewPodcasts.get_active();
	}
	
	// The idle is so that the dialog is layered properly above the media editor
	void file_chooser_set() {
		Idle.add( () => {
			if(fileChooser.get_current_folder() != App.settings.main.podcast_folder) {
				App.window.confirm_set_library_folder(App.library.podcast_library, File.new_for_path(fileChooser.get_current_folder()));
			}
			
			return false;
		});
	}
	
	void import_clicked() {
		App.actions.show_import_folders_dialog(App.library.podcast_library);
	}
	
	void rescan_clicked() {
		if(App.library.podcast_library.folder.query_exists()) {
			App.library.podcast_library.rescan_local_folder();
		}
		else {
			App.window.doAlert(_("Could not find Music Folder"), _("Please make sure that your Music folder is accessible and mounted."));
		}
	}
	
	public void save() {
		
	}
	
	public void cancel() {
		
	}
	
	void operation_started() {
		fileChooser.set_sensitive(false);
		import.set_sensitive(false);
		rescan.set_sensitive(false);
		fileChooser.set_tooltip_text(_("Please wait until all operations finish before setting your podcast folder."));
	}
	
	void operation_finished () {
		fileChooser.set_tooltip_text("");
		fileChooser.set_sensitive(true);
		import.set_sensitive(true);
		rescan.set_sensitive(true);
	}
}
