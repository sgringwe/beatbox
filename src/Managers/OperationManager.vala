/*
 * OperationManager.vala
 * =====================
 * Manage and execute asychronous operations.
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

using GLib;

namespace Beatbox {

	public class OperationManager : GLib.Object, OperationInterface {

		// Lock me first, please
		private Queue<Operation> queue;
		private bool running;

		public OperationManager() {
			queue = new Queue<Operation>();
			running = false;
		}

		private void execute(Operation op) {
			op.started.connect(() => {
				debug("Operation started: %s",
					get_current_operation().get_name());
				operation_started(
					get_current_operation());
			});

			op.status_updated.connect((status) => {
				debug("Status updated on operation %s: %s",
					get_current_operation().get_name(), status);
				operation_status_updated(
					get_current_operation(),
					status);
			});

			op.progress_updated.connect((progress) => {
				operation_progress_updated(
					get_current_operation(),
					progress);
			});

			op.cancelling.connect(() => {
				debug("Operation %s cancelling...",
					get_current_operation().get_name());
				operation_cancelling(
					get_current_operation());
			});

			op.exiting.connect(() => {
				debug("Operation %s finished.",
					get_current_operation().get_name());
				operation_finished(
					get_current_operation());

				lock(queue) {
					queue.pop_head();
					if(!queue.is_empty()) {
						execute(queue.peek_head());
					} else {
						running = false;
					}
				}
			});

			if(!op._start()) {
				warning("Failed to execute next operation, entering stall mode.");
			}

			running = true;
		}

		public void add_operation(Operation op) {
			lock(queue) {
				queue.push_tail(op);
				operation_added(op);
				if(!running) {
					execute(queue.peek_head());
				}
			}
		}

		public void remove_operation(Operation op) {
			lock(queue) {
				if(op == get_current_operation() && op.running) {
					op.cancel();
				} else {
					queue.remove(op);
				}
			}
		}

		public Operation? get_current_operation() {
			if(!running || queue.is_empty()) return null;
			return queue.peek_head();
		}

		public void cancel_current_operation() {
			lock(queue) {
				if(running)
					get_current_operation().cancel();
			}
		}

		public uint get_operation_count() {
			return queue.get_length();
		}
	}
}