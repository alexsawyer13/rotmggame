package game

import rl "vendor:raylib"

create_slime :: proc(pos : rl.Vector2) -> Entity_Handle {
	e : Entity_Handle = make_entity()
	t := add_transform_component(e, {
		pos = pos,
		size = {0.6, 0.6}
	})
	add_rect_collider_component(e, {
		entity = e,
		transform = t,
		tags = {.Collider_Target, .Collider_Enemy}
	})
	add_sprite_component(e, {
		transform = t,
		sprite = .Sprite_Slime,
	})
	add_target_component(e, {
		entity = e,
		health = 10,
		max_health = 10,
	})
	add_target_component(e, {
		entity = e,
		health = 100,
		max_health = 100,
		flags = {.Target_Enemy, .Target_Kill_On_Death}
	})
	return e
}
