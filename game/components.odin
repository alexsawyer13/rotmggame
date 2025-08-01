package game

import rl "vendor:raylib"
import "core:time"
import "core:math"

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

update_target_component :: proc(a : ^Target_Component) {
	if (a.health <= 0) && .Target_Kill_On_Death in a.flags {
		remove_entity(a.entity)
		return
	}

	t := get_transform_component(a.entity)
	if t == nil do return

	// Render health bar
	outline_pos := t.pos + {-t.size.x*0.5 + 0.1, t.size.y*0.5 + 0.1}
	outline_size : rl.Vector2 = {t.size.x - 0.2, 0.1}

	offset : rl.Vector2 = {0.02, 0.02}
	bar_pos := outline_pos + offset
	bar_size := outline_size - 2 * offset

	draw_rect_tl(outline_pos, outline_size, rl.BLACK, .LayerDebug)
	draw_rect_tl(bar_pos, bar_size, rl.RED, .LayerDebug)
	draw_rect_tl(bar_pos, {bar_size.x * f32(a.health) / f32(a.max_health), bar_size.y}, rl.GREEN, .LayerDebug)
}

update_control_component :: #force_inline proc(c : ^Control_Component) {
	t := get_transform_component(c.transform)
	cam := get_camera_component(c.camera)
	if t == nil do return
	if cam == nil do return

	dir : rl.Vector2 = {0.0, 0.0}
	rot : f32 = 0.0
	scr : f32 = 0.0

	cos := math.cos(t.rot * math.RAD_PER_DEG)
	sin := math.sin(t.rot * math.RAD_PER_DEG)

	// x is right and y is down
	// so this is the CW rotation matrix
	// but in this basis, which looks like
	// the CCW matrix in the standard basis
	x_dir : rl.Vector2 = {cos, sin}
	y_dir : rl.Vector2 = {-sin, cos}

	if rl.IsKeyDown(g_settings.right_key) {
		dir.x += x_dir.x
		dir.y += x_dir.y
	}

	if rl.IsKeyDown(g_settings.left_key) {
		dir.x -= x_dir.x
		dir.y -= x_dir.y
	}

	if rl.IsKeyDown(g_settings.down_key) {
		dir.x += y_dir.x
		dir.y += y_dir.y
	}

	if rl.IsKeyDown(g_settings.up_key) {
		dir.x -= y_dir.x
		dir.y -= y_dir.y
	}

	if rl.IsKeyDown(g_settings.cw_key) {
		rot += 1
	}

	if rl.IsKeyDown(g_settings.ccw_key) {
		rot -= 1
	}

	scr = rl.GetMouseWheelMove()

	if !(dir.x == 0.0 && dir.y == 0.0) {
		dir = rl.Vector2Normalize(dir)
		t.pos.x += dir.x * c.speed * g_dt
		t.pos.y += dir.y * c.speed * g_dt
	}

	t.rot += rot * g_settings.rot_speed * g_dt

	cam.zoom = math.clamp(cam.zoom - scr * g_dt * c.scroll_speed, 5, 20)

	if (rl.IsKeyPressed(g_settings.reset_rot_key)) {
		t.rot = 0.0
	}

	if rl.IsMouseButtonPressed(.LEFT) {
		mpos := screen_to_world_space(rl.GetMousePosition())
		dir := rl.Vector2Normalize(mpos - t.pos)
		create_projectile(t.pos, dir, 10.0, 5.0, 20.0, {.Projectile_Hit_Enemy})
	}

	if rl.IsKeyPressed(.SPACE) {
		NUM_PROJECTILES :: 10
		for i in 0..<NUM_PROJECTILES {
			angle : f32 = 2.0 * f32(math.PI) * f32(i) / NUM_PROJECTILES
			create_projectile(t.pos, {math.cos(angle), math.sin(angle)}, 10.0, 5.0, 2.0, {.Projectile_Hit_Enemy})
		}
	}

	if rl.IsKeyPressed(.B) {
		mpos := screen_to_world_space(rl.GetMousePosition())
		create_bandit_pack(mpos)
	}
}
