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
using Gee;

public class BeatBox.SmartPlaylistEditor : Window {
	const int BUFFER_SPACE = 500;
	SmartPlaylist sp;
	
	Box content;
	Box padding;
	
	private  Label nameLabel;
	private Label rulesLabel;
	private Label optionsLabel;
	
	Granite.Widgets.HintedEntry nameEntry;
	ComboBoxText comboMatch;
	
	bool is_in_scroll;
	EventBox no_scroll;
	Viewport scroll;
	ScrolledWindow scrolled_window;
	Box vertQueries;
	Gee.ArrayList<SmartPlaylistEditorQuery> spQueries;
	
	Button addButton;
	CheckButton limitMedias;
	SpinButton mediaLimit;
	Button save;
	
	public signal void playlist_saved(SmartPlaylist sp);
	
	public SmartPlaylistEditor(SmartPlaylist sp) {
		this.sp = sp;
		
		this.title = _("Smart Playlist Editor");
		
		this.window_position = WindowPosition.CENTER;
		this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal(true);
		this.set_transient_for(App.window);
		this.destroy_with_parent = true;
		
		content = new Box(Orientation.VERTICAL, 10);
		padding = new Box(Orientation.HORIZONTAL, 10);
		
		/* start out by creating all category labels */
		nameLabel = new Label(_("Name of Playlist"));
		rulesLabel = new Label(_("Rules"));
		optionsLabel = new Label(_("Options"));
		
		/* make them look good */
		nameLabel.xalign = 0.0f;
		rulesLabel.xalign = 0.0f;
		optionsLabel.xalign = 0.0f;
		nameLabel.set_markup("<b>%s</b>".printf(_("Name of Playlist")));
		rulesLabel.set_markup("<b>%s</b>".printf(_("Rules")));
		optionsLabel.set_markup("<b>%s</b>".printf(_("Options")));
		
		/* add the name entry */
		nameEntry = new Granite.Widgets.HintedEntry(_("Playlist Title"));
		if(sp.name != "")
			nameEntry.set_text(sp.name);
		
		/* create match checkbox/combo combination */
		Box matchBox = new Box(Orientation.HORIZONTAL, 2);
		Label tMatch = new Label(_("Match"));
		comboMatch = new ComboBoxText();
		comboMatch.insert_text(0, _("any"));
		comboMatch.insert_text(1, _("all"));
		Label tOfTheFollowing = new Label(_("of the following:"));
		
		matchBox.pack_start(tMatch, false, false, 0);
		matchBox.pack_start(comboMatch, false, false, 0);
		matchBox.pack_start(tOfTheFollowing, false, false, 0);
		
		if(sp.conditional == SmartPlaylist.Conditional.ANY)
			comboMatch.set_active(0);
		else
			comboMatch.set_active(1);
		
		/* create rule list */
		spQueries = new Gee.ArrayList<SmartPlaylistEditorQuery>();
		vertQueries = new Box(Orientation.VERTICAL, 2);
		no_scroll = new EventBox();
		scroll = new Viewport(null, null);
		scroll.set_border_width(0);
		scrolled_window = new ScrolledWindow(null, null);
		scrolled_window.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
		scrolled_window.set_size_request(-1, get_screen().get_height() - BUFFER_SPACE);
		scrolled_window.add(scroll);
		
		// to start, put in no_scroll
		no_scroll.add(vertQueries);
		
		foreach(SmartQuery q in sp.queries) {
			SmartPlaylistEditorQuery speq = new SmartPlaylistEditorQuery(q);
			
			vertQueries.pack_start(speq, false, true, 0);
			spQueries.add(speq);
			speq.removed.connect(speq_removed);
		}
		
		if(sp.queries.size == 0) {
			addRow();
		}
		
		addButton = new Button.with_label(_("Add"));
		addButton.clicked.connect(addButtonClick);
		
		vertQueries.margin_right = addButton.margin_right = 6;
		
		/* create extra option: limiter */
		limitMedias = new CheckButton.with_label(_("Limit to"));
		mediaLimit = new SpinButton.with_range(0, 500, 10);
		Label limiterLabel = new Label(_("medias"));
		
		limitMedias.set_active(sp.limit);
		mediaLimit.set_value((double)sp.limit_amount);
		
		Box limiterBox = new Box(Orientation.HORIZONTAL, 2);
		limiterBox.pack_start(limitMedias, false, false, 0);
		limiterBox.pack_start(mediaLimit, false, false, 0);
		limiterBox.pack_start(limiterLabel, false, false, 0);
		
		/* add the Done button on bottom */
		HButtonBox bottomButtons = new HButtonBox();
		bottomButtons.set_spacing (6);
		bottomButtons.set_layout(ButtonBoxStyle.END);
		save = new Button.with_label(_("Done"));
		var cancel = new Button.with_label(_("Cancel"));
		bottomButtons.pack_end(cancel, false, false, 0);
		bottomButtons.pack_end(save, false, false, 0);
		
		/* put it all together */
		content.pack_start(UI.wrap_alignment(nameLabel, 10, 0, 0, 0), false, false, 0);
		content.pack_start(UI.wrap_alignment(nameEntry, 0, 10, 0, 10), false, false, 0);
		content.pack_start(rulesLabel, false, true, 0);
		content.pack_start(UI.wrap_alignment(matchBox, 0, 10, 0, 10) , false, false, 0);
		content.pack_start(UI.wrap_alignment(no_scroll, 0, 0, 0, 0), false, false, 0);
		content.pack_start(UI.wrap_alignment(scrolled_window, 0, 0, 0, 0), false, false, 0);
		content.pack_start(UI.wrap_alignment(addButton, 0, 0, 0, 0), false, false, 0);
		content.pack_start(optionsLabel, false, false, 0);
		content.pack_start(UI.wrap_alignment(limiterBox, 0, 10, 0, 10), false, false, 0);
		content.pack_start(bottomButtons, false, false, 10);
		
		padding.pack_start(content, true, true, 0);
		
		scrolled_window.set_no_show_all(true);
		
		add(UI.wrap_alignment(padding, 0, 10, 0, 10));
		show_all();
		
		save.clicked.connect(saveClick);
		cancel.clicked.connect( () => { destroy(); } );
		nameEntry.changed.connect(nameChanged);
		
		scrolled_window.hide();
		resize_gui();
	}
	
