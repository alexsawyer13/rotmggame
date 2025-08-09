package build

import "core:fmt"
import "core:strings"

// Global stringbuilder for building files
// everywhere with write functions. 
sb : strings.Builder

writeln :: proc(args : ..string) {
    for arg in args {
        strings.write_string(&sb, arg)
    }
    strings.write_string(&sb, "\n")
}

@(private)
clear :: proc() {
    strings.builder_reset(&sb)
    free_all(context.temp_allocator)
}

main :: proc() {
    sb = strings.builder_make_none()
    defer strings.builder_destroy(&sb)

    if !generate_entity_file() do return; clear()
    if !generate_sprite_file() do return; clear()
}