package box

import "core:unicode/utf8/utf8string"
/*************************************************************************************************************
*
*   simple box2d implementation
*   
*   controls - 'left click' adds objects, and 'right click' deletes them
*              'x' alternates betweeen boxes and balls
*              'w' and 's' change the size of the balls and boxes depending on which is selected
*              'c' changes the color of the boxes and balls depending on which is selected       
*              'a' decreases time_step and 'b' increases time_step
*              'space' stops all movement   
*               'r' resets the simulation           
*
*   Created by Evan Martinez (@Nave55)
*
***************************************************************************************************************/

import "core:fmt"
import b2 "vendor:box2d"
import rl "vendor:raylib"

ObjType :: enum {
	Ball,
	Box,
}

Entity :: struct {
	body_id: b2.BodyId,
	pos:     rl.Vector2,
	dim:     rl.Vector2,
	col:     rl.Color,
	ang:     b2.Rot,
	move:    bool,
	type:    ObjType,
}

SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720
time_step: f32
sub_steps: i32
world_id: b2.WorldId
entities: [dynamic]Entity
pause: bool
obj_size: f32
selector: ObjType
clr: u8

main :: proc() {
	rl.SetTraceLogLevel(.ERROR)
	rl.SetConfigFlags({.MSAA_4X_HINT})
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Box2D")
	rl.SetTargetFPS(1000)
	defer {
		rl.CloseWindow()
		unloadGame()
	}
	initGame()

	for !rl.WindowShouldClose() do updateGame()
}

// procedures to help with printing text for simulation
debugGame1 :: proc(val: $T, col: rl.Color = rl.RED, size: i32 = 20, x: i32 = 5, y: i32 = 0) {
	rl.DrawText(rl.TextFormat("%v", val), x, y, size, col)
}

debugGame2 :: proc(
	val: $T,
	descrip: string,
	col: rl.Color = rl.RED,
	size: i32 = 20,
	x: i32 = 5,
	y: i32 = 0,
) {
	rl.DrawText(rl.TextFormat("%v: %v", descrip, val), x, y, size, col)
}

debugGame :: proc {
	debugGame1,
	debugGame2,
}

// invert y position for box2d
invertY :: proc(y, height: f32) -> f32 {
	return y + height
}

// translate box2d position to raylib coordinates
rayPos :: proc(pos, dim: rl.Vector2, t: ObjType, move: bool) -> rl.Vector2 {
	pos := pos
	if t == .Box {
		if !move do pos.y -= dim.y
		else {
			pos.x -= dim.x
			pos.y -= dim.y
		}
	}
	return pos
}

u8ToColor :: proc(val: u8) -> rl.Color {
	switch val {
	case 0:
		return rl.BLUE
	case 1:
		return rl.GREEN
	case 2:
		return rl.YELLOW
	case 3:
		return rl.PURPLE
	case 4:
		return rl.ORANGE
	}

	return rl.BLUE
}

// init game with starting state
initGame :: proc() {
	clr = 0
	obj_size = 20
	selector = .Box
	pause = false
	time_step = 1.0 / 60
	sub_steps = 4
	clear(&entities)

	// initialize simulation world
	world_def := b2.DefaultWorldDef()
	world_def.gravity = b2.Vec2{0, 9}
	world_id = b2.CreateWorld(world_def)

	// walls
	boxEntityInit({0, 600}, {1280, 120}, rl.GRAY, {}, false, .Box, .1, .2)
	boxEntityInit({0, 0}, {1, 720}, rl.GRAY, {}, false, .Box, .1, .2)
	boxEntityInit({1279, 0}, {1, 720}, rl.GRAY, {}, false, .Box, .1, .2)
	// boxEntityInit({0, 1},    {1280, 1},    rl.GRAY,  false, "box", .1, .2)

}

// procedure to create boxes and balls
boxEntityInit :: proc(
	pos, dim: rl.Vector2,
	col: rl.Color,
	ang: b2.Rot,
	move: bool,
	type: ObjType,
	fric, dens: f32,
	a_dam: f32 = 0,
) {

	// body def
	body_def := b2.DefaultBodyDef()
	if move do body_def.type = .dynamicBody
	else do body_def.type = .staticBody
	body_def.position = b2.Vec2{pos.x, invertY(pos.y, dim.y)}
	body_def.angularDamping = a_dam
	body_id := b2.CreateBody(world_id, body_def)

	// shape_def
	shape_def := b2.DefaultShapeDef()
	shape_def.material.friction = fric
	shape_def.density = dens

	// creates boxes and balls
	if type == .Box {
		box := b2.MakeBox(dim.x, dim.y)
		_ = b2.CreatePolygonShape(body_id, shape_def, box)
	} else if type == .Ball {
		circle := b2.Circle{{0, 0}, dim.x}
		_ = b2.CreateCircleShape(body_id, shape_def, circle)
	}

	// add entity to entities array
	ent := Entity{body_id, pos, dim, col, ang, move, type}
	append(&entities, ent)
}

