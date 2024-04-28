package asteroids

import rl "vendor:raylib"
import "core:math"

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

createTextures :: proc() {
    sml_image := rl.LoadImage("imgs/1.png")
    defer rl.UnloadImage(sml_image)
    sml_texture = rl.LoadTextureFromImage(sml_image)

    med_image := rl.LoadImage("imgs/1.png")
    defer rl.UnloadImage(med_image)
    rl.ImageResize(&med_image, 42, 36)
    med_texture = rl.LoadTextureFromImage(med_image)

    big_image := rl.LoadImage("imgs/2.png")
    defer rl.UnloadImage(big_image)
    rl.ImageResize(&big_image, 122, 96)
    big_texture = rl.LoadTextureFromImage(big_image)
}

createAsteroid :: proc(size: rl.Texture2D, pos: rl.Vector2, vel: rl.Vector2, rot: f32, type: string, alive: bool) {
    if type == "sml" do  append_elems(&asteroids, Asteroids{sml_texture, pos, vel, rot, type, alive})
    if type == "med" do  append_elems(&asteroids, Asteroids{med_texture, pos, vel, rot, type, alive})
    if type == "big" do  append_elems(&asteroids, Asteroids{big_texture, pos, vel, rot, type, alive})
}

destroyAnimation :: proc(center: rl.Vector2, radius: f32, color: rl.Color, alive: bool, timer: int) {
    for i in 1..=10 {
        x1 := center.x + math.sin(f32(i * 36.0)) * radius
        y1 := center.y + math.cos(f32(i * 36.0)) * radius
        velocity := rl.Vector2{x1, y1} - center
        append_elems(&destroy_particles, Destroy{{x1, y1}, .5, color, velocity, alive, timer})
    }
}
