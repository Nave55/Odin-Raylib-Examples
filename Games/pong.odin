package pong

import rl "vendor:raylib"
import "core:math/rand"

// Create all variables and structures
SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 800

Paddle :: struct {
    rect: rl.Rectangle,
    color: rl.Color,
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
score_1, score_2: int

main :: proc() {
    // window logic and main game loop
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Pong")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    initGame()

    for !rl.WindowShouldClose() do updateGame()
}

// initialize all variables per game state
initGame :: proc() {
    paddle_one.color = rl.WHITE
    paddle_one.rect = {10,
                       SCREEN_HEIGHT / 2 - 60,
                       25,
                       120}

    paddle_two = paddle_one
    paddle_two.rect.x = SCREEN_WIDTH - 35

    ball = {SCREEN_WIDTH / 2, 
            SCREEN_HEIGHT / 2, 
            20,  
            rl.WHITE,
            {rand.choice([]f32 {-12, 12}), rand.choice([]f32 {-12, 12})}}
}

// player controls and pause button
controls :: proc() {
    if !paused {
        if paddle_one.rect.y > 0 && rl.IsKeyDown(.UP) do paddle_one.rect.y -= 10
        if paddle_one.rect.y + paddle_one.rect.height < SCREEN_HEIGHT && rl.IsKeyDown(.DOWN) do paddle_one.rect.y += 10
    }

    if rl.IsKeyPressed(.SPACE) do paused = !paused
}

// basic ai logic
ai :: proc() {
    if !paused {
        for ball.y > paddle_two.rect.y && paddle_two.rect.y + paddle_two.rect.height < SCREEN_HEIGHT do paddle_two.rect.y += 10
        for ball.y < paddle_two.rect.y && paddle_two.rect.y > 0 do paddle_two.rect.y -= 10
    }
}

// updates ball per frame and checks for collisions with walls and paddles
movement :: proc() {
    if !paused {
        // update ball position
        ball.x += ball.vel.x
        ball.y += ball.vel.y

        // update score
        if ball.x + ball.radius >= SCREEN_WIDTH do score_1 += 1 
        if ball.x - ball.radius <= 0 do score_2 += 1 

        // reset position of object and pauses game if a score occurs
        if ball.x - ball.radius <= 0 || ball.x + ball.radius >= SCREEN_WIDTH {
            paused = true
            initGame()
        } 
        
        // reflects ball of ceiling and floor
        if (ball.y - ball.radius <= 0 || ball.y + ball.radius >= SCREEN_HEIGHT) do ball.vel.y *= -1
        
        // reflects ball of paddles
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
    // draw paddles, ball, lines, text and clears screen per frame
    rl.BeginDrawing()
    defer rl.EndDrawing()
    rl.ClearBackground(rl.BLACK)

    // draws center line
    rl.DrawLine(SCREEN_WIDTH / 2,
                0,
                SCREEN_WIDTH / 2,
                SCREEN_HEIGHT,
                rl.WHITE)
    
    // draws paddles
    rl.DrawRectangleRec(paddle_one.rect, paddle_one.color)

    rl.DrawRectangleRec(paddle_two.rect, paddle_two.color)
    
    // draws ball
    rl.DrawCircle(i32(ball.x), 
                  i32(ball.y),
                  ball.radius,
                  ball.color)
    
    // draw pause text
    if paused do rl.DrawText("PRESS SPACE TO CONTINUE", 
                            SCREEN_WIDTH / 2 - rl.MeasureText("PRESS SPACE TO CONTINUE", 40) / 2, 
                            SCREEN_HEIGHT / 2 - 50, 
                            40, 
                            rl.RED)

    // draws score for players
    rl.DrawText(rl.TextFormat("Player: %v", score_1), 
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

// main update function 
updateGame :: proc() {
    ai()
    controls()
    movement()
    drawGame()
}
