import os
import json
import regex

struct Config {
	main_file	string
	files		[]string
}

type Options = bool | string

fn read_file(path string) string {
	file := os.read_file(path) or { panic(err) }
	return file
}

fn pack(config string, verbose bool) {
	config_file := read_file("${config}")
	if verbose { println("[INFO] Loaded config file") }

	config_dec := json.decode(Config, config_file) or { 
		if verbose { println("[ERR] Failed to parse config file. Panicking!") }
		panic(err) 
	}

	if verbose { println("[INFO] Parsed config file") }

	mut final_file := ""

	last_ret_regex := r"(?:.(?!return))+$"
	import_reg := r"local(.*)require\(.*\)"

	for file in config_dec.files {
		mut ret_re := regex.regex_opt(last_ret_regex) or { 
			if verbose { println("[ERR] Failed to create regex. Panicking!") }
			panic(err) 
		}

		mut file_text := read_file(file)

		file_text = ret_re.replace_simple(file_text, "")
		if verbose { println("[INFO] Replaced text successfully") }

		final_file += file_text
	}

	mut imp_re := regex.regex_opt(import_reg) or { 
		if verbose { println("[ERR] Failed to create regex. Panicking!") }
		panic(err) 
	}

	mut main_file := read_file(config_dec.main_file)

	main_file = imp_re.replace_simple(main_file, "")
	final_file += main_file

	mut file := os.open_file("./packed.lua", "w") or { 
		if verbose { println("[ERR] Failed to create file. Panicking!") }
		panic(err) 
	}

	file.write_string(final_file) or { 
		if verbose { println("[ERR] Failed to write to file. Panicking!") }
		panic(err) 
	}

	if verbose { println("[INFO] Packed all files into ./packed.lua!") }
}

fn main() {
	mut verbose := false
	mut config := "packer.conf.json"

	if os.args.len <= 1 {
		print("Usage: packer [options]
	-v: Makes it verbose (Ex: packer -v)
	-c: Selects a custom config file (Ex: packer -c=\"packer.conf.json\")")
		exit(1)
	}

	for arg in os.args {
		if arg == "-c" {
			new_path := arg.replace("-c=", "")
			config = new_path
		} else if arg == "-v" {
			verbose = true
		}
 	}
	
	pack(config, verbose)
}