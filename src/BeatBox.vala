/*-
 * Copyright (c) 2011-2012 BeatBox Developers
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
 *
 * Authored by: Scott Ringwelski <sgringwe@mtu.edu>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */


public static int main (string[] args) {
	var context = new OptionContext ("- BeatBox help page.");
	//context.add_main_entries (Beatbox.get_option_group (), "beatbox");
	context.add_group (Gtk.get_option_group (true));
	context.add_group (Gst.init_get_option_group ());

	try {
		context.parse (ref args);
	}
	catch (Error err) {
		warning ("Error parsing arguments: %s", err.message);
	}

	Gtk.init(ref args);
	Environment.set_prgname ("beatbox");

	try {
		Gst.init_check (ref args);
	}
	catch (Error err) {
		error ("Could not init GStreamer: %s", err.message);
	}
  
    // Init internationalization support before anything else
    string package_name = Build.GETTEXT_PACKAGE;
    string langpack_dir = Path.build_filename (Build.DATADIR, "locale");
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (package_name, langpack_dir);
    Intl.bind_textdomain_codeset (package_name, "UTF-8");
    Intl.textdomain (package_name);
  
	var app = new BeatBox.App ();
	return app.run (args);
}


/**
 * Application class
 */

public class BeatBox.App : Granite.Application {
	public static BeatBox.Plugins.Manager plugins { get; private set; }
	public static BeatBox.LibraryInterface library { get; private set; }
	public static BeatBox.PlaylistInterface playlists { get; private set; }
	public static BeatBox.PodcastInterface podcasts { get; private set; }
	public static BeatBox.DatabaseInterface database { get; private set; }
	public static BeatBox.LibraryWindowInterface window { get; private set; }
	public static BeatBox.FileInterface files { get; private set; }
	public static BeatBox.OperationsInterface operations { get; private set; }
	public static BeatBox.PlaybackInterface playback { get; private set; }
	public static BeatBox.CoverInterface covers { get; private set; }
	public static BeatBox.ActionsInterface actions { get; private set; }
	public static BeatBox.IconsInterface icons { get; private set; }
	public static BeatBox.InfoInterface info { get; private set; }
	public static BeatBox.Settings settings { get; private set; }
	public static BeatBox.DeviceInterface devices { get; private set; }

	/*private static const OptionEntry[] app_options = {
		{ "debug", 'd', 0, OptionArg.NONE, ref Options.debug, N_("Enable debug logging"), null },
		{ "no-plugins", 'n', 0, OptionArg.NONE, ref Options.disable_plugins, N_("Disable plugins"), null},
		{ null }
	};*/

	construct {
		// This allows opening files. See the open() method below.
		flags |= ApplicationFlags.HANDLES_OPEN;

		// App info
		build_data_dir = Build.DATADIR;
		build_pkg_data_dir = Build.PKG_DATADIR;
		build_release_name = Build.RELEASE_NAME;
		build_version = Build.VERSION;
		build_version_info = Build.VERSION_INFO;

		program_name = "BeatBox";
		exec_name = "beatbox";

		app_copyright = "2012";
		application_id = "net.launchpad.beatbox";
		app_icon = "beatbox";
		app_launcher = "beatbox.desktop";
		app_years = "2010-2012";

		main_url = "https://launchpad.net/beat-box";
		bug_url = "https://bugs.launchpad.net/beat-box/+filebug";
		help_url = "https://answers.launchpad.net/beat-box";
		translate_url = "https://translations.launchpad.net/beat-box";

		about_authors = {"Scott Ringwelski <sgringwe@mtu.edu>",
						 "Victor Eduardo M. <victoreduardm@gmail.com>",
						 null};

		about_artists = {"Scott Ringwelski <sgringwe@mtu.edu>",
						 "Daniel Foré <daniel@elementaryos.org>", 
						 null};
	}

	public App () {
		// Create settings
		settings = new BeatBox.Settings ();
	}

	/*public static OptionEntry[] get_option_group () {
		return app_options;
	}*/

	public override void open (File[] files, string hint) {
		if(files == null || files.length == 0) {
			return;
		}
		
		// Activate, then play files
		this.activate ();
		var to_add = new Gee.LinkedList<File> ();
		for (int i = 0; i < files.length; i++) {
			var file = files[i];
			if (file != null) {
				to_add.add (file);
				message ("Adding file %s", file.get_uri());
			}
		}         
		
		if(to_add.size > 0) {
			library.song_library.add_files(to_add, true);
		}
	}

	protected override void activate () {
		if (window != null) {
			window.present ();
			return;
		}

		// Setup debugger
		if (DEBUG)
			Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
		else
			Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;
		
		icons = new Icons();
		database = new DataBaseManager();
		operations = new OperationsManager();
		playback = new PlaybackManager();
		info = new Info();
		actions = new Actions();
		devices = new DeviceManager();
		files = new FileOperator();
		covers = new CoverManager();
		library = new LibraryManager();
		playlists = new PlaylistManager();
		((LibraryManager)library).init_default_libraries();
		((PlaylistManager)playlists).load_playlists_from_db();
		window = new LibraryWindow(this);
		podcasts = new PodcastManager();
		
		((LibraryWindow)window).build_ui ();
		window.set_application(this);
		
		((CoverManager)covers).setup_signals();
		
		// Start playing the last playing song. By waiting 1 second, we
		// give everything time to finish initializing and avoid sending
		// out media_updated signals during startup.
		Timeout.add(500, () => {
			((PlaybackManager)playback).load_and_play_last_playing(); return false;
		});
		
		// Load plugins last so that we know that everything else is ready to go
		plugins = new BeatBox.Plugins.Manager (Build.PLUGIN_DIR, exec_name, null);  
		plugins.beatbox_app = this;
		plugins.hook_app(this);
		plugins.hook_main_window (window);
		
		// After everything settles down, load the covers that have been saved.
		Idle.add(() => {
			covers.fetch_image_cache_async (); return false;
		});
		
		// After 10 seconds, check for new podcasts
		Timeout.add(10000, () => {
			podcasts.find_new_podcasts();

			return false;
		});
	}
	
	/**
	 * We use this identifier to init everything inside the application.
	 * For instance: libnotify, etc.
	 */
	public string get_id () {
		return application_id;
	}

	public string get_name () {
		return program_name;
	}
	
	public string get_name_down () {
		return program_name.down ();
	}
	
	public string get_desktop_file_name () {
		return app_launcher;
	}
}

