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

public class BeatBox.SyncWarningDialog : Window {
	Device d;
	LinkedList<Media> to_sync;
	LinkedList<Media> not_in_library;
	
	private Box content;
	private Box padding;
	
	Button importMedias;
	Button sync;
	Button cancel;
	
	static string TITLE_TEXT = _("Sync will remove %d medias from %s");
	static string INFO_TEXT = _("If you continue to sync, medias will be removed from %s since they are not on the sync list. Would you like to import them to your library first?");
	
	public SyncWarningDialog(Device d, LinkedList<Media> to_sync, LinkedList<Media> not_in_library) {
		this.d = d;
		this.to_sync = to_sync;
		this.not_in_library = not_in_library;
		
		this.set_title("BeatBox");
		
		// set the size based on saved gconf settings
		//this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(App.window);
		this.destroy_with_parent = true;
		
		set_default_size(475, -1);
		resizable = false;
		
		content = new Box(Orientation.VERTICAL, 10);
		padding = new Box(Orientation.HORIZONTAL, 20);
		
		// initialize controls
		Image warning = new Image.from_stock(Gtk.Stock.DIALOG_ERROR, Gtk.IconSize.DIALOG);
		Label title = new Label("");
		Label info = new Label("");
		importMedias = new Button.with_label(_("Import medias to Library"));
		sync = new Button.with_label(_("Continue Syncing"));
		cancel = new Button.with_label(_("Dont Sync"));
		
		// pretty up labels
		title.xalign = 0.0f;
		title.set_markup("<span weight=\"bold\" size=\"larger\">" + TITLE_TEXT.printf(not_in_library.size, Markup.escape_text(d.getDisplayName())) + "</span>");
		info.xalign = 0.0f;
		info.set_line_wrap(true);
		info.set_markup(INFO_TEXT.printf(Markup.escape_text(d.getDisplayName())));
		
		importMedias.set_sensitive(!App.operations.doing_ops);
		sync.set_sensitive(!App.operations.doing_ops);
		
		/* set up controls layout */
		Box information = new Box(Orientation.HORIZONTAL, 0);
		Box information_text = new Box(Orientation.VERTICAL, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(importMedias, false, false, 0);
		bottomButtons.pack_end(sync, false, false, 0);
		bottomButtons.pack_end(cancel, false, false, 10);
		bottomButtons.set_spacing(6);
		
		content.pack_start(information, false, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		importMedias.clicked.connect(importMediasClicked);
		sync.clicked.connect(syncClicked);
		cancel.clicked.connect( () => { 
			this.destroy(); 
		});
		
		App.operations.operation_started.connect(operation_started);
		App.operations.operation_finished.connect(operation_finished);
		
		add(padding);
		show_all();
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
	
	public void importMediasClicked() {
		d.transfer_to_library(not_in_library);
		
		//TODO: Queue a sync
		
		this.destroy();
	}
	
	public void syncClicked() {
		d.sync_medias(to_sync);
		
		this.destroy();
	}
	
	public void operation_started() {
		importMedias.set_sensitive(false);
		sync.set_sensitive(false);
	}
	
	public void operation_finished() {
		importMedias.set_sensitive(true);
		sync.set_sensitive(true);
	}
}
