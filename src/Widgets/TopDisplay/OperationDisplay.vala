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

public class BeatBox.OperationDisplay : BeatBox.Display, Box {
	private Label operation_status;
	private ProgressBar operation_bar;
	
	bool _is_enabled;
	public bool is_enabled { get { return _is_enabled; } }
	
	public OperationDisplay() {
		operation_status = new Label("");
		operation_bar = new ProgressBar();
		
		operation_status.xalign = 0.5f;
		operation_status.set_justify(Justification.CENTER);
		operation_status.margin_left = 0;
		operation_status.ellipsize = Pango.EllipsizeMode.END;
		
		var left_box = new Box(Orientation.VERTICAL, 0);
		left_box.pack_start(operation_status, false, false, 0);
		left_box.pack_start(operation_bar, false, false, 0);
		
		this.set_orientation(Orientation.HORIZONTAL);
		pack_start(left_box, true, true, 0);
		
		App.operations.operation_started.connect(operation_started);
		App.operations.operation_progress_updated.connect(operation_progress_updated);
		App.operations.operation_status_updated.connect(operation_status_updated);
		App.operations.operation_finished.connect(operation_finished);
		
		// In case an operation is already going on at startup
		if(App.operations.doing_ops) {
			message("Found that app is already doing ops. Showing...");
			operation_started();
			operation_progress_updated(App.operations.current_progress);
			operation_status_updated(App.operations.current_status);
		}
	}
	
	void operation_started() {
		_is_enabled = true;
		enabled();
	}
	
	void operation_progress_updated(double progress) {
		operation_bar.set_fraction(progress);
	}
	
	void operation_status_updated(string? status) {
		if(status != null) {
			operation_status.set_markup(status);
		}
	}
	
	void operation_finished() {
		_is_enabled = false;
		disabled();
	}
	
	public bool is_cancellable() {
		return true;
	}
	
	public void cancel() {
		App.operations.cancel_current_operation();
	}
}
