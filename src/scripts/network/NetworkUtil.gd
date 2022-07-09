extends Node

class_name NetworkUtil

static func gen_unique_string(length: int) -> String:
	var _ascii_letters_and_digits = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var result = ""
	for _i in range(length):
		result += _ascii_letters_and_digits[randi() % _ascii_letters_and_digits.length()]
	return result

static func sort_snapshots(a, b):
	if a.time < b.time:
		return true
	return false
	
static func sort_network_inputs(a, b):
	if a.id < b.id:
		return true
	return false
	
static func get_cmd_line_ipaddress() -> String:
	var ip_address = "localhost"
	var args = Array(OS.get_cmdline_args())
	for arg in args:
		var formatted_arg_array = arg.split("=")
		print(formatted_arg_array)
		if formatted_arg_array.size() == 2:
			if formatted_arg_array[0] == "-ip":
				ip_address = formatted_arg_array[1]
				print("Using command line specified ip: " + ip_address)
	if ip_address == "localhost":
		print("Command line ip not specified. Defaulting to localhost")
	return ip_address
		
