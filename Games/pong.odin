package pong

import rl "vendor:raylib"
import "core:math/rand"

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 800

Paddle :: struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
    color: rl.Color,
    rect: rl.Rectangle
}

Ball :: struct {
    x: f32,
    y: f32,
    radius: f32,
    color: rl.Color,
    vel: rl.Vector2
}

paddle_one, paddle_two: Paddle
ball: Ball
paused := true
score, score_2: int

main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Pong")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    initGame()

    for !rl.WindowShouldClose() do updateGame()
}

initGame :: proc() {
    paddle_one.x = 10
    paddle_one.y = SCREEN_HEIGHT / 2 - 60
    paddle_one.width = 25
    paddle_one.height = 120
    paddle_one.color = rl.WHITE
    paddle_one.rect = {f32(paddle_one.x),
                       f32(paddle_one.y),
                       f32(paddle_one.width),
                       f32(paddle_one.height)}

    paddle_two = paddle_one
    paddle_two.x = SCREEN_WIDTH - 35
    paddle_two.rect = {f32(paddle_two.x),
                       f32(paddle_two.y),
                       f32(paddle_two.width),
                       f32(paddle_two.height)}

    ball = {SCREEN_WIDTH / 2, 
            SCREEN_HEIGHT / 2, 
            20,  
            rl.WHITE,
            {rand.choice([]f32{-12, 12}), rand.choice([]f32{-12, 12})}}
}

controls :: proc() {
    if !paused {
        if paddle_one.y > 0 && rl.IsKeyDown(.UP) do paddle_one.y -= 10
        if paddle_one.y + paddle_one.height < SCREEN_HEIGHT && rl.IsKeyDown(.DOWN) do paddle_one.y += 10
    }

    if rl.IsKeyPressed(.SPACE) do paused = !paused
}

ai :: proc() {
    if !paused {
        for i32(ball.y) > paddle_two.y && paddle_two.y + paddle_two.height < SCREEN_HEIGHT do paddle_two.y += 10
        for i32(ball.y) < paddle_two.y && paddle_two.y > 0 do paddle_two.y -= 10
    }
}

movement :: proc() {
    if !paused {
        paddle_one.rect.x = f32(paddle_one.x)
        paddle_one.rect.y = f32(paddle_one.y)
        paddle_two.rect.x = f32(paddle_two.x)
        paddle_two.rect.y = f32(paddle_two.y)

        ball.x += ball.vel.x
        ball.y += ball.vel.y

        if ball.x - ball.radius <= 0 do score_2 += 1 
        if ball.x + ball.radius >= SCREEN_WIDTH do score += 1 

        if ball.x - ball.radius <= 0 || ball.x + ball.radius >= SCREEN_WIDTH {
            paused = true
            initGame()
        } 
                
        if (ball.y - ball.radius <= 0 || ball.y + ball.radius >= SCREEN_HEIGHT) do ball.vel.y *= -1
            
        if rl.CheckCollisionCircleRec({ball.x, ball.y}, ball.radius, paddle_one.rect) {
            ball.x += 10
            ball.vel.x *= -1
        }

        if rl.CheckCollisionCircleRec({ball.x, ball.y}, ball.radius, paddle_two.rect) {
            ball.x -= 10
            ball.vel.x *= -1
        }
    }
}

drawGame :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()
    rl.ClearBackground(rl.BLACK)

    rl.DrawLine(SCREEN_WIDTH / 2,
                0,
                SCREEN_WIDTH / 2,
                SCREEN_HEIGHT,
                rl.WHITE)

    rl.DrawRectangle(paddle_one.x, 
                     paddle_one.y,
                     paddle_one.width, 
                     paddle_one.height,
                     paddle_one.color)

    rl.DrawRectangle(paddle_two.x, 
                     paddle_two.y,
                     paddle_two.width, 
                     paddle_two.height,
                     paddle_two.color)

    rl.DrawCircle(i32(ball.x), 
                  i32(ball.y),
                  ball.radius,
                  ball.color)

    if paused do rl.DrawText("PRESS SPACE TO CONTINUE", 
                            SCREEN_WIDTH / 2 - rl.MeasureText("PRESS SPACE TO CONTINUE", 40) / 2, 
                            SCREEN_HEIGHT / 2 - 50, 
                            40, 
                            rl.RED)
    
    rl.DrawText(rl.TextFormat("Player: %v", score), 
                0, 
                0, 
                40, 
                rl.RED)

    rl.DrawText(rl.TextFormat("Computer: %v", score_2), 
                SCREEN_WIDTH - rl.MeasureText(rl.TextFormat("Computer: %v", score_2), 40), 
                0, 
                40, 
                rl.RED)
}

updateGame :: proc() {
    ai()
    controls()
    movement()
    drawGame()
}
