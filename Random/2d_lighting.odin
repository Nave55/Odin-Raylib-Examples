package lighting

/*******************************************************************************************
*
*   2d lighting effect using ray casting 
*   
*   Created by Evan Martinez (@Nave55)
*
********************************************************************************************/

import "core:fmt"
import "core:math"
import lg "core:math/linalg"
import "core:mem"
import vm "core:mem/virtual"
import "core:slice"
import rl "vendor:raylib"

Intersect :: struct {
	result: bool,
	pos:    rl.Vector2,
}

Obstacle :: struct {
	center:   rl.Vector2,
	radius:   f32,
	sides:    i32,
	color:    rl.Color,
	vertices: [dynamic]rl.Vector2,
}

Data :: struct {
	obstacles:  [7]Obstacle,
	edges:      [4]rl.Vector2,
	intersects: [dynamic]rl.Vector2,
}

S_WIDTH :: 1280
S_HEIGHT :: 800
m_pos: rl.Vector2

main :: proc() {
	arena: vm.Arena
	err := vm.arena_init_static(&arena, 5 * mem.Megabyte)
	assert(err == .None, "Error in Init Arena")
	arena_allocator := vm.arena_allocator(&arena)

	// intersects := make([dynamic])
	rl.InitWindow(S_WIDTH, S_HEIGHT, "Lighting")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	data := initGame(arena_allocator)

	for !rl.WindowShouldClose() do updateGame(&data)
}

// create polygon based off values
createPoly :: proc(
	i: ^Obstacle,
	center: rl.Vector2,
	sides: i32,
	radius: f32,
	color: rl.Color = rl.DARKGRAY,
) {
	i.center = center
	i.sides = sides
	i.radius = radius
	i.color = color

	// create list of vertices for poly
	for j in 0 ..< i.sides {
		pos: rl.Vector2 = {
			i.center.x + math.sin(f32(j * 360 / i.sides + 90) * rl.DEG2RAD) * i.radius,
			i.center.y + math.cos(f32(j * 360 / i.sides + 90) * rl.DEG2RAD) * i.radius,
		}
		append(&i.vertices, pos)
	}
}

makeObject :: proc(allocator: mem.Allocator) -> Obstacle {
	return {{}, 0, 0, {}, make([dynamic]rl.Vector2, allocator)}
}

initGame :: proc(allocator: mem.Allocator) -> Data {
	data := Data {
		{
			makeObject(allocator),
			makeObject(allocator),
			makeObject(allocator),
			makeObject(allocator),
			makeObject(allocator),
			makeObject(allocator),
			makeObject(allocator),
		},
		{
			{0, 0}, // Top left
			{S_WIDTH, 0}, // Top Right
			{0, S_HEIGHT}, // Bottom Left
			{S_WIDTH, S_HEIGHT}, // Bottom Right
		},
		make([dynamic]rl.Vector2, allocator),
	}

	// create polys
	createPoly(&data.obstacles[0], {100, 300}, 3, 90)
	createPoly(&data.obstacles[1], {260, 130}, 4, 80)
	createPoly(&data.obstacles[2], {1100, 400}, 5, 60)
	createPoly(&data.obstacles[3], {700, 200}, 6, 80)
	createPoly(&data.obstacles[4], {320, 600}, 7, 70)
	createPoly(&data.obstacles[5], {800, 700}, 8, 100)
	createPoly(&data.obstacles[6], {620, 450}, 3, 75)

	return data
}

// checks if two lines intersect
lineIntersect :: proc(a, b, c, d: rl.Vector2) -> Intersect {
	r := (b - a)
	s := (d - c)
	rxs := lg.vector_cross2(r, s)
	cma := c - a
	t := lg.vector_cross2(cma, s) / rxs
	u := lg.vector_cross2(cma, r) / rxs
	if t >= 0 && t <= 1 && u >= 0 && u <= 1 do return {true, {a.x + t * r.x, a.y + t * r.y}}
	else do return {false, {0, 0}}
}

// offsets vector2 by radian value
lineOffset :: proc(start, end: rl.Vector2, angle: f32) -> rl.Vector2 {
	x_diff := end.x - start.x
	y_diff := end.y - start.y

	new_x := start.x + math.cos(angle) * x_diff - math.sin(angle) * y_diff
	new_y := start.y + math.sin(angle) * x_diff + math.cos(angle) * y_diff

	return {new_x, new_y}
}

rayCasting :: proc(using data: ^Data) {
	defer free_all(context.temp_allocator)
	//cursor
	m_pos = rl.GetMousePosition()

	clear(&intersects)

	// create array of all intersects
	for i in obstacles {
		for j in i.vertices {
			new1 := lineOffset(m_pos, j, 0.00001)
			new2 := lineOffset(m_pos, j, -0.00001)
			append_elems(&intersects, j)
			append_elems(&intersects, (new1 + (new1 - m_pos) * 100))
			append_elems(&intersects, (new2 + (new2 - m_pos) * 100))
		}
	}

	// create rays that intersect with screen corners
	for i in 0 ..< 4 {
		k := i < 2 ? 0 : 2
		l_inter := lineIntersect(m_pos, edges[i], edges[k], edges[k + 1])
		if l_inter.result do append(&intersects, l_inter.pos)
	}

	// check if a ray that collides with a screen edge collides with an obstacle first and then alter it's position
	for &i in intersects {
		tmp := make([dynamic]rl.Vector2, context.temp_allocator)
		distances := make([dynamic]f32, context.temp_allocator)

		for &j in obstacles {
			for k in 0 ..< len(j.vertices) - 1 {
				inter: Intersect
				inter = lineIntersect(m_pos, i, j.vertices[k], j.vertices[k + 1])
				if inter.result do append_elems(&tmp, inter.pos)
				if k == len(j.vertices) - 2 {
					inter = lineIntersect(m_pos, i, j.vertices[k + 1], j.vertices[0])
					if inter.result do append_elems(&tmp, inter.pos)
				}
			}
		}
		for k in 0 ..< len(tmp) do append(&distances, lg.distance(m_pos, tmp[k]))
		if tmp != nil do i = tmp[slice.min_index(distances[:])]
	}
}

sortIntersects :: proc(i, j: rl.Vector2) -> bool {
	return rl.Vector2LineAngle(m_pos, i) < rl.Vector2LineAngle(m_pos, j)
}

drawFan :: proc(using data: ^Data) {
	// sort intersects by angle
	slice.sort_by(intersects[:], sortIntersects)

	// insert mouse pos at index 0 and first ray to end of array 
	inject_at(&intersects, 0, m_pos)
	append(&intersects, intersects[1])
	rl.DrawTriangleFan(raw_data(intersects), i32(len(intersects)), rl.LIGHTGRAY)
}

drawGame :: proc(using data: ^Data) {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.BLACK)

	for &i in obstacles do rl.DrawPoly(i.center, i.sides, i.radius, 0, i.color)
	drawFan(data)
	rl.DrawCircleV(m_pos, 10, rl.YELLOW)
}

updateGame :: proc(data: ^Data) {
	rl.HideCursor()
	rayCasting(data)
	drawGame(data)
}
