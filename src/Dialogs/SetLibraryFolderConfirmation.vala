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

public class BeatBox.SetLibraryFolderConfirmation : Window {
	Library lib;
	File folder;
	
	Box content;
	Box padding;
	
	Button savePlaylists;
	Button ok;
	Button cancel;
	
	Gtk.Image is_finished;
	Gtk.Spinner is_working;
	
	public signal void finished(bool response);
	
	public SetLibraryFolderConfirmation(Library lib, File folder) {
		this.lib = lib;
		this.folder = folder;
		
		this.set_title("BeatBox");
		
		// set the size based on saved gconf settings
		//this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(App.window);
		this.destroy_with_parent = true;
		
		//set_default_size(250, -1);
		resizable = false;
		
		content = new Box(Orientation.VERTICAL, 10);
		padding = new Box(Orientation.HORIZONTAL, 10);
		
		// initialize controls
		Image warning = new Image.from_stock(Gtk.Stock.DIALOG_WARNING, Gtk.IconSize.DIALOG);
		Label title = new Label("");
		Label info = new Label("");
		savePlaylists = new Button.with_label(_("Export Playlists"));
		ok = new Button.with_label(_("Set %s Folder").printf(lib.name));
		cancel = new Button.from_stock (Gtk.Stock.CANCEL);
		is_finished = new Gtk.Image();
		is_working = new Gtk.Spinner();
		
		// pretty up labels
		title.xalign = 0.0f;
		title.set_markup("<span weight=\"bold\" size=\"larger\">%s</span>".printf(_("Set %s Folder?").printf(lib.name)));
		info.xalign = 0.0f;
		info.set_line_wrap(true);
		info.set_markup(_("Are you sure you want to set the %s folder to %s? This will reset your %s library.").printf("<b>" + lib.name + "</b>", "<b>" + Markup.escape_text(folder.get_path()) + "</b>", lib.name));
		
		/* set up controls layout */
		Box information = new Box(Orientation.HORIZONTAL, 0);
		Box information_text = new Box(Orientation.VERTICAL, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		// save playlist hbox
		Box playlistBox = new Box(Orientation.HORIZONTAL, 6);
		playlistBox.pack_start(savePlaylists, true, true, 0);
		playlistBox.pack_end(is_finished, false, false, 0);
		playlistBox.pack_end(is_working, false, false, 0);
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_start(playlistBox, false, false, 0);
		bottomButtons.pack_end(cancel, false, false, 0);
		bottomButtons.pack_end(ok, false, false, 0);
		bottomButtons.set_spacing(6);
		
		((Gtk.ButtonBox)bottomButtons).set_child_secondary(playlistBox, true);
		
		content.pack_start(information, false, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		savePlaylists.set_sensitive(App.library.media_count() > 0 && App.playlists.playlist_count() > 0);
		
		savePlaylists.clicked.connect(savePlaylistsClicked);
		cancel.clicked.connect(cancel_clicked);
		ok.clicked.connect(ok_clicked);
		
		add(padding);
		show_all();
		
		is_working.hide();
	}
	
	public void savePlaylistsClicked() {
		string folder = "";
		var file_chooser = new FileChooserDialog (_("Choose Music Folder"), this,
								  FileChooserAction.SELECT_FOLDER,
								  Gtk.Stock.CANCEL, ResponseType.CANCEL,
								  Gtk.Stock.OPEN, ResponseType.ACCEPT);
		if (file_chooser.run () == ResponseType.ACCEPT) {
			folder = file_chooser.get_filename();
		}
		
		file_chooser.destroy ();
		
		if(folder != "") {
			is_working.show();
			is_finished.hide();
			
			// foreach playlist in App.library.playlists(), save to (p.name).m3u
			var success = true;
			foreach(var p in App.playlists.playlists()) {
				if(p is StaticPlaylist) {
					if(!PlaylistUtils.save_playlist_m3u((StaticPlaylist)p, folder)) {
						success = false;
					}
				}
			}
			
			is_working.hide();
			is_finished.show();
			
			var process_completed_icon = App.icons.PROCESS_COMPLETED.render (IconSize.MENU);
			var process_error_icon = App.icons.PROCESS_ERROR.render (IconSize.MENU);
			
			is_finished.set_from_pixbuf(success ? process_completed_icon : process_error_icon);
		}
	}
	
	public void cancel_clicked() {
		finished(false);
		
		this.destroy();
	}
	
	public void ok_clicked() {
		finished(true);
		
		this.destroy();
	}
}
