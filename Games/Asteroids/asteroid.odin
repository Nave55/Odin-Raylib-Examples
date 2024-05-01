package asteroids

import rl "vendor:raylib"
import "core:math"
import "core:fmt"

Asteroids :: struct {
    asteroid: rl.Texture2D,
    pos: rl.Vector2,
    vel: rl.Vector2,
    rot: f32,
    type: string,
    alive: bool,
}

Destroy :: struct {
    center: rl.Vector2,
    radius: f32,
    color: rl.Color,
    velocity: rl.Vector2,
    alive: bool,
    timer: int,
}

sml_texture: rl.Texture2D
med_texture: rl.Texture2D
big_texture: rl.Texture2D

destroy_particles: [dynamic]Destroy
asteroids: [dynamic]Asteroids

// Function to create asteroid textures
createTextures :: proc() {
    sml_image := rl.LoadImage("imgs/1.png")
    defer rl.UnloadImage(sml_image)
    sml_texture = rl.LoadTextureFromImage(sml_image)

    rl.ImageResize(&sml_image, 42, 36)
    med_texture = rl.LoadTextureFromImage(sml_image)

    big_image := rl.LoadImage("imgs/2.png")
    defer rl.UnloadImage(big_image)
    rl.ImageResize(&big_image, 122, 96)
    big_texture = rl.LoadTextureFromImage(big_image)
}

// function to create asteroids
createAsteroid :: proc(type: string, pos: rl.Vector2) {
    vel: rl.Vector2
    if rl.GetRandomValue(0, 1) == 0 {
        vel.x = f32(rl.GetRandomValue(1, 2))
    }
    else do vel.x = f32(rl.GetRandomValue(-2, -1))
    if rl.GetRandomValue(0, 1) == 0 {
        vel.y = f32(rl.GetRandomValue(1, 2))
    }
    else do vel.y = f32(rl.GetRandomValue(-2, -1))

    if type == "big" do append_elems(&asteroids, Asteroids{big_texture, pos, vel, 0, type, true})
    if type == "med" do append_elems(&asteroids, Asteroids{med_texture, pos, vel, 0, type, true})
    if type == "sml" do append_elems(&asteroids, Asteroids{sml_texture, pos, vel, 0, type, true})  
}

// function to create particles for dead asteroids
destroyAnimation :: proc(center: rl.Vector2, radius: f32, color: rl.Color, alive: bool, timer: int) {
    for i in 1..=10 {
        pos: rl.Vector2 = {center.x + math.sin(f32(i * 36.0) * rl.DEG2RAD) * radius, 
                           center.y + math.cos(f32(i * 36.0) * rl.DEG2RAD) * radius}
        velocity := pos - center
        append_elems(&destroy_particles, Destroy{pos, 1, color, velocity, alive, timer})
    }
}
