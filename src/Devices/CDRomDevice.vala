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

using GPod;
using Gee;

public class BeatBox.CDRomDevice : GLib.Object, BeatBox.Device {
	Mount mount;
	GLib.Icon icon;
	string display_name;
	
	CDRipper ripper;
	Media media_being_ripped;
	int current_list_index;
	
	bool currently_transferring;
	
	LinkedList<Media> medias;
	
	public CDRomDevice(Mount mount) {
		this.mount = mount;
		this.icon = mount.get_icon();
		this.display_name = mount.get_name();
		
		medias = new LinkedList<Media>();
		media_being_ripped = null;
	}
	
	public DevicePreferences get_preferences() {
		return new DevicePreferences(get_unique_identifier());
	}
	
	public bool start_initialization() {
		return true;
	}
	
	public void finish_initialization() {
		try {
			new Thread<void*>.try (null, finish_initialization_thread);
		}
		catch (Error err) {
			warning ("Could not create thread to finish ipod initialization: %s", err.message);
		}
	}
	
	void* finish_initialization_thread() {
		medias = CDDA.getMediaList(mount.get_default_location().get_path());
		if(medias.size > 0) {
			setDisplayName(medias.get(0).album);
		}
		
		Idle.add( () => {
			initialized(this);
			
			return false;
		});
		
		return null;
	}
	
	public string getContentType() {
		return "cdrom";
	}
	
	public string getDisplayName() {
		return display_name;
	}
	
	public void setDisplayName(string name) {
		display_name = name;
	}
	
	public string get_fancy_description() {
		return _("Multimedia Disc");
	}
	
	public void set_mount(Mount mount) {
		this.mount = mount;
	}
	
	public Mount get_mount() {
		return mount;
	}
	
	public string get_path() {
		return mount.get_default_location().get_path();
	}
	
	string get_uri() {
		return mount.get_default_location().get_uri();
	}
	
	public void set_icon(GLib.Icon icon) {
		this.icon = icon;
	}
	
	public GLib.Icon get_icon() {
		return icon;
	}
	
	public uint64 get_capacity() {
		return (uint64)0;
	}
	
	public string get_fancy_capacity() {
		return _("Unknown capacity");
	}
	
	public uint64 get_used_space() {
		return (uint64)0;
	}
	
	public uint64 get_free_space() {
		return (uint64)0;
	}
	
	public void unmount() {
		
	}
	
	public void eject() {
		
	}
	
	public void get_device_type() {
		
	}
	
	public bool supports_podcasts() {
		return false;
	}
	
	public bool supports_audiobooks() {
		return false;
	}
	
	public Collection<Media> get_medias() {
		return medias;
	}
	
	public Collection<Media> get_songs() {
		return medias;
	}
	
	public Collection<Media> get_podcasts() {
		return new LinkedList<Media>();
	}
	
	public Collection<Media> get_audiobooks() {
		return new LinkedList<Media>();
	}
	
	public Collection<StaticPlaylist> get_static_playlists() {
		return new LinkedList<StaticPlaylist>();
	}
	
	public Collection<SmartPlaylist> get_smart_playlists() {
		return new LinkedList<SmartPlaylist>();
	}
	
	public void sync_medias(LinkedList<Media> list) {
		message("Ripping not supported on CDRom's.\n");
		return;
	}
	
	public void add_medias(LinkedList<Media> list) {
		return;
	}
	
	public void remove_medias(LinkedList<Media> list) {
		return;
	}
	
	public bool will_fit(LinkedList<Media> list) {
		return false;
	}
	
	public void transfer_to_library(LinkedList<File> list) {
		if(!GLib.File.new_for_path(App.settings.main.music_folder).query_exists()) {
			App.window.doAlert("Could not find Music Folder", "Please make sure that your music folder is accessible and mounted before importing the CD.");
			return;
		}
		if(medias.size == 0) {
			App.window.doAlert("No songs on CD", "BeatBox could not find any songs on the CD. No songs can be imported");
			return;
		}
		
		if(!App.operations.doing_ops) {
			MediasOperation op = new MediasOperation(transfer_to_library_start_sync, transfer_to_library_start_async, transfer_to_library_cancel, _("Ripping from %s").printf(Markup.escape_text(getDisplayName())));
			
			if(list.size == 0)
				op.medias = medias;
			else
				op.medias = list;
			
			App.operations.queue_operation(op);
		}
		else {
			warning("User tried to transfer from cd while doing operations");
		}
	}
	
