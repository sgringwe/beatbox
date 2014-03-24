public interface BeatBox.FieldEditor : Gtk.Box {
	public abstract void set_check_visible(bool val);
	public abstract bool checked();
	public abstract Value? get_value();
	public abstract void set_value(Value val);
	
	public abstract void set_width_request(int width);
}
