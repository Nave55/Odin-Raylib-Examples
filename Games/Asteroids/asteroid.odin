package asteroids

import rl "vendor:raylib"
import "core:math"

Asteroids :: struct {
    rect: rl.Rectangle,
    vel: rl.Vector2,
    rot: f32,
    type: string,
    alive: u8,
}

Particles :: struct {
    center: rl.Vector2,
    radius: f32,
    color: rl.Color,
    velocity: rl.Vector2,
    alive: u8,
    timer: u8,
}

particles: [dynamic]Particles
asteroids: [dynamic]Asteroids
ast_map := make(map[string]rl.Texture2D)

// Function to create asteroid textures
createTextures :: proc() {
    sml_image := rl.LoadImage("imgs/1.png"); defer rl.UnloadImage(sml_image)
    big_image := rl.LoadImage("imgs/2.png"); defer rl.UnloadImage(big_image)
    ast_map["sml"] = rl.LoadTextureFromImage(sml_image)
    ast_map["med"] = rl.LoadTextureFromImage(sml_image)
    ast_map["big"] = rl.LoadTextureFromImage(big_image)
}

// Create the x amount of large asteroids with random positions and velocities
initAsteroids :: proc(amt: int, min_vel, max_vel: i32) {
    for i in 0..<amt {
        pos: rl.Vector2 = {f32(rl.GetRandomValue(0, WIDTH)), f32(rl.GetRandomValue(0, HEIGHT))}
        createAsteroid("big", pos, min_vel, max_vel)
    }
}

// function to create asteroids
createAsteroid :: proc(type: string, pos: rl.Vector2, min_vel, max_vel: i32) {
    vel: rl.Vector2
    if rl.GetRandomValue(0, 1) == 0 {
        vel.x = f32(rl.GetRandomValue(min_vel, max_vel))
    }
    else do vel.x = f32(rl.GetRandomValue(-max_vel, -min_vel))
    if rl.GetRandomValue(0, 1) == 0 {
        vel.y = f32(rl.GetRandomValue(min_vel, max_vel))
    }
    else do vel.y = f32(rl.GetRandomValue(-max_vel, -min_vel))

    ast_size := rl.Vector2{f32(ast_map["sml"].width), f32(ast_map["sml"].height)}
    if type == "sml" do append_elems(&asteroids, Asteroids{{pos.x, pos.y, ast_size.x, ast_size.y}, vel, 0, type, 1})  
    if type == "med" do append_elems(&asteroids, Asteroids{{pos.x, pos.y, 42, 36}, vel, 0, type, 1})
    if type == "big" do append_elems(&asteroids, Asteroids{{pos.x, pos.y, 122, 96}, vel, 0, type, 1})
}

asteroidCollisions :: proc(amt: int, min_vel, max_vel: i32) {
    // Changes asteroid position when asteroid goes off screen
    for &j, ast_ind in asteroids {        
        if j.rect.x > WIDTH + j.rect.width / 2 do j.rect.x = -j.rect.width / 2
        else if j.rect.x < -j.rect.width / 2 do j.rect.x = WIDTH + j.rect.width / 2
        if j.rect.y > HEIGHT + j.rect.height / 2 do j.rect.y = -j.rect.height / 2;
        else if j.rect.y < -j.rect.height / 2 do j.rect.y = HEIGHT + j.rect.height / 2

        // create smaller asteroids
        if j.alive == 0 {
            for i in 0..<amt {
                pos: rl.Vector2 = {f32(rl.GetRandomValue(i32(j.rect.x - j.rect.width / 2), i32(j.rect.x + j.rect.width / 2))),
                                   f32(rl.GetRandomValue(i32(j.rect.y - j.rect.height / 2), i32(j.rect.y + j.rect.height / 2)))}
    
                if j.type == "big" {
                    createAsteroid("med", pos, min_vel, max_vel)
                    score += 10
                }
                else if j.type == "med" {
                    createAsteroid("sml", pos, min_vel, max_vel)
                    score += 20
                }
                else do score += 50
            }
            // remove dead asteroids
            unordered_remove(&asteroids, ast_ind)
        }
    }
}

// Draw Asteroids
drawAsteroids :: proc() {
    for &i in asteroids {
        if !pause {
            i.rot += 1
            i.rect.x += i.vel.x
            i.rect.y += i.vel.y
        }

        rl.DrawTexturePro(ast_map[i.type], 
                         {0, 0, f32(ast_map[i.type].width), f32(ast_map[i.type].height)}, 
                         i.rect, 
                         {i.rect.width / 2, i.rect.height / 2}, 
                         i.rot, 
                         rl.WHITE)
    }
}

// function to create particles for dead asteroids
spriteAnimation :: proc(center: rl.Vector2, radius: f32, color: rl.Color) {
    for i in 1..=10 {
        pos: rl.Vector2 = {center.x + math.sin(f32(i * 36.0) * rl.DEG2RAD) * radius, 
                           center.y + math.cos(f32(i * 36.0) * rl.DEG2RAD) * radius}
        velocity := pos - center
        append_elems(&particles, Particles{pos, 1, color, velocity, 1, 0})
    }
}

// Draw particles for destroyed asteroids
drawParticles :: proc() {
    for &i, ind in particles {
        if !pause {
            i.center += i.velocity / 50
            i.timer += 1
        }
        rl.DrawCircleV(i.center, i.radius, i.color)
        if i.timer == 100 do i.alive = 0
        if i.alive == 0 do unordered_remove(&particles, ind)
    }
}
