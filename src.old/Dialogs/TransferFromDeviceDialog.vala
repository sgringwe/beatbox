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

using Gee;
using Gtk;

public class BeatBox.TransferFromDeviceDialog : Window {
	LinkedList<Media> medias;
	Device d;
	
	//for padding around notebook mostly
	private Box content;
	private Box padding;
	
	CheckButton transferAll;
	ScrolledWindow mediasScroll;
	TreeView mediasView;
	ListStore mediasModel;
	Button transfer;
	
	Gtk.Menu viewMenu;
	Gtk.MenuItem selectItem;
	Gtk.MenuItem selectAlbum;
	Gtk.MenuItem selectArtist;
	
	LinkedList<Media> to_transfer;
	
	// TODO: Enable/disable sensitize based on operations
	public TransferFromDeviceDialog(Device d, LinkedList<Media> medias) {
		this.medias = medias;
		this.d = d;
		
		to_transfer = new LinkedList<Media>();
		
		this.set_title(_("Import from Device"));
		
		// set the size based on saved gconf settings
		//this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(App.window);
		this.destroy_with_parent = true;
		
		set_default_size(550, -1);
		resizable = false;
		
		content = new Box(Orientation.VERTICAL, 10);
		padding = new Box(Orientation.HORIZONTAL, 20);
		
		// initialize controls
		Image warning = new Image.from_stock(Gtk.Stock.DIALOG_QUESTION, Gtk.IconSize.DIALOG);
		Label title = new Label(_("Import medias from") + " " + d.getDisplayName());
		Label info = new Label(_("The following files were found on %s, but are not in your library. Check all files you would like to import.").printf(d.getDisplayName()));
		transferAll = new CheckButton.with_label(_("Import all medias"));
		mediasScroll = new ScrolledWindow(null, null);
		mediasView = new TreeView();
		mediasModel = new ListStore(5, typeof(bool), typeof(Media), typeof(string), typeof(string), typeof(string));
		mediasView.set_model(mediasModel);
		transfer = new Button.with_label(_("Import"));
		Button cancel = new Button.with_label(_("Don't Import"));
		
		// pretty up labels
		string title_text = "";
		if(medias.size == 1)
			title_text = _("Import %s from %s").printf(medias.get(0).title, Markup.escape_text(d.getDisplayName()));
		else
			title_text = _("Import %d medias from %s").printf(medias.size, Markup.escape_text(d.getDisplayName()));
		
		title.set_markup("<span weight=\"bold\" size=\"larger\">" + title_text + "</span>");
		title.xalign = 0.0f;
		info.xalign = 0.0f;
		info.set_line_wrap(true);
		
		/* add cellrenderers to columns and columns to treeview */
		var toggle = new CellRendererToggle ();
        toggle.toggled.connect ((toggle, path) => {
            var tree_path = new TreePath.from_string (path);
            TreeIter iter;
            mediasModel.get_iter (out iter, tree_path);
            mediasModel.set (iter, 0, !toggle.active);
            
            transfer.set_sensitive(false);
            mediasModel.foreach(updateTransferSensetivity);
        });

        var column = new TreeViewColumn ();
        column.title = "";
        column.pack_start (toggle, false);
        column.add_attribute (toggle, "active", 0);
        mediasView.append_column(column);
		
		column = new TreeViewColumn();
		column.title = "media";
		mediasView.append_column(column);
		
		mediasView.insert_column_with_attributes(-1, "Title", new CellRendererText(), "text", 2, null);
		mediasView.insert_column_with_attributes(-1, "Artist", new CellRendererText(), "text", 3, null);
		mediasView.insert_column_with_attributes(-1, "Album", new CellRendererText(), "text", 4, null);
		mediasView.headers_visible = true;
		
		for(int i = 0; i < 5; ++i) {
			mediasView.get_column(i).sizing = Gtk.TreeViewColumnSizing.FIXED;
			mediasView.get_column(i).resizable = true;
			mediasView.get_column(i).reorderable = false;
			mediasView.get_column(i).clickable = false;
		}
		
		mediasView.get_column(1).visible = false;
		
		mediasView.get_column(0).fixed_width = 25;
		mediasView.get_column(1).fixed_width = 10;
		mediasView.get_column(2).fixed_width = 300;
		mediasView.get_column(3).fixed_width = 125;
		mediasView.get_column(4).fixed_width = 125;
		
		//view.get_selection().set_mode(SelectionMode.MULTIPLE);
		
		/* fill the treeview */
		var medias_sorted = new LinkedList<Media>();
        foreach(var m in medias)
			medias_sorted.add(m);
		message("TODO: Fixme");
		//medias_sorted.sort((CompareFunc)mediaCompareFunc);
		
		foreach(var s in medias_sorted) {
			TreeIter item;
			mediasModel.append(out item);
			
			mediasModel.set(item, 0, false, 1, s, 2, s.title, 3, s.artist, 4, s.album);
		}
		
		mediasScroll.add(mediasView);
		mediasScroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		transfer.set_sensitive(false);
		
		/* set up controls layout */
		Box information = new Box(Orientation.HORIZONTAL, 0);
		Box information_text = new Box(Orientation.VERTICAL, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		Box listBox = new Box(Orientation.VERTICAL, 0);
		listBox.pack_start(mediasScroll, true, true, 5);
		
		Expander exp = new Expander(_("Select individual medias to import:"));
		exp.add(listBox);
		exp.expanded = false;
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(cancel, false, false, 10);
		bottomButtons.pack_end(transfer, false, false, 0);
		bottomButtons.set_spacing(6);
		
		content.pack_start(information, false, true, 0);
		content.pack_start(UI.wrap_alignment(transferAll, 5, 0, 0, 75), false, true, 0);
		content.pack_start(UI.wrap_alignment(exp, 0, 0, 0, 75), true, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		viewMenu = new Gtk.Menu();
		selectItem = new Gtk.MenuItem.with_label(_("Check Item"));
		selectAlbum = new Gtk.MenuItem.with_label(_("Check Album"));
		selectArtist = new Gtk.MenuItem.with_label(_("Check Artist"));
		
		transfer.clicked.connect(transferClick);
		transferAll.toggled.connect(transferAllToggled);
		//mediasView.button_press_event.connect(mediasViewClick);
		cancel.clicked.connect( () => { destroy(); });
		exp.activate.connect( () => {
			if(exp.get_expanded()) {
				resizable = true;
				set_size_request(550, 180);
				resize(475, 180);
				resizable = false;
			}
			else
				set_size_request(550, 500);
		});
		
		add(padding);
		show_all();
		
		App.operations.operation_started.connect(operation_started);
		App.operations.operation_finished.connect(operation_finished);
		transfer.set_sensitive(!App.operations.doing_ops);
	}
	
	/*public static int mediaCompareFunc(Media a, Media b) {
		if(a.artist == b.artist) {
			if(a.album == b.album)
				return (int)a.track - (int)b.track;
			else
				return (a.album > b.album) ? 1 : -1;
			
		}
		else
			return (a.artist > b.artist) ? 1 : -1;
	}*/
	
	bool updateTransferSensetivity(TreeModel model, TreePath path, TreeIter iter) {
		bool sel = false;
		model.get(iter, 0, out sel);
		
		if(sel) {
			transfer.set_sensitive(true);
			return true;
		}
		
		return false;
	}
	
	bool selectAll(TreeModel model, TreePath path, TreeIter iter) {
		mediasModel.set(iter, 0, true);
		
		return false;
	}
	
	bool unselectAll(TreeModel model, TreePath path, TreeIter iter) {
		mediasModel.set(iter, 0, false);
		
		return false;
	}
	
	void transferAllToggled() {
		if(transferAll.active) {
			mediasModel.foreach(selectAll);
			mediasView.set_sensitive(false);
			transfer.set_sensitive(true);
		}
		else {
			mediasModel.foreach(unselectAll);
			mediasView.set_sensitive(true);
			transfer.set_sensitive(false);
		}
	}
	
	bool createTransferList(TreeModel model, TreePath path, TreeIter iter) {
		Media? m = null;
		bool selected = false;
		mediasModel.get(iter, 0, out selected, 1, out m);
		
		if(m != null && selected) {
			to_transfer.add(m);
		}
		
		return false;
	}
	
	void transferClick() {
		to_transfer.clear();
		mediasModel.foreach(createTransferList);
		
		if(App.operations.doing_ops) {
			App.window.doAlert(_("Cannot Import"), _("BeatBox is already doing file operations. Please wait until those finish to import from ") + Markup.escape_text(d.getDisplayName()));
		}
		else {
			d.transfer_to_library(to_transfer);
			this.destroy();
		}
	}
	
	 void cancelClick() {
		this.destroy();
	}
	
	void operation_started() {
		transfer.set_sensitive(false);
	}
	
	void operation_finished() {
		transfer.set_sensitive(true);
	}
}