	void nameChanged() {
		if(nameEntry.get_text() == "") {
			save.set_sensitive(false);
			return;
		}
		else {
			foreach(var p in App.playlists.playlists()) {
				if((sp == null || sp.id != p.id) && nameEntry.get_text() == p.name) {
					save.set_sensitive(false);
					return;
				}
			}
		}
		
		save.set_sensitive(true);
	}
	
	void addRow() {
		SmartPlaylistEditorQuery speq = new SmartPlaylistEditorQuery(new SmartQuery());
		
		vertQueries.pack_start(speq, false, true, 0);
		spQueries.add(speq);
		speq.removed.connect(speq_removed);
		resize_gui();
	}
	
	void addButtonClick() {
		addRow();
	}
	
	void speq_removed(SmartPlaylistEditorQuery query) {
		spQueries.remove(query);
		vertQueries.remove(query);
		query.destroy();
		
		resize_gui();
	}
	
	void resize_gui() {
		Requisition min_req = Requisition();
		Requisition natural_req = Requisition();
		get_preferred_size(out min_req, out natural_req);
		
		resize(min_req.width, min_req.height);
		
		// Determine if we should move to scroll/out of scroll
		bool should_be_in_scroll = vertQueries.get_allocated_height() >= (get_screen().get_height() - BUFFER_SPACE);
		if(is_in_scroll && !should_be_in_scroll) {
			scroll.remove(vertQueries);
			scrolled_window.hide();
			no_scroll.add(vertQueries);
			no_scroll.show();
			is_in_scroll = false;
		}
		else if(!is_in_scroll && should_be_in_scroll) {
			no_scroll.remove(vertQueries);
			no_scroll.hide();
			scroll.add(vertQueries);
			scrolled_window.show();
			scroll.show();
			is_in_scroll = true;
		}
	}
	
