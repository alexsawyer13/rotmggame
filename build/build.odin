package build

import "core:os"
import "core:fmt"
import "core:strings"

File :: struct {
	string_builder : strings.Builder,
	path           : string
}

file_init :: proc(file : ^File, path : string) {
	file.string_builder = strings.builder_make_none()
	file.path = path
}

file_finish :: proc(file : ^File) {
	os.write_entire_file(file.path, file.string_builder.buf[:])
	strings.builder_destroy(&file.string_builder)
	if current_file == file do current_file = nil
}

file_set_current :: proc(file : ^File) {
	current_file = file
}

// Global file so you don't have to pass
// file in as a parameter everywhere
current_file : ^File

writeln :: proc(args : ..string) {
	if current_file == nil do return

    for arg in args {
        strings.write_string(&current_file.string_builder, arg)
    }
    strings.write_string(&current_file.string_builder, "\n")
}

main :: proc() {
    generate_entity_file()
    generate_sprite_file()
}
