package asteroids

import rl "vendor:raylib"

Bullets :: struct {
    center: rl.Vector2,
    radius: f32,
    color: rl.Color,
    velocity: rl.Vector2,
    alive: bool,
}

bullets: [dynamic]Bullets

// Function to create bullets
createBullet :: proc(center: rl.Vector2, radius: f32, color: rl.Color, velocity: rl.Vector2, alive: bool) {
    append_elems(&bullets, Bullets({center, radius, color, velocity, alive}))
}
