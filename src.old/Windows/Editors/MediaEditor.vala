/*-
 * Copyright (c) 2011-2012	   Scott Ringwelski <sgringwe@mtu.edu>
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
using Gee;
using Granite;

public class BeatBox.MediaEditor : Window {
	LinkedList<Media> entire_media_list;
	LinkedList<Media> current_medias;
	
	//for padding around notebook mostly
	Box content;
	Box padding;
	Granite.Widgets.StaticNotebook notebook;
	
	Collection<int> extra_views;
	bool have_added_extra_views;
	
	MediaEditorInterface editor;
	
	EventBox editor_container;
	Widget editor_widget;
	
	InfoViewport info_viewport;
	bool have_added_info_view;
	
	private NavigationArrows nav_arrows;
	private Button _save;
	
	public MediaEditor(LinkedList<Media> entire_media_list, LinkedList<Media> medias) {
		if(medias.size == 0)
			return;
		
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(App.window);
		this.destroy_with_parent = true;
		this.set_size_request (520, -1);
		this.set_resizable(false);
		
		content = new Box(Orientation.VERTICAL, 10);
		padding = new Box(Orientation.HORIZONTAL, 10);
		
		extra_views = new LinkedList<int>();
		
		this.entire_media_list = entire_media_list;
		this.current_medias = medias;
		
		// Assume all medias are of same type
		editor = medias.get(0).get_editor_widget();
		
		notebook = new Granite.Widgets.StaticNotebook();
		editor_container = new EventBox();
		editor_widget = editor.get_metadata_view(current_medias);
		
		editor_container.add(editor_widget);
		
		notebook.append_page(editor_container, new Label(_("Metadata")));
		if(current_medias.size == 1) {
			add_info_viewport(current_medias.get(0));
			add_extra_views();
		}
		
		HButtonBox buttonSep = new HButtonBox();
		buttonSep.set_layout(ButtonBoxStyle.END);
		buttonSep.set_spacing (6);
		nav_arrows = new NavigationArrows();
		_save = new Button.with_label(_("Done"));
		var cancel = new Button.with_label(_("Cancel"));
		
		buttonSep.pack_start(nav_arrows, false, false, 0);
		buttonSep.pack_start(cancel, false, false, 0);
		buttonSep.pack_end(_save, false, false, 0);
		
		content.pack_start(UI.wrap_alignment(notebook, 10, 0, 0, 0), true, true, 0);
		content.pack_start(UI.wrap_alignment(buttonSep, 0, 0, 10, 0), false, true, 0);
		
		(buttonSep as Gtk.ButtonBox).set_child_secondary(nav_arrows, true);
		
		padding.pack_start(content, true, true, 10);
		add(padding);
		
		show_all();
		
		nav_arrows.sensitive = entire_media_list.size > 1;
		if(current_medias.size == 1) {
			foreach(FieldEditor fe in editor.get_fields()) {
				fe.set_check_visible(false);
			}
		}
		
		if(current_medias.size == 1) {
			title = _("Editing %s").printf(current_medias.get(0).title);
		}
		else {
			title = _("Editing %d medias").printf(current_medias.size);
		}

		nav_arrows.previous_clicked.connect(previousClicked);
		nav_arrows.next_clicked.connect(nextClicked);
		_save.clicked.connect(saveClicked);
		cancel.clicked.connect( () => { destroy(); });
	}
	
	void add_info_viewport(Media m) {
		int old_page = notebook.page;
		info_viewport = new InfoViewport(m);
		notebook.append_page(info_viewport, new Label(_("Info")));
		notebook.page = old_page;
		
		have_added_info_view = true;
	}
	
	void add_extra_views() {
		foreach(var entry in editor.get_extra_views().entries) {
			int added = notebook.append_page(entry.value, new Label(entry.key));
			entry.value.show_all();
			extra_views.add(added);
		}
		
		have_added_extra_views = true;
	}
	
	void remove_extra_views() {
		foreach(int index in extra_views) {
			notebook.remove_page(index);
		}
		
		extra_views.clear();
	}
	
	void previousClicked() {
		Media m = null;
		int indexOfCurrentFirst = entire_media_list.index_of(current_medias.get(0));
		
		if(indexOfCurrentFirst == 0)
			m = entire_media_list.get(entire_media_list.size - 1);
		else
			m = entire_media_list.get(indexOfCurrentFirst - 1);
		
		save_and_change_media(m);
	}
	
	void nextClicked() {
		Media m = null;
		int indexOfCurrentLast = entire_media_list.index_of(current_medias.get(current_medias.size - 1));
		
		if(indexOfCurrentLast == entire_media_list.size - 1)
			m = entire_media_list.get(0);
		else
			m = entire_media_list.get(indexOfCurrentLast + 1);
			
		save_and_change_media(m);
	}
	
	void save_and_change_media(Media new_media) {
		// First save the current medias
		editor.save_medias(current_medias);
		
		// See if we need to change the editor
		if(new_media.media_type != current_medias.get(0).media_type) {
			current_medias = new LinkedList<Media>();
			current_medias.add(new_media);
		
			editor_container.remove(editor_widget);
			
			editor = new_media.get_editor_widget();
			editor_widget = editor.get_metadata_view(current_medias);
			
			editor_container.add(editor_widget);
			editor_widget.show_all();
			
			if(!have_added_info_view) {
				add_info_viewport(new_media);
			}
			else {
				info_viewport.set_media(new_media);
			}
			
			remove_extra_views();
			add_extra_views();
		}
		else {
			current_medias = new LinkedList<Media>();
			current_medias.add(new_media);
			
			editor.change_media(new_media);
			
			if(!have_added_info_view) {
				add_info_viewport(new_media);
			}
			else {
				info_viewport.set_media(new_media);
			}
			
			if(!have_added_extra_views) {
				add_extra_views();
			}
		}
		
		title = _("Editing %s").printf(new_media.title);
		
		// Don't show the checkboxes anymore
		foreach(FieldEditor fe in editor.get_fields()) {
			fe.set_check_visible(false);
		}
	}
	
	void saveClicked() {
		editor.save_medias(current_medias);
		
		this.destroy();
	}
}
