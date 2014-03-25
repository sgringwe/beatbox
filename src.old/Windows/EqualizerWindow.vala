/*-
 * Copyright (c) 2011-2012	   Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski and Victor Eduardo for
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

public class BeatBox.EqualizerWindow : Gtk.Window {
	VolumeWidget volume;
	private Switch eq_switch;
	private PresetList preset_combo;
	private Entry new_preset_entry;
	private Button close_button;

	private bool apply_changes;
	private bool initialized;
	private bool adding_preset;
	private bool closing;

	private const int ANIMATION_TIMEOUT = 20;

	private List<Scale> scale_list;
	private List<Label> label_list;

	private bool in_transition;
	private Gee.ArrayList<int> target_levels;

	private string new_preset_name;

	public EqualizerWindow () {
		scale_list = new List<VScale>();
		label_list = new List<Label>();
		target_levels = new Gee.ArrayList<int>();

		closing = false;
		adding_preset = false;
		initialized = false;
		apply_changes = false;

		build_ui();
		load_presets();

		initialized = true;

		if (App.settings.equalizer.auto_switch_preset) {
			preset_combo.selectAutomaticPreset();
		} else {
			var preset = App.settings.equalizer.selected_preset;
			if (preset != null)
				preset_combo.selectPreset(preset);
		}

		on_eq_switch_toggled ();
		apply_changes = true;
	}

	void build_ui () {
		set_title(_("Equalizer"));

		window_position = WindowPosition.CENTER;
		type_hint = Gdk.WindowTypeHint.DIALOG;
		set_transient_for(App.window);
		set_size_request(-1, 224);
		this.destroy_with_parent = true;
		resizable = false;

		set_icon(render_icon(Gtk.Stock.PREFERENCES, IconSize.DIALOG, null));

		var outer_box = new Box(Orientation.HORIZONTAL, 10);
		var inner_box = new Box(Orientation.VERTICAL, 10);
		var scales = new Box(Orientation.HORIZONTAL, 0);

		eq_switch = new Switch();
		preset_combo = new PresetList();

		eq_switch.set_active(App.settings.equalizer.equalizer_enabled);
		
		// First add volume control on left of equalizer scales
		volume = new VolumeWidget(App.playback.get_volume());
		scales.pack_start(volume, true, true, 6);
		scales.pack_start(new Gtk.Separator(Gtk.Orientation.VERTICAL), true, true, 6);
		
		string[] decibels = {"32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"};
		for (int index = 0; index < 10; ++index) {
			Box holder = new Box(Orientation.VERTICAL, 0);
			Scale v = new Scale.with_range(Orientation.VERTICAL, -80, 80, 1);
			v.add_mark(0, PositionType.LEFT, null);
			v.draw_value = false;
			v.inverted = true;

			var label = new Label(decibels[index]);

			holder.pack_start(v, true, true, 0);
			holder.pack_end(UI.wrap_alignment(label, 4, 0, 0, 0), false, false, 0);

			scales.pack_start(holder, true, true, 6);
			scale_list.append(v);
			label_list.append(label);

			v.value_changed.connect( () => {
				if(apply_changes && initialized && !preset_combo.automatic_chosen) {
					App.playback.setEqualizerGain(scale_list.index(v), (int)scale_list.nth_data(scale_list.index(v)).get_value());

					if(!in_transition) {
						if (!preset_combo.getSelectedPreset().is_default)
							preset_combo.getSelectedPreset().setGain(scale_list.index(v), (int)scale_list.nth_data(scale_list.index(v)).get_value());
						else
							on_default_preset_modified();
					}
				}
			});

		}

		preset_combo.set_size_request(165, -1);

		//var eq_switch_item = new ToolItem();
		//eq_switch_item.add(eq_switch);

		new_preset_entry = new Entry();
		new_preset_entry.set_size_request(165, -1);

		var entry_icon = App.icons.render_icon ("dialog-apply", IconSize.MENU);
		new_preset_entry.set_icon_from_pixbuf(Gtk.EntryIconPosition.SECONDARY, entry_icon);
		new_preset_entry.set_icon_tooltip_text(Gtk.EntryIconPosition.SECONDARY, _("Save preset"));
		
		close_button = new Button.with_label(_("Done"));
		
		HButtonBox bottom_toolbar = new HButtonBox();
		bottom_toolbar.set_layout(ButtonBoxStyle.END);
		
		bottom_toolbar.pack_start(eq_switch, false, false, 0);
		bottom_toolbar.pack_start(preset_combo, false, false, 0);
		bottom_toolbar.pack_start(new_preset_entry, false, false, 0);
		bottom_toolbar.pack_end(close_button, false, false, 0);
		
		(bottom_toolbar as Gtk.ButtonBox).set_child_secondary(eq_switch, true);
		(bottom_toolbar as Gtk.ButtonBox).set_child_secondary(preset_combo, true);
		(bottom_toolbar as Gtk.ButtonBox).set_child_secondary(new_preset_entry, true);

		inner_box.pack_end(UI.wrap_alignment(bottom_toolbar, 0, 0, 10, 0), false, false, 0);
		inner_box.pack_start(UI.wrap_alignment(scales, 0, 12, 0, 12), true, true, 10);

		outer_box.pack_start(inner_box, true, true, 10);
		add(outer_box);
		
		volume.volume_changed.connect(volume_changed);
		eq_switch.notify["active"].connect(on_eq_switch_toggled);
		preset_combo.automatic_preset_chosen.connect(on_automatic_chosen);
		preset_combo.delete_preset_chosen.connect(remove_preset_clicked);
		preset_combo.preset_selected.connect (preset_selected);
		new_preset_entry.activate.connect (add_new_preset);
		new_preset_entry.icon_press.connect (new_preset_entry_icon_pressed);
		new_preset_entry.focus_out_event.connect (on_entry_focus_out);

		close_button.clicked.connect(on_quit);
		destroy.connect(on_quit);

		show_all();
		
		new_preset_entry.set_no_show_all(true);
		new_preset_entry.visible = false;
	}
	
	void volume_changed() {
		App.playback.set_volume(volume.get_volume());
	}
	
	bool on_entry_focus_out () {
		if (!closing)
			new_preset_entry.grab_focus();
		return false;
	}

	void set_sliders_sensitivity (bool sensitivity) {
		foreach (var scale in scale_list) {
			label_list.nth_data(scale_list.index(scale)).sensitive = sensitivity;
			scale.sensitive = sensitivity;
		}
	}

	void on_eq_switch_toggled () {
		in_transition = false;

		bool eq_active = eq_switch.get_active();
		preset_combo.sensitive = eq_active;
		set_sliders_sensitivity (eq_active);
		App.settings.equalizer.equalizer_enabled = eq_active;

		if (eq_active) {
			if(!preset_combo.automatic_chosen) {
				EqualizerPreset? selected_preset = preset_combo.getSelectedPreset();

				if (selected_preset != null) {
					for(int i = 0; i < 10; ++i)
						App.playback.setEqualizerGain(i, selected_preset.getGain(i));
				}
			}
			else {
				preset_combo.selectAutomaticPreset();
			}
		}
		else {
			for (int i = 0; i < 10; ++i)
				App.playback.setEqualizerGain(i, 0);
		}
	}

	void load_presets () {
		foreach (EqualizerPreset preset in App.settings.equalizer.getDefaultPresets ()) {
			preset.is_default = true;
			preset_combo.addPreset(preset);
		}

		foreach (EqualizerPreset preset in App.settings.equalizer.getCustomPresets ()) {
			preset_combo.addPreset(preset);
		}
	}

	void save_presets () {
		var customPresets = new Gee.LinkedList<EqualizerPreset>();

		foreach (EqualizerPreset preset in preset_combo.getPresets()) {
			if (!preset.is_default)
				customPresets.add (preset);
		}

		App.settings.equalizer.custom_presets = App.settings.equalizer.getPresetsArray (customPresets);
	}

	void preset_selected (EqualizerPreset p) {

		if (!initialized)
			return;

		set_sliders_sensitivity (true);
		target_levels.clear();

		foreach (int i in p.gains) {
			target_levels.add(i);
		}

		if (closing || (initialized && !apply_changes) || adding_preset) {
			set_target_levels ();
		}
		else if (!in_transition) {
			in_transition = true;
			Timeout.add(ANIMATION_TIMEOUT, transition_scales);
		}
	}

	void set_target_levels () {
		in_transition = false;

		for (int index = 0; index < 10; ++index)
			scale_list.nth_data(index).set_value(target_levels.get(index));
	}

	bool transition_scales () {
		if (!in_transition)
			return false;

		bool is_finished = true;

		for (int index = 0; index < 10; ++index) {
			double currLvl = scale_list.nth_data(index).get_value();
			double targetLvl = target_levels.get(index);
			double difference = targetLvl - currLvl;

			if (closing || Math.fabs(difference) <= 1) {
				scale_list.nth_data(index).set_value(targetLvl);
				// if switching from the automatic mode, apply the changes correctly
				if (!preset_combo.automatic_chosen && targetLvl == 0)
					App.playback.setEqualizerGain (index, 0);
			}
			else {
				scale_list.nth_data(index).set_value(scale_list.nth_data(index).get_value() + (difference / 8.0));
				is_finished = false;
			}
		}

		if (is_finished) {
			in_transition = false;
			return false; // stop
		}

		return true; // keep going
	}

	void on_automatic_chosen () {
		App.settings.equalizer.auto_switch_preset = preset_combo.automatic_chosen;

		target_levels.clear();

		for (int i = 0; i < 10; ++i)
			target_levels.add(0);

		set_sliders_sensitivity (false);

		if (apply_changes) {
			in_transition = true;
			Timeout.add (ANIMATION_TIMEOUT, transition_scales);
			save_presets ();
			App.playback.change_gains_thread ();
		}
		else {
			set_target_levels ();
		}
	}

	void on_default_preset_modified () {

		if(adding_preset || closing)
			return;

		adding_preset = true;

		close_button.sensitive = !adding_preset;

		preset_combo.visible = false;
		new_preset_entry.visible = true;

		new_preset_name = create_new_preset_name(true);

		new_preset_entry.set_text(new_preset_name);
		eq_switch.sensitive = false;
		//bottom_toolbar.show_all();
		new_preset_entry.grab_focus();
	}

	void new_preset_entry_icon_pressed (EntryIconPosition pos, Gdk.Event event) {

		if(pos != Gtk.EntryIconPosition.SECONDARY && !adding_preset)
			return;

		add_new_preset();
	}

	void add_new_preset() {

		if(!adding_preset)
			return;

		var new_name = new_preset_entry.get_text();

		if(verify_preset_name(new_name))
			new_preset_name = new_name;

		int i = 0;
		int[] gains = new int[10];

		foreach(Scale scale in scale_list) {
			gains[i] = (int)scale_list.nth_data(scale_list.index(scale)).get_value();
			i++;
		}

		var new_preset = new EqualizerPreset.with_gains(new_preset_name, gains);
		preset_combo.addPreset(new_preset);

		new_preset_entry.visible = false;
		preset_combo.visible = true;
		//bottom_toolbar.show_all();
		eq_switch.sensitive = true;
		adding_preset = false;
		close_button.sensitive = !adding_preset;
	}

	string create_new_preset_name (bool from_current) {

		int i = 0;
		bool is_valid = false;

		string current_preset_name = (from_current)? preset_combo.getSelectedPreset().name : "";
		string preset_name = _("Custom Preset");

		do
		{
			preset_name = (from_current)? current_preset_name + " (" : "";
			preset_name += _("Custom") + ((from_current)? "" : _(" Preset"));
			preset_name += (!is_valid && i > 0)? " " + i.to_string() : "";
			preset_name += (from_current)? ")" : "";

			i++;

			is_valid = verify_preset_name(preset_name);

		} while (!is_valid);

		return preset_name;
	}

	public bool verify_preset_name (string preset_name) {

		int white_space = 0;
		int str_length = preset_name.length;
		bool preset_already_exists = false;

		if(preset_name == null || str_length < 1)
			return false;

		unichar c;
		for (int i = 0; preset_name.get_next_char (ref i, out c);)
			if (c.isspace())
				++white_space;

		if (white_space == str_length)
			return false;

		var current_presets = preset_combo.getPresets();

		preset_already_exists = false;

		foreach (EqualizerPreset preset in current_presets) {
			if (preset_name == preset.name) {
				preset_already_exists = true;
				break;
			}
		}

		return !preset_already_exists;
	}

	void remove_preset_clicked () {
		preset_combo.removeCurrentPreset();
	}

	void on_quit () {
		closing = true;

		if (in_transition)
			set_target_levels ();
		else if (adding_preset)
			add_new_preset ();

		save_presets ();
		App.settings.equalizer.volume = (int)(volume.get_volume()*100);
		App.settings.equalizer.selected_preset = (preset_combo.getSelectedPreset() != null)? preset_combo.getSelectedPreset().name : "";
		App.settings.equalizer.auto_switch_preset = preset_combo.automatic_chosen;
		
		App.actions.destroy_equalizer();
	}
}

