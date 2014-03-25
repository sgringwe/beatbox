/*
 * Copyright (c) 2012 BeatBox Developers
 *
 * This is a free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 *              Scott Ringwelski <sgringwe@mtu.edu>
 * 
 * The BeatBox project hereby grant permission for non-gpl compatible GStreamer
 * plugins to be used and distributed together with GStreamer and BeatBox. This
 * permission is above and beyond the permissions granted by the GPL license
 * BeatBox is covered by.
 */

using Gtk;

public class BeatBox.StatusBar : Granite.Widgets.StatusBar {
    public uint total_items {get; private set; default = 0;}
    public uint64 total_size {get; private set; default = 0;}
    public uint total_secs {get; private set; default = 0;}
    public TreeViewSetup.Hint media_type {get; private set;}
	
    private string STATUS_TEXT_FORMAT = _("%s, %s, %s");
    
    SimpleOptionChooser shuffle_chooser;
	SimpleOptionChooser repeat_chooser;
	Image show_eq_button;

    public StatusBar () {
		repeat_chooser = new SimpleOptionChooser();
		shuffle_chooser = new SimpleOptionChooser();
		show_eq_button = App.icons.EQ.render_image (Gtk.IconSize.MENU);
		
		var shuffle_on_image   = App.icons.SHUFFLE_ON.render_image (Gtk.IconSize.MENU);
        var shuffle_off_image  = App.icons.SHUFFLE_OFF.render_image (Gtk.IconSize.MENU);
        var repeat_on_image    = App.icons.REPEAT_ON.render_image (Gtk.IconSize.MENU);
        var repeat_once_image   = App.icons.REPEAT_ONCE.render_image (Gtk.IconSize.MENU);
        var repeat_off_image   = App.icons.REPEAT_OFF.render_image (Gtk.IconSize.MENU);
        
        repeat_chooser.append_option (_("Off"), repeat_off_image, _("Repeat Off"));
        repeat_chooser.append_option (_("Song"), repeat_once_image, _("Repeat Song"));
        repeat_chooser.append_option (_("Album"), repeat_on_image, _("Repeat Album"));
        repeat_chooser.append_option (_("Artist"), repeat_on_image, _("Repeat Artist"));
        repeat_chooser.append_option (_("All"), repeat_on_image, _("Repeat All"));
        repeat_chooser.setOption ((int)App.settings.main.repeat_mode);
        
        shuffle_chooser.append_option (_("Off"), shuffle_off_image, _("Shuffle Disabled"));
        shuffle_chooser.append_option (_("All"), shuffle_on_image, _("Shuffle Enabled"));
        shuffle_chooser.setOption ((int)App.settings.main.shuffle_mode);
        
		var eq_eventbox = new EventBox();
		eq_eventbox.add(show_eq_button);
		eq_eventbox.set_above_child(true);
		eq_eventbox.set_visible_window(false);
        
        repeat_chooser.margin_left = shuffle_chooser.margin_left = eq_eventbox.margin_right = 6;
        
        insert_widget(shuffle_chooser, true);
        insert_widget(repeat_chooser, true);
        insert_widget(eq_eventbox, false);
		
        show_all();
        
        repeat_chooser.option_changed.connect(repeat_chooser_option_changed);
        shuffle_chooser.option_changed.connect(shuffle_chooser_option_changed);
        eq_eventbox.button_press_event.connect(show_eq_button_clicked);
    }

    public void set_files_size (uint64 total_size) {
        this.total_size = total_size;
        update_label ();
    }

    public void set_total_time (uint total_secs) {
        this.total_secs = total_secs;
        update_label ();
    }

    public void set_total_medias (uint total_medias, TreeViewSetup.Hint media_type) {
        this.total_items = total_medias;
        this.media_type = media_type;
        update_label ();
    }

    private void update_label () {
        if (total_items == 0) {
            set_text ("");
            return;
        }

        string time_text = "", media_description = "", medias_text = "", size_text = "";

        if(total_secs < 3600) { // less than 1 hour show in minute units
            time_text = ngettext("%d minutes", "%d minutes", total_secs/60).printf(total_secs/60);
        }
        else if(total_secs < (24 * 3600)) { // less than 1 day show in hour units
            time_text = ngettext("%d hour", "%d hours", total_secs/3600).printf(total_secs/3600);
        }
        else { // units in days
            time_text = ngettext("%d day", "%d days", total_secs/(24 * 3600)).printf(total_secs/(24 * 3600));
        }

        size_text = GLib.format_size (total_size);

        switch (media_type) {
            case TreeViewSetup.Hint.MUSIC:
                media_description = ngettext ("song", "songs", total_items);
                break;
            case TreeViewSetup.Hint.PODCAST:
                media_description = ngettext ("episode", "episodes", total_items);
                break;
            case TreeViewSetup.Hint.AUDIOBOOK:
                media_description = ngettext ("audiobook", "audiobooks", total_items);
                break;
            case TreeViewSetup.Hint.STATION:
                media_description = ngettext ("station", "stations", total_items);
                break;
            default:
                media_description = ngettext ("item", "items", total_items);
                break;
        }

        medias_text = "%i %s".printf ((int)total_items, media_description);

        set_text (STATUS_TEXT_FORMAT.printf (medias_text, time_text, size_text));
    }
    
    
    public void set_info (TreeViewSetup.Hint media_type, uint total_medias,
                                     uint64 total_size, uint total_seconds) {
        set_total_medias (total_medias, media_type);
        set_files_size (total_size);
        set_total_time (total_seconds);
    }
    
    void repeat_chooser_option_changed(int val) {
        if(val == 0)
            App.playback.set_repeat_mode (PlaybackInterface.RepeatMode.OFF);
        else if(val == 1)
            App.playback.set_repeat_mode (PlaybackInterface.RepeatMode.MEDIA);
        else if(val == 2)
            App.playback.set_repeat_mode (PlaybackInterface.RepeatMode.ALBUM);
        else if(val == 3)
            App.playback.set_repeat_mode (PlaybackInterface.RepeatMode.ARTIST);
        else if(val == 4)
            App.playback.set_repeat_mode (PlaybackInterface.RepeatMode.ALL);
    }

    void shuffle_chooser_option_changed(int val) {
        if(val == 0) {
            App.playback.set_shuffle_mode (PlaybackInterface.ShuffleMode.OFF);
        } else if(val == 1) {
            App.playback.set_shuffle_mode (PlaybackInterface.ShuffleMode.ALL);
        }
    }
    
    bool show_eq_button_clicked(Gdk.EventButton event) {
		if(App.actions.show_equalizer.get_sensitive()) {
			App.actions.show_equalizer.activate();
		}
		
		return false;
    }
}

