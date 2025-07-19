package game

import "core:math"
import rl "vendor:raylib"

cw_rotation_trig :: #force_inline proc(p : rl.Vector2, rot : f32) -> rl.Vector2 {
	return {
		math.cos(rot) * p.x - math.sin(rot) * p.y,
		math.sin(rot) * p.x + math.cos(rot) * p.y,
	}
}

cw_rotation_angle :: #force_inline proc(p : rl.Vector2, cos, sin : f32) -> rl.Vector2 {
	return {
		cos * p.x - sin * p.y,
		sin * p.x + cos * p.y,
	}
}

cw_rotation :: proc{
	cw_rotation_trig,
	cw_rotation_angle,
}

ccw_rotation_trig :: #force_inline proc(p : rl.Vector2, rot : f32) -> rl.Vector2 {
	return {
		math.cos(rot) * p.x + math.sin(rot) * p.y,
		-math.sin(rot) * p.x + math.cos(rot) * p.y,
	}
}

ccw_rotation_angle :: #force_inline proc(p : rl.Vector2, cos, sin : f32) -> rl.Vector2 {
	return {
		cos * p.x + sin * p.y,
		-sin * p.x + cos * p.y,
	}
}

ccw_rotation :: proc{
	ccw_rotation_trig,
	ccw_rotation_angle,
}
