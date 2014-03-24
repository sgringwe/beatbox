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

public class BeatBox.BehaviorPreferences : GLib.Object, PreferencesSection {
	public PreferencesSectionCategory category { get { return PreferencesSectionCategory.GENERAL; } }
	public string title { get { return "Behavior"; } }
	public Gdk.Pixbuf? icon { get { return null; } }
	public Widget widget { get { return content; } }
	
	Box content;
	CheckButton organizeFolders;
	CheckButton writeMetadataToFile;
	CheckButton copyImportedMusic;
	
	public BehaviorPreferences() {
		content = new Box(Orientation.VERTICAL, 0);
		content.spacing = 10;
		
		var managementLabel = new Label(_("Library Management"));
		organizeFolders = new CheckButton.with_label(_("Keep media folders organized"));
		writeMetadataToFile = new CheckButton.with_label(_("Write metadata to file"));
		copyImportedMusic = new CheckButton.with_label(_("Copy files to library folder when imported"));
		
		managementLabel.xalign = 0.0f;
		managementLabel.set_markup("<b>" + _("Library Management") + "</b>");
		
		organizeFolders.set_active(App.settings.main.update_folder_hierarchy);
		writeMetadataToFile.set_active(App.settings.main.write_metadata_to_file);
		copyImportedMusic.set_active(App.settings.main.copy_imported_music);
		
		content.pack_start(managementLabel, false, true, 0);
		content.pack_start(UI.wrap_alignment(organizeFolders, 0, 0, 0, 10), false, true, 0);
		content.pack_start(UI.wrap_alignment(writeMetadataToFile, 0, 0, 0, 10), false, true, 0);
		content.pack_start(UI.wrap_alignment(copyImportedMusic, 0, 0, 0, 10), false, true, 0);
		
		organizeFolders.toggled.connect(organize_folders_toggled);
		writeMetadataToFile.toggled.connect(write_metadata_to_file_toggled);
		copyImportedMusic.toggled.connect(copy_imported_music_toggled);
	}
	
	void organize_folders_toggled() {
		App.settings.main.update_folder_hierarchy = organizeFolders.get_active();
	}
	
	void write_metadata_to_file_toggled() {
		App.settings.main.write_metadata_to_file = writeMetadataToFile.get_active();
	}
	
	void copy_imported_music_toggled() {
		App.settings.main.copy_imported_music = copyImportedMusic.get_active();
	}
	
	public void save() {
		
	}
	
	public void cancel() {
		
	}
}
