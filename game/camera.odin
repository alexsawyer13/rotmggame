package game

import "core:math"
import rl "vendor:raylib"

Camera_Component :: struct {
	transform   : Transform_Handle,
	zoom        : f32, // Number of world space units in the width of the viewport
	main_camera : bool,
}

update_camera_component :: #force_inline proc(c : ^Camera_Component) {
	if c.main_camera {
		g_camera.target = get_transform_component(c.transform).pos
		g_camera.rotation = -get_transform_component(c.transform).rot // Camera rotates counter clockwise by default
		g_camera.offset = g_viewport_half_size
		g_camera.zoom = (g_viewport_size.x / c.zoom) // Pixels per world space unit
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

	// Because camera rotation is by default a CCW rotation
	// and my angles are by default a CW rotaion
	// so ccw_roation(camera_angle) = cw_rotation(my angle)
	// For some reason raylib is inconsistent between camera and draw??
	return ccw_rotation((pos - g_camera.offset) / g_camera.zoom, cos, sin) + g_camera.target
}
