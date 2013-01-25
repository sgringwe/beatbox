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

public abstract interface BeatBox.OperationsInterface : GLib.Object {
	public signal void operation_started();
	public signal void operation_status_updated(string? status);
	public signal void operation_progress_updated(double progress);
	public signal void operation_finished();
	
	public abstract bool doing_ops { get; }
	public abstract bool operation_cancelled { get; protected set; }
	
	public abstract string? current_status { get; set; }
	public abstract int operation_progress { get; set; }
	public abstract int operation_total { get; set; }
	public abstract double current_progress { get; }
	public abstract Operation current_op { get; protected set; }
	
	public abstract void queue_operation(Operation op);
	public abstract void cancel_current_operation();
	public abstract void finish_operation();
}
