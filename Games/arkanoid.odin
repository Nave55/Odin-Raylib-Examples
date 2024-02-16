package arkanoid
/*******************************************************************************************
*
*   raylib - classic game: arkanoid
*
*   Sample game developed by Marc Palau and Ramon Santamaria
*
*   This game has been created using raylib v1.3 (www.raylib.com)
*   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
*
*   Translation from https://github.com/raysan5/raylib-games/blob/master/classics/src/arkanoid.c to Odin
*
*   Copyright (c) 2015 Ramon Santamaria (@raysan5)
*   Copyright (c) 2024 Evan Martinez (@Nave55)
*
********************************************************************************************/
import rl "vendor:raylib"

PLAYER_MAX_LIFE :: 5
LINES_OF_BRICKS :: 5
BRICKS_PER_LINE :: 20

Player :: struct {
    position: rl.Vector2,
    size: rl.Vector2,
    life: int,
}

Ball :: struct {
    position: rl.Vector2,
    speed: rl.Vector2,
    radius: f32,
    active: bool,
}

Brick :: struct{
    position: rl.Vector2,
    active: bool,
}

SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 450

gameOver := false
pause := false

player: Player
ball: Ball
brick: [LINES_OF_BRICKS][BRICKS_PER_LINE]Brick
brickSize: rl.Vector2

main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "classic game: arkanoid")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    initGame()
    
    for !rl.WindowShouldClose() do updateDrawFrame()
}

initGame :: proc() {
    brickSize = {f32(rl.GetScreenWidth() / BRICKS_PER_LINE), 40}

    // Initialize player
    player.position = {f32(SCREEN_WIDTH / 2), f32(SCREEN_HEIGHT * 7 / 8)}
    player.size = {f32(SCREEN_WIDTH/10), 20}
    player.life = PLAYER_MAX_LIFE

    // Initialize ball
    ball.position = {f32(SCREEN_WIDTH / 2), f32(SCREEN_HEIGHT * 7 / 8 - 30)}
    ball.speed = {0, 0}
    ball.radius = 7
    ball.active = false

    // Initialize bricks
    initialDownPosition :f32 = 50

    for i in 0..<LINES_OF_BRICKS {
        for j in 0..<BRICKS_PER_LINE {
            brick[i][j].position = {f32(j) * brickSize.x + brickSize.x / 2, 
                                    f32(i) * brickSize.y + initialDownPosition}
            brick[i][j].active = true
        }
    }
}

