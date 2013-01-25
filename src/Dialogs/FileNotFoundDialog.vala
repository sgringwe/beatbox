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

public class BeatBox.FileNotFoundDialog : Window {
	LinkedList<Media> ids;
	MediaType m_type;
	
	Box content;
	Box padding;
	
	ScrolledWindow filesScroll;
	MusicList list;
	Button removeMedia;
	Button locateMedia;
	Button rescanLibrary;
	Button doNothing;
	
	public FileNotFoundDialog(LinkedList<Media> ids) {
		if(ids.size == 0) {
			return;
		}
		
		this.ids = ids;
		
		this.set_title("BeatBox");
		
		m_type = MediaType.ITEM;
		foreach(var m in ids) {
			if(m_type == MediaType.ITEM) {
				m_type = m.media_type;
			}
			else if(m.media_type != m_type) {
				m_type = MediaType.ITEM;
				break;
			}
		}
		
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
		filesScroll = new ScrolledWindow(null, null);
		list = new MusicList(new TreeViewSetup(MusicColumn.TITLE, SortType.ASCENDING, TreeViewSetup.Hint.FILES_NOT_FOUND));
		removeMedia = new Button.with_label(_("Remove %s").printf(m_type.to_string(ids.size)));
		rescanLibrary = new Button.with_label(_("Rescan %s Library").printf(m_type.to_string(1)));
		locateMedia = new Button.with_label(_("Locate %s").printf(m_type.to_string(ids.size)));
		doNothing = new Button.with_label(_("Do Nothing"));
		
		// pretty up labels
		title.xalign = 0.0f;
		title.set_markup("<span weight=\"bold\" size=\"larger\">%s</span>".printf(_("Could not find %s %s").printf(m_type.to_string(1), ngettext("file", "files", ids.size))));
		info.xalign = 0.0f;
		info.set_line_wrap(false);
		if(ids.size == 1)
			info.set_markup(_("The file for %s by %s could not be found. What would you like to do?").printf("<b>" + Markup.escape_text(ids.get(0).title) + "</b>", "<b>" + Markup.escape_text(ids.get(0).artist) + "</b>"));
		else
			info.set_markup(_("%s files could not be found. What would you like to do?").printf("<b>" + ids.size.to_string() + "</b>"));
		
		rescanLibrary.set_sensitive(!App.operations.doing_ops);
		
		/* set up controls layout */
		Box information = new Box(Orientation.HORIZONTAL, 0);
		Box information_text = new Box(Orientation.VERTICAL, 0);
		information.pack_start(warning, false, false, 10);
		information_text.pack_start(title, false, true, 10);
		information_text.pack_start(info, false, true, 0);
		information.pack_start(information_text, true, true, 10);
		
		var media_list = new HashTable<int, Media>(null, null);
		foreach(var m in ids) {
			media_list.set((int)media_list.size(), m);
		}
		list.set_table(media_list);
		
		filesScroll.add(list);
		filesScroll.set_policy(PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
		
		Box listBox = new Box(Orientation.VERTICAL, 0);
		listBox.pack_start(filesScroll, true, true, 5);
		
		Expander exp = new Expander(_("%s not found:").printf(m_type.to_string(ids.size)));
		exp.add(listBox);
		exp.expanded = false;
		
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_layout(ButtonBoxStyle.END);
		bottomButtons.pack_end(removeMedia, false, false, 0);
		bottomButtons.pack_end(rescanLibrary, false, false, 0);
		if(ids.size == 1)	bottomButtons.pack_end(locateMedia, false, false, 0);
		bottomButtons.pack_end(doNothing, false, false, 10);
		bottomButtons.set_spacing(10);
		
		content.pack_start(information, false, true, 0);
		//content.pack_start(UI.wrap_alignment(exp, 0, 0, 0, 75), true, true, 0);
		content.pack_start(bottomButtons, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		
		removeMedia.clicked.connect(removeMediaClicked);
		rescanLibrary.clicked.connect(rescanLibraryClicked);
		locateMedia.clicked.connect(locateMediaClicked);
		doNothing.clicked.connect( () => { 
			this.destroy(); 
		});
		
		
		/*exp.activate.connect( () => {
			if(exp.get_expanded()) {
				resizable = true;
				set_size_request(475, 180);
				resize(475, 180);
				resizable = false;
			}
			else
				set_size_request(475, 350);
		});*/
		
		App.operations.operation_started.connect(operation_started);
		App.operations.operation_finished.connect(operation_finished);
		
		add(padding);
		show_all();
		
		rescanLibrary.set_visible(m_type != MediaType.ITEM);
	}
	
	void removeMediaClicked() {
		App.library.remove_medias(ids, false);
		
		this.destroy();
	}
	
	void locateMediaClicked() {
		Media m = ids.get(0);
		
		string file = "";
		var file_chooser = new FileChooserDialog (_("Locate Music File"), this,
								  FileChooserAction.OPEN,
								  Gtk.Stock.CANCEL, ResponseType.CANCEL,
								  Gtk.Stock.OPEN, ResponseType.ACCEPT);
		
		// try and help user by setting a sane default folder
		var invalid_file = File.new_for_uri(m.uri);
		
		if(invalid_file.get_parent().query_exists())
			file_chooser.set_current_folder(invalid_file.get_parent().get_path());
		else if(invalid_file.get_parent().get_parent().query_exists() && 
		invalid_file.get_parent().get_parent().get_path().contains(App.settings.main.music_folder))
			file_chooser.set_current_folder(invalid_file.get_parent().get_parent().get_path());
		else if(File.new_for_path(App.settings.main.music_folder).query_exists())
			file_chooser.set_current_folder(App.settings.main.music_folder);
		else
			file_chooser.set_current_folder(Environment.get_home_dir());
		
		if (file_chooser.run () == ResponseType.ACCEPT) {
			file = file_chooser.get_filename();
		}
		
		file_chooser.destroy ();
		
		if(file != "" && File.new_for_path(file).query_exists()) {
			m.uri = File.new_for_path(file).get_uri();
			m.location_unknown = false;
			m.unique_status_image = null;
			App.playback.media_found(m);
			
			var to_update = new LinkedList<Media>();
			to_update.add(m);
			App.library.update_medias(to_update, false, false, true);
			
			this.destroy();
		}
	}
	
	void rescanLibraryClicked() {
		// If all the medias are of the same type, rescan that one library.
		// Otherwise... TODO
		if(m_type != MediaType.ITEM) {
			App.library.get_library(ids.get(0).key).rescan_local_folder();
		}
		
		this.destroy();
	}
	
	void operation_started() {
		rescanLibrary.set_sensitive(false);
	}
	
	void operation_finished() {
		rescanLibrary.set_sensitive(true);
	}
}
