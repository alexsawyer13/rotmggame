package game

import rl "vendor:raylib"

Attribute_Component :: struct {
	transform : Transform_Handle,

	health : u32,
	max_health : u32,
	
	mana : u32,
	max_mana : u32,

	attack : u32,
	dexterity : u32,

	defence : u32,
	speed : u32,

	wisdom : u32,
	vitality : u32,
}

create_slime :: proc(pos : rl.Vector2) -> Entity_Handle {
	e : Entity_Handle = make_entity()
	t := add_transform_component(e, {
		pos = pos,
		size = {0.6, 0.6}
	})
	add_rect_collider_component(e, {
		entity = e,
		transform = t,
		tags = {.Collider_Enemy}
	})
	add_sprite_component(e, {
		transform = t,
		sprite = .Sprite_Slime,
	})
	add_attribute_component(e, {
		transform = t,
		health = 10,
		max_health = 10,

		mana = 0,
		max_mana = 0,

		attack = 1,
		dexterity = 1,

		defence = 0,
		speed = 1,

		wisdom = 0,
		vitality = 0,
	})
	return e
}
