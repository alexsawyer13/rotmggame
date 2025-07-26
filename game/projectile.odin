package game

import "core:fmt"
import "core:math"
import "core:time"
import rl "vendor:raylib"

Projectile_Flag :: enum {
	Projectile_Hit_Player,
	Projectile_Hit_Enemy,
}

Projectile_Component :: struct {
	entity     : Entity_Handle,
	transform  : Transform_Handle,
	collider   : Rect_Collider_Handle,

	damage     : i32,

	dir        : rl.Vector2,
	speed      : rl.Vector2,

	birth      : time.Time,
	lifetime_s : f32,

	flags      : bit_set[Projectile_Flag]
}

create_projectile :: proc(
	pos, dir : rl.Vector2,
	speed, lifetime_s : f32,
	damage : i32,
	flags : bit_set[Projectile_Flag]
) -> Entity_Handle {
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

		damage = damage,

		flags = flags,
	})
	return e
}

update_projectile_component :: #force_inline proc(p : ^Projectile_Component) {
	t := get_transform_component(p.transform)
	if t == nil do return

	// Move projectile and get its age
	t.pos += (p.dir * p.speed * g_dt)
	
	// Kill if it's lived too long
	age_s := time.duration_seconds(time.diff(p.birth, time.now()))
	if age_s > f64(p.lifetime_s) {
		remove_entity(p.entity)
		return
	}

	// Get collider
	c := get_rect_collider_component(p.collider)
	if c == nil do return

	// Get target collisions
	target : ^Target_Component

	if collides, handle := get_first_collides_with_tag(c^, .Collider_Target); collides {
		rect := get_rect_collider_component(handle)
		if rect == nil do return
		entity := rect.entity
		t := get_target_component(entity)
		if t != nil && (.Target_Player in t.flags && .Projectile_Hit_Player in p.flags) || (.Target_Enemy in t.flags && .Projectile_Hit_Enemy in p.flags) {
			target = t
		}
	}

	if target == nil do return

	// Damage target and remove projectile
	fmt.println(p.damage)
	target.health -= p.damage
	remove_entity(p.entity)
}
