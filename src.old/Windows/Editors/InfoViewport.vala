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

public class BeatBox.InfoViewport : Viewport {
	Media media;
	
	Box left; // Contains labels
	Box right; // Contains values
	Box content; // Combines left and right
	
	Label location;
	Label file_size;
	Label date_added;
	Label last_played;
	Label last_modified;
	Label plays;
	Label skips;
	Label length;
	Label bitrate;
	Label samplerate;
	
	public InfoViewport(Media m) {
		left = new Box(Orientation.VERTICAL, 0);
		right = new Box(Orientation.VERTICAL, 0);
		content = new Box(Orientation.HORIZONTAL, 0);
		
		var location_label = new Label("");
		var file_size_label = new Label("");
		var date_added_label = new Label("");
		var last_played_label = new Label("");
		var last_modified_label = new Label("");
		var plays_label = new Label("");
		var skips_label = new Label("");
		var length_label = new Label("");
		var bitrate_label = new Label("");
		var samplerate_label = new Label("");
		
		location_label.set_markup("<b>" + _("Location:") + "</b>");
		file_size_label.set_markup("<b>" + _("File Size:") + "</b>");
		date_added_label.set_markup("<b>" + _("Date Added:") + "</b>");
		last_played_label.set_markup("<b>" + _("Last Played:") + "</b>");
		last_modified_label.set_markup("<b>" + _("Last Modified:") + "</b>");
		plays_label.set_markup("<b>" + _("Play Count:") + "</b>");
		skips_label.set_markup("<b>" + _("Skip Count") + "</b>");
		length_label.set_markup("<b>" + _("Duration:") + "</b>");
		bitrate_label.set_markup("<b>" + _("Audio Bitrate:") + "</b>");
		samplerate_label.set_markup("<b>" + _("Sample Rate:") + "</b>");
		
		location_label.xalign = 0.0f;
		file_size_label.xalign = 0.0f;
		date_added_label.xalign = 0.0f;
		last_played_label.xalign = 0.0f;
		last_modified_label.xalign = 0.0f;
		plays_label.xalign = 0.0f;
		skips_label.xalign = 0.0f;
		length_label.xalign = 0.0f;
		bitrate_label.xalign = 0.0f;
		samplerate_label.xalign = 0.0f;
		
		left.pack_start(location_label, false, false, 0);
		left.pack_start(file_size_label, false, false, 0);
		left.pack_start(date_added_label, false, false, 0);
		left.pack_start(last_played_label, false, false, 0);
		left.pack_start(last_modified_label, false, false, 0);
		left.pack_start(plays_label, false, false, 0);
		left.pack_start(skips_label, false, false, 0);
		left.pack_start(length_label, false, false, 0);
		left.pack_start(bitrate_label, false, false, 0);
		left.pack_start(samplerate_label, false, false, 0);
		
		location = new Label("");
		file_size = new Label("");
		date_added = new Label("");
		last_played = new Label("");
		last_modified = new Label("");
		plays = new Label("");
		skips = new Label("");
		length = new Label("");
		bitrate = new Label("");
		samplerate = new Label("");
		
		right.pack_start(location, false, false, 0);
		right.pack_start(file_size, false, false, 0);
		right.pack_start(date_added, false, false, 0);
		right.pack_start(last_played, false, false, 0);
		right.pack_start(last_modified, false, false, 0);
		right.pack_start(plays, false, false, 0);
		right.pack_start(skips, false, false, 0);
		right.pack_start(length, false, false, 0);
		right.pack_start(bitrate, false, false, 0);
		right.pack_start(samplerate, false, false, 0);
		
		location.xalign = 0.0f;
		file_size.xalign = 0.0f;
		date_added.xalign = 0.0f;
		last_played.xalign = 0.0f;
		last_modified.xalign = 0.0f;
		plays.xalign = 0.0f;
		skips.xalign = 0.0f;
		length.xalign = 0.0f;
		bitrate.xalign = 0.0f;
		samplerate.xalign = 0.0f;
		
		location.max_width_chars = 30;
		location.ellipsize = Pango.EllipsizeMode.START;
		location.has_tooltip = true;
		
		content.pack_start(left, false, false, 0);
		content.pack_start(UI.wrap_alignment(right, 0, 10, 10, 4), true, true, 0);
		
		add(content);
		
		set_media(m);
		
		show_all();
		hide();
	}
	
	public void set_media(Media m) {
		media = m;
		
		Library lib = App.library.get_library(m.key);
		if(m.is_local) {
			if(lib != null) {
				location.set_label(File.new_for_uri(m.uri).get_path().replace(lib.folder.get_path(), ".."));
			}
			else {
				location.set_label(File.new_for_uri(m.uri).get_path());
			}
		}
		else {
			location.set_label(m.uri);
		}
		
		location.tooltip_text = m.uri;
		
		if(m.file_size == 0) {
			file_size.set_label(_("Unknown Size"));
		}
		else {
			file_size.set_label(GLib.format_size(m.file_size));
		}
		
		date_added.set_label(TimeUtils.pretty_timestamp_from_uint(m.date_added));
		
		if(m.last_played == 0) {
			last_played.set_label(_("Never Played"));
		}
		else {
			last_played.set_label(TimeUtils.pretty_timestamp_from_uint(m.last_played));
		}
		
		if(m.last_modified == 0) {
			last_modified.set_label(_("Never Modified"));
		}
		else {
			last_modified.set_label(TimeUtils.pretty_timestamp_from_uint(m.last_modified));
		}
		
		if(m.play_count == 0) {
			plays.set_label(_("No Plays"));
		}
		else {
			plays.set_label("%u %s".printf(m.play_count, ngettext("Play", "Plays", m.play_count)));
		}
		
		if(m.skip_count == 0) {
			skips.set_label(_("No Skips"));
		}
		else {
			skips.set_label("%u %s".printf(m.skip_count, ngettext("Skip", "Skips", m.skip_count)));
		}
		
		length.set_label(TimeUtils.pretty_time_mins(m.length));
		
		if(m.bitrate == 0) {
			bitrate.set_label(_("Unknown Bitrate"));
		}
		else {
			bitrate.set_label(_("%d kbps").printf(m.bitrate));
		}
		
		if(m.samplerate == 0) {
			samplerate.set_label(_("Unknown Sample Rate"));
		}
		else {
			samplerate.set_label(_("%d Hz").printf(m.samplerate));
		}
	}
}
