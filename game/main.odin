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
INVERSE_UI_ASPECT_RATIO :: (1 / 0.35)

g_settings : Settings

g_renderer : Renderer
g_audio    : AudioContext

g_sprites  : [SpriteType]Sprite

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

g_debug_draw_colliders : bool = false

update :: #force_inline proc() {
	control_component_foreach(update_control_component)

	bandit_king_component_foreach(update_bandit_king_component)
	bandit_component_foreach(update_bandit_component)

	projectile_component_foreach(update_projectile_component)
	target_component_foreach(update_target_component)

	camera_component_foreach(update_camera_component)

	t := get_transform_component(g_player)
	draw_map(g_map, rl.Rectangle {
		x = t.pos.x - 20.0,
		y = t.pos.y - 20.0,
		width = 40.0, height = 40.0
	})

	sprite_component_foreach(update_sprite_component)
	rect_collider_component_foreach(update_rect_collider_component)
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

	g_map = generate_map(rand.uint64(), 1000, 1000)
}

shutdown :: #force_inline proc() {
	delete_map(&g_map)
}


debug :: #force_inline proc() {
	if rl.IsKeyPressed(.F1) {
		g_debug_draw_colliders = !g_debug_draw_colliders
	}
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

	make_audio()
	defer delete_audio()

	if (true) {
		return
	}

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

		draw_rect_centre({0.175, 0.5}, {0.35, 0.35}, rl.RED, .LayerUi)

		debug()
		update()
		render()

		free_all(context.temp_allocator)
	}
}
