package game

import rl "vendor:raylib"
import "core:time"

Transform_Component :: struct {
	pos  : rl.Vector2,
	size : rl.Vector2,
	rot  : f32,
}

Control_Component :: struct {
	transform    : Transform_Handle,
	camera       : Camera_Handle,
	speed        : f32,
	scroll_speed : f32,
}

Target_Flags :: enum {
	Target_Player,
	Target_Enemy,

	Target_Kill_On_Death,
	Target_Invulnerable,
}

Target_Component :: struct {
	entity     : Entity_Handle,
	health     : i32,
	max_health : i32,
	flags      : bit_set[Target_Flags],
}
