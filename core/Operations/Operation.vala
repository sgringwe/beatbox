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
 
public class BeatBox.Operation : GLib.Object {
	public delegate void OperationFunc(Operation op);
	
	public unowned OperationFunc start_sync_func { get; set; }
	public unowned OperationFunc start_async_func { get; set; }
	public unowned OperationFunc cancel_func { get; set; }
	
	// These functions are optional, but will be executed if not null
	public unowned OperationFunc finished_func { get; set; }
	
	public string description { get; set; }
	
	public signal void started();
	public signal void status_updated(string? status);
	public signal void progress_updated(double progress);
	public signal void cancelled();
	public signal void finished();
	
	public Operation(Operation.OperationFunc sync_start, Operation.OperationFunc async_start, Operation.OperationFunc cancel, string description) {
		start_async_func = async_start;
		start_sync_func = sync_start;
		cancel_func = cancel;
		this.description = description;
	}
	
	/** Called by operation manager. The job here is to notify the client
	 * that it now has control of operations and can do its thing **/
	public void start() {
		start_sync_func(this);
		
		try {
			new Thread<void*>.try (null, () => {
				start_async_func(this);
				return null;
			});
		}
		catch (Error err) {
			warning ("Could not create thread to start operatoin %s: %s", description, err.message);
		}
	}
	
	/** Called by operation manager. Notifies client that it needs to gracefully
	 * cancel whatever it is doing and then call finished() **/
	public void cancel() {
		cancel_func(this);
	}
}
