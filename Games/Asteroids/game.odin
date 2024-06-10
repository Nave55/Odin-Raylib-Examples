package asteroids

/*******************************************************************************************
*
*   Asteroids
*   Sample game developed by Evan Martinez (@Nave55)
*
********************************************************************************************/

import rl "vendor:raylib"
import "core:math"

WIDTH :: 1000
HEIGHT :: 840
pause := true
game_over := false

main :: proc() {
    // Manage window and load textures
    rl.InitWindow(WIDTH, HEIGHT, "Asteroids")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    defer unloadGame()
    createTextures()
    initGame()

    // update game loop
    for !rl.WindowShouldClose() do updateGame()
}

initGame :: proc() {
    // initialize all game objects and settings
    clear(&asteroids)
    clear(&bullets)
    clear(&particles)
    pause = true
    if game_over do score = 0
    initShip()
    initAsteroids(6, 1, 2)
}

controls :: proc() {
    shipControls()

    // Pause 
    if rl.IsKeyPressed(.ENTER) {
        pause = !pause
        game_over = false
    }
}

collisions :: proc() {    
    bulletCollisions()
    shipCollisions()
    asteroidCollisions(2, 1, 2)
}

drawGame :: proc() {
    // Allow drawing and clear screen with black background
    rl.BeginDrawing()
    defer rl.EndDrawing()
    rl.ClearBackground(rl.BLACK)

    drawParticles()
    drawAsteroids()
    drawBullets()
    drawShip()
    drawText()
}  

updateGame :: proc() {
    // Check if game is over
    if (len(asteroids) == 0 || game_over) && !pause do initGame()
    // Call functions to update the game
    controls()
    collisions()
    drawGame()
}

unloadGame :: proc() {
    delete(ast_map)
    delete(particles)
    delete(asteroids)
    delete(bullets)
}