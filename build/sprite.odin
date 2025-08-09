package build

import "core:os"
import "core:fmt"
import "core:image/png"

generate_sprite_file :: proc() -> bool {
    os_err : os.Error
    sprite_dir : os.Handle
    files : []os.File_Info

    fmt.println("----- Generating sprite.odin -----")

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

    for file in files {
        fmt.println(file.name)
        bytes, err := os.read_entire_file(file.fullpath)
        if err {
            fmt.println("Failed to read ", file.fullpath)
            return false
        }
        header, success := png.read_header(raw_data(bytes))
        fmt.println(file.name, " ", header.width, " ", header.height)
    }

    return true
}