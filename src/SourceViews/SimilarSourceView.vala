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

public class BeatBox.SimilarSourceView : SourceView {
	public static const int REQUIRED_MEDIAS = 12;
	Media base_media;
	bool fetched;
	public new bool have_media { get { return media_count >= REQUIRED_MEDIAS; } }
	
	Gtk.Menu playlistMenu;
	Gtk.MenuItem playlistSave;
	Gtk.MenuItem playlistExport;
	
	public SimilarSourceView() {
		base(new LinkedList<Media>(), App.window.setups.get_setup(ListSetupInterface.SIMILAR_KEY));
		
		this.fetched = false;
		media_representation = _("song");
				
		list_view = new MusicList(tvs);
		list_view.is_mixed = true;
		error_box = new EmbeddedAlert();
		pack_widgets();
		
		//similar songs right click menu
		playlistMenu = new Gtk.Menu();
		playlistSave = new Gtk.MenuItem.with_label(_("Save as Playlist"));
		playlistExport = new Gtk.MenuItem.with_label(_("Export..."));
		playlistMenu.append(playlistSave);
		playlistMenu.append(playlistExport);
		playlistSave.activate.connect(playlistSaveClicked);
		playlistExport.activate.connect(playlistExportClicked);
		playlistMenu.show_all();
		
		// Populate views
		set_media(original_medias);
		
		App.playback.media_played.connect(media_played);
		App.info.lastfm.similar_retrieved.connect(similar_retrieved);
		App.library.song_library.medias_removed.connect (remove_medias);
	}
	
	protected override void pre_set_as_current_view() {
		
	}
	
	protected override void set_default_warning () {
		
	}
	
	void media_played(Media m, Media? old) {
		fetched = false;
		
		if(!list_view.get_is_current_list()) {
			base_media = m;
			set_media(new LinkedList<int>());
		}
	}
	
	void similar_retrieved(LinkedList<Media> similar_internal, LinkedList<Media> similar_external) {
		fetched = true;
		
		var to_set = new LinkedList<Media>();
		foreach(var m in similar_internal)
			to_set.add(m);
		
		int external_count = 0;
		foreach(var m in similar_external) {
			to_set.add(m);
			
			++external_count;
			if(external_count > similar_internal.size && to_set.size >= REQUIRED_MEDIAS)
				break;
		}
		
		set_media (to_set);
	}
	
	public void savePlaylist() {
		if(base_media == null) {
			stdout.printf("User tried to save similar playlist, but there is no base media\n");
			return;
		}
		
		StaticPlaylist p = new StaticPlaylist();
		p.name = _("Similar to %s").printf (base_media.title);
		
		var to_add = new LinkedList<Media>();
		foreach(Media m in list_view.get_table().get_values()) {
			if(!m.isTemporary)
				to_add.add(m);
		}
		p.add_medias(to_add);
		
		App.playlists.add_playlist(p);
	}
	
	public new void set_media (Collection<Media> new_media) {
		if(!list_view.get_is_current_list()) {
			in_update.lock ();
			
			/** We don't want to populate with songs if there are not
			enough for it to be valid. Only populate to set 0 songs or
			to populate with at least REQUIRED_MEDIAS songs. **/
			if(!fetched || new_media.size >= REQUIRED_MEDIAS) {
				var medias = new HashTable<int, Media>(null, null);
				foreach(var m in new_media) {
					medias.set((int)medias.size(), m);
				}
				
				list_view.set_table(medias);
			}
			
			set_statusbar_info ();
			update_library_window_widgets ();
			in_update.unlock ();
			
			if(base_media != null) {
				if(!fetched) { // still fetching similar media
					var text = _("BeatBox is finding songs similar to <b>%s</b> by <b>%s</b>").printf(Markup.escape_text(base_media.title), Markup.escape_text(base_media.artist));
					error_box.set_alert(_("Fetching similar songs"), text, null, false, Gtk.MessageType.INFO);
					set_active_view (SourceViewType.ERROR);

					return;
				}
				else {
					if(new_media.size < REQUIRED_MEDIAS) { // say we could not find similar media
						if (have_error_box) {
							var text = _("BeatBox could not find songs similar to <b>%s</b> by <b>%s</b>. ").printf(Markup.escape_text(base_media.title), Markup.escape_text(base_media.artist)) + 
								_("Make sure all song info is correct and you are connected to the Internet. Some songs may not have matches.");
							error_box.set_alert(_("No similar songs found"), text, null, true, Gtk.MessageType.ERROR);
							// Show the error box
							set_active_view (SourceViewType.ERROR);
						}

						return;
					}
					else {
						set_active_view (SourceViewType.LIST);
					}
				}
			}
		}
	}
	
	/** Specific implementations for View interface **/
	public override View.ViewType get_view_type() {
		return View.ViewType.SIMILAR;
	}
	
	public override Object? get_object() {
		return null;
	}
	
	public override Gdk.Pixbuf get_view_icon() {
		return App.icons.SMART_PLAYLIST.render(IconSize.MENU, null);
	}
	
	public override string get_view_name() {
		return _("Similar Songs");
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
	
	// can only be done on similar medias
	public void playlistSaveClicked() {
		savePlaylist();
	}
	
	void playlistExportClicked() {
		StaticPlaylist p = new StaticPlaylist();
		
		var to_add = new LinkedList<Media>();
		foreach(Media m in list_view.get_table().get_values()) {
			to_add.add(m);
		}
		p.add_medias(to_add);
		
		p.name = (App.playback.media_active) ? (_("Similar to %s").printf(Markup.escape_text(App.playback.current_media.title))) : _("Similar list");
		
		PlaylistUtils.export_playlist_to_file(p, App.window, null);
	}
}

