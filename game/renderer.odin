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
	debug_rects : [dynamic]RectDrawInfo
}

make_renderer :: proc() {
	g_renderer.world_sprites = make([dynamic]SpriteDrawInfo)
	g_renderer.debug_rects = make([dynamic]RectDrawInfo)
}

delete_renderer :: proc() {
	delete(g_renderer.world_sprites)
	delete(g_renderer.debug_rects)
}

draw_world_sprite_centre :: #force_inline proc(pos, size : rl.Vector2, sprite : SpriteType, rot : f32 = 0.0) {
	append(&g_renderer.world_sprites, SpriteDrawInfo {
		pos, size, sprite, rot
	})
}

draw_debug_rect_tl :: #force_inline proc(pos, size : rl.Vector2, colour : rl.Color, rot : f32 = 0.0) {
	append(&g_renderer.debug_rects, RectDrawInfo {
		pos, size, colour, rot
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
	for s in g_renderer.debug_rects {
		rl.DrawRectangleV(
			s.pos, s.size, s.colour
		)
	}
	}

	rl.EndMode2D()
	rl.EndDrawing()

	clear(&g_renderer.world_sprites)
}
