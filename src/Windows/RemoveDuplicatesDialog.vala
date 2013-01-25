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

public class BeatBox.RemoveDuplicatesDialog : Gtk.Window {
	ComboBoxText matchOption;
	SpinButton matchPercent;
	Box percent_box;
	int index;
	int total;
	Gtk.Spinner is_working;
	Gtk.Label feedback_label;
	Button cancel;
	Button analyze;
	
	public signal void duplicates_found(HashMap<Media, Collection<Media>> dups);
	
	static string FEEDBACK_STRING = _("Analyzing %d of %d...");
	
	public RemoveDuplicatesDialog() {
		build_ui();
	}
	
	void build_ui () {
		set_title(_("Duplicates Remover"));

		// Window properties
		window_position = WindowPosition.CENTER;
		type_hint = Gdk.WindowTypeHint.DIALOG;
		modal = true;
		resizable = false;
		set_transient_for(App.window);
		set_size_request(400, -1);

		var content = new Box(Orientation.VERTICAL, 10);
		var padding = new Box(Orientation.HORIZONTAL, 10);
		
		var matchLabel = new Label("");
		matchOption = new ComboBoxText();
		matchPercent = new SpinButton.with_range(80, 100, 5);
		is_working = new Gtk.Spinner();
		feedback_label = new Gtk.Label(FEEDBACK_STRING.printf(0, 0));
		cancel = new Button.with_label(_("Cancel"));
		analyze = new Button.with_label(_("Analyze..."));
		
		percent_box = new Box(Orientation.HORIZONTAL, 0);
		var percentLabel = new Label(_("Media must match by at least "));
		var percentPercentLabel = new Label(_(" percent."));
		percent_box.pack_start(percentLabel, false, false, 0);
		percent_box.pack_start(matchPercent, false, false, 0);
		percent_box.pack_start(percentPercentLabel, false, false, 0);
		
		Box feedbackBox = new Box(Orientation.HORIZONTAL, 6);
		feedbackBox.pack_start(is_working, false, false, 0);
		feedbackBox.pack_start(feedback_label, false, false, 0);
		
		HButtonBox buttonSep = new HButtonBox();
		buttonSep.set_spacing (6);
		buttonSep.set_layout(ButtonBoxStyle.END);
		buttonSep.pack_start(feedbackBox, false, false, 0);
		buttonSep.pack_end(cancel, false, false, 0);
		buttonSep.pack_end(analyze, false, false, 0);
		(buttonSep as Gtk.ButtonBox).set_child_secondary(feedbackBox, true);
		
		// fancy up the category labels
		matchLabel.xalign = 0.0f;
		matchLabel.set_markup("<b>" + _("Matching Criteria") + "</b>");
		matchOption.append_text(_("Title and Artist"));
		matchOption.append_text(_("Title, Artist, and Album"));
		matchOption.set_active(0);
		
		// Pack all widgets
		content.pack_start(wrap_alignment(matchLabel, 10, 0, 0, 0), false, true, 0);
		content.pack_start(wrap_alignment(matchOption, 0, 0, 0, 10), false, true, 0);
		content.pack_start(wrap_alignment(percent_box, 0, 0, 0, 10), false, true, 0);
		content.pack_end(buttonSep, false, true, 10);
		
		padding.pack_start(content, true, true, 10);
		add(padding);
		
		is_working.set_no_show_all(true);
		feedback_label.set_no_show_all(true);
		percent_box.set_no_show_all(true);
		
		show_all();
		
		cancel.clicked.connect(cancel_clicked);
		analyze.clicked.connect(analyze_clicked);
	}
	
	static Gtk.Alignment wrap_alignment (Gtk.Widget widget, int top, int right, int bottom, int left) {
	
		var alignment = new Gtk.Alignment(0.0f, 0.0f, 1.0f, 1.0f);
		alignment.top_padding = top;
		alignment.right_padding = right;
		alignment.bottom_padding = bottom;
		alignment.left_padding = left;
		
		alignment.add(widget);
		return alignment;
	}
	
	void cancel_clicked() {
		destroy();
	}
	
	void analyze_clicked() {
		analyze.set_sensitive(false);
		is_working.show();
		feedback_label.show();
		
		is_working.start();
		
		try {
			new Thread<void*>.try (null, find_duplicates_thread);
		}
		catch (Error err) {
			warning ("Could not create thread to analyze duplicates: %s", err.message);
		}
	}
	
	void* find_duplicates_thread () {
		var arr = App.library.medias().to_array();
		var all = new HashMap<Media, int>(); // 1 = is in dups
		var dups = new HashMap<Media, Collection<Media>>();
		
		index = 0;
		total = arr.length;
		Timeout.add(250, duplicateFeedbackTimeout);
		
		for(int i = 0; i < arr.length; ++i) {
			Media m = arr[i];
			++index;
			
			if(all.get(m) == 1)
				continue;
			
			for(int x = i; x < arr.length; ++x) {
				Media n = arr[x];
				if(all.get(n) == 1)
					continue;
				
				if(is_duplicate(m, n)) {
					all.set(m, 1);
					all.set(n, 1);
					if(dups.get(m) == null) {
						var list = new LinkedList<Media>();
						list.add(n);
						dups.set(m, list);
					}
					else {
						dups.get(m).add(n);
					}
				}
			}
		}
		
		// We now have all duplicates in dups
		Idle.add( () => {
			duplicates_found(dups);
			this.destroy();
			
			return false;
		});
		
		return null;
	}
	
	bool is_duplicate(Media m, Media n) {
		if(m == n)
			return false;
		
		if(m.title.down() == n.title.down()) {
			if(m.artist.down() == n.artist.down()) {
				if(matchOption.active == 0)
					return true;
				else
					return m.album.down() == n.album.down();
			}
		}
		
		return false;
	}
	
	
	// These functions are way to slow, but would have matched duplicates more generously
	/*int minimum(int a, int b, int c) {
			return ((a < b) ? ((a < c) ? a : c) : ((b < c) ? b : c));
	}*/

	/*double compute_similarity(string str1, string str2) {
		int[,] distance = new int[str1.length + 1, str2.length + 1];

		for (int i = 0; i <= str1.length; i++)
			distance[i, 0] = i;
		for (int j = 0; j <= str2.length; j++)
			distance[0, j] = j;

		for (int i = 1; i <= str1.length; i++)
			for (int j = 1; j <= str2.length; j++)
				distance[i, j] = minimum(
									distance[i - 1, j] + 1,
									distance[i, j - 1] + 1,
									distance[i - 1, j - 1] + ((str1.get(i - 1) == str2.get(j - 1)) ? 0 : 1));

		int differences = distance[str1.length, str2.length];
		int average_length = (str1.length + str2.length)/2;
		
		return 100 * ((double)(average_length - differences))/((double)average_length);
	}*/
	
	public bool duplicateFeedbackTimeout() {
		feedback_label.set_label(FEEDBACK_STRING.printf(index, total));
		
		if(index < total) {
			return true;
		}
		
		return false;
	}
}
