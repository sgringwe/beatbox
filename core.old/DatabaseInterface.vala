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

public class BeatBox.DatabaseTransactionFiller {
	public delegate void TransactionFiller(ref SQLHeavy.Transaction transaction, DatabaseTransactionFiller db_filler);
	public unowned TransactionFiller filler;
	public Object data;
	public string pre_transaction_execute;
	
	public DatabaseTransactionFiller() { }
}

public interface BeatBox.DatabaseInterface : GLib.Object {
	public abstract SQLHeavy.QueryResult execute(string statement);
	public abstract void queue_transaction(DatabaseTransactionFiller db_filler);
	public abstract void add_periodic_transaction(DatabaseTransactionFiller periodic_filler);
}
