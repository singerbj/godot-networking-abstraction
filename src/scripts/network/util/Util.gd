extends Node


class_name Util

static func gen_unique_string(length: int) -> String:
	var _ascii_letters_and_digits = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var result = ""
	for _i in range(length):
		result += _ascii_letters_and_digits[randi() % _ascii_letters_and_digits.length()]
	return result

#var args = Array(OS.get_cmdline_args())
#	for arg in args:
#		var formatted_arg_array = arg.split("=")
#		print(formatted_arg_array)
#		if formatted_arg_array.size() == 2:
#			if formatted_arg_array[0] == "-ip":
#				ip_address = formatted_arg_array[1]
#				print("Using command line specified ip: " + ip_address)
#			else:
#				print("Command line ip not specified")
			
