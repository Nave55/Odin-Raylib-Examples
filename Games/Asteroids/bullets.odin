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

bulletCollisions :: proc() {
    if len(bullets) > 0 {
        // Labels bullets when they go off screen
        for &i, bul_ind in bullets {
            if i.center.x + i.radius >= WIDTH || i.center.x - i.radius <= 0 do i.alive = false
            if i.center.y + i.radius >= HEIGHT || i.center.y - i.radius <= 0 do i.alive = false

            if len(asteroids) > 0 {
                // Labels asteroids and bullets when they collide and shows explosion animation
                for &j, ast_ind in asteroids {
                    asteroid_bb: rl.Rectangle = {(j.rect.x - j.rect.width / 2), j.rect.y - j.rect.height / 2, j.rect.width, j.rect.height}
                    if rl.CheckCollisionCircleRec(i.center, i.radius, asteroid_bb)  {
                        i.alive = false
                        j.alive = false
                        destroyAnimation({j.rect.x, j.rect.y}, j.rect.width / 4, rl.GRAY, true, 0)
                    }
                }
            }
        }
    }

    // Removes bullets that aren't alive
    for &i, bul_ind in bullets {
        if i.alive == false do unordered_remove(&bullets, bul_ind)
    }
}

drawBullets :: proc() {
    // Draw bullets
    for &i in bullets {
        rl.DrawCircleV(i.center, i.radius, i.color)
        if !pause do i.center += {i.velocity.x * 1.5, -i.velocity.y * 1.5}
    }
}