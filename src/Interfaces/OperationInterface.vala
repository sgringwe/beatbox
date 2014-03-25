/*
 * OperationInterface.vala
 * =======================
 * Interface to OperationManager.
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

namespace Beatbox {

	public interface OperationInterface : GLib.Object {
		public signal void operation_added(Operation op);
		public signal void operation_started(Operation op);
		public signal void operation_status_updated(Operation op, string status);
		public signal void operation_progress_updated(Operation op, double progress);
		public signal void operation_cancelling(Operation op);
		public signal void operation_finished(Operation op);

		public abstract void 		add_operation(Operation op);
		public abstract void 		remove_operation(Operation op);
		public abstract Operation? 	get_current_operation();
		public abstract void 		cancel_current_operation();
		public abstract uint 		get_operation_count();
	}
}