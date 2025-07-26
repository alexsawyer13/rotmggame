package game

import "core:math"
import "core:math/rand"

import rl "vendor:raylib"

Bandit_King_Component :: struct {
	transform  : Transform_Handle,
	
	centre     : rl.Vector2,
	target     : rl.Vector2,
	has_target : bool,
}

Bandit_Component :: struct {
	transform : Transform_Handle,
	king      : Transform_Handle,

	centre     : rl.Vector2,
	target     : rl.Vector2,
	has_target : bool,
}

BANDIT_KING_SPEED :: 1.0
BANDIT_KING_JIGGLE_RADIUS :: 0.5
BANDIT_KING_WANDER_RADIUS :: 5.0

BANDIT_SPEED :: 1.5
BANDIT_JIGGLE_RADIUS :: 1.0
BANDIT_WANDER_INNER_RADIUS :: 3.0
BANDIT_WANDER_OUTER_RADIUS :: 3.0

create_bandit_pack :: proc(pos : rl.Vector2){
	e := create_bandit_king(pos)
	k := get_bandit_king_component(e)
	if k == nil do return
	t := get_transform_component(e)
	if t == nil do return

	for i in 0..<4 {
		bandit_pos := t.pos + {
			rand.float32_range(-BANDIT_WANDER_OUTER_RADIUS, BANDIT_WANDER_OUTER_RADIUS),
			rand.float32_range(-BANDIT_WANDER_OUTER_RADIUS, BANDIT_WANDER_OUTER_RADIUS),
		}
		create_bandit(bandit_pos, k^)
	}
}

create_bandit_king :: proc(pos : rl.Vector2) -> Entity_Handle {
	e := make_entity()
	t := add_transform_component(e, {
		pos = pos,
		size = {1.5, 1.5}
	})
	add_sprite_component(e, {
		transform = t,
		sprite = .Sprite_Bandit_King
	})
	add_rect_collider_component(e, {
		entity = e,
		transform = t,
		tags = {.Collider_Target, .Collider_Enemy}
	})
	add_bandit_king_component(e, {
		transform = t,
		centre = pos
	})
	add_target_component(e, {
		entity = e,
		health = 100,
		max_health = 100,
		flags = {.Target_Enemy, .Target_Kill_On_Death}
	})
	return e
}

create_bandit_healer :: proc(king : Bandit_King_Component) -> Entity_Handle {
	return {-1, -1}
}

create_bandit_rogue :: proc(king : Bandit_King_Component) -> Entity_Handle {
	return {-1, -1}
}

create_bandit :: proc(pos : rl.Vector2, king : Bandit_King_Component) -> Entity_Handle {
	e := make_entity()
	t := add_transform_component(e, {
		pos = pos,
		size = {1.0, 1.0}
	})
	add_sprite_component(e, {
		transform = t,
		sprite = .Sprite_Bandit
	})
	add_rect_collider_component(e, {
		entity = e,
		transform = t,
		tags = {.Collider_Target, .Collider_Enemy}
	})
	add_bandit_component(e, {
		transform = t,
		king = king.transform,
	})
	add_target_component(e, {
		entity = e,
		health = 100,
		max_health = 100,
		flags = {.Target_Enemy, .Target_Kill_On_Death}
	})
	return e
}

update_bandit_king_component :: proc(c : ^Bandit_King_Component) {
	t := get_transform_component(c.transform)
	if t == nil do return

	if !c.has_target {
		c.target = t.pos + {
			rand.float32_range(-BANDIT_KING_JIGGLE_RADIUS, BANDIT_KING_JIGGLE_RADIUS),
			rand.float32_range(-BANDIT_KING_JIGGLE_RADIUS, BANDIT_KING_JIGGLE_RADIUS),
		}
		c.target.x = math.clamp(c.target.x, c.centre.x - BANDIT_KING_WANDER_RADIUS, c.centre.x + BANDIT_KING_WANDER_RADIUS)
		c.target.y = math.clamp(c.target.y, c.centre.y - BANDIT_KING_WANDER_RADIUS, c.centre.y + BANDIT_KING_WANDER_RADIUS)
		c.has_target = true
	} else {
		displacement := c.target - t.pos
		dir := rl.Vector2Normalize(displacement)
		move := dir * BANDIT_KING_SPEED * g_dt
		t.pos += move
		if (rl.Vector2LengthSqr(displacement) < 0.1) {
			c.has_target = false
		}
	}
}

update_bandit_component :: proc(c : ^Bandit_Component) {
	t := get_transform_component(c.transform)
	if t == nil do return

	k := get_transform_component(c.king)
	if k == nil do return

	if !c.has_target {
		c.target = t.pos + {
			rand.float32_range(-BANDIT_JIGGLE_RADIUS, BANDIT_JIGGLE_RADIUS),
			rand.float32_range(-BANDIT_JIGGLE_RADIUS, BANDIT_JIGGLE_RADIUS),
		}
		c.target.x = math.clamp(c.target.x, k.pos.x - BANDIT_WANDER_OUTER_RADIUS, k.pos.x + BANDIT_WANDER_OUTER_RADIUS)
		c.target.y = math.clamp(c.target.y, k.pos.y - BANDIT_WANDER_OUTER_RADIUS, k.pos.y + BANDIT_WANDER_OUTER_RADIUS)
		c.has_target = true
	} else {
		displacement := c.target - t.pos
		dir := rl.Vector2Normalize(displacement)
		move := dir * BANDIT_SPEED * g_dt
		t.pos += move
		if (rl.Vector2LengthSqr(displacement) < 0.1) {
			c.has_target = false
		}
	}
}