gameControls :: proc() {
	// press 'r' to restart simulation
	if rl.IsKeyPressed(.R) do initGame()

	// pres 'space' to pause all motion
	if rl.IsKeyPressed(.SPACE) do pause = !pause

	// 'left click' add balls at mouse location and 'right click' add balls at mouse location
	if rl.IsMouseButtonPressed(.LEFT) {
		if selector == .Ball {
			boxEntityInit(
				rl.GetMousePosition(),
				{obj_size, obj_size},
				u8ToColor(clr),
				{1, 1},
				true,
				.Ball,
				.3,
				1,
				.1,
			)
		} else {
			boxEntityInit(
				rl.GetMousePosition(),
				{obj_size, obj_size},
				u8ToColor(clr),
				{1, 1},
				true,
				.Box,
				.3,
				1,
				.1,
			)
		}
	}

	if rl.IsMouseButtonPressed(.RIGHT) {
		m_pos := rl.GetMousePosition()
		for &val, i in entities {
			pos := val.pos
			if val.type == .Ball {
				if rl.CheckCollisionPointCircle(m_pos, val.pos, val.dim[0]) {
					b2.DestroyBody(val.body_id)
					unordered_remove(&entities, i)
				}
			} else {
				if val.col != rl.GRAY {
					if rl.CheckCollisionPointRec(
						m_pos,
						{
							val.pos.x - val.dim.x,
							val.pos.y - val.dim.y,
							val.dim.x * 2,
							val.dim.y * 2,
						},
					) {
						b2.DestroyBody(val.body_id)
						unordered_remove(&entities, i)
					}
				}
			}
		}
	}

	// press 's' changes between boxes and balls for color and size changes
	if rl.IsKeyPressed(.X) {
		if selector == .Ball do selector = .Box
		else do selector = .Ball
	}

	// press 'up' or 'down' to change boxes and ball size
	if rl.IsKeyPressed(.W) do obj_size += 10
	if rl.IsKeyPressed(.S) do obj_size -= 10

	// pressing 'c' changes color of boxes and balls depending on selector
	if rl.IsKeyPressed(.C) do clr = (clr + 1) % 5

	// press 'a' to slow simulation and 'd' to speed it up
	if rl.IsKeyPressed(.D) do time_step += .001
	if rl.IsKeyPressed(.A) do time_step -= .001
}

// updates simulation based on time step and sub steps
updateB2D :: proc() {
	if !pause {
		b2.World_Step(world_id, time_step, sub_steps)

		for &i in entities {
			i.pos = b2.Body_GetPosition(i.body_id)
			i.ang = b2.Body_GetRotation(i.body_id)
		}
	}
}

// draw all entities and text
drawGame :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.BLACK)

	for &i in entities {
		using i
		if i.type == .Box {
			if move {
				rot := b2.Rot_GetAngle(b2.Body_GetRotation(body_id))
				posi := rayPos(pos, dim, type, move)
				rl.DrawRectanglePro(
					{pos.x, pos.y, dim.x * 2, dim.y * 2},
					{dim.x, dim.y},
					rot * (180 / 3.14),
					col,
				)
			} else do rl.DrawRectangleV(rayPos(pos, dim, type, move), dim, col)
		}
		if i.type == .Ball do rl.DrawCircleV(rayPos(pos, dim, type, move), dim.x, col)
	}

	mouse := rl.GetMousePosition()
	if selector == .Box {
		b_clr := u8ToColor(clr)
		rl.DrawRectangleRec(
			{mouse.x - obj_size, mouse.y - obj_size, obj_size * 2, obj_size * 2},
			{b_clr.r, b_clr.g, b_clr.b, 200},
		)
	}

	if selector == .Ball {
		b_clr := u8ToColor(clr)
		rl.DrawCircleV({mouse.x, mouse.y}, obj_size, {b_clr.r, b_clr.g, b_clr.b, 200})
	}

	if pause do rl.DrawText("PRESS SPACE TO CONTINUE", SCREEN_WIDTH / 2 - rl.MeasureText("PRESS SPACE TO CONTINUE", 40) / 2, SCREEN_HEIGHT / 2 - 50, 40, rl.RED)
}

updateGame :: proc() {
	gameControls()
	updateB2D()
	drawGame()
}

unloadGame :: proc() {
	b2.DestroyWorld(world_id)
	delete(entities)
}
