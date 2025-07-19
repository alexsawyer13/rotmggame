package game

import rl "vendor:raylib"

Rect_Collider_Component :: struct {
	entity    : Entity_Handle,
	transform : Transform_Handle,
	tags      : bit_set[Collider_Tag],
}

Collider_Tag :: enum {
	Collider_Player,
	Collider_Enemy,
	Collider_Projectile,
}

rect_rect_collision :: proc(r1, r2 : rl.Rectangle) -> bool {
	return ((r2.x > r1.x && r2.x < r1.x + r1.width) &&
	       (r2.y > r1.y && r2.y < r1.y + r1.height)) ||
	       ((r2.x + r2.width > r1.x && r2.x < r1.x + r1.width) &&
	       (r2.y + r2.height > r1.y && r2.y < r1.y + r1.height))
}

get_first_collides_with_tag :: proc(collider : Rect_Collider_Component, tag : Collider_Tag) -> (bool, Rect_Collider_Handle) {
	t := get_transform_component(collider.transform)
	if t == nil do return false, {-1, -1}

	r1 := rl.Rectangle {
		x = t.pos.x - 0.5 * t.size.x,
		y = t.pos.y - 0.5 * t.size.y,
		width = t.size.x,
		height = t.size.y
	}

	for c, i in g_ecs.rect_collider_components.items {
		if c.removed do continue
		if !(tag in c.item.tags) do continue
		t2 := get_transform_component(c.item.transform)
		if t2 == nil do continue

		r2 := rl.Rectangle {
			x = t2.pos.x - 0.5 * t2.size.x,
			y = t2.pos.y - 0.5 * t2.size.y,
			width = t2.size.x,
			height = t2.size.y
		}

		if rect_rect_collision(r1, r2) do return true, {c.id, i64(i)}
	}

	return false, {-1, -1}
}

update_rect_collider_component :: #force_inline proc(c : ^Rect_Collider_Component) {
	when DEBUG_DRAW_COLLIDERS {
		t := get_transform_component(c.transform)
		if t == nil do return
		draw_world_outline_centre(t.pos, t.size, rl.RED)
	}
}
