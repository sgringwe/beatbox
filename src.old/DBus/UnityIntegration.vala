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
#if HAVE_UNITY
using GLib;

public class BeatBox.UnityIntegration : GLib.Object {
	Unity.LauncherEntry entry;
	
	Dbusmenu.Menuitem quicklist;
	Dbusmenu.Menuitem previous;
	Dbusmenu.Menuitem playpause;
	Dbusmenu.Menuitem next;
	Dbusmenu.Menuitem preferences;
	Dbusmenu.Menuitem equalizer;
	
	public UnityIntegration() {
		
	}
	
	// TODO: Use actions list of actions to create these
	// dbus menu items rather than creating custom ones.
	public bool initialize() {
		entry = Unity.LauncherEntry.get_for_desktop_file("beatbox.desktop");
		if(entry == null)
			return false;
		
		quicklist = new Dbusmenu.Menuitem ();
		previous = new Dbusmenu.Menuitem ();
		playpause = new Dbusmenu.Menuitem ();
		next = new Dbusmenu.Menuitem ();
		preferences = new Dbusmenu.Menuitem ();
		equalizer = new Dbusmenu.Menuitem ();
		previous.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Previous"));
		playpause.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Play"));
		next.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Next"));
		preferences.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Preferences"));
		equalizer.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Equalizer"));
		previous.item_activated.connect(previous_activated);
		playpause.item_activated.connect(playpause_activated);
		next.item_activated.connect(next_activated);
		preferences.item_activated.connect(preferences_activated);
		equalizer.item_activated.connect(equalizer_activated);
		quicklist.child_append (previous);
		quicklist.child_append (playpause);
		quicklist.child_append (next);
		var sep = new Dbusmenu.Menuitem();
		sep.property_set(Dbusmenu.MENUITEM_PROP_TYPE, Dbusmenu.CLIENT_TYPES_SEPARATOR);
		quicklist.child_append (sep);
		quicklist.child_append (preferences);
		quicklist.child_append (equalizer);
		entry.quicklist = quicklist;
		
		App.operations.operation_started.connect(operation_started);
		App.operations.operation_progress_updated.connect(operation_progress_updated);
		App.operations.operation_finished.connect(operation_finished);
		
		App.playback.playback_played.connect(playing_changed);
		App.playback.playback_paused.connect(playing_changed);
		App.playback.playback_stopped.connect(playing_changed);
		
		return true;
	}
	
	void previous_activated(uint object) {
		App.playback.request_previous();
	}
	
	void playpause_activated(uint object) {
		if(App.playback.playing)
			App.playback.pause();
		else
			App.playback.play();
	}
	
	void next_activated(uint object) {
		App.playback.request_next();
	}
	
	void preferences_activated(uint object) {
		App.actions.show_preferences.activate();
	}
	
	void equalizer_activated(uint object) {
		//if(App.actions.show_equalizer.get_sensitive()) {
			App.actions.show_equalizer.activate();
		//}
	}
	
	void operation_started() {
		entry.progress_visible = true;
	}
	
	void operation_progress_updated(double progress) {
		if(entry == null)
			return;
		
		entry.progress = progress;
	}
	
	void operation_finished() {
		entry.progress_visible = false;
	}
	
	void playing_changed() {
		string lbl = (App.playback.playing) ? _("Pause") : _("Play");
		playpause.property_set (Dbusmenu.MENUITEM_PROP_LABEL, lbl);
	}
}

#endif
