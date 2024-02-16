package bouncing

import rl "vendor:raylib"

// create all variables and data structures
SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720

Rects :: struct {
    rect: rl.Rectangle,
    vel: rl.Vector2,
    color: rl.Color,
    rotation: f32,
}

rect_array : [50]Rects
pause := false

main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Prac Proj")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    initGame()

    // main game loop
    for !rl.WindowShouldClose() do updateAll()
}

// function to initialize all rects
initGame :: proc() {
    for i in &rect_array {
        // set Rectangle to random values
        i.rect.x = f32(rl.GetRandomValue(0,1200))
        i.rect.y = f32(rl.GetRandomValue(0,650))
        i.rect.width = f32(rl.GetRandomValue(20,60))
        i.rect.height = f32(rl.GetRandomValue(20, 60))

        // set velocity to random values
        neg: rl.Vector2 = {f32(rl.GetRandomValue(0,1)), f32(rl.GetRandomValue(0,1))}
        if neg.x == 0 do neg.x = -1
        if neg.y == 0 do neg.y = -1
        i.vel = {f32(rl.GetRandomValue(1,5)), f32(rl.GetRandomValue(1,5))} * neg

        // set color to random values
        i.color = {u8(rl.GetRandomValue(0,255)), u8(rl.GetRandomValue(0,255)), u8(rl.GetRandomValue(0,255)), u8(255)}
    }
}

updateGame :: proc() {
    // controls
    if rl.IsKeyPressed(.P) do pause = !pause

    if !pause {
        for i in &rect_array {
            // move entities by velocity
            i.rect.x += i.vel.x
            i.rect.y += i.vel.y
            
            // reverse velocity if entity collides with a walll
            if  i.rect.x <= 0 || i.rect.x + i.rect.width >= SCREEN_WIDTH do i.vel.x *= -1
            if  i.rect.y <= 0 || i.rect.y + i.rect.height >= SCREEN_HEIGHT do i.vel.y *= -1
        }
    }
}
 
drawGame :: proc() {
    // draw all object and clear screen
    rl.BeginDrawing()
    defer rl.EndDrawing()

    for i in rect_array {
        rl.DrawRectanglePro(i.rect, {0,0}, i.rotation, i.color)
        rl.ClearBackground(rl.BLACK)
    }

    // pause label
    if pause do rl.DrawText("GAME PAUSED", 
                            SCREEN_WIDTH / 2 - rl.MeasureText("GAME PAUSED", 40) / 2, 
                            SCREEN_HEIGHT / 2 - 40, 40, 
                            rl.WHITE)
}

// function to update all game variables per frame
updateAll :: proc() {
    updateGame()
    drawGame()
    rl.DrawFPS(0,0)
}
