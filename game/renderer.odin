package game

import "core:math"
import rl "vendor:raylib"

DrawType :: enum {
	DrawSprite,
	DrawRect,
	DrawOutline,
}

RectDrawInfo :: struct {
	pos       : rl.Vector2,
	size      : rl.Vector2,
	rot       : f32,
	origin    : rl.Vector2,

	type      : DrawType,

	colour    : rl.Color,
	sprite    : SpriteType,
	thickness : f32,
}

Renderer :: struct {
	world_rects : [dynamic]RectDrawInfo,
}

make_renderer :: proc() {
	g_renderer.world_rects = make([dynamic]RectDrawInfo)
}

delete_renderer :: proc() {
	delete(g_renderer.world_rects)
}

draw_world_sprite_centre :: #force_inline proc(pos, size : rl.Vector2, sprite : SpriteType, rot : f32 = 0.0) {
	append(&g_renderer.world_rects, RectDrawInfo {
		pos = pos, size = size, rot = rot, origin = 0.5 * size,
		type = .DrawSprite, sprite = sprite
	})
}

draw_world_outline_centre :: #force_inline proc(pos, size : rl.Vector2, colour : rl.Color) {
	append(&g_renderer.world_rects, RectDrawInfo {
		pos = pos, size = size, rot = 0.0, origin = 0.5 * size,
		type = .DrawOutline, colour = colour, thickness = 0.05
	})
}

draw_world_sprite_tl :: #force_inline proc(pos, size : rl.Vector2, sprite : SpriteType, rot : f32 = 0.0) {
	append(&g_renderer.world_rects, RectDrawInfo {
		pos = pos, size = size, rot = rot, origin = {0.0, 0.0},
		type = .DrawSprite, sprite = sprite
	})
}

render :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground({0, 0, 0, 255})
	rl.BeginMode2D(g_camera)

	for s in g_renderer.world_rects {
		switch s.type {
		case .DrawSprite:
			rl.DrawTexturePro(
				g_sprites[s.sprite].texture,
				rl.Rectangle { // Src
					x = 0, y = 0,
					width = f32(g_sprites[s.sprite].width),
					height = f32(g_sprites[s.sprite].height),
				},
				rl.Rectangle { // Dst
					x = s.pos.x, y = s.pos.y,
					width = s.size.x, height = s.size.y
				},
				s.origin, // Origin
				s.rot, // Rotation CW
				{255, 255, 255, 255} // Tint
			)

		case .DrawRect:
			rl.DrawRectanglePro(
				rl.Rectangle {
					x = s.pos.x, y = s.pos.y,
					width = s.size.x, height = s.size.y
				},
				s.origin,
				s.rot,
				s.colour
			)

		case .DrawOutline:
			p1, p2, p3, p4 : rl.Vector2

			cos := math.cos(s.rot)
			sin := math.sin(s.rot)

			p1 = cw_rotation({0.0, 0.0} * s.size + s.pos - s.origin, cos, sin)
			p2 = cw_rotation({1.0, 0.0} * s.size + s.pos - s.origin, cos, sin)
			p3 = cw_rotation({1.0, 1.0} * s.size + s.pos - s.origin, cos, sin)
			p4 = cw_rotation({0.0, 1.0} * s.size + s.pos - s.origin, cos, sin)
			
			// TODO(ALEX): Is using quads a good idea?
			// Maybe gl_lines is better

			rl.DrawLineEx(p1, p2, s.thickness, s.colour) 
			rl.DrawLineEx(p2, p3, s.thickness, s.colour) 
			rl.DrawLineEx(p3, p4, s.thickness, s.colour) 
			rl.DrawLineEx(p4, p1, s.thickness, s.colour) 
		}
	}

	rl.EndMode2D()

	rl.DrawRectangleV(g_ui_pos, g_ui_size, rl.GRAY)

	rl.EndDrawing()

	clear(&g_renderer.world_rects)
}
