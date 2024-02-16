package Snake
/*******************************************************************************************
*
*   raylib - classic game: snake
*
*   Sample game developed by Ian Eito, Albert Martos and Ramon Santamaria
*
*   This game has been created using raylib v1.3 (www.raylib.com)
*   raylib is licensed under an unmodified zlib/libpng license (View raylib.h for details)
*
*  Translation from https://github.com/raysan5/raylib-games/blob/master/classics/src/snake.c to Odin
*
*   Copyright (c) 2015 Ramon Santamaria (@raysan5)
*   Copyright (c) 2024 Evan Martinez (@Nave55)
*
********************************************************************************************/
import rl "vendor:raylib"

// Create All Variables and Structs
SNAKE_LENGTH :: 256
SQUARE_SIZE :: 31

Snake :: struct {
    position: rl.Vector2,
    size: rl.Vector2,
    speed: rl.Vector2,
    color: rl.Color,
}

Food :: struct {
    position: rl.Vector2,
    size: rl.Vector2,
    active: bool,
    color: rl.Color,
}

SCREEN_WIDTH ::  800
SCREEN_HEIGHT :: 450

framesCounter := 0
gameOver := false
pause := false

fruit: Food
snake: [SNAKE_LENGTH]Snake 
snakePosition: [SNAKE_LENGTH]rl.Vector2
allowMove := false
offset: rl.Vector2
counterTail := 0

// Main Function
main :: proc() {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "classic game: snake")
    defer rl.CloseWindow()

    initGame()
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() do updateDrawFrame()
}

// Init variables and game settings whem game starts or restarts
initGame :: proc() {
    framesCounter = 0
    gameOver = false
    pause = false
    counterTail = 1
    allowMove = false
    
    offset = {(f32)(SCREEN_WIDTH % SQUARE_SIZE), 
              (f32)(SCREEN_HEIGHT % SQUARE_SIZE)}

    for i in 0..<SNAKE_LENGTH {
        snake[i].position = {offset.x / 2, offset.y / 2}
        snake[i].size = {SQUARE_SIZE, SQUARE_SIZE}
        snake[i].speed = {SQUARE_SIZE, 0}

        if i == 0 do snake[i].color = rl.DARKBLUE
        else do snake[i].color = rl.BLUE
    }

    fruit.size = {SQUARE_SIZE, SQUARE_SIZE}
    fruit.color = rl.SKYBLUE
    fruit.active = false
}

