package game

import "core:fmt"
import "core:math"
import "core:time"
import rl "vendor:raylib"

// TODO(Alex): add_##_component doesn't consider
// whether a component already exists. It will
// add a new one and overlay the old. This isn't
// good. Make sure it deletes old component

TileType :: enum {
	None,
	Dirt,
	Grass
}

Tile :: struct {
	type : TileType
}

Map :: struct {
	width : i32,
	height : i32,
	tiles : []Tile,
}

Settings :: struct {
	window_width  : i32,
	window_height : i32,

	rot_speed : f32,

	up_key : rl.KeyboardKey,
	down_key : rl.KeyboardKey,
	right_key : rl.KeyboardKey,
	left_key : rl.KeyboardKey,
	cw_key : rl.KeyboardKey,
	ccw_key : rl.KeyboardKey,
	reset_rot_key : rl.KeyboardKey
}

g_renderer : Renderer
g_sprites : [SpriteType]Sprite
g_settings : Settings

g_main_camera : rl.Camera2D
g_ecs : Ecs
g_map : Map

g_dt : f32

DEBUG :: true
DEBUG_DRAW_COLLIDERS :: true

create_player :: proc() -> Entity_Handle {
	e : Entity_Handle = make_entity()
	t := add_transform_component(e, {
		pos = {10.0, 10.0},
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
		speed = 10.0,
	})
	add_camera_component(e, {
		transform = t,
		zoom = 100.0,
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

update_transform_component :: #force_inline proc(t : ^Transform_Component) {

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

	// TODO(Alex): Maybe change this to use a
	// mouse to world position function
	// Could be useful to have in future
	if rl.IsMouseButtonPressed(.LEFT) {
		mpos := rl.GetMousePosition()
		screen_centre := rl.Vector2 {f32(g_settings.window_width) * 0.5, f32(g_settings.window_height) * 0.5}
		proj_dir_screen := rl.Vector2Normalize(mpos - screen_centre)
		proj_dir_world := rl.Vector2 {
			cos * proj_dir_screen.x - sin * proj_dir_screen.y,
			sin * proj_dir_screen.x + cos * proj_dir_screen.y
		}

		create_projectile(t.pos, proj_dir_world, 10.0, 5.0)
	}
}

update_follow_component :: proc(c : ^Follow_Component) {
	transform := get_transform_component(c.transform)
	if transform == nil do return
	target := get_transform_component(c.target)
	if target == nil do return

	transform.pos += rl.Vector2Normalize(target.pos - transform.pos) * c.speed * g_dt
}

generate_map :: proc(m : ^Map) {

}

default_settings :: #force_inline proc() {
	g_settings.rot_speed = 100.0
	g_settings.window_width = 1600
	g_settings.window_height = 900
	g_settings.up_key = .W
	g_settings.down_key = .S
	g_settings.right_key = .D
	g_settings.left_key = .A
	g_settings.cw_key = .E
	g_settings.ccw_key = .Q
	g_settings.reset_rot_key = .Z
}

init :: #force_inline proc() {
	g_main_camera.offset = {0.0, 0.0}
	g_main_camera.target = {0.0, 0.0}
	g_main_camera.rotation = 0.0
	g_main_camera.zoom = 100.0

	player := create_player()
	slime1 := create_slime({11.0, 11.0})
	slime2 := create_slime({12.0, 12.0})
	slime3 := create_slime({13.0, 13.0})

	add_follow_component(slime2, {
		transform = get_transform_handle(slime2),
		target = get_transform_handle(player),
		speed = 1.0
	})

	add_follow_component(slime3, {
		transform = get_transform_handle(slime3),
		target = get_transform_handle(player),
		speed = 3.0
	})
}

shutdown :: #force_inline proc() {
	delete(g_map.tiles)
}

update :: #force_inline proc() {
	default_control_system()

	default_projectile_system()
	default_follow_system()

	default_camera_system()
	default_sprite_system()
}

main :: proc() {
	default_settings()

	rl.InitWindow(1600, 900, "rotmggame")
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

		if pause do g_dt = 0
		if rl.IsKeyPressed(.P) do pause = !pause
		
		update()
		render()

		free_all(context.temp_allocator)
	}
}
