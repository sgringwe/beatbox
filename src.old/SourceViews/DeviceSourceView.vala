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
 * 
 * This SourceView is for device media lists (songs, podcasts, etc.), cdroms,
 * and any other list that contains content on a device.
 */

using Gee;
using Gtk;

public class BeatBox.DeviceSourceView : SourceView {
	Device d;
	
	// For View implementation
	Gtk.Menu CDMenu;
	Gtk.MenuItem CDimportToLibrary;
	Gtk.MenuItem CDeject;
	
	public DeviceSourceView(Collection<Media> medias, TreeViewSetup tvs, Device d) {
		base(medias, tvs);
		
		this.d = d;
		this.media_representation = _("song");
		
		// Setup content widgets
		list_view = new MusicList(tvs);
		error_box = new EmbeddedAlert();
		pack_widgets();
		
		// Setup context menu for this view
		CDMenu = new Gtk.Menu();
		CDimportToLibrary = new Gtk.MenuItem.with_label(_("Import to Library"));
		CDeject = new Gtk.MenuItem.with_label(_("Eject"));
		CDMenu.append(CDimportToLibrary);
		//CDMenu.append(CDeject);
		CDimportToLibrary.activate.connect(CDimportToLibraryClicked);
		CDeject.activate.connect(CDejectClicked);
		CDMenu.show_all();
		
		// Populate views
		set_media(original_medias, false);
		
		// Setup signal handlers
		list_view.import_requested.connect(import_request);
		d.sync_finished.connect(sync_finished);
	}
	
	protected override void pre_set_as_current_view() {
		
	}
	
	protected override void set_default_warning () {
		if(!have_error_box)
			return;
		
		switch (hint) {
			case TreeViewSetup.Hint.DEVICE_PODCAST:
				error_box.set_alert (_("No Podcasts Found"), _("This device supports podcasts. To sync podcasts with this device, edit the device's preferences."),
				null, true, Gtk.MessageType.INFO);

				break;
			case TreeViewSetup.Hint.DEVICE_AUDIO:
				error_box.set_alert (_("No Music Found"), _("To sync music with this device, edit the device's preferences."),
				null, true, Gtk.MessageType.INFO);

				break;
			case TreeViewSetup.Hint.DEVICE_AUDIOBOOK:
			
				break;
			case TreeViewSetup.Hint.CDROM:
				error_box.set_alert (_("Audio CD Invalid"), _("BeatBox could not read the contents of this Audio CD."), null, true, Gtk.MessageType.ERROR);
				
				break;
			default:
			
				break;
		}
	}
	
	void set_list(Collection<Media> medias) {
		if(have_list_view) {
			in_update.lock ();
			var new_table = new HashTable<int, Media>(null, null);
			foreach(var m in medias) {
				new_table.set((int)new_table.size(), m);
			}
			
			list_view.set_table(new_table);
			
			set_statusbar_info ();
			//check_have_media ();
			update_library_window_widgets ();
			
			in_update.unlock ();
		}
	}
	
	void import_request(LinkedList<Media> to_import) {
		if(!App.operations.doing_ops) {
			d.transfer_to_library(to_import);
		}
	}
	
	void sync_finished(bool success) {
		if(hint == TreeViewSetup.Hint.DEVICE_AUDIO)
			set_list(d.get_songs());
		else if(hint == TreeViewSetup.Hint.DEVICE_PODCAST)
			set_list(d.get_podcasts());
	}
	
	/** Specific implementations for View interface **/
	public override View.ViewType get_view_type() {
		switch (hint) {
			case TreeViewSetup.Hint.DEVICE_AUDIO:
				return View.ViewType.DEVICE_AUDIO;
			case TreeViewSetup.Hint.DEVICE_PODCAST:
				return View.ViewType.DEVICE_PODCAST;
			case TreeViewSetup.Hint.DEVICE_AUDIOBOOK:
				return View.ViewType.DEVICE_AUDIOBOOK;
			case TreeViewSetup.Hint.CDROM:
				return View.ViewType.CDROM;
			default:
				error("Device view with unknown hint");
		}
	}
	
	public override Object? get_object() {
		return d;
	}
	
	public override Gdk.Pixbuf get_view_icon() {
		switch (hint) {
			case TreeViewSetup.Hint.DEVICE_AUDIO:
				return App.icons.MUSIC.render(IconSize.MENU, null);
			case TreeViewSetup.Hint.DEVICE_PODCAST:
				return App.icons.PODCAST.render(IconSize.MENU, null);
			case TreeViewSetup.Hint.DEVICE_AUDIOBOOK:
				return App.icons.AUDIOBOOK.render(IconSize.MENU, null);
			case TreeViewSetup.Hint.CDROM:
				return App.icons.AUDIO_CD.render(IconSize.MENU, null);
			default:
				error("Device view with unknown hint");
		}
	}
	
	public override string get_view_name() {
		switch (hint) {
			case TreeViewSetup.Hint.DEVICE_AUDIO:
				return _("Music");
			case TreeViewSetup.Hint.DEVICE_PODCAST:
				return _("Podcasts");
			case TreeViewSetup.Hint.DEVICE_AUDIOBOOK:
				return _("Audiobooks");
			case TreeViewSetup.Hint.CDROM:
				return d.getDisplayName();
			default:
				error("Device view with unknown hint");
		}
	}
	
	public override Gtk.Menu? get_context_menu() {
		switch (hint) {
			case TreeViewSetup.Hint.DEVICE_AUDIO:
			case TreeViewSetup.Hint.DEVICE_PODCAST:
			case TreeViewSetup.Hint.DEVICE_AUDIOBOOK:
				return null;
			case TreeViewSetup.Hint.CDROM:
				return CDMenu;
			default:
				error("Device view with unknown hint");
		}
	}
	
	public override bool can_receive_drop() {
		return false;
	}
	
	public override void drag_received(Gtk.SelectionData data) {
		
	}
	
	// Note: In some cases, this will be a child of a device view and
	// this function will not be used; it's parent will be the device view
	public override SideTreeCategory get_sidetree_category() {
		return SideTreeCategory.DEVICE;
	}
	
	// Context menu signal handlers
	void CDimportToLibraryClicked() {
		if(d.getContentType() == "cdrom") {
			var to_transfer = new LinkedList<Media>();
			foreach(var m in d.get_medias())
				to_transfer.add(m);
			
			d.transfer_to_library(to_transfer);
		}
	}
	
	void CDejectClicked() {
		if(d.getContentType() == "cdrom") {
			d.unmount();
		}
	}
}

