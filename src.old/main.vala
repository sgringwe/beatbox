public static int main (string[] args) {
	var context = new OptionContext ("- BeatBox help page.");
	context.add_main_entries (Beatbox.get_option_group (), "beatbox");
	context.add_group (Gtk.get_option_group (true));
	context.add_group (Gst.init_get_option_group ());

	try {
		context.parse (ref args);
	}
	catch (Error err) {
		warning ("Error parsing arguments: %s", err.message);
	}

	Gtk.init(ref args);

	try {
		Gst.init_check (ref args);
	}
	catch (Error err) {
		error ("Could not init GStreamer: %s", err.message);
	}

	var app = new Beatbox ();
	return app.run (args);
}
