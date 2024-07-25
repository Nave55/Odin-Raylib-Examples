package box

import rl "vendor:raylib"
import b2 "vendor:box2d"
import "core:fmt"

Entity :: struct {
    body_id: b2.Body_ID,
    pos: rl.Vector2,
    dim: rl.Vector2,
    col: rl.Color,
    move: bool,
    type: string,
}

Selector :: enum {
    Ball,
    Box,
}

Colors :: enum {
    Green,
    Blue,
    Yellow,
    Purple,
    Orange,
}

c_Struct :: struct {
    c_enum: Colors,
    color: rl.Color
}

SCREEN_WIDTH  :: 1280
SCREEN_HEIGHT :: 720
time_step:       f32 
sub_steps:       i32
world_id:        b2.World_ID
entities:        [dynamic]Entity
angle:           f32
pause:           bool
box_size:        f32
ball_size:       f32
selector:        Selector
clr:             [5]c_Struct
c_mode:          [2]u8


main :: proc() {
    rl.SetConfigFlags({.MSAA_4X_HINT})
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Box2D")
    // rl.SetTargetFPS(60)
    defer { 
        rl.CloseWindow()
        unloadGame()
    }
    time_step = 1.0 / 60
    sub_steps = 4
    initGame()

    for !rl.WindowShouldClose() do updateGame()   
}

debugGame1 :: proc(val: $T, col: rl.Color = rl.RED, size: i32 = 20,  x: i32 = 5, y: i32 = 0) {
    rl.DrawText(rl.TextFormat("%v", val), 
                x,
                y,
                size, 
                col)
}

debugGame2 :: proc(val: $T, descrip: string, col: rl.Color = rl.RED, size: i32 = 20,  x: i32 = 5, y: i32 = 0) {
    rl.DrawText(rl.TextFormat("%v: %v", descrip, val), 
                x,
                y,
                size, 
                col)
}

debugGame :: proc{
    debugGame1,
    debugGame2,
}


invertY :: proc(y, height: f32) -> f32 {
    return y + height
}

rayPos :: proc(pos, dim: rl.Vector2, t: string, move: bool) -> rl.Vector2 {
    pos := pos
    if t == "box" {
        if !move do pos.y -= dim.y
        else {
            pos.x -= dim.x
            pos.y -= dim.y
        }
    }
    return pos
}

initGame :: proc() {
    c_mode =    {0, 1}
    box_size =  20
    ball_size = 20
    selector = .Box
    pause =    false
    clr =   {{.Blue, rl.BLUE}, {.Green, rl.GREEN}, {.Yellow, rl.YELLOW}, {.Purple, rl.PURPLE}, {.Orange, rl.ORANGE}}
    clear(&entities)

    // initialize simulation world
    world_def := b2.default_world_def()
    world_def.gravity = b2.Vec2{0, 10}
    world_id = b2.create_world(&world_def)


    // wall
    boxEntityInit({0, 600},  {1280, 120}, rl.GRAY,  false, "box", .1, .2)
    boxEntityInit({0, 0},    {1, 720},    rl.GRAY,  false, "box", .1, .2)
    boxEntityInit({1279, 0}, {1, 720},    rl.GRAY,  false, "box", .1, .2)
    boxEntityInit({0, 1},    {1280, 1},    rl.GRAY,  false, "box", .1, .2)

}

boxEntityInit :: proc(pos, dim: rl.Vector2, col: rl.Color, move: bool, type: string, fric, dens: f32, a_dam: f32 = 0 ) {
    pos := pos
    body_def := b2.default_body_def()
    if move do body_def.type = .Dynamic
    body_def.position = b2.Vec2{pos.x, invertY(pos.y, dim.y)}
    body_def.angular_damping = a_dam
    body_id := b2.create_body(world_id, &body_def)
    
    shape_def := b2.default_shape_def()
    shape_def.friction = fric
    shape_def.density = dens
    
    if type == "box" {
        box := b2.make_box(dim.x, dim.y)
        b2.create_polygon_shape(body_id, &shape_def, &box)
    }
    else if type == "ball" {
        circle := b2.Circle{{0, 0}, dim.x}
        b2.create_circle_shape(body_id, &shape_def, &circle)
    }
    
    ent := Entity{body_id, pos, dim, col, move, type}
    append(&entities, ent)
}

gameControls :: proc() {
    if rl.IsKeyPressed(.R) do initGame()
    
    if rl.IsKeyPressed(.SPACE) do pause = !pause
    if rl.IsMouseButtonPressed(.LEFT)  do boxEntityInit(rl.GetMousePosition(), {ball_size, ball_size}, clr[c_mode[0]].color, true, "ball", .3, .1, .1)
    if rl.IsMouseButtonPressed(.RIGHT) do boxEntityInit(rl.GetMousePosition(), {box_size, box_size},   clr[c_mode[1]].color, true, "box",  .3, .1, .1)

    if rl.IsKeyPressed(.S) {
        if selector == .Ball do selector = .Box
        else do selector = .Ball
    }

    if rl.IsKeyPressed(.UP) {
        if selector == .Ball do ball_size += 1
        else do box_size += 1
    }

    if rl.IsKeyPressed(.DOWN) {
        if selector == .Ball do ball_size -= 1
        else do box_size -= 1
    }

    if rl.IsKeyPressed(.C) {
        if selector == .Ball  {
            if c_mode[0] != 4 do c_mode[0] += 1
            else do c_mode[0] = 0
        }
        else {
            if c_mode[1] != 4 do c_mode[1] += 1
            else do c_mode[1] = 0
        }
    }

    if rl.IsKeyPressed(.D) do time_step += .001
    if rl.IsKeyPressed(.A) do time_step -= .001
 }

updateB2D :: proc() {
    if !pause {
        b2.world_step(world_id, time_step, sub_steps)

        for &i in entities {
            i.pos = b2.body_get_position(i.body_id)
            angle = b2.body_get_angle(i.body_id)   
        }
    }
}

drawGame :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()
    rl.ClearBackground(rl.BLACK)

    for &i in entities {
        using i
        if i.type == "box"  do rl.DrawRectangleV(rayPos(pos, dim, type, move), dim * 2, col)
        if i.type == "ball" do rl.DrawCircleV(rayPos(pos, dim, type, move),    dim.x,   col) 
    }

    debugGame(selector,  rl.RED)
    debugGame(box_size,  "Box Size",  clr[c_mode[1]].color, 20, 5, 30)
    debugGame(ball_size, "Ball Size", clr[c_mode[0]].color, 20, 5, 60)

    if pause do rl.DrawText("PRESS SPACE TO CONTINUE", 
                            SCREEN_WIDTH / 2 - rl.MeasureText("PRESS SPACE TO CONTINUE", 40) / 2, 
                            SCREEN_HEIGHT / 2 - 50, 
                            40, 
                            rl.RED)
}

updateGame :: proc() {
    gameControls()
    updateB2D()
    drawGame()
}

unloadGame :: proc() {
    b2.destroy_world(world_id)
    delete(entities) 
}