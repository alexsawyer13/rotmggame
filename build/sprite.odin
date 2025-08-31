package build

import "core:os"
import "core:fmt"
import "core:image/png"

generate_sprite_file :: proc() -> bool {

	Image :: struct {
		width  : int,
		height : int,

		enum_name : string,
		full_path : string,
	}

	make_image :: proc(name : string) {
		image : Image
		image.enum_name = "test"
	}

	delete_image :: proc() {

	}


	file : File
	file_init(&file, "game/gen_sprite.odin")
	file_set_current(&file)

    fmt.println("----- Generating sprite.odin -----")

	os_err : os.Error
	sprite_dir : os.Handle
	files : []os.File_Info

	images := make([dynamic]Image)
	defer delete(images)

	// Get all files in sprite directory
    sprite_dir, os_err = os.open("sprites")
    if os_err != nil {
        fmt.println("Failed to open game directory")
        return false
    }
    defer os.close(sprite_dir)

    files, os_err = os.read_dir(sprite_dir, -1)
    if os_err != nil {
        fmt.println("Failed to read game directory")
        return false
    }
    defer {
        for file in files {
            delete(file.fullpath)
        }
        delete(files)
    }

	// Loop through all files and get info about them
    for f in files {
		image, err := png.load_from_file(f.fullpath, allocator = context.temp_allocator)
        if err != nil {
            fmt.println("Failed to read ", f.fullpath)
            return false
        }
		append(&images, Image {
			name = f.name,
			width = image.width,
			height = image.height
		})
		free_all(context.temp_allocator)
    }

	// Generate file!

	for image in images {
		fmt.println(image.name, " ", image.width, "x", image.height, sep = "")
	}

	// Write file to disk

	file_finish(&file)

    return true
}
