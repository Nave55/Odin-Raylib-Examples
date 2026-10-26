package conway

import rl "vendor:raylib"

WIDTH :: 960
HEIGHT :: 960
CELL_SIZE :: 6
ROWS :: int(HEIGHT / CELL_SIZE)
COLS :: int(WIDTH / CELL_SIZE)
GREY: rl.Color : {29, 29, 29, 255}
DARK_GREY: rl.Color : {55, 55, 55, 255}
fps: i32 = 12
running := false
cells: [COLS][ROWS]int
tmp_cells: [COLS][ROWS]int

main :: proc() {
	rl.InitWindow(WIDTH, HEIGHT, "Game of Life")
	defer rl.CloseWindow()
	rl.SetTargetFPS(fps)

	for !rl.WindowShouldClose() do update_game()
}

draw_cells :: proc() {
	for row in 0 ..< ROWS {
		for col in 0 ..< COLS {
			color := cells[row][col] == 1 ? rl.GREEN : DARK_GREY
			rl.DrawRectangle(
				i32(col * CELL_SIZE),
				i32(row * CELL_SIZE),
				i32(CELL_SIZE - 1),
				i32(CELL_SIZE - 1),
				color,
			)
		}
	}
}

fill_random :: proc() {
	if !running {
		for row in 0 ..< ROWS {
			for col in 0 ..< COLS {
				cells[row][col] = rl.GetRandomValue(0, 3) == 1 ? 1 : 0
			}
		}
	}
}

clear_grid :: proc() {
	if !running {
		for row in 0 ..< ROWS {
			for col in 0 ..< COLS {
				cells[row][col] = 0
			}
		}
	}
}

count_live_nbrs :: proc(row, col: int) -> (live_neighbors := 0) {
	c0 := (col - 1 + COLS) % COLS
	c1 := col
	c2 := (col + 1) % COLS
	r0 := &cells[(row - 1 + ROWS) % ROWS]
	r1 := &cells[row]
	r2 := &cells[(row + 1) % ROWS]

	return r0[c0] + r0[c1] + r0[c2] + r1[c0] + r1[c2] + r2[c0] + r2[c1] + r2[c2]
}

update_sim :: proc() {
	if running {
		for row in 0 ..< ROWS {
			for col in 0 ..< COLS {
				live_neighbors := count_live_nbrs(row, col)
				cell_value := cells[row][col]

				if cell_value == 1 {
					tmp_cells[row][col] = (live_neighbors > 3 || live_neighbors < 2) ? 0 : 1
				} else {
					tmp_cells[row][col] = live_neighbors == 3 ? 1 : 0
				}
			}
		}
		for row in 0 ..< ROWS {
			for col in 0 ..< COLS {
				cells[row][col] = tmp_cells[row][col]
			}
		}
	}
}

controls :: proc() {
	if rl.IsKeyPressed(.ENTER) do running = !running
	if rl.IsKeyPressed(.R) do fill_random()
	if rl.IsKeyPressed(.C) do clear_grid()
	if rl.IsKeyPressed(.F) || rl.IsKeyPressed(.S) {
		if rl.IsKeyPressed(.F) do fps += 2
		if rl.IsKeyPressed(.S) && fps > 5 do fps -= 2
		rl.SetTargetFPS(fps)
	}
}

draw_game :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(GREY)
	draw_cells()
}

update_game :: proc() {
	controls()
	update_sim()
	draw_game()
	if running do rl.SetWindowTitle(rl.TextFormat("Game of Life is Running at %v fps", fps))
	else do rl.SetWindowTitle("Game of Life is Paused")
}
