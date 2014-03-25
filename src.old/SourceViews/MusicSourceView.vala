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

public class BeatBox.MusicSourceView : SourceView {
	HashMap<int, Device> welcome_screen_keys;
	
	public MusicSourceView() {
		base(App.library.song_library.medias(), App.window.setups.get_setup(ListSetupInterface.MUSIC_KEY));
		
		this.media_representation = _("song");
		
		// Setup welcome screen
		welcome_screen = new Granite.Widgets.Welcome(_("Get Some Tunes"), _("BeatBox can't find your music."));
		welcome_screen_keys = new HashMap<int, Device>();
		var music_folder_icon = App.icons.MUSIC_FOLDER.render (IconSize.DIALOG, null);
		welcome_screen.append_with_pixbuf(music_folder_icon, _("Locate"), _("Change your music folder."));
		welcome_screen.activated.connect(welcome_screen_activated);
		
		warning("TODO: Fixme");
		App.devices.device_added.connect(device_added);
		App.devices.device_removed.connect(device_removed);
		
		// Setup content widgets
		list_view = new MusicList (tvs);
		album_view = new AlbumGrid(this, tvs);
		error_box = new EmbeddedAlert();
		pack_widgets();
		
		// Populate views
		set_media_sync(original_medias, false);
		
		// Setup signal handlers
		App.library.song_library.medias_updated.connect (update_medias);
		App.library.song_library.medias_added.connect (add_medias);
		App.library.song_library.medias_removed.connect (remove_medias);
		App.operations.operation_started.connect(operation_started);
		App.operations.operation_finished.connect(operation_finished);
	}
	
	protected override void pre_set_as_current_view() {
		
	}
	
	protected override void set_default_warning () {
		
	}
	
	/* device stuff for welcome screen */
	public void device_added(Device d) {
		// add option to import in welcome screen
		string secondary = (d.getContentType() == "cdrom") ? _("Import songs from audio CD") : _("Import media from device");
		int key = welcome_screen.append_with_image( new Image.from_gicon(d.get_icon(), Gtk.IconSize.DIALOG), d.getDisplayName(), secondary);
		welcome_screen_keys.set(key, d);
		
		// Show the newly added item
		if(welcome_screen.visible) {
			welcome_screen.show_all();
		}
	}

	public void device_removed(Device d) {
		// remove option to import from welcome screen
		int key = 0;
		foreach(int i in welcome_screen_keys.keys) {
			if(welcome_screen_keys.get(i) == d) {
				key = i;
				break;
			}
		}
		
		/// Remember that 0 is taken by set location, so keys start at 1, 2, 3.
		int offset = 1; // How many items are before device items
		if(key >= offset) {
			// Move down all higher indexes so that they are not offset
			for(int i = key; i < welcome_screen_keys.size - 1 + offset; ++i) {
				welcome_screen_keys.set(i, welcome_screen_keys.get(i + 1));
			}
			
			welcome_screen_keys.unset(welcome_screen_keys.size - 1 + offset); // size == last index
			welcome_screen.remove_item(key);
		}
		else {
			warning("Device removed but not found in welcome_screen_keys. UI may be messed up\n");
		}
	}
	
	void welcome_screen_activated(int index) {
		if(App.operations.doing_ops) {
			return;
		}
		
		if(index == 0) {
			App.actions.show_set_library_folder_dialog(App.library.song_library);
		}
		else {
			Device d = welcome_screen_keys.get(index);

			if(d.getContentType() == "cdrom") {
				View cd_view = App.window.get_view_from_object(d);
				if(cd_view != null) {
					App.window.set_active_view(cd_view);
				}

				var to_transfer = new LinkedList<Media>();
				foreach(var m in d.get_medias())
					to_transfer.add(m);

				d.transfer_to_library(to_transfer);
			}
			else {
				// ask the user if they want to import medias from device that they don't have in their library (if any)
				// this should be same as DeviceView
				if(App.settings.main.music_folder != "") {
					var found = new LinkedList<Media>();
					var not_found = new LinkedList<Media>();
					App.library.medias_from_name(d.get_medias(), ref found, ref not_found);
					
					if(not_found.size > 0) {
						TransferFromDeviceDialog tfdd = new TransferFromDeviceDialog(d, not_found);
						tfdd.show();
					}
					else {
						App.window.doAlert(_("No External Songs"), _("There were no songs found on this device that are not in your library."));
					}
				}
			}
		}
	}
	
	void operation_started() {
		for(int i = 0; i < 1 + welcome_screen_keys.size; ++i) {
			welcome_screen.set_item_sensitivity(i, false);
		}
	}
	
	void operation_finished() {
		for(int i = 0; i < 1 + welcome_screen_keys.size; ++i) {
			welcome_screen.set_item_sensitivity(i, true);
		}
	}
	
	/** Specific implementations for View interface **/
	public override View.ViewType get_view_type() {
		return View.ViewType.MUSIC;
	}
	
	public override Object? get_object() {
		return null;
	}
	
	public override Gdk.Pixbuf get_view_icon() {
		return App.icons.MUSIC.render(IconSize.MENU, null);
	}
	
	public override string get_view_name() {
		return _("Music");
	}
	
	public override Gtk.Menu? get_context_menu() {
		return null;
	}
	
	public override bool can_receive_drop() {
		return false;
	}
	
	public override void drag_received(Gtk.SelectionData data) {
		
	}
	
	public override SideTreeCategory get_sidetree_category() {
		return SideTreeCategory.LIBRARY;
	}
}

