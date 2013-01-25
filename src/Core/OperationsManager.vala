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

public class BeatBox.OperationsManager : GLib.Object, BeatBox.OperationsInterface {
	public bool doing_ops { get { return current_op != null; } }
	public bool operation_cancelled { get; protected set; }
	
	private string? _current_status;
	public string? current_status {
		get { return _current_status; }
		set {
			if(value != _current_status) {
				_current_status = value;
				status_updated = true;
			}
		}
	}
	
	private int _operation_progress;
	public int operation_progress {
		get { return _operation_progress; }
		set {
			if(value != _operation_progress) {
				_operation_progress = value;
				progress_updated = true;
			}
		}
	}
	
	private int _operation_total;
	public int operation_total {
		get { return _operation_total; }
		set {
			if(value != _operation_total) {
				_operation_total = value;
				progress_updated = true;
			}
		}
	}
	
	public double current_progress {
		get {
			return (double)((double)operation_progress/(double)operation_total);
		}
	}
	
	private bool progress_updated;
	private bool status_updated;
	
	public Operation current_op { get; protected set; }
	private LinkedList<Operation> op_queue;
	
	public OperationsManager() {
		op_queue = new LinkedList<Operation>();
		current_status = null;
		
		Timeout.add(100, update_checker);
	}
	
	/** In the case that an operation is willing to wait for the current (or more)
	 * to finish, it may call queue_operation.
	 * 
	 * @param start The function to call when the item is started
	 * @param cancel The function to call when the user cancels this item. It is still
	 * up to the caller to gracefully finish their operation and call finish_operation() with
	 * the key it was given.
	 * 
	*/
	public void queue_operation(Operation op) {
		if(current_op == null) {
			begin_operation(op);
		}
		else {
			op_queue.offer(op);
		}
	}
	
	/**Called to actually start the operation once it is its turn.
	 * Starts a thread and calls the op's start func. 
	*/
	private void begin_operation(Operation op) {
		current_op = op;
		operation_cancelled = false;
		current_status = null;
		operation_progress = 0;
		operation_total = 0;
		
		operation_started();
		current_op.start();
	}
	
	/**Usually called when user clicks on cancel, or something similar. Calls the
	 * OperationCancelFunc of the current operation. Current operation handles
	 * doing the actual cancelling
	*/
	public void cancel_current_operation() {
		if(current_op == null) {
			warning("User tried to cancel current operation, but no operation is running.");
			return;
		}
		
		operation_cancelled = true;
		current_op.cancel();
		message("Operation " + current_op.description + " has been told to cancel itself");
	}
	
	/**Signal that the operation finished, and then start the next if there
	 * is a next in the queue.**/
	public void finish_operation() {
		if(current_op == null)
			return;
		
		var previous_op = current_op;
		current_op = null;
		
		if(previous_op.finished_func != null)
			previous_op.finished_func(previous_op);
		
		if(op_queue.size > 0) {
			begin_operation(op_queue.poll());
		}
		else {
			operation_finished();
		}
	}
	
	public bool update_checker() {
		if(status_updated)
			operation_status_updated(current_status);
		if(progress_updated)
			operation_progress_updated(current_progress);
		
		status_updated = false;
		progress_updated = false;
		
		return true;
	}
}
	
