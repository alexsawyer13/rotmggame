package game

import "core:math"
import rl "vendor:raylib"

update_camera_component :: #force_inline proc(c : ^Camera_Component) {
	if c.main_camera {
		g_camera.target = get_transform_component(c.transform).pos
		g_camera.rotation = -get_transform_component(c.transform).rot // CW rotation
		g_camera.offset = {
			f32(g_window_half_width),
			f32(g_window_half_height)
		}
		g_camera.zoom = 100
	}
}

set_main_camera :: proc(h : Camera_Handle) {
	cam := get_camera_component(h)
	if cam == nil {
		panic("Setting main camera to a non existent camera!")
	}

	for &c in g_ecs.camera_components.items {
		if !c.removed do c.item.main_camera = false
	}

	cam.main_camera = true
}

screen_to_world_space :: proc(pos : rl.Vector2) -> rl.Vector2 {
	sin := math.sin(g_camera.rotation * math.RAD_PER_DEG)
	cos := math.cos(g_camera.rotation * math.RAD_PER_DEG)

	unrotated := (pos - g_camera.offset) / g_camera.zoom

	// CW rotation, looks like CCW
	unshifted := rl.Vector2 {
		cos * unrotated.x + sin * unrotated.y,
		- sin * unrotated.x + cos * unrotated.y
	}

	world := unshifted + g_camera.target

	return world
}
