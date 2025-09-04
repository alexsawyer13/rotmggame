package game

import "core:math/rand"
import "core:fmt"
import "core:math"
import "core:time"
import "core:os"

import sdl "vendor:sdl3"
import rl "vendor:raylib"

// TODO(Alex): Citations!
// https://hamdy-elzanqali.medium.com/let-there-be-triangles-sdl-gpu-edition-bd82cf2ef615
// https://moonside.games/posts/sdl-gpu-sprite-batcher/

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

g_window   : ^sdl.Window
g_device   : ^sdl.GPUDevice
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

// Returns true if window should close
// Returns false if not
poll_events :: #force_inline proc() -> bool {
	event : sdl.Event

	for sdl.PollEvent(&event) {
		if event.type == .WINDOW_CLOSE_REQUESTED {
			return true
		}
	}

	return false
}

main :: proc() {
	fmt.println("Hello, world!")

	if !sdl.Init({}) {
		fmt.println("[ERROR] Failed to initialise SDL")
		return
	}
	fmt.println("[INFO] Initialised SDL")

	g_window := sdl.CreateWindow(
		"Test window!",
		g_settings.default_window_width,
		g_settings.default_window_height,
		{.RESIZABLE}
	)

	if g_window == nil {
		fmt.println("[ERROR] Failed to create window")
		return
	}
	defer sdl.DestroyWindow(g_window)

	g_device = sdl.CreateGPUDevice({.SPIRV}, true, nil)
	if g_device == nil {
		fmt.println("[ERROR] Failed to create GPU device")
		return
	}
	defer sdl.DestroyGPUDevice(g_device)

	if !sdl.ClaimWindowForGPUDevice(g_device, g_window) {
		fmt.println("[ERROR] Failed to link GPU to window")
		return
	}

	vertices : []f32 = {
	    0.0, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0,     // Top vertex
    	-0.5, -0.5, 0.0, 1.0, 1.0, 0.0, 1.0,   // Bottom left vertex
    	0.5, -0.5, 0.0, 1.0, 0.0, 1.0, 1.0     // Bottom right vertex
	}
	
	buffer_create_info : sdl.GPUBufferCreateInfo = {
		size = size_of(vertices),
		usage = {.VERTEX}
	}
	vertex_buffer := sdl.CreateGPUBuffer(g_device, buffer_create_info)
	if vertex_buffer == nil {
		fmt.println("[ERROR] Failed to create vertex buffer")
		return
	}
	defer sdl.ReleaseGPUBuffer(g_device, vertex_buffer)

	transfer_buffer_create_info : sdl.GPUTransferBufferCreateInfo = {
		size = size_of(vertices),
		usage = .UPLOAD
	}
	transfer_buffer := sdl.CreateGPUTransferBuffer(g_device, transfer_buffer_create_info)
	if transfer_buffer == nil {
		fmt.println("[ERROR] Failed to create transfer buffer")
		return
	}
	defer sdl.ReleaseGPUTransferBuffer(g_device, transfer_buffer)

	ptr := sdl.MapGPUTransferBuffer(g_device, transfer_buffer, false)
	sdl.memcpy(ptr, raw_data(vertices), size_of(vertices))
	sdl.UnmapGPUTransferBuffer(g_device, transfer_buffer) 

	cmd_buffer := sdl.AcquireGPUCommandBuffer(g_device)
	copy_pass := sdl.BeginGPUCopyPass(cmd_buffer)

	transfer_buffer_location : sdl.GPUTransferBufferLocation = {
		transfer_buffer = transfer_buffer,
		offset = 0
	}

	gpu_buffer_region : sdl.GPUBufferRegion = {
		buffer = vertex_buffer,
		size = size_of(vertices),
		offset = 0
	}

	sdl.UploadToGPUBuffer(copy_pass, transfer_buffer_location, gpu_buffer_region, true)

	sdl.EndGPUCopyPass(copy_pass)
	if !sdl.SubmitGPUCommandBuffer(cmd_buffer) {
		fmt.println("[ERROR] Failed to subbmit GPU command buffer")
		return
	}

	vertex_shader_src, vert_res := os.read_entire_file_from_filename("shaders/vertex.spv")
	if !vert_res {
		fmt.println("[ERROR] Failed to load vertex shader file")
		return
	}
	
	fragment_shader_src, frag_res := os.read_entire_file_from_filename("shaders/fragment.spv")
	if !frag_res {
		fmt.println("[ERROR] Failed to load fragment shader file")
		return
	}

	vertex_shader_create_info : sdl.GPUShaderCreateInfo	= {
		code = raw_data(vertex_shader_src),
		code_size = len(vertex_shader_src),
		entrypoint = "main",
		format = {.SPIRV},
		stage = .VERTEX,
		num_samplers = 0,
		num_storage_buffers = 0,
  		num_storage_textures = 0,
  		num_uniform_buffers = 0,
	}

	fragment_shader_create_info : sdl.GPUShaderCreateInfo	= {
		code = raw_data(fragment_shader_src),
		code_size = len(fragment_shader_src),
		entrypoint = "main",
		format = {.SPIRV},
		stage = .FRAGMENT,
		num_samplers = 0,
		num_storage_buffers = 0,
  		num_storage_textures = 0,
  		num_uniform_buffers = 0,
	}

	vertex_shader := sdl.CreateGPUShader(g_device, vertex_shader_create_info);
	if vertex_shader == nil {
		fmt.println("[ERROR] Failed to create vertex shader")
		return
	}

	fragment_shader := sdl.CreateGPUShader(g_device, fragment_shader_create_info);
	if fragment_shader == nil {
		fmt.println("[ERROR] Failed to create fragment shader")
		return
	}

	delete(vertex_shader_src)
	delete(fragment_shader_src)


	vertex_buffer_desc : sdl.GPUVertexBufferDescription = {
		slot = 0,
		input_rate = .VERTEX,
		instance_step_rate = 0,
		pitch = 7 * size_of(f32),
	}

	graphics_pipeline_create_info : sdl.GPUGraphicsPipelineCreateInfo = {
		vertex_shader = vertex_shader,
		fragment_shader = fragment_shader,
		primitive_type = .TRIANGLELIST
	}

	vertex_buffer_description : sdl.GPUVertexBufferDescription = {
		slot = 0,
		input_rate = .VERTEX,
		instance_step_rate = 0,
		pitch = 7 * size_of(f32)
	}

	graphics_pipeline_create_info.vertex_input_state.num_vertex_buffers = 1
	graphics_pipeline_create_info.vertex_input_state.vertex_buffer_descriptions = &vertex_buffer_description

	vertex_attributes : [2]sdl.GPUVertexAttribute = {
			sdl.GPUVertexAttribute { // a_position
				buffer_slot = 0,
				location = 0,
				format = .FLOAT3,
				offset = 0
			},
			sdl.GPUVertexAttribute { // a_colour
				buffer_slot = 0,
				location = 1,
				format = .FLOAT4,
				offset = size_of(f32) * 3
			}
	}

	graphics_pipeline_create_info.vertex_input_state.num_vertex_attributes = 2
	graphics_pipeline_create_info.vertex_input_state.vertex_attributes = raw_data(&vertex_attributes)

	colour_target_description : sdl.GPUColorTargetDescription = {
		format = sdl.GetGPUSwapchainTextureFormat(g_device, g_window)
	}

	graphics_pipeline_create_info.target_info.num_color_targets = 1
	graphics_pipeline_create_info.target_info.color_target_descriptions = &colour_target_description

	graphics_pipeline := sdl.CreateGPUGraphicsPipeline(
		g_device,
		graphics_pipeline_create_info
	)
	defer sdl.ReleaseGPUGraphicsPipeline(g_device, graphics_pipeline)

	sdl.ReleaseGPUShader(g_device, vertex_shader)
	sdl.ReleaseGPUShader(g_device, fragment_shader)

	for {
		if poll_events() {
			fmt.println("[INFO] Window closing")
			return
		}

		cmd_buffer := sdl.AcquireGPUCommandBuffer(g_device)
		if cmd_buffer == nil {
			fmt.println("[ERROR] Failed to acquire command buffer")
			return
		}

		swapchain_texture : ^sdl.GPUTexture
		width, height : u32

		if !sdl.WaitAndAcquireGPUSwapchainTexture(cmd_buffer, g_window, &swapchain_texture, &width, &height) {
			fmt.println("[INFO] No swapchain")
			if !sdl.SubmitGPUCommandBuffer(cmd_buffer) {
				fmt.println("[ERROR] Failed to submit command buffer")
				return
			}
			continue
		}
		
		colour_target : sdl.GPUColorTargetInfo = {
			clear_color = {0.7, 0.7, 0.7, 1.0},
			load_op = .CLEAR,
			store_op = .STORE,
			texture = swapchain_texture,
		}

		render_pass := sdl.BeginGPURenderPass(cmd_buffer, &colour_target, 1, nil)

		if render_pass == nil {
			fmt.println("[ERROR] Failed to begin render pass")
			return
		}

		sdl.EndGPURenderPass(render_pass)

		if !sdl.SubmitGPUCommandBuffer(cmd_buffer) {
			fmt.println("[ERROR] Failed to submit command buffer")
			return
		}
	}

	if (true) do return

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
