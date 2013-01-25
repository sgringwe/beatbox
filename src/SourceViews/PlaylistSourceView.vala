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

public class BeatBox.PlaylistSourceView : SourceView {
	StaticPlaylist p;
	
	Gtk.Menu playlistMenu;
	Gtk.MenuItem playlistEdit;
	Gtk.MenuItem playlistRemove;
	Gtk.MenuItem playlistExport;
	
	public PlaylistSourceView(StaticPlaylist p) {
		if(App.window.setups.get_setup(p.name) == null) {
			App.window.setups.add_setup(p.name, new TreeViewSetup(MusicColumn.NUMBER, Gtk.SortType.ASCENDING, TreeViewSetup.Hint.PLAYLIST));
		}
		
		base(p.analyze(new LinkedList<Media>()), App.window.setups.get_setup(p.name));
		
		this.p = p;
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
		set_media(p.analyze(new LinkedList<Media>()), false);
		
		// Setup signal handlers
		App.library.medias_removed.connect (remove_medias);
		App.playlists.playlist_changed.connect(playlist_changed);
	}
	
	protected override void pre_set_as_current_view() {
		
	}
	
	protected override void set_default_warning () {
		error_box.set_alert (_("No Media"), _("To add to this playlist, drag and drop songs from a list onto the sidebar item or\nright click on an item and choose \"Add to Playlist\"."),
		null, true, Gtk.MessageType.INFO);
	}
	
	void playlist_changed (BasePlaylist p) {
		if(p.id == relative_id) {
			set_media (p.analyze(new LinkedList<Media>()));
		}
	}
	
	/** Specific implementations for View interface **/
	public override View.ViewType get_view_type() {
		return View.ViewType.PLAYLIST;
	}
	
	public override Object? get_object() {
		return p;
	}
	
	public override Gdk.Pixbuf get_view_icon() {
		return App.icons.PLAYLIST.render(IconSize.MENU, null);
	}
	
	public override string get_view_name() {
		return App.playlists.playlist_from_id(relative_id).name;
	}
	
	public override Gtk.Menu? get_context_menu() {
		return playlistMenu;
	}
	
	public override bool can_receive_drop() {
		return true;
	}
	
	public override void drag_received(Gtk.SelectionData data) {
		BasePlaylist p = App.playlists.playlist_from_id(relative_id);
		if(!(p is StaticPlaylist)) {
			warning("User tried to drop media onto a smart playlist");
			return;
		}
		
		var static_p = (StaticPlaylist)p;
		
		message("Adding files to playlist %s\n", p.name);
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
		static_p.add_medias(to_add);
		
		App.playlists.update_playlist(p);
	}
	
	public override SideTreeCategory get_sidetree_category() {
		return SideTreeCategory.PLAYLIST;
	}
	
	void playlistMenuEditClicked() {
		PlaylistNameWindow pnw = new PlaylistNameWindow((StaticPlaylist)App.playlists.playlist_from_id (relative_id));
		pnw.playlist_saved.connect(playlistNameWindowSaved);
	}
	
	void playlistNameWindowSaved(StaticPlaylist p) {
		App.playlists.update_playlist(p);
	}
	
	public void playlistMenuRemoveClicked() {
		App.playlists.remove_playlist (relative_id);
	}
	
	void playlistExportClicked() {
		BasePlaylist p = App.playlists.playlist_from_id(relative_id);
		
		if(p != null && p is StaticPlaylist) {
			PlaylistUtils.export_playlist_to_file((StaticPlaylist)p, App.window, null);
		}
	}
}