	void saveClick() {
		sp.queries.clear();
		foreach(SmartPlaylistEditorQuery speq in spQueries) {
			sp.queries.add(speq.getQuery());
		}
		
		sp.name = nameEntry.text;
		sp.conditional = (SmartPlaylist.Conditional)comboMatch.get_active();
		sp.limit = limitMedias.get_active();
		sp.limit_amount = (int)mediaLimit.get_value();
		
		playlist_saved(sp);
		
		this.destroy();
	}
}

public class BeatBox.SmartPlaylistEditorQuery : Box {
	SmartQuery q;
	
	ListStore field_model;
	ComboBox field;
	
	ListStore comparator_model;
	TreeModelFilter comparator_filter;
	ComboBox comparator;
	
	ListStore media_option_model;
	TreeModelFilter media_option_filter;
	ComboBox media_option;
	Entry entry;
	SpinButton spinbutton;
	
	Label units;
	Button removeButton;
	
	public signal void removed(SmartPlaylistEditorQuery query);
	
	public SmartPlaylistEditorQuery(SmartQuery q) {
		this.q = q;
		
		// Create drop downs
		field_model = new ListStore(2, typeof(int), typeof(string));
		field = new ComboBox.with_model(field_model);
		var cell = new CellRendererText();
		field.pack_start(cell, true);
		field.add_attribute(cell, "text", 1);
		field.set_id_column(0);
		field.set_entry_text_column(1);
		foreach(SmartQuery.Field field in SmartQuery.Field.all()) {
			TreeIter iter;
			field_model.append(out iter);
			field_model.set(iter, 0, (int)field, 1, field.to_string());
		}
		
		comparator_model = new ListStore(2, typeof(int), typeof(string));
		comparator_filter = new TreeModelFilter(comparator_model, null);
		comparator = new ComboBox.with_model(comparator_filter);
		cell = new CellRendererText();
		comparator.pack_start(cell, true);
		comparator.add_attribute(cell, "text", 1);
		comparator.set_id_column(0);
		comparator.set_entry_text_column(1);
		comparator_filter.set_visible_func(visible_func);
		foreach(SmartQuery.Comparator com in SmartQuery.Comparator.all()) {
			TreeIter iter;
			comparator_model.append(out iter);
			comparator_model.set(iter, 0, (int)com, 1, com.to_string());
		}
		
		entry = new Entry();
		spinbutton =  new SpinButton.with_range(0, 9999, 1);
		
		media_option_model = new ListStore(2, typeof(int), typeof(string));
		media_option_filter = new TreeModelFilter(media_option_model, null);
		media_option = new ComboBox.with_model(media_option_filter);
		cell = new CellRendererText();
		media_option.pack_start(cell, true);
		media_option.add_attribute(cell, "text", 1);
		media_option.set_id_column(0);
		media_option.set_entry_text_column(1);
		TreeIter iter;
		
		// TODO: RE-implement MediaType.to_string()
		media_option_model.append(out iter);
		media_option_model.set(iter, 0, (int)MediaType.SONG, 1, MediaType.SONG.to_string(1));
		media_option_model.append(out iter);
		media_option_model.set(iter, 0, (int)MediaType.PODCAST, 1, MediaType.PODCAST.to_string(1));
		media_option_model.append(out iter);
		media_option_model.set(iter, 0, (int)MediaType.AUDIOBOOK, 1, MediaType.AUDIOBOOK.to_string(1));
		media_option_model.append(out iter);
		media_option_model.set(iter, 0, (int)MediaType.STATION, 1, MediaType.STATION.to_string(1));
		
		units = new Label("");
		removeButton = new Button.with_label(_("Remove"));
		
		field.set_active((int)q.field);
		comparator_filter.refilter();
		comparator_filter.foreach( (model, path, iter) => {
			int id;
			model.get(iter, 0, out id);
			
			if((SmartQuery.Comparator)id == q.comparator) {
				int index = int.parse(path.to_string());
				comparator.set_active(index);
				return true;
			}
			
			return false;
		});
		
		entry.set_no_show_all(true);
		media_option.set_no_show_all(true);
		spinbutton.set_no_show_all(true);
		
		comparator.set_size_request(160, -1);
		entry.set_size_request(200, -1);
		media_option.set_size_request(200, -1);
		spinbutton.set_size_request(200, -1);
		
		// Set the value
		if(q.field.is_string()) {
			entry.set_text(q.string_value);
			entry.show();
		}
		else if(q.field.is_type()) {
			media_option.set_active(q.int_value);
			media_option.show();
		}
		else if(q.field.is_int() || q.field.is_time()) {
			spinbutton.set_value(q.int_value);
			spinbutton.show();
		}
		
		pack_start(field, false, true, 0);
		pack_start(comparator, false ,true, 0);
		pack_start(entry, true, true, 0);
		pack_start(media_option, true, true, 0);
		pack_start(spinbutton, true, true, 0);
		pack_start(units, false, true, 0);
		pack_start(removeButton, false, true, 0);
		
		show_all();
		
		removeButton.clicked.connect(removeClicked);
		field.changed.connect(fieldChanged);
	}
	
