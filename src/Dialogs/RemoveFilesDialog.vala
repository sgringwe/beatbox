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

public class BeatBox.RemoveFilesDialog : Window {
	private Box content;
	private Box padding;
	
	private Button remove_button;
	private Button trash_button;
	private Button cancel_button;
	
	public signal void remove_media(bool response);
	
	public RemoveFilesDialog (Collection<Media> to_remove, TreeViewSetup.Hint media_type) {
		this.set_title("BeatBox");
		
		// set the size based on saved gconf settings
		//this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(App.window);
		this.destroy_with_parent = true;
		resizable = false;
		
		content = new Box(Orientation.VERTICAL, 10);
		padding = new Box(Orientation.HORIZONTAL, 20);
		
		// initialize controls
		Image warning = new Image.from_stock(Gtk.Stock.DIALOG_WARNING, Gtk.IconSize.DIALOG);
		Label title = new Label("");
		Label info = new Label("");
		trash_button = new Button.with_label(_("Move to Trash"));
		remove_button = new Button.with_label(_("Remove from BeatBox"));
		cancel_button = new Button.from_stock (Gtk.Stock.CANCEL);
		
		bool multiple_media = to_remove.size > 1;
		var media_text = new StringBuilder();
		switch (media_type) {
			case TreeViewSetup.Hint.MUSIC:
				media_text.append(ngettext("song", "songs", to_remove.size));
				break;
			case TreeViewSetup.Hint.PODCAST:
				media_text.append(ngettext("podcast episode", "podcast episodes", to_remove.size));
				break;
			case TreeViewSetup.Hint.AUDIOBOOK:
				media_text.append(ngettext("audiobook", "audiobooks", to_remove.size));
				break;
			case TreeViewSetup.Hint.STATION:
				media_text.append(ngettext("station", "stations", to_remove.size));
				break;
			case TreeViewSetup.Hint.DUPLICATES:
			default:
				media_text.append(ngettext("item", "items", to_remove.size));
				break;
		}
		
		// set title text
		title.xalign = 0.0f;
		string title_text = "";
		if (multiple_media) {
			title_text = _("Remove %d %s from BeatBox?").printf(to_remove.size, media_text.str);
		}
		else {
  			Media m = to_remove.to_array()[0];
  			
  			if(m is Station)
				title_text = _("Remove %s from BeatBox?").printf(Markup.escape_text(m.title));
			else
				title_text = _("Remove %s from BeatBox?").printf(Markup.escape_text(m.album_artist));
		}
		title.set_markup("<span weight=\"bold\" size=\"larger\">" + title_text + "</span>");
		
		// set info text
		info.xalign = 0.0f;
		info.set_line_wrap(true);
		string info_text = _("This will remove the %s from your library and from any device that automatically syncs with BeatBox.").printf(media_text.str.down());
		info.set_markup(info_text);
		
		// decide if we need the trash button
		bool need_trash = false;
		foreach(var m in to_remove) {
			if(m.uri.has_prefix("file:/")) {
				need_trash = true;
			}
		}
		
		/* set up controls layout */
		Box information = new Box(Orientation.HORIZONTAL, 0);
		Box information_text = new Box(Orientation.VERTICAL, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		if(need_trash)	bottomButtons.pack_end(trash_button, false, false, 0);
		bottomButtons.pack_end(cancel_button, false, false, 0);
		bottomButtons.pack_end(remove_button, false, false, 0);
		bottomButtons.set_spacing(6);
		
		content.pack_start(information, false, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		trash_button.clicked.connect ( () => {
			remove_media (true);
			destroy ();
		});

		remove_button.clicked.connect ( () => {
			remove_media (false);
			destroy ();
		});

		cancel_button.clicked.connect ( () => {
			destroy ();
		});
		
		add(padding);
		show_all();
	}
}
