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

public class BeatBox.DeviceManager : GLib.Object, BeatBox.DeviceInterface {
	VolumeMonitor vm;
	LinkedList<Device> devices;
	
	HashMap<string, DevicePreferences> _device_preferences;
	
	public DeviceManager() {
		vm = VolumeMonitor.get();
		devices = new LinkedList<Device>();
		_device_preferences = new HashMap<string, DevicePreferences>();
		
		// load devices and their preferences
		load_devices();
		
		vm.mount_added.connect(mount_added);
		vm.mount_changed.connect(mount_changed);
		vm.mount_pre_unmount.connect(mount_pre_unmount);
		vm.mount_removed.connect(mount_removed);
		vm.volume_added.connect(volume_added);
		
		// setup periodic saves of device prefereneces
		DatabaseTransactionFiller devices_filler = new DatabaseTransactionFiller();
		devices_filler.filler = periodic_devices_filler;
		devices_filler.pre_transaction_execute = "DELETE FROM 'devices'";
		App.database.add_periodic_transaction(devices_filler);
	}
	
	public void load_pre_existing_devices() {
		
		// this can take time if we have to rev up the cd drive
		try {
			new Thread<void*>.try (null, get_pre_existing_mounts);
		}
		catch (Error err) {
			warning ("Could not create mount getter thread: %s", err.message);
		}
	}
	
	void* get_pre_existing_mounts () {
		var mounts = new LinkedList<Mount>();
		var volumes = new LinkedList<Volume>();
		
		foreach(var m in vm.get_mounts()) {
			mounts.add(m);
		}
		
		foreach(var v in vm.get_volumes()) {
			volumes.add(v);
		}
		
		Idle.add( () => {
			
			foreach(var m in mounts) {
				mount_added(m);
			}
			
			foreach(var v in volumes) {
				volume_added(v);
			}
			
			return false;
		});
		
		return null;
	}
	
	void volume_added(Volume volume) {
		if(App.settings.main.music_mount_name == volume.get_name() && volume.get_mount() == null) {
			message("Mounting %s because it is believed to be the music folder\n", volume.get_name());
			volume.mount(MountMountFlags.NONE, null, null);
		}
	}
	
	void mount_added (Mount mount) {
		foreach(var dev in devices) {
			if(dev.get_path() == mount.get_default_location().get_path()) {
				return;
			}
		}
		
		Device added;
		if(mount.get_default_location().get_uri().has_prefix("cdda://") && mount.get_volume() != null) {
			added = new CDRomDevice(mount);
		}
		else if(File.new_for_path(mount.get_default_location().get_path() + "/iTunes_Control").query_exists() ||
				File.new_for_path(mount.get_default_location().get_path() + "/iPod_Control").query_exists() ||
				File.new_for_path(mount.get_default_location().get_path() + "/iTunes/iTunes_Control").query_exists()) {
			added = new iPodDevice(mount);	
		}
		else if(mount.get_default_location().get_parse_name().has_prefix("afc://")) {
			added = new iPodDevice(mount);
		}
		else if(File.new_for_path(mount.get_default_location().get_path() + "/Android").query_exists()) {
			added = new AndroidDevice(mount);
		}
		else if(App.settings.main.music_folder.contains(mount.get_default_location().get_path())) {
			// user mounted music folder, rescan for images
			App.settings.main.music_mount_name = mount.get_volume().get_name();
			App.library.recheck_files_not_found_async ();
			App.covers.fetch_image_cache_async ();
			
			return;
		}
		else { // not a music player, ignore it
			return;
		}
		
		if(added == null) {
			message("Found device at %s is invalid. Not using it\n", mount.get_default_location().get_parse_name());
			return;
		}
		
		added.set_mount(mount);
		devices.add(added);
		
		if(added.start_initialization()) {
			added.finish_initialization();
			added.initialized.connect(deviceInitialized);
		}
		else {
			mount_removed(added.get_mount());
		}
	}
	
	void deviceInitialized(Device d) {
		message("Adding device %s\n", d.getDisplayName());
		device_added(d);
		App.window.update_sensitivities();
	}
	
