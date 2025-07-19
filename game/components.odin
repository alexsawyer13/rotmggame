package game

import rl "vendor:raylib"
import "core:time"

Transform_Component :: struct {
	pos  : rl.Vector2,
	size : rl.Vector2,
	rot  : f32,
}

Control_Component :: struct {
	transform : Transform_Handle,
	speed     : f32,
}

Projectile_Component :: struct {
	entity     : Entity_Handle,
	transform  : Transform_Handle,
	collider   : Rect_Collider_Handle,

	dir        : rl.Vector2,
	speed      : rl.Vector2,

	birth      : time.Time,
	lifetime_s : f32,
}

Follow_Component :: struct {
	transform : Transform_Handle,
	target    : Transform_Handle,
	speed     : f32,
}
