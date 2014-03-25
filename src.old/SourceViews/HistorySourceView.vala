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

public class BeatBox.HistorySourceView : SourceView {
	Gtk.Menu playlistMenu;
	Gtk.MenuItem playlistSave;
	Gtk.MenuItem playlistExport;
	
	public HistorySourceView() {
		base(App.playback.history(), App.window.setups.get_setup(ListSetupInterface.HISTORY_KEY));
		
		media_representation = _("item");
				
		list_view = new MusicList(tvs);
		error_box = new EmbeddedAlert();
		pack_widgets();
		
		playlistMenu = new Gtk.Menu();
		playlistSave = new Gtk.MenuItem.with_label(_("Save as Playlist"));
		playlistExport = new Gtk.MenuItem.with_label(_("Export..."));
		playlistMenu.append(playlistSave);
		playlistMenu.append(playlistExport);
		playlistSave.activate.connect(playlistSaveClicked);
		playlistExport.activate.connect(playlistExportClicked);
		playlistMenu.show_all();
		
		// Populate views
		set_media(original_medias, false);
		
		// Setup signal handlers
		App.library.medias_removed.connect (remove_medias);
		App.playback.history_changed.connect(already_played_changed);
	}
	
	protected override void pre_set_as_current_view() {
		
	}
	
	protected override void set_default_warning () {
		error_box.set_alert (_("No songs in History"), _("After a part of a song has been played, it is added to the history list.") + 
		"\n" + _("You can use this list to see all the songs you have played during the current session."),
		null, true, Gtk.MessageType.INFO);

	}
	
	void already_played_changed () {
		set_media(App.playback.history());
	}
	
	/** Specific implementations for View interface **/
	public override View.ViewType get_view_type() {
		return View.ViewType.HISTORY;
	}
	
	public override Object? get_object() {
		return null;
	}
	
	public override Gdk.Pixbuf get_view_icon() {
		return App.icons.HISTORY.render(IconSize.MENU, null);
	}
	
	public override string get_view_name() {
		return _("History");
	}
	
	public override Gtk.Menu? get_context_menu() {
		return playlistMenu;
	}
	
	public override bool can_receive_drop() {
		return false;
	}
	
	public override void drag_received(Gtk.SelectionData data) {
		
	}
	
	public override SideTreeCategory get_sidetree_category() {
		return SideTreeCategory.PLAYLIST;
	}
	
	public void playlistSaveClicked() {
		StaticPlaylist p = new StaticPlaylist();
		p.name = Time.local(time_t()).format("%Y-%b-%e %l:%M %p") + " " + _(" play history");
		
		var to_add = new LinkedList<Media>();
		foreach(Media m in list_view.get_table().get_values()) {
			if(!m.isTemporary)
				to_add.add(m);
		}
		p.add_medias(to_add);
		
		App.playlists.add_playlist(p);
	}
	
	void playlistExportClicked() {
		StaticPlaylist p = new StaticPlaylist();
		p.name = Time.local(time_t()).format("%Y-%b-%e %l:%M %p") + " " + _(" play history");
		
		var to_add = new LinkedList<Media>();
		foreach(Media m in list_view.get_table().get_values()) {
			to_add.add(m);
		}
		p.add_medias(to_add);
		
		PlaylistUtils.export_playlist_to_file(p, App.window, null);
	}
}

