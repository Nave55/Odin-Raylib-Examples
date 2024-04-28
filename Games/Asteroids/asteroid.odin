package asteroids

import rl "vendor:raylib"

Asteroids :: struct {
    asteroid: rl.Texture2D,
    pos: rl.Vector2,
    vel: rl.Vector2,
    rot: f32,
    type: string,
    alive: bool,
}

sml_texture: rl.Texture2D
med_texture: rl.Texture2D
big_texture: rl.Texture2D

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

destroyAnimation :: proc() {
}

asteroids: [dynamic]Asteroids