package box

import rl "vendor:raylib"
import b2 "vendor:box2d"
import "core:fmt"

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720
time_step: f32 
sub_steps: i32
world_id: b2.World_ID
body_id: [2]b2.Body_ID
position: [2][2]f32
angle: f32

main :: proc() {
    rl.SetConfigFlags({.MSAA_4X_HINT})
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Box2D")
    defer rl.CloseWindow()
    // rl.SetTargetFPS(60)
    initGame()
    defer b2.destroy_world(world_id)

    for !rl.WindowShouldClose() do updateGame()
    
}

invertY :: proc(y, height: f32) -> f32 {
    return y + height
}

initGame :: proc() {
    world_def := b2.default_world_def()
    world_def.gravity = b2.Vec2{0, 10}
    world_id = b2.create_world(&world_def)

    ground_body_def := b2.default_body_def()
    ground_body_def.position = b2.Vec2{0, invertY(600, 120)}
    ground_body_id := b2.create_body(world_id, &ground_body_def)

    ground_box := b2.make_box(1280, 120)
    ground_shape_def := b2.default_shape_def()
    ground_shape_def.friction = .1
    ground_shape_def.density = .2
    b2.create_polygon_shape(ground_body_id, &ground_shape_def, &ground_box)

    body_def := b2.default_body_def()
    body_def.type = .Dynamic
    body_def.position = b2.Vec2{600, 400}
    body_def.angular_damping = .1
    body_id[0] = b2.create_body(world_id, &body_def)

    body_def2 := b2.default_body_def()
    body_def2.type = .Dynamic
    body_def2.position = b2.Vec2{605, invertY(0, 20)}
    body_def2.angular_damping = .1
    body_id[1] = b2.create_body(world_id, &body_def2)

    shape_def := b2.default_shape_def()
    shape_def.density = 1
    shape_def.friction = .3

    circle := b2.Circle{{0, 0}, 20}
    b2.create_circle_shape(body_id[0], &shape_def, &circle)
  
    box := b2.make_box(40, 40)
    b2.create_polygon_shape(body_id[1], &shape_def, &box)
    
    time_step = 1.0 / 60
    sub_steps = 4
}

updateB2D :: proc() {
    b2.world_step(world_id, time_step, sub_steps)
    position[0] = b2.body_get_position(body_id[0])
    position[1] = b2.body_get_position(body_id[1])
    angle = b2.body_get_angle(body_id[0])
    // fmt.println(position, angle)
}

drawGame :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()
    rl.ClearBackground(rl.BLACK)

    rl.DrawCircleV(position[0], 20, rl.GREEN) 
    rl.DrawRectangleV(position[1] - {20, 0}, {40, 40}, rl.YELLOW)

    rl.DrawRectangle(0, 600, 1280, 120, rl.RED)
}

updateGame :: proc() {
    updateB2D()
    drawGame()
}
