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

public class BeatBox.FieldEditorImpl : Box, FieldEditor {
	enum FieldEditorType {
		INTEGER,
		STRING,
		LONG_STRING,
		RATING,
		OPTIONS
	}
	
	FieldEditorType type;
	string field_name;
	Value original;
	
	Box field_name_box;
	CheckButton check;
	Label label;
	Widget edit_widget;
	
	public FieldEditorImpl.for_integer(string field_name, int original, int min, int max) {
		FieldEditorImpl.basic(field_name);
		
		this.original = Value(typeof(int));
		this.original.set_int(original);
		type = FieldEditorType.INTEGER;
		
		check.set_active(original != 0);
		
		var spin_button = new SpinButton.with_range(min, max, 1);
		spin_button.set_size_request(100, -1);
		spin_button.set_value(check.get_active() ? (double)this.original.get_int() : 0.0);
		spin_button.adjustment.value_changed.connect(spin_button_changed);
		
		edit_widget = spin_button;
		this.pack_start(spin_button, true, true, 0);
	}
	
	public FieldEditorImpl.for_string(string field_name, string original) {
		FieldEditorImpl.basic(field_name);
		
		this.original = Value(typeof(string));
		this.original.set_string(original);
		type = FieldEditorType.STRING;
		
		check.set_active(original != "");
			
		var entry = new Entry();
		entry.set_text(original);
		entry.changed.connect(entry_changed);
		
		edit_widget = entry;
		this.pack_start(entry, true, true, 0);
	}
	
	public FieldEditorImpl.for_long_string(string field_name, string original) {
		FieldEditorImpl.basic(field_name);
		
		this.original = Value(typeof(string));
		this.original.set_string(original);
		type = FieldEditorType.LONG_STRING;
		
		check.set_active(original != "");
			
		var text_view = new TextView();
		text_view.set_wrap_mode(WrapMode.WORD_CHAR);
		text_view.get_buffer().text = original;
		text_view.buffer.changed.connect(text_view_changed);
		
		ScrolledWindow scroll = new ScrolledWindow(null, null);
		Viewport viewport = new Viewport(null, null);
		viewport.set_shadow_type(ShadowType.ETCHED_IN);
		scroll.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
		viewport.add(text_view);
		scroll.add(viewport);
		
		edit_widget = text_view;
		this.pack_start(scroll, true, true, 0);
	}
	
	public FieldEditorImpl.for_rating(string field_name, int original) {
		FieldEditorImpl.basic(field_name);
		
		this.original = Value(typeof(int));
		this.original.set_int(original);
		type = FieldEditorType.RATING;
		
		check.set_active(original != 0);
			
		var rating_widget = new RatingWidget(false, IconSize.MENU, false, null);
		rating_widget.set_rating(original);
		rating_widget.rating_changed.connect(rating_changed);
		
		edit_widget = rating_widget;
		this.pack_start(rating_widget, true, true, 0);
	}
	
	private FieldEditorImpl.basic(string field_name) {
		this.field_name = field_name;
		
		this.spacing = 0;
		this.set_orientation(Orientation.VERTICAL);
		
		check = new CheckButton();
		label = new Label(field_name);
		field_name_box = new Box(Orientation.HORIZONTAL, 0);
		
		label.justify = Justification.LEFT;
		label.xalign = 0.0f;
		label.set_markup("<b>" + Markup.escape_text(field_name) + "</b>");
		
		field_name_box.pack_start(check, false, false, 0);
		field_name_box.pack_start(label, false, true, 0);
		this.pack_start(field_name_box, false, false, 0);
	}
	
	public void set_width_request(int width) {
		//label.set_size_request(width, -1);
		set_size_request(width, -1);
	}
	
	public void set_check_visible(bool val) {
		check.set_visible(false);
	}
	
	void entry_changed() {
		Entry entry = (Entry)edit_widget;
		
		if(entry.text != original.get_string())
			check.set_active(true);
		else
			check.set_active(false);
	}
	
	void text_view_changed() {
		TextView text_view = (TextView)edit_widget;
		
		if(text_view.get_buffer().text != original.get_string())
			check.set_active(true);
		else
			check.set_active(false);
	}
	
	void spin_button_changed() {
		SpinButton spin_button = (SpinButton)edit_widget;
		
		if(spin_button.value != (double)original.get_int())
			check.set_active(true);
		else
			check.set_active(false);
	}
	
	void rating_changed(int new_rating) {
		RatingWidget rating_widget = (RatingWidget)edit_widget;
		
		if(rating_widget.get_rating() != original.get_int())
			check.set_active(true);
		else
			check.set_active(false);
	}
	
	/*void comboChanged() {
		if(comboBox.get_active() != int.parse(_original))
			check.set_active(true);
		else
			check.set_active(false);
	}*/
	
	public bool checked() {
		return check.get_active();
	}
	
	/*void resetClicked() {
		if(entry != null) {
			entry.text = _original;
		}
		else if(textView != null) {
			textView.get_buffer().text = _original;
		}
		else if(spinButton != null) {
			spinButton.value = double.parse(_original);
		}
		/*else if(image != null) {
			image.set_from_file(_original);
		}*
		else if(ratingWidget != null) {
			ratingWidget.set_rating(int.parse(_original));
		}
		/*else if(comboBox != null) {
			comboBox.set_active(int.parse(_original));
		}*
	}*/
	
	public Value? get_value() {
		if(type == FieldEditorType.INTEGER) {
			Value rv = Value(typeof(int));
			rv.set_int((int)((SpinButton)edit_widget).value);
			return rv;
		}
		else if(type == FieldEditorType.STRING) {
			Value rv = Value(typeof(string));
			rv.set_string(((Entry)edit_widget).text);
			return rv;
		}
		else if(type == FieldEditorType.LONG_STRING) {
			Value rv = Value(typeof(string));
			rv.set_string(((TextView)edit_widget).get_buffer().text);
			return rv;
		}
		else if(type == FieldEditorType.RATING) {
			Value rv = Value(typeof(int));
			rv.set_int(((RatingWidget)edit_widget).get_rating());
			return rv;
		}
		
		return null;
	}
	
	public void set_value(Value val) {
		if(type == FieldEditorType.INTEGER) {
			((SpinButton)edit_widget).value = (double)val.get_int();
		}
		else if(type == FieldEditorType.STRING) {
			((Entry)edit_widget).text = val.get_string();
		}
		else if(type == FieldEditorType.LONG_STRING) {
			((TextView)edit_widget).get_buffer().text = val.get_string();
		}
		else if(type == FieldEditorType.RATING) {
			((RatingWidget)edit_widget).set_rating(val.get_int());
		}
	}
}
