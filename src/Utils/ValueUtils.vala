public namespace ValueUtils {
	public Value create_string_value(string s) {
		Value rv = Value(typeof(string));
		rv.set_string(s);
		return rv;
	}
	
	public Value create_integer_value(int i) {
		Value rv = Value(typeof(int));
		rv.set_int(i);
		return rv;
	}
}
