package asteroids

import rl "vendor:raylib"
import "core:math"

Ship :: struct {
    position:     rl.Vector2,
    sides:        i32,
    radius:       f32,
    rotation:     f32,
    color:        rl.Color,
    speed:        rl.Vector2,
    acceleration: f32,
}

SHIP_SPEED :: 6.0
ship:         Ship
immune:       f16
fired:        bool

// Function to create ship
initShip :: proc() {
    fired = false
    immune = 0
    ship.sides = 3
    ship.radius = 15
    ship.position = {WIDTH / 2, HEIGHT / 2}
    ship.rotation = 30
    ship.acceleration = 0
    ship.speed = {0, 0}
    ship.color = rl.RED
}

shipControls :: proc() {
    if !pause {
        using ship
        // Controls for thrust and braking
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
        // Calculate ship trajectory
        speed.x = math.sin((rotation - 30) * rl.DEG2RAD) * SHIP_SPEED
        speed.y = math.cos((rotation - 30) * rl.DEG2RAD) * SHIP_SPEED
        position.x += (speed.x * acceleration)
        position.y -= (speed.y * acceleration)

        // Ship rotation
        if rl.IsKeyDown(.LEFT) do rotation -= 5
        if rl.IsKeyDown(.RIGHT) do rotation += 5

        // Calculate front of ship and create bullets in front of it
        x1 := ship.position.x + (ship.radius * math.cos((ship.rotation + 240) * rl.DEG2RAD))
        y1 := ship.position.y + (ship.radius * math.sin((ship.rotation + 240) * rl.DEG2RAD))
        if rl.IsKeyPressed(.SPACE) {
            createBullet({x1, y1}, 2, rl.WHITE, {speed.x, speed.y})
            fired = true
        }
    }
    
    // Mechanics for immmunity
    if fired do immune = 10
    if immune < 10 && !pause do immune += .1
}

shipCollisions :: proc() {
    // Changes ship position when ship goes off screen
    {
        using ship
        if position.x > WIDTH + radius * 2 do position.x = -(radius * 2)
        else if position.x < -(radius * 2) do position.x = WIDTH + (radius * 2)
        if position.y > (HEIGHT + radius * 2) do ship.position.y = -(radius * 2);
        else if position.y < -(radius * 2) do position.y = HEIGHT + radius * 2
    }

    // If not immune check collisions btwn asteroids and ship
    for &j, ast_ind in asteroids {
        asteroid_bb: rl.Rectangle = {(j.rect.x - (j.rect.width / 2)), j.rect.y - (j.rect.height / 2), j.rect.width, j.rect.height}
        if immune >= 10 {
            if rl.CheckCollisionCircleRec(ship.position, ship.radius- 3, asteroid_bb) {
                game_over = true
                last_score = score
            }
        }   
    }
}

drawShip :: proc() {
    // Find back of ship 
    x2 := ship.position.x + (-ship.radius / 1.5 * math.cos((ship.rotation - 120) * rl.DEG2RAD))
    y2 := ship.position.y + (-ship.radius / 1.5 * math.sin((ship.rotation - 120) * rl.DEG2RAD))

    // Draw Ship
    rl.DrawPoly(ship.position, ship.sides, ship.radius, ship.rotation, ship.color)
    // Draw Exhaust 
    rl.DrawPoly({x2, y2}, ship.sides, 5, ship.rotation + 180, rl.YELLOW)
}
        
       
