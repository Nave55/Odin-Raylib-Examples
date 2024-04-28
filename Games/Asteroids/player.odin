package asteroids

import rl "vendor:raylib"

Player :: struct {
    position: rl.Vector2,
    sides: i32,
    radius: f32,
    rotation: f32,
    color: rl.Color,
    speed: rl.Vector2,
    acceleration: f32,
}

player: Player

// Function to create player
createPlayer :: proc() {
    player.sides = 3
    player.radius = 15
    player.position = {WIDTH / 2, HEIGHT / 2}
    player.rotation = 30
    player.acceleration = 0
    player.speed = {0, 0}
    player.color = rl.RED
}
