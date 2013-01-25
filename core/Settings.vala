/*-
 * Copyright (c) 2011-2012	   Scott Ringwelski <sgringwe@mtu.edu>
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

public class BeatBox.Settings {

    public LastFM lastfm { get; set; }
    public SavedState saved_state { get; set; }
    public Settings main { get; set; }
    public Equalizer equalizer { get; set; }

    public Settings () {
        lastfm = new LastFM ();
        saved_state = new SavedState ();
        main = new Settings ();
        equalizer = new Equalizer ();
    }

    public string get_album_art_cache_dir () {
        return GLib.Path.build_path ("/", get_cache_dir (), "album-art");
    }

    public string get_cache_dir () {
        return GLib.Path.build_path ("/", Environment.get_user_cache_dir(), "beatbox");
    }

    public enum Position {
        AUTOMATIC = 0,
        LEFT      = 2,
        TOP       = 1
    }

    public enum WindowState {
        NORMAL = 0,
        MAXIMIZED = 1,
        FULLSCREEN = 2
    }
    
    public class LastFM : Granite.Services.Settings {

        public string session_key { get; set; }
        public bool is_subscriber { get; set; }
        public string username { get; set; }
        
        public LastFM () {
            base ("net.launchpad.beatbox.LastFM");
        }
    }
    
    public class SavedState : Granite.Services.Settings {

        public int window_width { get; set; }
        public int window_height { get; set; }
        public WindowState window_state { get; set; }
        public int sidebar_width { get; set; }
        public int more_width { get; set; }
        public bool more_visible { get; set; }
        public int view_mode { get; set; }
        public int miller_width { get; set; }
        public int miller_height { get; set; }
        public bool miller_columns_enabled { get; set; }
        public string[] music_miller_visible_columns { get; set; }
        public string[] generic_miller_visible_columns { get; set; }
        public Position miller_columns_position { get; set; }

        public SavedState () {
            base ("net.launchpad.beatbox.SavedState");
        }
        
    }

    public class Settings : Granite.Services.Settings {

        public string music_mount_name { get; set; }
        public string music_folder { get; set; }
        public string podcast_folder { get; set; }
        public bool update_folder_hierarchy { get; set; }
        public bool write_metadata_to_file { get; set; }
        public bool copy_imported_music { get; set; }
        public bool download_new_podcasts { get; set; }
        public int last_media_playing { get; set; }
        public int last_media_position { get; set; }
        public int shuffle_mode { get; set; }
        public int repeat_mode { get; set; }
        public string search_string { get; set; }
        public string[] plugins_enabled { get; set;}
        
        public Settings ()  {
            base ("net.launchpad.beatbox.Settings");
        }
    }

    public class Equalizer : Granite.Services.Settings {

        public bool equalizer_enabled { get; set; }
        public bool auto_switch_preset { get; set; }
        public string selected_preset { get; set; }
        public string[] custom_presets { get; set;}
        public string[] default_presets { get; set;}
        public int volume { get; set;}
        
        public Equalizer () {
            base ("net.launchpad.beatbox.Equalizer");
        }
        
        public Gee.Collection<BeatBox.EqualizerPreset> getCustomPresets () {

            var presets_data = new Gee.LinkedList<string> ();
            
            if (custom_presets != null) {
                for (int i = 0; i < custom_presets.length; i++) {
                    presets_data.add (custom_presets[i]);
                }
            }
            
            var rv = new Gee.LinkedList<BeatBox.EqualizerPreset>();
            
            foreach (var preset_str in presets_data) {
                var equalizer_preset = new BeatBox.EqualizerPreset.from_string (preset_str);
                if (equalizer_preset != null)
                    rv.add (equalizer_preset);
            }
            
            return rv;
        }
        
        public Gee.Collection<BeatBox.EqualizerPreset> getDefaultPresets () {

            var presets_data = new Gee.LinkedList<string> ();
            
            if (default_presets != null) {
                for (int i = 0; i < default_presets.length; i++) {
                    presets_data.add (default_presets[i]);
                }
            }
            
            var rv = new Gee.LinkedList<BeatBox.EqualizerPreset>();
            
            foreach (var preset_str in presets_data) {
                var equalizer_preset = new BeatBox.EqualizerPreset.from_string (preset_str);
                if (equalizer_preset != null)
                    rv.add (equalizer_preset);
            }
            
            return rv;
        }
        
        public string[] getPresetsArray (Gee.Collection<BeatBox.EqualizerPreset> presets) {
            string[] vals = new string[presets.size];
            vals.resize (presets.size);
            
            int index = 0;
            foreach (var p in presets) {
                string preset = p.name;

                for(int i = 0; i < 10; ++i) {
                    preset += "/" + p.getGain(i).to_string();
                }

                vals[index] = preset;
                index++;
            }

            return vals;
        }
    }
}

