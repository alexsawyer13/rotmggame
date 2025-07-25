package game

import "core:math"
import "core:time"
import rl "vendor:raylib"

create_projectile :: proc(pos, dir : rl.Vector2, speed, lifetime_s : f32) -> Entity_Handle {
	e := make_entity()
	t := add_transform_component(e, {
		pos = pos,
		size = {0.4, 0.25},
		rot = math.atan2(dir.y, dir.x) * math.DEG_PER_RAD
	})
	add_sprite_component(e, {
		transform = t,
		sprite = .Sprite_Projectile
	})
	c := add_rect_collider_component(e, {
		entity = e,
		transform = t,
		tags = {.Collider_Player_Projectile}
	})
	add_projectile_component(e, {
		entity = e,
		transform = t,
		collider = c,

		dir = dir,
		speed = speed,

		birth = time.now(),
		lifetime_s = lifetime_s,
	})
	return e
}

update_projectile_component :: #force_inline proc(p : ^Projectile_Component) {
	t := get_transform_component(p.transform)
	if t == nil do return

	t.pos += (p.dir * p.speed * g_dt)
	age_s := time.duration_seconds(time.diff(p.birth, time.now()))

	if age_s > f64(p.lifetime_s) {
		remove_entity(p.entity)
		return
	}

	c := get_rect_collider_component(p.collider)
	if c == nil do return
	if collides, enemy := get_first_collides_with_tag(c^, .Collider_Enemy); collides {
		remove_entity(p.entity)
		remove_entity(get_rect_collider_component(enemy).entity)
		return
	}
}
