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

using Gee;
using Gtk;

public class BeatBox.PodcastSourceView : SourceView {
	HashMap<int, Device> welcome_screen_keys;
	
	// For View implementation
	Gtk.Menu podcastMenu;
	
	public PodcastSourceView() {
		base(App.library.podcast_library.medias(), App.window.setups.get_setup(ListSetupInterface.PODCAST_KEY));
		
		media_representation = _("podcast");
		
		// Setup welcome screen
		welcome_screen = new Granite.Widgets.Welcome(_("Subscribe to Podcasts"), _("No Podcasts were found."));
		welcome_screen_keys = new HashMap<int, Device>();
		var podcast_icon = App.icons.PODCAST.render (IconSize.DIALOG, null);
		welcome_screen.append_with_pixbuf(podcast_icon, _("Search"), _("Find RSS feeds online."));
		welcome_screen.activated.connect(welcome_screen_activated);
		
		list_view = new PodcastList (tvs);
		album_view = new AlbumGrid(this, tvs);
		error_box = new EmbeddedAlert();
		pack_widgets();
		
		// Setup context menu
		podcastMenu = new Gtk.Menu();
		podcastMenu.append((Gtk.MenuItem)App.actions.add_podcast_feed.create_menu_item());
		podcastMenu.append((Gtk.MenuItem)App.actions.refresh_podcasts.create_menu_item());
		podcastMenu.show_all();
		
		// Populate views
		set_media_sync(original_medias, false);
		
		// Setup signal handlers
		App.library.podcast_library.medias_updated.connect (update_medias);
		App.library.podcast_library.medias_added.connect (add_medias);
		App.library.podcast_library.medias_removed.connect (remove_medias);
	}
	
	protected override void pre_set_as_current_view() {
		
	}
	
	protected override void set_default_warning () {
		error_box.set_alert (_("No Podcasts Found"), _("To add a podcast, visit a website such as Miro Guide to find RSS Feeds.") + 
		"\n" + _("You can then copy and paste the feed into the \"Add Podcast\" window by right clicking on \"Podcasts\"."),
		null, true, Gtk.MessageType.INFO);
	}
	
	void welcome_screen_activated(int index) {
		if(index == 0) {
			try {
				new Thread<void*>.try (null, take_action);
			}
			catch (Error err) {
				warning ("Could not create thread to have fun: %s", err.message);
			}
		}
	}
	
	private void* take_action () {
		try {
			GLib.AppInfo.launch_default_for_uri ("https://www.miroguide.com/toprated/", null);
		}
		catch(Error err) {
			stdout.printf("Couldn't open miro guide webpage: %s\n", err.message);
		}
		
		return null;
	}
	
	/** Specific implementations for View interface **/
	public override View.ViewType get_view_type() {
		return View.ViewType.PODCAST;
	}
	
	public override Object? get_object() {
		return null;
	}
	
	public override Gdk.Pixbuf get_view_icon() {
		return App.icons.PODCAST.render(IconSize.MENU, null);
	}
	
	public override string get_view_name() {
		return _("Podcasts");
	}
	
	public override Gtk.Menu? get_context_menu() {
		return podcastMenu;
	}
	
	public override bool can_receive_drop() {
		return false;
	}
	
	public override void drag_received(Gtk.SelectionData data) {
		
	}
	
	public override SideTreeCategory get_sidetree_category() {
		return SideTreeCategory.LIBRARY;
	}
	
	// podcast context menu
	public void podcastAddClicked() {
		AddPodcastWindow apw = new AddPodcastWindow();
		apw.show();
	}
	
	public void podcastRefreshClicked() {
		App.podcasts.find_new_podcasts();
	}
}