// Update function which contains all game logic to update the game every frame.
updateGame :: proc() {
    if !gameOver {
        // Controls
        if rl.IsKeyPressed(.P) do pause = !pause

        if !pause {
            if rl.IsKeyPressed(.RIGHT) && (snake[0].speed.x == 0) && allowMove {
                snake[0].speed = {SQUARE_SIZE, 0}
                allowMove = false
            }

            if rl.IsKeyPressed(.LEFT) && (snake[0].speed.x == 0) && allowMove {
                snake[0].speed = {-SQUARE_SIZE, 0}
                allowMove = false
            }

            if rl.IsKeyPressed(.UP) && (snake[0].speed.y == 0) && allowMove {
                snake[0].speed = {0, -SQUARE_SIZE}
                allowMove = false
            }

            if rl.IsKeyPressed(.DOWN) && (snake[0].speed.y == 0) && allowMove {
                snake[0].speed = {0, SQUARE_SIZE}
                allowMove = false
            }
            
            // Snake Movement
            for i in 0..<counterTail do snakePosition[i] = snake[i].position
            
            if framesCounter % 5 == 0 {
                for i in 0..<counterTail {
                    if i == 0 {
                        snake[0].position.x += snake[0].speed.x
                        snake[0].position.y += snake[0].speed.y
                        allowMove = true
                    }
                    else do snake[i].position = snakePosition[i-1]
                }
            }

            // Collisions with wall
            if (snake[0].position.x > (SCREEN_WIDTH - offset.x)) ||
            (snake[0].position.y > (SCREEN_HEIGHT - offset.y)) ||
            (snake[0].position.x < 0) || snake[0].position.y < 0 {
                gameOver = true
            }

            // Collisions with oneself
            for i in 1..<counterTail {
                if (snake[0].position.x == snake[i].position.x) && (snake[0].position.y == snake[i].position.y) do gameOver = true
            }
            
            // Fruit positioning
            if (!fruit.active) {
                fruit.active = true
                fruit.position = {f32(rl.GetRandomValue(0,(SCREEN_WIDTH / SQUARE_SIZE) - 1) * SQUARE_SIZE) + offset.x/2, 
                                  f32(rl.GetRandomValue(0,(SCREEN_HEIGHT / SQUARE_SIZE) - 1) * SQUARE_SIZE) + offset.y/2}

                for i in 0..< counterTail {
                    for (fruit.position.x == snake[i].position.x) && (fruit.position.y == snake[i].position.y) {
                        fruit.position = {f32(rl.GetRandomValue(0, (SCREEN_WIDTH / SQUARE_SIZE) - 1) * SQUARE_SIZE) + offset.x/2, 
                                          f32(rl.GetRandomValue(0, (SCREEN_HEIGHT / SQUARE_SIZE) - 1) * SQUARE_SIZE) + offset.y/2}
                        i := 0
                    }
                }
            }

            // Collisions with fruit
            if ((snake[0].position.x < (fruit.position.x + fruit.size.x) && 
                (snake[0].position.x + snake[0].size.x) > fruit.position.x) &&
                (snake[0].position.y < (fruit.position.y + fruit.size.y) && 
                (snake[0].position.y + snake[0].size.y) > fruit.position.y)) {
                snake[counterTail].position = snakePosition[counterTail - 1]
                counterTail += 1
                fruit.active = false
            }

            framesCounter += 1
        }
    }
    else {
        if rl.IsKeyPressed(.ENTER) {
            initGame()
            gameOver = false
        }
    } 
}

// Function to draw snake, fruit, and grid.
drawGame :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

        // Draw the background white
        rl.ClearBackground(rl.RAYWHITE)

        if !gameOver {
            // Draw grid lines
            for i in 0..<SCREEN_WIDTH/SQUARE_SIZE + 1 {
                rl.DrawLineV({f32(SQUARE_SIZE * i) + offset.x / 2, offset.y / 2}, 
                             {f32(SQUARE_SIZE * i) + offset.x / 2, SCREEN_HEIGHT - offset.y / 2}, 
                             rl.LIGHTGRAY)
            }

            for i in 0..<SCREEN_HEIGHT/SQUARE_SIZE + 1 {
                rl.DrawLineV({offset.x / 2, f32(SQUARE_SIZE * i) + offset.y / 2}, 
                             {f32(SCREEN_WIDTH) - offset.x / 2, f32(SQUARE_SIZE * i) + offset.y / 2}, 
                             rl.LIGHTGRAY)
            }

            // Draw snake
            for i in 0..<counterTail do rl.DrawRectangleV(snake[i].position, snake[i].size, snake[i].color)
            // Draw fruit
            rl.DrawRectangleV(fruit.position, fruit.size, fruit.color)

            if pause do rl.DrawText("GAME PAUSED", 
                        SCREEN_WIDTH / 2 - rl.MeasureText("GAME PAUSED", 40) / 2, 
                        SCREEN_HEIGHT / 2 - 40, 40, 
                        rl.GRAY)
        }
        else do rl.DrawText("PRESS [ENTER] TO PLAY AGAIN", 
                rl.GetScreenWidth() / 2 - rl.MeasureText("PRESS [ENTER] TO PLAY AGAIN", 20) / 2, 
                rl.GetScreenHeight() / 2 - 50, 20, 
                rl.GRAY)
}

updateDrawFrame :: proc() {
    updateGame()
    drawGame()
}
