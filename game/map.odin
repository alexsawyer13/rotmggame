package game

import "core:fmt"
import "core:math"
import "core:math/noise"
import rl "vendor:raylib"

TileType :: enum {
	Tile_None,
	Tile_Dirt,
	Tile_Grass
}

Map :: struct {
	width : u32,
	height : u32,
	tiles : []TileType,
}

map_set_tile :: #force_inline proc(m : ^Map, x, y : u32, t : TileType) {
	m.tiles[y * m.width + x] = t
}

map_get_tile :: #force_inline proc(m : Map, x, y : u32) -> TileType {
	return m.tiles[y * m.width + x]
}

generate_map :: proc(seed : u64, width, height : u32) -> Map {
	m : Map

	seed : i64 = transmute(i64)seed

	m.width = width
	m.height = height

	m.tiles = make([]TileType, width*height)

	choose_tile :: #force_inline proc(seed : i64, pos : noise.Vec2) -> TileType {
		n := noise.noise_2d(seed, pos * 0.1)
		if n < 0.5 {
			return .Tile_Dirt
		} else {
			return .Tile_Grass
		}
	}

	for x in 0 ..< width {
		for y in 0 ..< height {
			map_set_tile(&m, x, y, choose_tile(seed, {f64(x), f64(y)}))
		}
	}

	return m
}

delete_map :: proc(m : ^Map) {
	delete(m.tiles)
}

draw_map :: proc(m : Map, range : rl.Rectangle) {
	x1 := math.clamp(u32(max(range.x, 0)), 0, m.width)
	y1 := math.clamp(u32(max(range.y, 0)), 0, m.height)
	x2 := math.clamp(u32(range.x + range.width), 0, m.width)
	y2 := math.clamp(u32(range.y + range.height), 0, m.height)

	for x in x1 ..< x2 {
		for y in y1 ..< y2 {
			s : SpriteType
			switch map_get_tile(m, x, y) {
			case .Tile_None:
				s = .Sprite_None
			case .Tile_Dirt:
				s = .Sprite_Dirt
			case .Tile_Grass:
				s = .Sprite_Grass
			}
			draw_world_sprite_tl(rl.Vector2 {f32(x), f32(y)}, {1.0, 1.0}, s)
		}
	}
}
