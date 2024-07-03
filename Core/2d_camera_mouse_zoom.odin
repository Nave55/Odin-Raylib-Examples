package main

/*******************************************************************************************
*
*   raylib [core] example - 2d camera mouse zoom
*
*   Example originally created with raylib 4.2, last time updated with raylib 4.2
*
*   Example licensed under an unmodified zlib/libpng license, which is an OSI-certified,
*   BSD-like license that allows static linking with closed source software
*
*   Copyright (c) 2022-2024 Jeffery Myers (@JeffM2501)
*   Translation to Odin by Evan Martinez (@Nave55)
*
********************************************************************************************/

import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

main :: proc() 
    {
    // Initialization
    //--------------------------------------------------------------------------------------
    screenWidth :: 800
    screenHeight :: 450

    rl.InitWindow(screenWidth, screenHeight, "raylib [core] example - 2d camera mouse zoom")

    camera := rl.Camera2D{zoom = 1.0, rotation = 0}

    rl.SetTargetFPS(60)                 // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    for (! rl.WindowShouldClose())        // Detect window close button or ESC key
    {
        // Update
        //----------------------------------------------------------------------------------
        // Translate based on mouse right click
        if rl.IsMouseButtonDown(rl.MouseButton.RIGHT) == true
        {   
            delta := rl.GetMouseDelta()
            delta *= -1.0 / camera.zoom

            camera.target += delta
        }

        // Zoom based on mouse wheel
        wheel := rl.GetMouseWheelMove()
        if wheel != 0
        {
            // Get the world point that is under the mouse
            mouseWorldPos := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)
            
            // Set the offset to where the mouse is
            camera.offset = rl.GetMousePosition()

            // // Set the target to match, so that the camera maps the world space point 
            // // under the cursor to the screen space point under the cursor at any zoom
            camera.target = mouseWorldPos

            // Zoom increment
            zoomIncrement:f32 = 0.125

            camera.zoom += wheel*zoomIncrement
            if camera.zoom < zoomIncrement do camera.zoom = zoomIncrement
        }

        // ----------------------------------------------------------------------------------

        // Draw
        // ----------------------------------------------------------------------------------
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        rl.BeginMode2D(camera)
        // Draw the 3d grid, rotated 90 degrees and centered around 0,0 
        // just so we have something in the XY plane
        rlgl.PushMatrix()
        rlgl.Translatef(0, 25*50, 0)
        rlgl.Rotatef(90, 1, 0, 0)
        rl.DrawGrid(100, 50)
        rlgl.PopMatrix()
    
        // Draw a reference circle
        rl.DrawCircle(100, 100, 50, rl.YELLOW)
                
        rl.EndMode2D()

        rl.DrawText("Mouse right button drag to move, mouse wheel to zoom", 10, 10, 20, rl.WHITE)
        
        rl.EndDrawing()
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    rl.CloseWindow()        // Close window and OpenGL context
    // --------------------------------------------------------------------------------------
}
