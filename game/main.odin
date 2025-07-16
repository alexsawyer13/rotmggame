package game

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Sprite :: struct {
	width : i32,
	height : i32,
	texture : rl.Texture2D,
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
}

g_ecs : Ecs
g_sprites : [SpriteType]Sprite
g_settings : Settings

g_main_camera : rl.Camera2D

g_dt : f32

create_player :: proc() -> Entity_Handle {
	player : Entity_Handle = make_entity()
	add_transform_component(player, {
		pos = {10.0, 10.0},
		rot = 0.0,
		size = {1.0, 1.0}
	})
	add_sprite_component(player, {
		transform = get_transform_handle(player),
		sprite = .Sprite_Wizard
	})
	add_control_component(player, {
		transform = get_transform_handle(player),
		speed = 10.0,
	})
	add_camera_component(player, {
		transform = get_transform_handle(player),
		zoom = 100.0,
		main_camera = true
	})
	return player
}

create_slime :: proc(pos : rl.Vector2) -> Entity_Handle {
	slime : Entity_Handle = make_entity()
	add_transform_component(slime, {
		pos = pos,
		size = {0.8, 0.8}
	})
	add_sprite_component(slime, {
		transform = get_transform_handle(slime),
		sprite = .Sprite_Slime,
	})
	return slime
}

draw_sprite_centre :: proc(pos : rl.Vector2, size : rl.Vector2, sprite : SpriteType, rot : f32 = 0.0) {
	rl.DrawTexturePro(
		g_sprites[sprite].texture,
		rl.Rectangle { // Src
			x = 0, y = 0,
			width = f32(g_sprites[sprite].width),
			height = f32(g_sprites[sprite].height),
		},
		rl.Rectangle { // Dst
			x = pos.x, y = pos.y,
			width = size.x, height = size.y
		},
		{0.0, 0.0}, // Origin
		rot, // Rotation
		{255, 255, 255, 255} // Tint
	)
}

update_transform_component :: #force_inline proc(t : ^Transform_Component) {

}

update_sprite_component :: #force_inline proc(s : ^Sprite_Component) {
	t : ^Transform_Component = get_transform_component(s.transform)
	if t == nil do return
	draw_sprite_centre(t.pos, t.size, s.sprite, -t.rot)
}

update_control_component :: #force_inline proc(c : ^Control_Component) {
	t : ^Transform_Component = get_transform_component(c.transform)
	if t == nil do return

	dir : rl.Vector2 = {0.0, 0.0}
	rot : f32 = 0.0

	cos := math.cos(t.rot * math.RAD_PER_DEG)
	sin := math.sin(t.rot * math.RAD_PER_DEG)

	x_dir : rl.Vector2 = {cos, -sin}
	y_dir : rl.Vector2 = {sin, cos}

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
		rot -= 1
	}

	if rl.IsKeyDown(g_settings.ccw_key) {
		rot += 1
	}

	if !(dir.x == 0.0 && dir.y == 0.0) {
		dir = rl.Vector2Normalize(dir)
		t.pos.x += dir.x * c.speed * g_dt
		t.pos.y += dir.y * c.speed * g_dt
	}

	t.rot += rot * g_settings.rot_speed * g_dt
}

update_camera_component :: #force_inline proc(c : ^Camera_Component) {
	if c.main_camera {
		g_main_camera.target = get_transform_component(c.transform).pos
		g_main_camera.rotation = get_transform_component(c.transform).rot
		g_main_camera.offset = {
			f32(g_settings.window_width) * 0.5,
			f32(g_settings.window_height) * 0.5
		}
	}
}

set_main_camera :: proc(h : Camera_Handle) {
	cam := get_camera_component(h)
	if cam == nil {
		panic("Setting main camera to a non existent camera!")
	}

	for &c in g_ecs.camera_components.items {
		if !c.removed do c.item.main_camera = false
	}

	cam.main_camera = true
}

init :: #force_inline proc() {
	g_settings.rot_speed = 100.0
	g_settings.window_width = 1600
	g_settings.window_height = 900
	g_settings.up_key = .W
	g_settings.down_key = .S
	g_settings.right_key = .D
	g_settings.left_key = .A
	g_settings.cw_key = .E
	g_settings.ccw_key = .Q
	
	g_main_camera.offset = {0.0, 0.0}
	g_main_camera.target = {0.0, 0.0}
	g_main_camera.rotation = 0.0
	g_main_camera.zoom = 100.0

	player := create_player()
	slime1 := create_slime({11.0, 11.0})
	slime2 := create_slime({12.0, 12.0})
	slime3 := create_slime({13.0, 13.0})

	add_camera_component(slime2, {
		transform = get_transform_handle(slime2),
		zoom = 100.0,
		main_camera = false,
	})
}

update :: #force_inline proc() {
	control_system()
	camera_system()
}

draw :: #force_inline proc() {
	rl.BeginDrawing()
	rl.ClearBackground({255, 0, 255, 255})
	rl.BeginMode2D(g_main_camera)

	sprite_system()

	rl.EndMode2D()
	rl.EndDrawing()
}

main :: proc() {

	rl.InitWindow(g_settings.window_width, g_settings.window_height, "rotmggame")
	defer rl.CloseWindow()

	g_sprites = make_sprites()
	defer delete_sprites(g_sprites)

	init()

	for !rl.WindowShouldClose() {
		g_dt = rl.GetFrameTime()
		update()
		draw()
	}
}
