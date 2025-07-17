package game

import rl "vendor:raylib"

SpriteDrawInfo :: struct {
	pos : rl.Vector2,
	size : rl.Vector2,
	sprite : SpriteType,
	rot : f32,
}

RectDrawInfo :: struct {
	pos : rl.Vector2,
	size : rl.Vector2,
	colour : rl.Color,
	rot : f32,
}

Renderer :: struct {
	world_sprites : [dynamic]SpriteDrawInfo,
	debug_outlines : [dynamic]RectDrawInfo
}

make_renderer :: proc() {
	g_renderer.world_sprites = make([dynamic]SpriteDrawInfo)
	g_renderer.debug_outlines = make([dynamic]RectDrawInfo)
}

delete_renderer :: proc() {
	delete(g_renderer.world_sprites)
	delete(g_renderer.debug_outlines)
}

draw_world_sprite_centre :: #force_inline proc(pos, size : rl.Vector2, sprite : SpriteType, rot : f32 = 0.0) {
	append(&g_renderer.world_sprites, SpriteDrawInfo {
		pos, size, sprite, rot
	})
}

draw_debug_outline_centre :: #force_inline proc(pos, size : rl.Vector2, colour : rl.Color) {
	append(&g_renderer.debug_outlines, RectDrawInfo {
		pos - 0.5 * size, size, colour, 0.0
	})
}

render :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground({255, 0, 255, 255})
	rl.BeginMode2D(g_main_camera)

	for s in g_renderer.world_sprites {
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
			s.size * 0.5, // Origin
			s.rot, // Rotation CW
			{255, 255, 255, 255} // Tint
		)
	}

	when DEBUG {
	for s in g_renderer.debug_outlines {
		rl.DrawRectangleLinesEx( rl.Rectangle ({
				x = s.pos.x, y = s.pos.y,
				width = s.size.x, height = s.size.y
			}),
			0.05,
			s.colour
		)
	}
	}

	rl.EndMode2D()
	rl.EndDrawing()

	clear(&g_renderer.world_sprites)
	clear(&g_renderer.debug_outlines)
}
