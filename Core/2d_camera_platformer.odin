package platformer

/*******************************************************************************************
*
*   raylib [core] example - 2D Camera platformer
*
*   Example originally created with raylib 2.5, last time updated with raylib 3.0
*
*   Example contributed by arvyy (@arvyy) and reviewed by Ramon Santamaria (@raysan5)
*
*   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
*   BSD-like license that allows static linking with closed source software
*
*   Copyright (c) 2019-2024 arvyy (@arvyy)
*   Translation to Odin by Evan Martinez (@Nave55)
*
********************************************************************************************/

import lg "core:math/linalg"
import rl "vendor:raylib"

G :: 400
PLAYER_JUMP_SPD: f32 : 350
PLAYER_HOR_SPD: f32 : 200
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450

Player :: struct {
	position: rl.Vector2,
	speed:    f32,
	canJump:  bool,
}

EnvItem :: struct {
	rect:     rl.Rectangle,
	blocking: i32,
	color:    rl.Color,
}

GameData :: struct {
	player:              Player,
	env_items:           [5]EnvItem,
	camera:              rl.Camera2D,
	camera_descriptions: [5]cstring,
	camera_option:       int,
	delta:               f32,
}

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "raylib [core] example - 2d camera")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	g_data := initGame()

	// function ptrs for cameras
	camera_ptrs := [5]proc(_: ^GameData) {
		updateCameraCenter,
		updateCameraCenterClamp,
		updateCameraSmooth,
		updateCameraHorizontalLand,
		updateCameraScreenEdge,
	}

	for !rl.WindowShouldClose() do updateGame(&g_data, camera_ptrs[:])
}

initGame :: proc() -> (game_data: GameData) {
	game_data.player = {{400, 280}, 0, false}

	game_data.env_items = {
		{{0, 0, 1000, 400}, 0, rl.LIGHTGRAY},
		{{0, 400, 1000, 200}, 1, rl.GRAY},
		{{300, 200, 400, 10}, 1, rl.GRAY},
		{{250, 300, 100, 10}, 1, rl.GRAY},
		{{650, 300, 100, 10}, 1, rl.GRAY},
	}

	game_data.camera.target = game_data.player.position
	game_data.camera.offset = {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
	game_data.camera.rotation = 0
	game_data.camera.zoom = 1

	game_data.camera_descriptions = {
		"Follow player center",
		"Follow player center, but clamp to map edges",
		"Follow player center; smoothed",
		"Follow player center horizontally; update player center vertically after landing",
		"Player push camera on getting too close to screen edge",
	}

	game_data.camera_option = 0

	return game_data
}

controls :: proc(game_data: ^GameData) {
    using game_data

	delta = rl.GetFrameTime()
	camera.zoom += rl.GetMouseWheelMove() * .05

	if camera.zoom > 3 do camera.zoom = 3
	else if camera.zoom < .25 do camera.zoom = .25

	if rl.IsKeyPressed(.R) {
		camera.zoom = 1
		player.position = {400, 280}
	}

	if rl.IsKeyPressed(.C) do camera_option = (camera_option + 1) % len(camera_descriptions)
}

updatePlayer :: proc(game_data: ^GameData) {
	using game_data

	if rl.IsKeyDown(.LEFT) do player.position.x -= PLAYER_HOR_SPD * delta
	if rl.IsKeyDown(.RIGHT) do player.position.x += PLAYER_HOR_SPD * delta
	if rl.IsKeyDown(.SPACE) && player.canJump {
		player.speed = -PLAYER_JUMP_SPD
		player.canJump = false
	}

	hit_obstacle := false

	for &i in env_items {
		if i.blocking == 1 &&
		   i.rect.x <= player.position.x &&
		   i.rect.x + i.rect.width >= player.position.x &&
		   i.rect.y >= player.position.y &&
		   i.rect.y <= player.position.y + player.speed * delta {
			hit_obstacle = true
			player.speed = 0
			player.position.y = i.rect.y
		}
	}

	if !hit_obstacle {
		player.position.y += player.speed * delta
		player.speed += G * delta
		player.canJump = false
	} else do player.canJump = true
}

drawGame :: proc(game_data: GameData) {
	using game_data

	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.LIGHTGRAY)

	{
		rl.BeginMode2D(camera)
		defer rl.EndMode2D()
		for i in env_items do rl.DrawRectangleRec(i.rect, i.color)
		rl.DrawRectangleRec({player.position.x - 20, player.position.y - 40, 40, 40}, rl.RED)
	}

	rl.DrawText("Controls:", 20, 20, 10, rl.BLACK)
	rl.DrawText("- Right/Left to move", 40, 40, 10, rl.DARKGRAY)
	rl.DrawText("- Space to jump", 40, 60, 10, rl.DARKGRAY)
	rl.DrawText("- Mouse Wheel to Zoom in-out, R to reset zoom", 40, 80, 10, rl.DARKGRAY)
	rl.DrawText("- C to change camera mode", 40, 100, 10, rl.DARKGRAY)
	rl.DrawText("Current camera mode:", 20, 120, 10, rl.BLACK)
	rl.DrawText(camera_descriptions[camera_option], 40, 140, 10, rl.DARKGRAY)
}

