var args = Array(OS.get_cmdline_args())
	for arg in args:
		var formatted_arg_array = arg.split("=")
		print(formatted_arg_array)
		if formatted_arg_array.size() == 2:
			if formatted_arg_array[0] == "-ip":
				ip_address = formatted_arg_array[1]
				print("Using command line specified ip: " + ip_address)
			else:
				print("Command line ip not specified")
			