	public SmartQuery getQuery() {
		SmartQuery rv = new SmartQuery();
		
		rv.field = (SmartQuery.Field)field.get_active();
		
		int id;
		TreeIter iter;
		comparator.get_active_iter(out iter);
		comparator_filter.get(iter, 0, out id);
		rv.comparator = (SmartQuery.Comparator)id;
		
		if(rv.field.is_string())
			rv.string_value = entry.text;
		else if(rv.field.is_type())
			rv.int_value = (MediaType)media_option.get_active();
		else
			rv.int_value = (int)spinbutton.value;
		
		return rv;
	}
	
	bool visible_func(TreeModel model, TreeIter iter) {
		bool rv = false;
		
		int id;
		model.get(iter, 0, out id);
		
		
		SmartQuery.Field cur_field = (SmartQuery.Field)field.get_active();
		switch (id) {
			case SmartQuery.Comparator.IS:
				rv = cur_field.is_string() || cur_field.is_type(); // strings, mediatype,
				break;
			case SmartQuery.Comparator.IS_EXACTLY:
				rv = cur_field.is_int() || cur_field.is_time(); // ints, times
				break;
			case SmartQuery.Comparator.IS_NOT:
				rv = cur_field.is_type(); //mediatype
				break;
			case SmartQuery.Comparator.IS_AT_LEAST:
			case SmartQuery.Comparator.IS_AT_MOST:
				rv = cur_field.is_int(); // ints
				break;
			case SmartQuery.Comparator.IS_WITHIN:
			case SmartQuery.Comparator.IS_BEFORE:
				rv = cur_field.is_time(); // times
				break;
			case SmartQuery.Comparator.CONTAINS:
			case SmartQuery.Comparator.DOES_NOT_CONTAIN:
				rv = cur_field.is_string(); // strings
				break;
			default:
				rv = false;
				break;
		}
		
		return rv;
	}
	
	void fieldChanged() {
		if(((SmartQuery.Field)field.get_active()).is_string()) {
			entry.show();
			media_option.hide();
			spinbutton.hide();
		}
		else if(((SmartQuery.Field)field.get_active()).is_type()) {
			entry.hide();
			spinbutton.hide();
			media_option.show();
			media_option.set_active(q.int_value);
		}
		else {
			spinbutton.show();
			entry.hide();
			media_option.hide();
		}
		
		comparator_filter.refilter();
		comparator.set_active(0);
		
		
		//helper for units
		if(((SmartQuery.Field)field.get_active()) == SmartQuery.Field.LENGTH) {
			units.set_text(_("seconds"));
			units.show();
		}
		else if(((SmartQuery.Field)field.get_active()).is_time()) {
			units.set_text(_("days ago"));
			units.show();
		}
		else if(((SmartQuery.Field)field.get_active()) == SmartQuery.Field.BITRATE) {
			units.set_text(_("kbps"));
			units.show();
		}
		else
			units.hide();
	}
	
	void removeClicked() {
		removed(this);
	}
}
