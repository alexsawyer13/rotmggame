package game

import rl "vendor:raylib"

Transform_Component :: struct {
	pos  : rl.Vector2,
	size : rl.Vector2,
	rot  : f32,
}

Sprite_Component :: struct {
	transform : Transform_Handle,
	sprite : SpriteType,
}

Control_Component :: struct {
	transform : Transform_Handle,
	speed : f32,
}

Camera_Component :: struct {
	transform : Transform_Handle,
	zoom : f32,
	main_camera : bool,
}
