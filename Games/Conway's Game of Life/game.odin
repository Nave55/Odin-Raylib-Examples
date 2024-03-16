package conway

/*******************************************************************************************
*
*   Conway's Game of Life
* 
*   Original version https://github.com/educ8s/Python-Game-Of-Life-with-Pygame
*   Original video tutorial https://www.youtube.com/watch?v=uR0lNADr4dc
*
*   Original by Programming With Nick @(educ8s)
*   Translation to Odin by Evan Martinez (@Nave55)
*
*********************************************************************************************
*/

import rl "vendor:raylib"

fps: i32 = 12
running := false

main :: proc() {
    rl.InitWindow(WIDTH, HEIGHT, "Game of Life")
    defer rl.CloseWindow()
    rl.SetTargetFPS(fps)

    for !rl.WindowShouldClose() do updateGame()
}

controls :: proc() {
    if rl.IsKeyPressed(.ENTER) do running = !running
    if rl.IsKeyPressed(.R) do fillRandom()
    if rl.IsKeyPressed(.C) do clearGrid()
    if rl.IsKeyPressed(.F) || rl.IsKeyPressed(.S) {
        if rl.IsKeyPressed(.F) do fps += 2
        if rl.IsKeyPressed(.S) && fps > 5 do fps -= 2
        rl.SetTargetFPS(fps)
    }
}

drawGame :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(GREY)
    drawCells()
}

updateGame :: proc() {
    if running do rl.SetWindowTitle(rl.TextFormat("Game of Life is Running at %v fps", fps))
    else do rl.SetWindowTitle("Game of Life is Paused")
    controls()
    updateSim()
    drawGame()
}
