package game

import "core:math/rand"
import "core:fmt"
import "core:math"
import "core:time"
import rl "vendor:raylib"

// TODO(Alex): add_##_component doesn't consider
// whether a component already exists. It will
// add a new one and overlay the old. This isn't
// good. Make sure it deletes old component

Settings :: struct {
	default_window_width  : i32,
	default_window_height : i32,

	rot_speed : f32,

	up_key : rl.KeyboardKey,
	down_key : rl.KeyboardKey,
	right_key : rl.KeyboardKey,
	left_key : rl.KeyboardKey,
	cw_key : rl.KeyboardKey,
	ccw_key : rl.KeyboardKey,
	reset_rot_key : rl.KeyboardKey
}

UI_ASPECT_RATIO :: 0.35

g_renderer : Renderer
g_sprites : [SpriteType]Sprite
g_settings : Settings

g_window_width : i32
g_window_height : i32
g_window_size : rl.Vector2
g_window_half_size : rl.Vector2

g_viewport_pos : rl.Vector2
g_viewport_size : rl.Vector2
g_viewport_half_size : rl.Vector2
g_ui_pos : rl.Vector2
g_ui_size : rl.Vector2

g_camera : rl.Camera2D
g_ecs : Ecs
g_map : Map

g_player : Entity_Handle

g_dt : f32

DEBUG_DRAW_COLLIDERS :: false

create_player :: proc() -> Entity_Handle {
	e : Entity_Handle = make_entity()
	t := add_transform_component(e, {
		pos = {0.0, 0.0},
		rot = 0.0,
		size = {1.0, 1.0}
	})
	add_rect_collider_component(e, {
		entity = e,
		transform = t,
		tags = {.Collider_Player}
	})
	add_sprite_component(e, {
		transform = t,
		sprite = .Sprite_Wizard
	})

	add_control_component(e, {
		transform = t,
		speed = 3.0,
	})
	add_camera_component(e, {
		transform = t,
		zoom = 10.0,
		main_camera = true
	})
	return e
}

create_slime :: proc(pos : rl.Vector2) -> Entity_Handle {
	e : Entity_Handle = make_entity()
	t := add_transform_component(e, {
		pos = pos,
		size = {0.8, 0.8}
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
	return e
}

update_control_component :: #force_inline proc(c : ^Control_Component) {
	t : ^Transform_Component = get_transform_component(c.transform)
	if t == nil do return

	dir : rl.Vector2 = {0.0, 0.0}
	rot : f32 = 0.0

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

	if !(dir.x == 0.0 && dir.y == 0.0) {
		dir = rl.Vector2Normalize(dir)
		t.pos.x += dir.x * c.speed * g_dt
		t.pos.y += dir.y * c.speed * g_dt
	}

	t.rot += rot * g_settings.rot_speed * g_dt

	if (rl.IsKeyPressed(g_settings.reset_rot_key)) {
		t.rot = 0.0
	}

	if rl.IsMouseButtonPressed(.LEFT) {
		mpos := screen_to_world_space(rl.GetMousePosition())
		dir := rl.Vector2Normalize(mpos - t.pos)
		create_projectile(t.pos, dir, 10.0, 5.0)
	}

	if rl.IsKeyPressed(.SPACE) {
		NUM_PROJECTILES :: 10
		for i in 0..<NUM_PROJECTILES {
			angle : f32 = 2.0 * f32(math.PI) * f32(i) / NUM_PROJECTILES
			create_projectile(t.pos, {math.cos(angle), math.sin(angle)}, 10.0, 5.0)
		}
	}
}

update_follow_component :: proc(c : ^Follow_Component) {
	transform := get_transform_component(c.transform)
	if transform == nil do return
	target := get_transform_component(c.target)
	if target == nil do return

	transform.pos += rl.Vector2Normalize(target.pos - transform.pos) * c.speed * g_dt
}


default_settings :: #force_inline proc() {
	g_settings.rot_speed = 100.0
	g_settings.default_window_width = 1280
	g_settings.default_window_height = 720
	g_settings.up_key = .W
	g_settings.down_key = .S
	g_settings.right_key = .D
	g_settings.left_key = .A
	g_settings.cw_key = .E
	g_settings.ccw_key = .Q
	g_settings.reset_rot_key = .Z
}

init :: #force_inline proc() {
	g_camera.offset = {0.0, 0.0}
	g_camera.target = {0.0, 0.0}
	g_camera.rotation = 0.0
	g_camera.zoom = 100.0

	player := create_player()
	slime1 := create_slime({1.0, 1.0})
	slime2 := create_slime({2.0, 2.0})
	slime3 := create_slime({3.0, 3.0})

	add_follow_component(slime2, {
		transform = get_transform_handle(slime2),
		target = get_transform_handle(player),
		speed = 1.0
	})

	add_follow_component(slime3, {
		transform = get_transform_handle(slime3),
		target = get_transform_handle(player),
		speed = 2.0
	})

	g_map = generate_map(rand.uint64(), 1000, 1000)
}

shutdown :: #force_inline proc() {
	delete_map(&g_map)
}

update :: #force_inline proc() {
	control_component_foreach(update_control_component)

	projectile_component_foreach(update_projectile_component)
	follow_component_foreach(update_follow_component)

	rect_collider_component_foreach(update_rect_collider_component)

	camera_component_foreach(update_camera_component)
	t := get_transform_component(g_player)
	draw_map(g_map, rl.Rectangle {
		x = t.pos.x - 20.0,
		y = t.pos.y - 20.0,
		width = 40.0, height = 40.0
	})
	sprite_component_foreach(update_sprite_component)
}

update_screen_size :: proc(width, height : i32) {
	g_window_width = width
	g_window_height = height

	g_window_size = {f32(g_window_width), f32(g_window_height)}
	g_window_half_size = g_window_size * 0.5			

	g_ui_size = {UI_ASPECT_RATIO * g_window_size.y, g_window_size.y}
	g_ui_pos = {g_window_size.x - g_ui_size.x, 0.0}

	g_viewport_size = {g_window_size.x - g_ui_size.x, g_window_size.y}
	g_viewport_half_size = 0.5 * g_viewport_size
	g_viewport_pos = {0.0, 0.0}
}

main :: proc() {
	default_settings()

	update_screen_size(g_settings.default_window_width, g_settings.default_window_height)

	rl.InitWindow(g_window_width, g_window_height, "rotmggame")
	defer rl.CloseWindow()

	make_renderer()
	defer delete_renderer()

	g_sprites = make_sprites()
	defer delete_sprites(g_sprites)
	
	make_ecs()
	defer delete_ecs()

	init()

	pause : bool = false

	for !rl.WindowShouldClose() {
		g_dt = rl.GetFrameTime()
		
		if rl.IsWindowResized() {
			update_screen_size(rl.GetScreenWidth(), rl.GetScreenHeight())
		}

		if pause do g_dt = 0
		if rl.IsKeyPressed(.P) do pause = !pause
		
		update()
		render()

		free_all(context.temp_allocator)
	}
}
