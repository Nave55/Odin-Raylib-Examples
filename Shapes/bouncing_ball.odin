package bouncing_ball

/*******************************************************************************************
*
*   raylib [shapes] example - bouncing ball
*
*   Example originally created with raylib 2.5, last time updated with raylib 2.5
*
*   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
*   BSD-like license that allows static linking with closed source software
*
*   Copyright (c) 2013-2024 Ramon Santamaria (@raysan5)
*   Translation to Odin by Evan Martinez (@Nave55)
*
********************************************************************************************/

import "core:fmt"
import rl "vendor:raylib"

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450

Ball :: struct {
    position: rl.Vector2,
    vel: rl.Vector2,
    color: rl.Color,
    radius: f32,
}

pause := false
frame_counter := 0
ball: Ball

main :: proc() {
    flags: rl.ConfigFlags = {rl.ConfigFlag.MSAA_4X_HINT}
    rl.SetConfigFlags(flags)
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Bouncing Ball")
    rl.SetTargetFPS(60)
    defer rl.CloseWindow()
    initGame()

    for !rl.WindowShouldClose() do updateGame()
}

initGame :: proc() {
    ball = {{SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2},
            {5, 4},
             rl.MAROON,
             20,
            }
}

controls :: proc() {
    if rl.IsKeyPressed(.SPACE) do pause = !pause
}

movement :: proc() {
    if !pause {
        ball.position += ball.vel
        if ball.position.x - ball.radius <= 0 || ball.position.x + ball.radius >= SCREEN_WIDTH do ball.vel.x *= -1
        if ball.position.y - ball.radius <= 0 || ball.position.y + ball.radius >= SCREEN_HEIGHT do ball.vel.y *= -1   
    }
    else do frame_counter += 1
}

drawGame :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()
    rl.ClearBackground(rl.BLACK)

    rl.DrawCircleV(ball.position, ball.radius, ball.color)

    if pause && int(frame_counter / 30) % 2 == 1 do rl.DrawText("PAUSED", 350, 200, 30, rl.GRAY)
    
    rl.DrawFPS(10, 10)
}

updateGame :: proc() {
    controls()
    movement()
    drawGame()
}