updateGame :: proc() {
    if (!gameOver) {
        if rl.IsKeyPressed(.P) do pause = !pause

        if !pause {
            // Player movement logic
            if rl.IsKeyDown(.LEFT) do player.position.x -= 5
            if (player.position.x - player.size.x / 2) <= 0  do player.position.x = player.size.x / 2
            if rl.IsKeyDown(.RIGHT) do player.position.x += 5
            if (player.position.x + player.size.x / 2) >= SCREEN_WIDTH do player.position.x = SCREEN_WIDTH - player.size.x / 2

            // Ball launching logic
            if (!ball.active) {
                if rl.IsKeyPressed(.SPACE) {
                    ball.active = true
                    ball.speed = {0, -5}
                }
            }

            // Ball movement logic
            if (ball.active) {
                ball.position.x += ball.speed.x
                ball.position.y += ball.speed.y
            }
            else {
                ball.position = {player.position.x, f32(SCREEN_HEIGHT) * 7 / 8 - 30}
            }

            // Collision logic: ball vs walls
            if (ball.position.x + ball.radius) >= SCREEN_WIDTH || ((ball.position.x - ball.radius) <= 0) do ball.speed.x *= -1
            if (ball.position.y - ball.radius) <= 0 do ball.speed.y *= -1
            if (ball.position.y + ball.radius >= SCREEN_HEIGHT) {
                ball.speed = {0, 0}
                ball.active = false
                player.life -= 1
            }

            // Collision logic: ball vs player
            if (rl.CheckCollisionCircleRec(ball.position, ball.radius,
                                          {player.position.x - player.size.x / 2, 
                                           player.position.y - player.size.y / 2, 
                                           player.size.x, player.size.y}))
            {
                if (ball.speed.y > 0) {
                    ball.speed.y *= -1
                    ball.speed.x = (ball.position.x - player.position.x) / (player.size.x / 2) * 5
                }
            }

            // Collision logic: ball vs bricks
            for i in 0..<LINES_OF_BRICKS {
                for j in 0..<BRICKS_PER_LINE {
                    if (brick[i][j].active) {
                        // Hit below
                        if ((ball.position.y - ball.radius) <= (brick[i][j].position.y + brickSize.y / 2)) &&
                            ((ball.position.y - ball.radius) > (brick[i][j].position.y + brickSize.y / 2 + ball.speed.y)) &&
                            ((abs(ball.position.x - brick[i][j].position.x)) < (brickSize.x / 2 + ball.radius * 2 / 3)) && (ball.speed.y < 0) {
                            brick[i][j].active = false
                            ball.speed.y *= -1
                        }
                        else if ((ball.position.y + ball.radius) >= (brick[i][j].position.y - brickSize.y / 2)) &&
                                ((ball.position.y + ball.radius) < (brick[i][j].position.y - brickSize.y / 2 + ball.speed.y)) &&
                                ((abs(ball.position.x - brick[i][j].position.x)) < (brickSize.x / 2 + ball.radius * 2 / 3)) && (ball.speed.y > 0) {
                            brick[i][j].active = false
                            ball.speed.y *= -1
                        }
                        else if ((ball.position.x + ball.radius) >= (brick[i][j].position.x - brickSize.x / 2)) &&
                                ((ball.position.x + ball.radius) < (brick[i][j].position.x - brickSize.x / 2 + ball.speed.x)) &&
                                ((abs(ball.position.y - brick[i][j].position.y)) < (brickSize.y/2 + ball.radius * 2 / 3)) && (ball.speed.x > 0) {
                            brick[i][j].active = false
                            ball.speed.x *= -1
                        }
                        else if ((ball.position.x - ball.radius) <= (brick[i][j].position.x + brickSize.x / 2)) &&
                                ((ball.position.x - ball.radius) > (brick[i][j].position.x + brickSize.x / 2 + ball.speed.x)) &&
                                ((abs(ball.position.y - brick[i][j].position.y)) < (brickSize.y / 2 + ball.radius * 2 / 3)) && (ball.speed.x < 0) {
                            brick[i][j].active = false
                            ball.speed.x *= -1
                        }
                    }
                }
            }

            // Game over logic
            if player.life <= 0 do gameOver = true
            else {
                gameOver = true
                for i in 0..<LINES_OF_BRICKS {
                    for j in 0..<BRICKS_PER_LINE {
                        if brick[i][j].active do gameOver = false
                    }
                }
            }
        }
    }
    else {
        if rl.IsKeyPressed(.ENTER) {
            initGame()
            gameOver = false
        }
    }
}

drawGame :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.RAYWHITE)
    defer rl.EndDrawing()

    if (!gameOver) {
            // Draw player bar
            rl.DrawRectangle(i32(player.position.x) - i32(player.size.x / 2), 
                             i32(player.position.y) - i32(player.size.y / 2), 
                             i32(player.size.x), 
                             i32(player.size.y), 
                             rl.BLACK)

            // Draw player lives
            for i in 0..<player.life do rl.DrawRectangle(20 + 40 * i32(i), 
                                                          SCREEN_HEIGHT- 30, 
                                                          35, 
                                                          10, 
                                                          rl.LIGHTGRAY)

            // Draw ball
            rl.DrawCircleV(ball.position, ball.radius, rl.MAROON)

            // Draw bricks
            for i in 0..<LINES_OF_BRICKS {
                for j in 0..<BRICKS_PER_LINE {
                    if brick[i][j].active  {
                        if (i + j) % 2 == 0 do rl.DrawRectangle(i32(brick[i][j].position.x - brickSize.x / 2), 
                                                                i32(brick[i][j].position.y - brickSize.y / 2), 
                                                                i32(brickSize.x), 
                                                                i32(brickSize.y), 
                                                                rl.GRAY)
                        else do rl.DrawRectangle(i32(brick[i][j].position.x - brickSize.x / 2), 
                                                 i32(brick[i][j].position.y - brickSize.y / 2), 
                                                 i32(brickSize.x), 
                                                 i32(brickSize.y), 
                                                 rl.DARKGRAY)
                    }
                }
            }

            if pause do rl.DrawText("GAME PAUSED", 
                                    SCREEN_WIDTH / 2 - rl.MeasureText("GAME PAUSED", 40) / 2, 
                                    SCREEN_HEIGHT / 2 - 40, 40, 
                                    rl.GRAY)
        }
        else do rl.DrawText("PRESS [ENTER] TO PLAY AGAIN", 
                            rl.GetScreenWidth() / 2 - rl.MeasureText("PRESS [ENTER] TO PLAY AGAIN", 20) / 2, 
                            rl.GetScreenHeight() / 2 - 50, 
                            20, 
                            rl.GRAY)
}

updateDrawFrame :: proc() {
    updateGame()
    drawGame()
}
