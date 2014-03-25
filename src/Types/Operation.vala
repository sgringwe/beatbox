/*
 * Operation.vala
 * ==============
 * Operations which carried out by OperationManager.
 *
 * Copyright (c) 2011-2012 BeatBox Developers
 * See AUTHORS and LICENCE file for further details.
 */

using GLib;

namespace Beatbox {

	public abstract class Operation : GLib.Object {
		public bool running { get; private set; }

		public signal void started();
		public signal void status_updated(string status);
		public signal void progress_updated(double progress);
		public signal void cancelling();
		public signal void exiting();

		public Operation() {
			running = false;
		}

		public virtual string get_name() {
			return "Untitled Operation";
		}

		public virtual string get_description() {
			return "No description";
		}

		public abstract void run();
		public abstract void cancel();
		public abstract double get_progress();
		public abstract string get_status();

		// This function is intended to be called by OperationManager,
		// DO NOT CALL DIRECTLY
		public bool _start() {
			try {
				running = true;
				new Thread<void*>.try(null, () => {
					started();
					run();
					running = false;
					exiting();
					return null;
				});
			} catch(Error e) {
				warning("Unable to launch operation %s in a new thread: %s",
					get_name(), e.message);
				running = false;
				return false;
			}
			return true;
		}

		// This function is intended to be called by OperationManager,
		// DO NOT CALL DIRECTLY
		public void _stop() {
			cancel();
			cancelling();
		}
	}
}