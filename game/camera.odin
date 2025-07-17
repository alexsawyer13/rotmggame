package game

update_camera_component :: #force_inline proc(c : ^Camera_Component) {
	if c.main_camera {
		g_camera.target = get_transform_component(c.transform).pos
		g_camera.rotation = -get_transform_component(c.transform).rot // CW rotation
		g_camera.offset = {
			f32(g_settings.window_width) * 0.5,
			f32(g_settings.window_height) * 0.5
		}
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
