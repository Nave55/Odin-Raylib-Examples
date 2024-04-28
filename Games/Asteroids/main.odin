package asteroids

/*******************************************************************************************
*
*   Asteroids
*   Sample game developed by Evan Martinez (@Nave55)
*
********************************************************************************************/

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

WIDTH :: 1000
HEIGHT :: 840
PLAYER_SPEED :: 6.0
score: int
pause := true
game_over := false
immune: f32 = 0
fired := false

main :: proc() {
    rl.InitWindow(WIDTH, HEIGHT, "Asteroids")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    createTextures()
    initGame()

    for !rl.WindowShouldClose() do updateGame()
}

initGame :: proc() {
    clear(&asteroids)
    clear(&bullets)
    clear(&destroy_particles)
    createPlayer()
    immune = 0
    fired = false
    if game_over {
        score = 0
        game_over = false
    }
    
    for i in 1..=5 {
        pos: rl.Vector2 = {f32(rl.GetRandomValue(0, WIDTH)), f32(rl.GetRandomValue(0, HEIGHT))}
        
        vel: rl.Vector2
        if rl.GetRandomValue(0, 1) == 0 {
            vel.x = f32(rl.GetRandomValue(1, 2))
        }
        else do vel.x = f32(rl.GetRandomValue(-2, -1))

        if rl.GetRandomValue(0, 1) == 0 {
            vel.y = f32(rl.GetRandomValue(1, 2))
        }
        else do vel.y = f32(rl.GetRandomValue(-2, -1))

        createAsteroid(big_texture, pos, vel, 0, "big", true)
    }
}

controls :: proc() {
    x1 := player.position.x + (player.radius * math.cos((player.rotation + 240) * rl.DEG2RAD))
    y1 := player.position.y + (player.radius * math.sin((player.rotation + 240) * rl.DEG2RAD))
    {   
        if !pause {
            using player
            if rl.IsKeyDown(.UP) {
                if acceleration < 1 do acceleration += 0.04
            }
            else {
                if acceleration > 0 do acceleration -= 0.02
                else if acceleration < 0 do acceleration = 0
            }

            if rl.IsKeyDown(.DOWN) {
                if acceleration > 0 do acceleration -= 0.04
                else if acceleration < 0 do acceleration = 0
            }
            speed.x = math.sin((rotation - 30) * rl.DEG2RAD) * PLAYER_SPEED
            speed.y = math.cos((rotation - 30) * rl.DEG2RAD) * PLAYER_SPEED
            position.x += (speed.x * acceleration)
            position.y -= (speed.y * acceleration)

        
            if rl.IsKeyDown(.LEFT) do rotation -= 5
            if rl.IsKeyDown(.RIGHT) do rotation += 5
            if rl.IsKeyPressed(.SPACE) {
                createBullet({x1, y1}, 2, rl.WHITE, {speed.x, speed.y}, true)
                fired = true
            }
        }
        if rl.IsKeyPressed(.ENTER) {
            pause = !pause
            game_over = false
        }
    }
}

