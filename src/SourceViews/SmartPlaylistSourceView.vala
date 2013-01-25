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

public class BeatBox.SmartPlaylistSourceView : SourceView {
	SmartPlaylist sp;
	bool needs_analyze;
	
	Gtk.Menu playlistMenu;
	Gtk.MenuItem playlistEdit;
	Gtk.MenuItem playlistRemove;
	Gtk.MenuItem playlistExport;
	
	public SmartPlaylistSourceView(SmartPlaylist p) {
		if(App.window.setups.get_setup(p.name) == null) {
			App.window.setups.add_setup(p.name, new TreeViewSetup(MusicColumn.ARTIST, Gtk.SortType.ASCENDING, TreeViewSetup.Hint.SMART_PLAYLIST));
		}
		
		base(new LinkedList<Media>(), App.window.setups.get_setup(p.name)); // Use a empty list so we don't analyze now. This reduces startup time.
		
		this.sp = p;
		this.relative_id = p.id;
		this.media_representation = _("item");
				
		list_view = new MusicList(tvs);
		album_view = new AlbumGrid(this, tvs);
		list_view.relative_id = relative_id;
		album_view.relative_id = relative_id;
		error_box = new EmbeddedAlert();
		pack_widgets();
		
		//playlist right click menu
		playlistMenu = new Gtk.Menu();
		playlistEdit = new Gtk.MenuItem.with_label(_("Edit"));
		playlistRemove = new Gtk.MenuItem.with_label(_("Remove"));
		playlistExport = new Gtk.MenuItem.with_label(_("Export..."));
		playlistMenu.append(playlistEdit);
		playlistMenu.append(playlistRemove);
		playlistMenu.append(playlistExport);
		playlistEdit.activate.connect(playlistMenuEditClicked);
		playlistRemove.activate.connect(playlistMenuRemoveClicked);
		playlistExport.activate.connect(playlistExportClicked);
		playlistMenu.show_all();
		
		// Populate views
		set_media(new LinkedList<Media>(), false);
		
		// Setup signal handlers
		App.library.medias_updated.connect (sp_update_medias);
		App.library.medias_added.connect (sp_add_medias);
		App.library.medias_removed.connect (sp_remove_medias);
		App.playlists.playlist_changed.connect(sp_playlist_changed);
		
		needs_analyze = true;
	}
	
	void sp_update_medias(Collection<Media> updates, bool meta_changed) {
		if(is_current_wrapper) {
			update_medias(updates, meta_changed);
		}
		else {
			require_analyze();
		}
	}
	
	void sp_add_medias(Collection<Media> added) {
		if(is_current_wrapper) {
			add_medias(added);
		}
		else {
			require_analyze();
		}
	}
	
	void sp_remove_medias(Collection<Media> removed) {
		if(is_current_wrapper) {
			remove_medias(removed);
		}
		else {
			require_analyze();
		}
	}
	
	void sp_playlist_changed(BasePlaylist p) {
		if(p.id == relative_id) {
			if(is_current_wrapper) {
				set_media(sp.analyze(App.library.medias()), true);
			}
			else {
				require_analyze();
			}
		}
	}
	
	void require_analyze() {
		needs_analyze = true;
	}
	
	protected override void pre_set_as_current_view() {
		if(needs_analyze) {
			set_media(sp.analyze(App.library.medias()), true);
		}
		
		needs_analyze = false;
	}
	
	protected override void set_default_warning () {
		error_box.set_alert (_("No Media"), _("No media fits this smart playlist's rules. To edit its rules, right click on it in the sidebar and choose \"Edit\"."), null, true, Gtk.MessageType.INFO);
	}
	
	/** Specific implementations for View interface **/
	public override View.ViewType get_view_type() {
		return View.ViewType.SMART_PLAYLIST;
	}
	
	public override Object? get_object() {
		return sp;
	}
	
	public override Gdk.Pixbuf get_view_icon() {
		return App.icons.SMART_PLAYLIST.render(IconSize.MENU, null);
	}
	
	public override string get_view_name() {
		return App.playlists.playlist_from_id(relative_id).name;
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
	
	void playlistMenuEditClicked() {
		SmartPlaylistEditor spe = new SmartPlaylistEditor((SmartPlaylist)App.playlists.playlist_from_id (relative_id));
		spe.playlist_saved.connect(smartPlaylistEditorSaved);
	}
	
	void smartPlaylistEditorSaved(SmartPlaylist sp) {
		App.playlists.update_playlist(sp);
	}
	
	public void playlistMenuRemoveClicked() {
		App.playlists.remove_playlist (relative_id);
	}
	
	void playlistExportClicked() {
		StaticPlaylist p = new StaticPlaylist();
		var smart_playlist = App.playlists.playlist_from_id (relative_id);
		
		p.add_medias(smart_playlist.analyze(App.library.medias()));
		p.name = smart_playlist.name;
		
		PlaylistUtils.export_playlist_to_file(p, App.window, null);
	}
}

