package game

create_player :: proc() -> Entity_Handle {
	e : Entity_Handle = make_entity()
	t := add_transform_component(e, {
		pos = {0.0, 0.0},
		rot = 0.0,
		size = {1.0, 1.0}
	})
	add_rect_collider_component(e, {
		entity = e,
		transform = t,
		tags = {.Collider_Player, .Collider_Target}
	})
	add_sprite_component(e, {
		transform = t,
		sprite = .Sprite_Wizard
	})
	c := add_camera_component(e, {
		transform = t,
		zoom = 13.0,
		main_camera = true
	})
	add_control_component(e, {
		transform = t,
		camera = c,
		speed = 3.0,
		scroll_speed = 1000.0
	})
	add_target_component(e, {
		entity = e,
		health = 100,
		max_health = 100,
		flags = {.Target_Player}
	})
	return e
}