updateCameraCenter :: proc(game_data: ^GameData) {
	game_data.camera.offset = {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
	game_data.camera.target = game_data.player.position
}

updateCameraCenterClamp :: proc(game_data: ^GameData) {
	using game_data

	camera.target = player.position
	camera.offset = {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
	min_x, min_y, max_x, max_y: f32 = 1000, 1000, -1000, -1000

	for &i in env_items {
		min_x = min(i.rect.x, min_x)
		max_x = max(i.rect.x + i.rect.width, max_x)
		min_y = min(i.rect.y, min_y)
		max_y = max(i.rect.y + i.rect.height, max_y)
	}

	max := rl.GetWorldToScreen2D({max_x, max_y}, camera)
	min := rl.GetWorldToScreen2D({min_x, min_y}, camera)

	if max.x < SCREEN_WIDTH do camera.offset.x = SCREEN_WIDTH - (max.x - SCREEN_WIDTH / 2)
	if max.y < SCREEN_HEIGHT do camera.offset.y = SCREEN_HEIGHT - (max.y - SCREEN_HEIGHT / 2)
	if min.x > 0 do camera.offset.x = SCREEN_WIDTH / 2 - min.x
	if min.y > 0 do camera.offset.y = SCREEN_HEIGHT / 2 - min.y
}

updateCameraSmooth :: proc(game_data: ^GameData) {
	using game_data

	min_speed: f32 = 30
	min_effect_length: f32 = 10
	fraction_speed: f32 = .8

	camera.offset = {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
	diff := player.position - camera.target
	length := lg.length(diff)

	if length > min_effect_length {
		speed := max(fraction_speed * length, min_speed)
		camera.target = camera.target + (diff * (speed * delta / length))
	}
}

updateCameraHorizontalLand :: proc(game_data: ^GameData) {
	using game_data

	@(static) even_out_speed: f32 = 700
	@(static) evening_out := false
	@(static) even_out_target: f32

	camera.offset = {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
	camera.target.x = player.position.x

	if evening_out {
		if even_out_target > camera.target.y {
			camera.target.y += even_out_speed * delta

			if camera.target.y > even_out_target {
				camera.target.y = even_out_target
				evening_out = false
			}
		} else {
			camera.target.y -= even_out_speed * delta

			if camera.target.y < even_out_target {
				camera.target.y = even_out_target
				evening_out = false
			}
		}
	} else {
		if (player.canJump && player.speed == 0) && (player.position.y != camera.target.y) {
			evening_out = true
			even_out_target = player.position.y
		}
	}
}

updateCameraScreenEdge :: proc(game_data: ^GameData) {
	using game_data

	@(static) bbox: rl.Vector2 = {0.2, 0.2}

	bbox_world_min: rl.Vector2 = rl.GetScreenToWorld2D(
		{(1 - bbox.x) * 0.5 * SCREEN_WIDTH, (1 - bbox.y) * 0.5 * SCREEN_HEIGHT},
		camera,
	)
	bbox_world_max: rl.Vector2 = rl.GetScreenToWorld2D(
		{(1 + bbox.x) * 0.5 * SCREEN_WIDTH, (1 + bbox.y) * 0.5 * SCREEN_HEIGHT},
		camera,
	)
	camera.offset = {(1 - bbox.x) * 0.5 * SCREEN_WIDTH, (1 - bbox.y) * 0.5 * SCREEN_HEIGHT}

	if player.position.x < bbox_world_min.x do camera.target.x = player.position.x
	if player.position.y < bbox_world_min.y do camera.target.y = player.position.y
	if player.position.x > bbox_world_max.x do camera.target.x = bbox_world_min.x + (player.position.x - bbox_world_max.x)
	if player.position.y > bbox_world_max.y do camera.target.y = bbox_world_min.y + (player.position.y - bbox_world_max.y)
}

updateGame :: proc(game_data: ^GameData, camera_ptrs: []proc(_: ^GameData)) {
	controls(game_data)
	updatePlayer(game_data)
	camera_ptrs[game_data.camera_option](game_data) // calls the function ptr based on the int value of camera_option
	drawGame(game_data^)
}
