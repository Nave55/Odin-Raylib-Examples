package asteroids

import rl "vendor:raylib"
import "core:math"

Player :: struct {
    position: rl.Vector2,
    sides: i32,
    radius: f32,
    rotation: f32,
    color: rl.Color,
    speed: rl.Vector2,
    acceleration: f32,
    collider: rl.Vector3,
}

player: Player

createPlayer :: proc() {
    player.sides = 3
    player.radius = 15
    player.position = {WIDTH / 2, HEIGHT / 2}
    player.rotation = 30
    player.acceleration = 0
    player.speed = {0, 0}
    player.collider = {player.position.x + math.sin(player.rotation * rl.DEG2RAD) * ((player.radius * 2) / 2.5), player.position.y - math.cos(player.rotation * rl.DEG2RAD)*((player.radius * 2) / 2.5), 12};
    player.color = rl.RED
}