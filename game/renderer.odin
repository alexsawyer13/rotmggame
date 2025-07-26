package game

import "core:math"
import rl "vendor:raylib"

DrawType :: enum {
	DrawSprite,
	DrawRect,
	DrawOutline,
}

DrawLayer :: enum {
	LayerWorld,
	LayerUi,
	LayerDebug
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
	rects : [DrawLayer][dynamic]RectDrawInfo,
}

make_renderer :: proc() {
	for layer in DrawLayer {
		g_renderer.rects[layer] = make([dynamic]RectDrawInfo)
	}
}

delete_renderer :: proc() {
	for layer in DrawLayer {
		delete(g_renderer.rects[layer])
	}
}

draw_sprite_centre :: #force_inline proc(pos, size : rl.Vector2, sprite : SpriteType, layer : DrawLayer, rot : f32 = 0.0) {
	append(&g_renderer.rects[layer], RectDrawInfo {
		pos = pos, size = size, rot = rot, origin = 0.5 * size,
		type = .DrawSprite, sprite = sprite
	})
}

draw_rect_centre :: #force_inline proc(pos, size : rl.Vector2, colour : rl.Color, layer : DrawLayer, rot : f32 = 0.0) {
	append(&g_renderer.rects[layer], RectDrawInfo {
		pos = pos, size = size, rot = rot, origin = 0.5 * size,
		type = .DrawRect, colour = colour
	})
}

draw_rect_tl :: #force_inline proc(pos, size : rl.Vector2, colour : rl.Color, layer : DrawLayer, rot : f32 = 0.0) {
	append(&g_renderer.rects[layer], RectDrawInfo {
		pos = pos, size = size, rot = rot, origin = {0.0, 0.0},
		type = .DrawRect, colour = colour
	})
}

draw_outline_centre :: #force_inline proc(pos, size : rl.Vector2, colour : rl.Color, layer : DrawLayer, rot : f32 = 0.0) {
	append(&g_renderer.rects[layer], RectDrawInfo {
		pos = pos, size = size, rot = rot, origin = 0.5 * size,
		type = .DrawOutline, colour = colour, thickness = 0.05
	})
}

draw_sprite_tl :: #force_inline proc(pos, size : rl.Vector2, sprite : SpriteType, layer : DrawLayer, rot : f32 = 0.0) {
	append(&g_renderer.rects[layer], RectDrawInfo {
		pos = pos, size = size, rot = rot, origin = {0.0, 0.0},
		type = .DrawSprite, sprite = sprite
	})
}

render :: proc() {
	render_layer :: proc(layer : DrawLayer, transform : proc(rl.Vector2) -> rl.Vector2) {
		for s in g_renderer.rects[layer] {
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
	}

	identity :: proc(v : rl.Vector2) -> rl.Vector2 {
		return v
	}

	// UI will be a rect of size Ratio x 1 (i.e. 0.35 x 1)
	// This converts these into pixel coordinates
	ui :: proc(v : rl.Vector2) -> rl.Vector2 {
		return {
			g_ui_size.y * v.y,
			g_ui_size.x * v.x * INVERSE_UI_ASPECT_RATIO,
		}
	}

	rl.BeginDrawing()
	rl.ClearBackground({0, 0, 0, 255})
	rl.BeginMode2D(g_camera)
	render_layer(.LayerWorld, identity)
	render_layer(.LayerDebug, identity)
	rl.EndMode2D()
	rl.DrawRectangleV(g_ui_pos, g_ui_size, rl.GRAY)
	render_layer(.LayerUi, ui)
	rl.EndDrawing()

	for layer in DrawLayer {
		clear(&g_renderer.rects[layer])
	}
}