collisions :: proc() {
    {
        using player
        if position.x > WIDTH + radius * 2 do position.x = -(radius * 2)
        else if position.x < -(radius * 2) do position.x = WIDTH + (radius * 2)
        if position.y > (HEIGHT + radius * 2) do player.position.y = -(radius * 2);
        else if position.y < -(radius * 2) do position.y = HEIGHT + radius * 2
    }

    for &j, ast_ind in asteroids {
        if j.pos.x > WIDTH + f32(j.asteroid.width) do j.pos.x = -(f32(j.asteroid.width))
        else if j.pos.x < -(f32(j.asteroid.width)) do j.pos.x = WIDTH + (f32(j.asteroid.width))
        if j.pos.y > (HEIGHT + f32(j.asteroid.height) * 2) do j.pos.y = -(f32(j.asteroid.height));
        else if j.pos.y < -(f32(j.asteroid.height)) do j.pos.y = HEIGHT + f32(j.asteroid.height)
    }

    if len(
        bullets) > 0 {
        for &i, bul_ind in bullets {
            if i.center.x + i.radius >= WIDTH || i.center.x - i.radius <= 0 do i.alive = false
            if i.center.y + i.radius >= HEIGHT || i.center.y - i.radius <= 0 do i.alive = false

            if len(asteroids) > 0 {
                for &j, ast_ind in asteroids {
                    asteroid_bb: rl.Rectangle = {(j.pos.x - f32(j.asteroid.width / 2)), j.pos.y - f32(j.asteroid.height / 2), f32(j.asteroid.width), f32(j.asteroid.height)}
                    if rl.CheckCollisionCircleRec(i.center, i.radius, asteroid_bb)  {
                        i.alive = false
                        j.alive = false
                        destroyAnimation(j.pos, f32(j.asteroid.width / 4), rl.GRAY, true, 0)
                    }
                }
            }
        }
    }

    for &i, bul_ind in bullets {
        if i.alive == false do unordered_remove(&bullets, bul_ind)
    }

    if fired do immune = 10
    if immune < 10 && !pause do immune += .1
    for &j, ast_ind in asteroids {
        asteroid_bb: rl.Rectangle = {(j.pos.x - f32(j.asteroid.width / 2)), j.pos.y - f32(j.asteroid.height / 2), f32(j.asteroid.width), f32(j.asteroid.height)}
        if immune >= 10 {
            if rl.CheckCollisionCircleRec(player.position, player.radius, asteroid_bb) do game_over = true
        }
        
        if j.alive == false {
            x_val := f32(rl.GetRandomValue(i32(j.pos.x) - j.asteroid.width / 2, i32(j.pos.x) + j.asteroid.width / 2))
            y_val := f32(rl.GetRandomValue(i32(j.pos.y) - j.asteroid.height / 2, i32(j.pos.y) + j.asteroid.height / 2))
            x_val_2 := f32(rl.GetRandomValue(i32(j.pos.x) - j.asteroid.width / 2, i32(j.pos.x) + j.asteroid.width / 2))
            y_val_2 := f32(rl.GetRandomValue(i32(j.pos.y) - j.asteroid.height / 2, i32(j.pos.y) + j.asteroid.height / 2))

            vel: rl.Vector2
            vel_2: rl.Vector2

            if rl.GetRandomValue(0, 1) == 0 {
                vel.x = f32(rl.GetRandomValue(1, 2))
            }
            else do vel.x = f32(rl.GetRandomValue(-2, -1))
    
            if rl.GetRandomValue(0, 1) == 0 {
                vel.y = f32(rl.GetRandomValue(1, 2))
            }
            else do vel.y = f32(rl.GetRandomValue(-2, -1))

            if rl.GetRandomValue(0, 1) == 0 {
                vel_2.x = f32(rl.GetRandomValue(1, 2))
            }
            else do vel_2.x = f32(rl.GetRandomValue(-2, -1))
    
            if rl.GetRandomValue(0, 1) == 0 {
                vel_2.y = f32(rl.GetRandomValue(1, 2))
            }
            else do vel_2.y = f32(rl.GetRandomValue(-2, -1))

            if j.type == "big" {
                createAsteroid(med_texture, {x_val, y_val}, vel, 0, "med", true)
                createAsteroid(med_texture, {x_val_2, y_val_2}, vel_2, 0, "med", true)
                score += 10
            }
            else if j.type == "med" {
                createAsteroid(sml_texture, {x_val, y_val}, vel, 0, "sml", true)
                createAsteroid(sml_texture, {x_val_2, y_val_2}, vel_2, 0, "sml", true)
                score += 20
            }
            else do score += 50

            unordered_remove(&asteroids, ast_ind)
        }
    }
}

drawGame :: proc() {
    fmt.println(len(bullets))
    rl.BeginDrawing()
    defer rl.EndDrawing()
    rl.ClearBackground(rl.BLACK)

    x2 := player.position.x + (-player.radius / 1.5 * math.cos((player.rotation - 120) * rl.DEG2RAD))
    y2 := player.position.y + (-player.radius / 1.5 * math.sin((player.rotation - 120) * rl.DEG2RAD))

    rl.DrawPoly(player.position, player.sides, player.radius, player.rotation, player.color)
    rl.DrawPoly({x2, y2}, player.sides, 5, player.rotation + 180, rl.YELLOW)

    for &i in bullets {
        rl.DrawCircleV(i.center, i.radius, i.color)
        if !pause do i.center += {i.velocity.x * 1.5, -i.velocity.y * 1.5}
    }

    for &i in asteroids {
        if !pause {
            i.rot += 1
            i.pos += i.vel
        }

        rl.DrawTexturePro(i.asteroid, 
                         {0, 0, f32(i.asteroid.width), f32(i.asteroid.height)}, 
                         {i.pos.x, i.pos.y, f32(i.asteroid.width), f32(i.asteroid.height)}, 
                         {f32(i.asteroid.width) / 2, f32(i.asteroid.height) / 2}, 
                         i.rot, 
                         rl.WHITE)
    }

    for &i, ind in destroy_particles {
        if !pause {
            i.center += i.velocity / 50
            i.timer += 1
        }
        rl.DrawCircleV(i.center, i.radius, i.color)
        if i.timer == 30 do i.alive = false
        if i.alive == false do unordered_remove(&destroy_particles, ind)
    }

    rl.DrawText(rl.TextFormat("Score: %v", score), 0, 0, 30, rl.DARKPURPLE)

    if pause && !game_over do rl.DrawText("PRESS ENTER TO CONTINUE", 
                                           WIDTH / 2 - rl.MeasureText("PRESS ENTER TO CONTINUE", 40) / 2, 
                                           HEIGHT / 2 - 50, 
                                           40, 
                                           rl.DARKGRAY)

    if immune < 10 do rl.DrawText("IMMUNE", 
                                   WIDTH / 2 - rl.MeasureText("IMMUNE", 40) / 2, 
                                   0, 
                                   40, 
                                   rl.GREEN)
}   

updateGame :: proc() {
    if len(asteroids) == 0 || game_over {
        pause = true
        initGame()
    }
    controls()
    collisions()
    drawGame()
}
