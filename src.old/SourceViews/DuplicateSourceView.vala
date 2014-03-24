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

public class BeatBox.DuplicateSourceView : SourceView {
	HashMap<Media, Collection<Media>> dups;
	
	Gtk.Box top_bar;
	Gtk.Button remove_checked;
	Gtk.ComboBoxText priority;
	
	GLib.CompareFunc<Media> first_priority;
	
	// For View implementation
	Gtk.Menu duplicatesMenu;
	
	public DuplicateSourceView() {
		base(new LinkedList<Media>(), new TreeViewSetup(DuplicateColumn.TITLE, Gtk.SortType.ASCENDING, TreeViewSetup.Hint.DUPLICATES));
		
		media_representation = _("item");
		
		// Add the top bar with different options
		top_bar = new Box(Orientation.HORIZONTAL, 0);
		top_bar.margin = 6;
		remove_checked = new Gtk.Button.with_label(_("Remove Checked Items"));
		priority = new ComboBoxText();
		priority.append("manual", _("Manually select duplicates"));
		priority.append("bitrate", _("Keep highest bitrate"));
		priority.append("file", _("Keep largest file"));
		priority.set_active(0);
		first_priority = (GLib.CompareFunc)highest_bitrate;
		top_bar.pack_start(priority, false, false, 0);
		top_bar.pack_end(remove_checked, false, false, 0);
		pack_end(top_bar, false, true, 0);
		
		// Add list and alert widgets
		list_view = new DuplicateList(tvs);
		error_box = new EmbeddedAlert();
		pack_widgets();
		
		// Setup context menu
		duplicatesMenu = new Gtk.Menu();
		duplicatesMenu.append((Gtk.MenuItem)App.actions.hide_duplicates.create_menu_item());
		duplicatesMenu.show_all();
		
		priority.changed.connect(priority_changed);
		remove_checked.clicked.connect(remove_checked_clicked);
		((DuplicateList)list_view).checked_changed.connect(checked_changed);
		
		// Setup signal handlers
		App.library.medias_removed.connect (remove_medias);
	}
	
	protected override void pre_set_as_current_view() {
		
	}
	
	protected override void set_default_warning () {
		error_box.set_alert (_("Victory! No Duplicates!"), _("Your library has no duplicates."), null, true, Gtk.MessageType.INFO);
	}
	
	public void set_dups(HashMap<Media, Collection<Media>> dups) {
		this.dups = dups;
		
		var all_dups_list = new LinkedList<Media>();
		foreach(var m in dups.keys)
			all_dups_list.add(m);
		foreach(var list in dups.values)
			all_dups_list.add_all(list);
		
		set_media(all_dups_list);
		autocheck_medias();
	}
	
	public void update_visibilities () {
		top_bar.set_visible(dups.size > 0);
	}
	
	void autocheck_medias() {
		message("Autochecking items based on selected priority...\n");
		var dup_list = (DuplicateList)list_view;
		dup_list.clear_checked();
		
		if(priority.get_active() != 0) {
			foreach(var ent in dups.entries) {
				var all = new PriorityQueue<Media>(first_priority);
				all.offer(ent.key);
				foreach(var m in ent.value)
					all.offer(m);
				
				var chosen = all.peek();
				foreach(var m in all) {
					dup_list.set_checked(m, m != chosen);
				}
			}
		}
		
		// To update visual check marks, queue_draw
		queue_draw();
		checked_changed();
	}
	
	void priority_changed() {
		int a = priority.get_active();
		if(a == 1)
			first_priority = (GLib.CompareFunc)largest_file;
		else if(a == 2)
			first_priority = (GLib.CompareFunc)highest_bitrate;
		
		autocheck_medias();
	}
	
	void remove_checked_clicked() {
		var checked = ((DuplicateList)list_view).get_checked_medias();
		
		var rfd = new RemoveFilesDialog(checked, hint);
		rfd.remove_media.connect ( (delete_files) => {
			App.library.remove_medias (checked, delete_files);
			
			// Close me
			App.actions.hide_duplicates.activate();
		});
	}
	
	int largest_file(Media a, Media b) {
		if(a == null || b == null)
			return 0;
		
		int rv = (int)(a.file_size - b.file_size);
		return rv;
}
	
	int highest_bitrate(Media a, Media b) {
		if(a == null || b == null)
			return 0;
		
		int rv = (int)(a.bitrate - b.bitrate);
		return rv;
	}
	
	void checked_changed() {
		var checked = ((DuplicateList)list_view).get_checked_medias();
		remove_checked.set_sensitive(checked.size > 0);
	}
	
	/** Specific implementations for View interface **/
	public override View.ViewType get_view_type() {
		return View.ViewType.DUPLICATES;
	}
	
	public override Object? get_object() {
		return null;
	}
	
	public override Gdk.Pixbuf get_view_icon() {
		return render_icon_pixbuf(Gtk.Stock.COPY, Gtk.IconSize.MENU);
	}
	
	public override string get_view_name() {
		return _("Duplicates");
	}
	
	public override Gtk.Menu? get_context_menu() {
		return duplicatesMenu;
	}
	
	public override bool can_receive_drop() {
		return false;
	}
	
	public override void drag_received(Gtk.SelectionData data) {
		
	}
	
	public override SideTreeCategory get_sidetree_category() {
		return SideTreeCategory.LIBRARY;
	}
}