	void mount_changed (Mount mount) {
		//stdout.printf("mount_changed:%s\n", mount.get_uuid());
	}
	
	void mount_pre_unmount (Mount mount) {
		//stdout.printf("mount_preunmount:%s\n", mount.get_uuid());
	}
	
	void mount_removed (Mount mount) {
		foreach(var dev in devices) {
			if(dev.get_path() == mount.get_default_location().get_path()) {
				// Let other objects remove device reference
				device_removed(dev);
				
				// Actually remove it
				devices.remove(dev);
				
				return;
			}
		}
	}
	
	/** Device Preferences **/
	public Gee.Collection<DevicePreferences> device_preferences() {
		return _device_preferences.values;
	}
	
	public DevicePreferences? get_device_preferences(string id) {
		return _device_preferences.get(id);
	}
	
	public void add_device_preferences(DevicePreferences dp) {
		lock (_device_preferences) {
			_device_preferences.set(dp.id, dp);
		}
	}
	
	// DB Stuff
	void load_devices() {
		try {
			var results = App.database.execute("SELECT rowid,* FROM 'devices'");
			if(results == null) {
				warning("Could not load devices from database");
				return;
			}
			
			for (; !results.finished; results.next() ) {
				DevicePreferences dp = new DevicePreferences(results.fetch_string(1));
				
				dp.sync_when_mounted = results.fetch_int(2) == 1;
				dp.sync_music = results.fetch_int(3) == 1;
				dp.sync_podcasts = results.fetch_int(4) == 1;
				dp.sync_audiobooks = results.fetch_int(5) == 1;
				dp.sync_all_music = results.fetch_int(6) == 1;
				dp.sync_all_podcasts = results.fetch_int(7) == 1;
				dp.sync_all_audiobooks = results.fetch_int(8) == 1;
				dp.music_playlist = results.fetch_string(9);
				dp.podcast_playlist = results.fetch_string(10);
				dp.audiobook_playlist = results.fetch_string(11);
				dp.last_sync_time = results.fetch_int(12);
				
				lock(_device_preferences) {
					_device_preferences.set(dp.id, dp);
				}
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error loading devices: %s", err.message);
		}
	}
	
	void periodic_devices_filler(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler) {
		try {
			SQLHeavy.Query query = transaction.prepare("""INSERT INTO 'devices' ('unique_id', 'sync_when_mounted', 'sync_music', 
			'sync_podcasts', 'sync_audiobooks', 'sync_all_music', 'sync_all_podcasts', 'sync_all_audiobooks', 'music_playlist', 
			'podcast_playlist', 'audiobook_playlist', 'last_sync_time') VALUES (:unique_id, :sync_when_mounted, :sync_music, :sync_podcasts, :sync_audiobooks, 
			:sync_all_music, :sync_all_podcasts, :sync_all_audiobooks, :music_playlist, :podcast_playlist, :audiobook_playlist, :last_sync_time);""");
			
			foreach(DevicePreferences dp in _device_preferences.values) {
				query.set_string(":unique_id", dp.id);
				query.set_int(":sync_when_mounted", dp.sync_when_mounted ? 1 : 0);
				
				query.set_int(":sync_music", dp.sync_music ? 1 : 0);
				query.set_int(":sync_podcasts", dp.sync_podcasts ? 1 : 0);
				query.set_int(":sync_audiobooks", dp.sync_audiobooks ? 1 : 0);
				
				query.set_int(":sync_all_music", dp.sync_all_music ? 1 : 0);
				query.set_int(":sync_all_podcasts", dp.sync_all_podcasts ? 1 : 0);
				query.set_int(":sync_all_audiobooks", dp.sync_all_audiobooks ? 1 : 0);
				
				query.set_string(":music_playlist", dp.music_playlist);
				query.set_string(":podcast_playlist", dp.podcast_playlist);
				query.set_string(":audiobook_playlist", dp.audiobook_playlist);
				query.set_int(":last_sync_time", dp.last_sync_time);
				
				query.execute();
			}
		}
		catch(SQLHeavy.Error err) {
			warning("Error saving devices: %s", err.message);
		}
	}
}
