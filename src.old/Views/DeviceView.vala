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

public class BeatBox.DeviceView : Box, View {
	Device d;
	DeviceSummaryWidget summary;
	
	GLib.List<View> sub_views; // will be different depending on what device supports
	View songs_view;
	View podcasts_view;
	//View audiobooks_view;
	
	Gtk.Menu deviceMenu;
	Gtk.MenuItem deviceImportToLibrary;
	Gtk.MenuItem deviceSync;
	Gtk.MenuItem deviceUnmount;
	
	public DeviceView(Device d) {
		this.d = d;
		
		buildUI();
		
		// Build the sub views
		songs_view =  new DeviceSourceView(d.get_songs(), new TreeViewSetup(MusicColumn.ARTIST, SortType.ASCENDING, TreeViewSetup.Hint.DEVICE_AUDIO), d);
		sub_views.append(songs_view);
		
		if(d.supports_podcasts()) {
			podcasts_view = new DeviceSourceView(d.get_podcasts(), new TreeViewSetup(PodcastColumn.ARTIST, SortType.ASCENDING, TreeViewSetup.Hint.DEVICE_PODCAST), d);
			sub_views.append(podcasts_view);
		}
		if(d.supports_audiobooks() && false) {
			//sub_views = new DeviceSourceView(lm, lm.lw, d.get_podcasts(), "Artist", Gtk.SortType.ASCENDING, SourceView.Hint.DEVICE_AUDIOBOOK, -1, d);
			//sub_views.append(audiobooks_view);
		}
		
		// Auto sync
		if(d.get_preferences().sync_when_mounted)
			syncClicked();
	}
	
	void buildUI() {
		summary = new DeviceSummaryWidget(d);
		pack_start(summary, true, true, 0);
		
		deviceMenu = new Gtk.Menu();
		deviceImportToLibrary = new Gtk.MenuItem.with_label(_("Import from Device"));
		deviceSync = new Gtk.MenuItem.with_label(_("Sync"));
		deviceUnmount = new Gtk.MenuItem.with_label(_("Unmount"));
		deviceMenu.append(deviceImportToLibrary);
		deviceMenu.append(deviceSync);
		deviceMenu.append(deviceUnmount);
		deviceImportToLibrary.activate.connect(deviceImportToLibraryClicked);
		deviceSync.activate.connect(deviceSyncClicked);
		deviceUnmount.activate.connect(deviceUnmountClicked);
		deviceMenu.show_all();
		
		show_all();
	}
	
	public void showImportDialog() {
		// ask the user if they want to import medias from device that they don't have in their library (if any)
		// this should be same as MusicViewWrapper
		if(!App.operations.doing_ops && App.settings.main.music_folder != "") {
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
	
	public void syncClicked() {
		summary.syncClicked();
	}
	
	/** Implement view interface **/
	public View.ViewType get_view_type() {
		return View.ViewType.DEVICE;
	}
	
	public Object? get_object() {
		return d;
	}
	
	public Gdk.Pixbuf get_view_icon() {
		if(d.getContentType() == "cdrom")
			return App.icons.AUDIO_CD.render(IconSize.MENU, null);
		else if(d.getContentType() == "ipod-new")
			return App.icons.render_icon ("phone", IconSize.MENU);
		else if(d.getContentType() == "ipod-old")
			return App.icons.render_icon("multimedia-player", IconSize.MENU);
		else if(d.getContentType() == "android")
			return App.icons.render_icon("phone", IconSize.MENU);
		else
			return App.icons.render_icon("multimedia-player", IconSize.MENU);
	}
	
	public string get_view_name() {
		return d.getDisplayName();
	}
	
	public Gtk.Menu? get_context_menu() {
		return deviceMenu;
	}
	
	public bool can_receive_drop() {
		return !App.operations.doing_ops;
	}
	
	public void drag_received(Gtk.SelectionData data) {
		message("Adding files to device from drag'n'drop\n");
				
		var to_add = new LinkedList<Media>();
		foreach (string uri in data.get_uris ()) {
			File file = File.new_for_uri (uri);
			if(file.query_file_type(FileQueryInfoFlags.NOFOLLOW_SYMLINKS) == FileType.REGULAR && file.is_native ()) {
				Media m = App.library.media_from_file(uri);
				
				if(m != null) {
					to_add.add(m);
				}
			}
		}
		
		d.add_medias(to_add);
	}
	
	public GLib.List<View> get_sub_views() {
		return sub_views.copy(); // Does that mean our views will be duplicated to? if so, we'll have 2 versions floating around
	}
	
	public void set_as_current_view () {
		show_all();
		summary.refreshLists();
	}
	
	public void unset_as_current_view() {
		// Nothing to do
	}
	
	public SideTreeCategory get_sidetree_category() {
		return SideTreeCategory.DEVICE;
	}
	
	// Search
	public bool supports_search() {
		return false;
	}
	
	public int requested_search_timeout() {
		return 0;
	}
	
	public void search_activated(string search) {
		//App.window.set_active_view(songs_view);
		//songs_view.search_activated(search);
	}
	
	public void search_changed(string search) {
		//App.window.set_active_view(songs_view);
		//songs_view.search_activated(search);
	}
	
	public GLib.List<Gtk.MenuItem>? get_search_menu(string search) {
		//App.window.set_active_view(songs_view);
		//songs_view.search_activated(search);
		
		return null;
	}
	
	public bool supports_view_selector() {
		return false;
	}
	
	public void view_selection_changed(int option) {
		
	}
	
	// Playback
	public bool can_set_as_current_list() {
		return false;
	}
	
	public void set_as_current_list(Media? m) {
		// Nothing to do
	}
	
	public void play_first_media () {
		//App.window.set_active_view(songs_view);
		//songs_view.play_first_media();
	}
	
	// General
	public string? get_statusbar_text() {
		return null;
	}
	
	public void reset_view() {
		
	}
	
	// Context menu event handlers
	void deviceImportToLibraryClicked() {
		showImportDialog();
	}
	
	void deviceSyncClicked() {
		syncClicked();
	}
	
	void deviceUnmountClicked() {
		d.unmount();
	}
}
