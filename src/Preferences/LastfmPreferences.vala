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

public class BeatBox.LastfmPreferences : GLib.Object, PreferencesSection {
	public PreferencesSectionCategory category { get { return PreferencesSectionCategory.GENERAL; } }
	public string title { get { return "Last.fm"; } }
	public Gdk.Pixbuf? icon { get { return null; } }
	public Widget widget { get { return content; } }
	
	Box content;
	Label auth_info;
	Box login_box;
	Entry username;
	Entry password;
	Button login;
	Button logout;
	Gtk.Spinner is_working;
	
	public LastfmPreferences() {
		content = new Box(Orientation.VERTICAL, 0);
		content.spacing = 10;
		
		auth_info = new Label("");
		username = new Entry();
		password = new Entry();
		login = new Button.with_label(_("Login"));
		logout = new Button.with_label(_("Logout"));
		is_working = new Gtk.Spinner();
		
		var auth_label = new Label(_("Authentication"));
		
		// fancy up the category labels
		auth_label.xalign = 0.0f;
		auth_label.set_markup("<b>" + _("Authentication") + "</b>");
		
		auth_info.xalign = 0.0f;
		auth_info.set_line_wrap(true);
		password.set_visibility(false);
		
		// The login entry boxes
		login_box = new Box(Orientation.HORIZONTAL, 0);
		var left_box = new Box(Orientation.VERTICAL, 0);
		var right_box = new Box(Orientation.VERTICAL, 0);
		
		var username_label = new Label("");
		var password_label = new Label("");
		username_label.set_markup("<b>" + _("Username:") + "</b>");
		password_label.set_markup("<b>" + _("Password:") + "</b>");
		username_label.xalign = 0.0f;
		password_label.xalign = 0.0f;
		
		left_box.pack_start(username_label, false, false, 0);
		left_box.pack_start(password_label, false, false, 0);
		right_box.pack_start(username, false, false, 0);
		right_box.pack_start(password, false, false, 0);
		login_box.pack_start(UI.wrap_alignment(left_box, 0, 4, 0, 0), false, false, 0);
		login_box.pack_start(right_box, true, true, 0);
		
		left_box.vexpand = true;
		left_box.homogeneous = true;
		login_box.vexpand = false;
		
		var button_box = new HButtonBox();
		button_box.set_layout(ButtonBoxStyle.END);
		button_box.pack_end(is_working, false, false, 0);
		button_box.pack_end(login, false, false, 0);
		button_box.pack_end(logout, false, false, 0);
		
		// Pack all widgets
		content.pack_start(auth_label, false, false, 0);
		content.pack_start(UI.wrap_alignment(auth_info, 0, 0, 0, 10), false, false, 0);
		content.pack_start(UI.wrap_alignment(login_box, 0, 0, 0, 10), false, false, 0);
		content.pack_start(UI.wrap_alignment(button_box, 0, 0, 0, 10), false, true, 0);
		
		login.clicked.connect(login_click);
		logout.clicked.connect(logout_click);
		App.info.lastfm.login_returned.connect(login_returned);
		App.info.lastfm.logged_out.connect(logged_out);
		
		login_box.show_all();
		
		auth_info.set_no_show_all(true);
		login_box.set_no_show_all(true);
		login.set_no_show_all(true);
		logout.set_no_show_all(true);
		is_working.set_no_show_all(true);
		
		if(!String.is_empty(App.info.lastfm.session_key)) {
			show_loggedin_gui();
		}
		else {
			show_loginprompt_gui();
		}
	}
	
	void login_click() {
		// TODO: Show this once gtk gets its act together. (Also, need to force it to be smaller)
		//is_working.show();
		is_working.start();
		is_working.active = true;
		
		App.info.lastfm.authenticate_user(username.get_text(), password.get_text());
	}
	
	void login_returned(bool success) {
		//is_working.hide();
		is_working.stop();
		is_working.active = false;
		
		if(success) {
			show_loggedin_gui();
		}
		else {
			show_loginfailed_gui();
		}
	}
	
	void logout_click() {
		App.info.lastfm.logout_user();
	}
	
	void logged_out() {
		show_loginprompt_gui();
	}
	
	void show_loginprompt_gui() {
		auth_info.hide();
		login_box.show();
		login.show();
		logout.hide();
	}
	
	void show_loggedin_gui() {
		auth_info.show();
		auth_info.set_markup(_("You are logged in as %s.").printf("<b>" + Markup.escape_text(App.info.lastfm.username) + "</b>"));
		login_box.hide();
		login.hide();
		logout.show();
	}
	
	void show_loginfailed_gui() {
		auth_info.show();
		auth_info.set_markup(_("BeatBox was unable to log in as %s. Please try again.").printf("<b>" + Markup.escape_text(username.get_text()) + "</b>"));
		login_box.show();
		login.show();
		logout.hide();
	}
	
	public void save() {
		
	}
	
	public void cancel() {
		
	}
}
