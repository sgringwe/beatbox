/*
 * Main.vala
 * =========
 * Load application and process parameters.
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

public static int main (string[] args) {
	try {
		var opt_context = new OptionContext("- Beatbox Music Player.");
		opt_context.set_help_enabled(true);
		opt_context.add_main_entries(Beatbox.Beatbox.available_options, null);
		opt_context.parse (ref args);
	} catch (OptionError e) {
		warning("Error parsing arguments: %s", e.message);
		warning("Run '%s --help' to see a full list of available command line options.\n", 
			args[0]);
		return 0;
	}

	try {
		Gtk.init(ref args);
		Gst.init_check(ref args);
	} catch (Error e) {
		warning("Could not initialize components: %s", e.message);
		return 0;
	}

    // Init internationalization support before anything else
	Environment.set_prgname("beatbox");
    string package_name = Build.GETTEXT_PACKAGE;
    string langpack_dir = Path.build_filename(Build.DATADIR, "locale");
    Intl.setlocale(LocaleCategory.ALL, "");
    Intl.bindtextdomain(package_name, langpack_dir);
    Intl.bind_textdomain_codeset(package_name, "UTF-8");
    Intl.textdomain(package_name);

	return (new Beatbox.Beatbox()).run(args);
}
