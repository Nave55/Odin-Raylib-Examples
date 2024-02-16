package shapes

import rl "vendor:raylib"
import "core:fmt"

// create all variables and data structures
SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720

Rects :: struct {
    vel: rl.Vector2,
    center: rl.Vector2,
    side: i32,
    radius: f32,
    rotation: f32,
    color: rl.Color,
}

rect_array : [25]Rects
pause := false

main :: proc() {
    // create window
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Prac Proj")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    initGame()

    // main game loop
    for !rl.WindowShouldClose() do updateAll()
}

initGame :: proc() {
    for i in &rect_array {

        // create poly values
        i.center = {f32(rl.GetRandomValue(100,1200)),f32(rl.GetRandomValue(100,650))}
        i.side = rl.GetRandomValue(3,8)
        i.radius = f32(rl.GetRandomValue(15,50))
        i.color = {u8(rl.GetRandomValue(0,255)), u8(rl.GetRandomValue(0,255)), u8(rl.GetRandomValue(0,255)), u8(255)}

        // set velocity to random values
        neg: rl.Vector2 = {f32(rl.GetRandomValue(0,1)), f32(rl.GetRandomValue(0,1))}
        if neg.x == 0 do neg.x = -1
        if neg.y == 0 do neg.y = -1
        i.vel = {f32(rl.GetRandomValue(1,5)), f32(rl.GetRandomValue(1,5))} * neg
    }
}

updateGame :: proc() {
    // controls
    if rl.IsKeyPressed(.P) do pause = !pause

    if !pause {
        for i in &rect_array {
            // move entities by velocity and rotate them
            i.rotation += 2
            i.center += {i.vel.x, i.vel.y}

            // reverse velocity if entity collides with a walll
            if  i.center.x - i.radius <= 0 || i.center.x + i.radius >= SCREEN_WIDTH do i.vel.x *= -1
            if  i.center.y - i.radius <= 0 || i.center.y + i.radius >= SCREEN_HEIGHT do i.vel.y *= -1
        }
    }
}

drawGame :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    // draw polygons
    for i in &rect_array {
        rl.DrawPoly(i.center, i.side, i.radius, i.rotation, i.color)
        rl.ClearBackground(rl.BLACK)
    }

    // pause label
    if pause do rl.DrawText("GAME PAUSED", 
                            SCREEN_WIDTH / 2 - rl.MeasureText("GAME PAUSED", 40) / 2, 
                            SCREEN_HEIGHT / 2 - 40, 40, 
                            rl.WHITE)
}

// call all functions that you need on a by frame basis
updateAll :: proc() {
    updateGame()
    drawGame()
}