	private void transfer_to_library_start_sync (Operation op) {
		var list = ((MediasOperation)op).medias;
		
		ripper = new CDRipper(get_uri(), medias.size);
		if(!ripper.initialize()) {
			critical("Could not create CD Ripper to import.\n");
			return;
		}
		ripper.media_ripped.connect(mediaRipped);
		//ripper.error.connect(ripperError);
		ripper.progress_notification.connect(ripperProgress);
		
		current_list_index = 0;
		Media s = list.to_array()[current_list_index];
		media_being_ripped = s;
		s.showIndicator = true;
		
		// initialize gui feedback
		App.operations.operation_progress = 0;
		App.operations.operation_total = 1000; // This way we can have sub-progress for each song
		App.operations.current_status = "Ripping track " + s.track.to_string() + ": <b>" + Markup.escape_text(s.title) + "</b>" + ((s.artist != "Unknown Artist") ? " by " : "") + "<b>" + Markup.escape_text(s.artist) + "</b>" + ((s.album != "Unknown Album") ? " on " : "") + "<b>" + Markup.escape_text(s.album) + "</b>";
		currently_transferring = true;
		
		// start process
		ripper.ripMedia(s.track, s);
		
		// this refreshes so that the spinner shows
		warning("TODO: Fixme");
		SourceView vw = (SourceView)App.window.get_view_from_object(this);
		vw.list_view.get_column(MusicColumn.ICON).visible = false; // this shows spinner for some reason
		vw.list_view.get_column(MusicColumn.ICON).visible = true; // this shows spinner for some reason
		vw.list_view.resort();
		vw.set_media (medias);
		
		// this spins the spinner for the current media being imported
		Timeout.add(100, pulser);
	}

	private void transfer_to_library_start_async (Operation op) {
		// Nothing to do. The asyncronous part of importing cdrom is in gstreamer
	}
	
	private void transfer_to_library_cancel(Operation op) {
		App.operations.current_status = _("CD Import cancelled. Finishing ripping track %s...").printf("<b>" + Markup.escape_text(media_being_ripped.title) + "</b>");
	}
	
	private void ripperProgress(double song_progress) {
		int total_length = ((MediasOperation)App.operations.current_op).medias.size;
		int starting_point = (int)(1000.0f * ((double)current_list_index/(double)total_length));
		double single_song_range = (double)(1000.0 * (1.0f/(double)total_length));
		App.operations.operation_progress = (int)(starting_point + (single_song_range * song_progress));
	}
	
	public void mediaRipped(Media s) {
		var list = ((MediasOperation)App.operations.current_op).medias;
		s.showIndicator = false;
		
		// Create a copy and add it to the library
		Media lib_copy = s.copy();
		lib_copy.isTemporary = false;
		App.library.add_media(lib_copy);
		
		// update media in cdrom list to show as completed
		warning("TODO: Fixme: Get rid of UI code from here.");
		SourceView vw = (SourceView)App.window.get_view_from_object(this);
		s.unique_status_image = App.icons.PROCESS_COMPLETED.render(Gtk.IconSize.MENU, vw.list_view.get_style_context());
		
		if(GLib.File.new_for_uri(lib_copy.uri).query_exists()) {
			try {
				lib_copy.file_size = (int)(GLib.File.new_for_uri(lib_copy.uri).query_info("*", FileQueryInfoFlags.NONE).get_size());
			}
			catch(Error err) {
				lib_copy.file_size = 5; // best guess
				warning("Could not get ripped media's file_size: %s\n", err.message);
			}
		}
		else {
			warning("Just-imported song from CD could not be found at %s\n", lib_copy.uri);
			// TODO: What is best guess for bytes?
			//s.file_size = 5; // best guess
		}
		
		App.library.update_media(lib_copy, true, true, true);
		
		// do it again on next track
		if(current_list_index < (((MediasOperation)App.operations.current_op).medias.size - 1) && !App.operations.operation_cancelled) {
			++current_list_index;
			Media next = list.to_array()[current_list_index];
			media_being_ripped = next;
			ripper.ripMedia(next.track, next);
			
			// this refreshes so that the spinner shows
			next.showIndicator = true;
			warning("TODO: Fixem");
			vw.list_view.resort();
			vw.set_media (medias);
			
			++App.operations.operation_progress;
			App.operations.current_status = "<b>Importing</b> track " + next.track.to_string() + ": <b>" + next.title.replace("&", "&amp;") + "</b>" + ((next.artist != "Unknown Artist") ? " by " : "") + "<b>" + next.artist.replace("&", "&amp;") + "</b>" + ((next.album != "Unknown Album") ? " on " : "") + "<b>" + next.album.replace("&", "&amp;") + "</b>";
		}
		else {
			// this refreshes so that the checkmark shows
			warning("TODO: Fixme");
			vw.list_view.resort();
			vw.set_media (medias);
			
			media_being_ripped = null;
			currently_transferring = false;
			App.operations.finish_operation();
			
			//FIXME: We already do this and more in the library_manager import_operation_finished. Use that
			// and use the same text as here for CD imports
			if(!App.window.has_toplevel_focus) {
				App.window.show_notification(_("Import Complete"), _("BeatBox has finished importing %d song(s) from Audio CD").printf(current_list_index + 1), null);
			}
		}
	}
	
	public bool pulser() {
		if(media_being_ripped != null) {
			media_being_ripped.pulseProgress++;
			
			// warning("TODO: Fixme");
			App.window.get_view_from_object(this).queue_draw();
			
			return true;
		}
		else {
			return false;
		}
	}
	
	public bool is_syncing() {
		return false;
	}
	
	public bool is_transferring() {
		return currently_transferring;
	}
	
	//public void ripperError(string err, Gst.Message message) {
	//	warning("TODO: Fixme");
		/*if(err == "missing element") {
			if(message.get_structure() != null && Gst.is_missing_plugin_message(message)) {
					InstallGstreamerPluginsDialog dialog = new InstallGstreamerPluginsDialog(message);
					dialog.show();
				}
		}*/
	//}
}
