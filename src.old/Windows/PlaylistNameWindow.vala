/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
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

public class BeatBox.PlaylistNameWindow : Window {
	public StaticPlaylist _original;
	
	Box content;
	Box padding;
	
	public Entry _name {get; private set;}
	public Button _save {get; private set;}
	public Button _cancel {get; private set;}

	public signal void playlist_saved(StaticPlaylist p);
	
	public PlaylistNameWindow(StaticPlaylist original) {
		title = "BeatBox";
		
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(App.window);
		this.destroy_with_parent = true;
//		this.type = WindowType.POPUP;
		
		set_size_request (250, -1);
		resizable = false;
		
		_original = original;
		
		content = new Box(Orientation.VERTICAL, 12);
		padding = new Box(Orientation.HORIZONTAL, 12);
		
		/* start out by creating all category labels */
		Label nameLabel = new Label(_("Name of Playlist"));
		_name = new Entry();
		_save = new Button.with_label(_("Done"));
		_cancel = new Button.with_label (_("Cancel"));

		/* set up controls */
		nameLabel.xalign = 0.0f;
		nameLabel.set_markup("<b>%s</b>".printf(_("Name of Playlist")));
		
		_name.text = original.name;
		
		/* add controls to form */
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_spacing (6);
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(_cancel, false, false, 0);
		bottomButtons.pack_end(_save, false, false, 0);
		
		content.pack_start(wrap_alignment(nameLabel, 12, 0, 0, 0), false, true, 0);
		content.pack_start(wrap_alignment(_name, 0, 12, 0, 12), false, true, 0);
		content.pack_start(bottomButtons, false, false, 12);
		
		padding.pack_start(content, true, true, 12);
		
		add(padding);
		
		show_all();

		_save.clicked.connect(saveClicked);
		_cancel.clicked.connect (cancel_clicked);
		_name.activate.connect(nameActivate);
		_name.changed.connect(nameChanged);
	}

	void cancel_clicked () {
		destroy ();
	}

	public static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	void saveClicked() {
		_original.name = _name.text;
		playlist_saved(_original);
		
		this.destroy();
	}
	
	void nameActivate() {
		saveClicked();
	}
	
	void nameChanged() {
		if(_name.get_text() == "") {
			_save.set_sensitive(false);
			return;
		}
		else {
			foreach(var p in App.playlists.playlists()) {
				if((_original == null || _original.id != p.id) && _name.get_text() == p.name) {
					_save.set_sensitive(false);
					return;
				}
			}
		}
		
		_save.set_sensitive(true);
	}
}
