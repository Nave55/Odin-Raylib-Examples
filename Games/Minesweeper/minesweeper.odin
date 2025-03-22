package minesweeper

/*******************************************************************************************
*
*   Minesweeper (16x16)
*   Sample game ported to Odin based off the Microsoft game. 
*
********************************************************************************************/

import sa "core:container/small_array"
import "core:fmt"
import "core:math"
import "core:slice"
import "core:time"
import "core:mem"
import vm "core:mem/virtual"
import rl "vendor:raylib"

// enum for tile markings
Mark :: enum {
	Clear,
	Flag,
	Question,
}

// struct which makes up the grid
TileInfo :: struct {
	using rect: rl.Rectangle,
	grid_pos:   [2]int,
	revealed:   bool,
	value:      int,
	mark:       Mark,
}

// Game Data to be passed to functions
GameData :: struct {
	game_over: bool,
	first_move: bool,
	bombs_left: i32,
	victory:    bool,
	stopwatch:  time.Stopwatch,
	visited:    map[[2]int]struct{},
	int_map:    map[int]rl.Texture2D,
	enum_map:   map[Mark]rl.Texture2D,
}

// global constants
SCREEN_WIDTH :: 687
SCREEN_HEIGHT :: 777
COLS :: 16
ROWS :: 16
TILE_SIZE :: 40
BOMBS :: 40

// grid 
grid: [16][16]TileInfo

// main proc
main :: proc() {
	arena: vm.Arena
	err := vm.arena_init_static(&arena, 4 * mem.Kilobyte)
    	assert(err == .None)
    	arena_allocator := vm.arena_allocator(&arena)
    	defer vm.arena_destroy(&arena)

	rl.SetTraceLogLevel(.NONE)
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Minesweeper")
	defer rl.CloseWindow()
	rl.SetTargetFPS(30)

	// unloadGame(&game_data)
	game_data := initGameData(arena_allocator)
	loadTextures(&game_data)
	initGame(&game_data)

	for !rl.WindowShouldClose() do updateGame(&game_data, &arena)
}

// Main Game Loop Functions

@require_results
initGameData :: proc(arena_allocator: mem.Allocator) -> GameData {
	game_data := GameData {
		false,
		true,
		0,
		false,
		{},
		make(map[[2]int]struct{}, 100, context.temp_allocator),
		make(map[int]rl.Texture2D, arena_allocator),
		make(map[Mark]rl.Texture2D, arena_allocator),
	}

	return game_data
} 

// initialize game on each start
initGame :: proc(game_data: ^GameData) {
	if len(game_data.visited) > 0 do clear(&game_data.visited)
	game_data.first_move = true
	game_data.game_over = false
	game_data.victory = false
	time.stopwatch_reset(&game_data.stopwatch)
	initalizeGrid()
}

// main control proc. calls other small control procs
controls :: proc(game_data: ^GameData, arena: ^vm.Arena) {
	if rl.IsMouseButtonReleased(.LEFT) {
		if !game_data.game_over do unveilTile(game_data)
		if hoverSmiley() do initGame(game_data)
	}

	if rl.IsMouseButtonReleased(.RIGHT) {
		if !game_data.game_over do markTile()
	}
}

// main draw call
drawGame :: proc(game_data: ^GameData) {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.DrawTexture(game_data.int_map[-4], 0, 0, 255)
	drawTextures(game_data)
	drawBombTracker(game_data^)
	drawTimer(game_data)
}

// update game loop
updateGame :: proc(game_data: ^GameData, arena: ^vm.Arena) {
	controls(game_data, arena)
	bombsAndVictory(game_data)
	drawGame(game_data)
}

// Grid Functions for init
// initializes all tiles starting conditions
initalizeGrid :: proc() {
	for &r_val, r_ind in grid {
		for &c_val, c_ind in r_val {
			c_val = {
				{f32(c_ind * TILE_SIZE) + 21, f32(r_ind * TILE_SIZE) + 116, TILE_SIZE, TILE_SIZE},
				{r_ind, c_ind},
				false,
				0,
				.Clear,
			}
		}
	}
}
// sets all tile values
setGridVals :: proc(pos: [2]int) {
	x := make(map[i32]struct{}, context.temp_allocator)
	defer free_all(context.temp_allocator)

	num := i32(pos.x * 16 + pos.y)

	for len(x) < BOMBS {
		val := rl.GetRandomValue(0, 255)
		for val == num do val = rl.GetRandomValue(0, 255)
		x[val] = {}
	}

	ttl: i32 = 0
	for r_val, r_ind in grid {
		for c_val, c_ind in r_val {
			if ttl in x {
				grid[r_ind][c_ind].value = -1
			}
			ttl += 1
		}
	}
	setTileVals(&grid)
}

// Controls

// Reveal tile. 
unveilTile :: proc(game_data: ^GameData) {
	m_pos := rl.GetMousePosition()
	t_pos := getTilePos(m_pos)
	if inBounds(t_pos, 16, 16) {
		if game_data.first_move {
			game_data.first_move = false
			setGridVals(t_pos)
			time.stopwatch_start(&game_data.stopwatch)
		}
		val := fetchVal(&grid, t_pos)
		if val.mark == .Clear {
			dfs(&grid, t_pos, &game_data.visited)

			if val.revealed && val.value == -1 do game_data.game_over = true
		}
	}
}

// Returns a tile pos if you are hovering a tile that hasn't been revealed
hoverTile :: proc() -> (t_pos: [2]int) {
	if rl.IsMouseButtonDown(.LEFT) {
		m_pos := rl.GetMousePosition()
		t_pos = getTilePos(m_pos)
		if inBounds(t_pos, 16, 16) {
			if fetchVal(&grid, t_pos).revealed == false do return
		}
	}
	return {-1, -1}
}

// If right click release cycle through clear, bomb, and question enum.
markTile :: proc() {
	m_pos := rl.GetMousePosition()
	t_pos := getTilePos(m_pos)
	if inBounds(t_pos, 16, 16) {
		val := fetchVal(&grid, t_pos)
		if !val.revealed {
			switch val.mark {
			case .Clear:
				val.mark = .Flag
			case .Flag:
				val.mark = .Question
			case .Question:
				val.mark = .Clear
			}
		}
	}
}

// Checks if hovering over smiley face
@require_results
hoverSmiley :: proc() -> bool {
	face_loc: rl.Vector2 = {336, 56}
	m_pos := rl.GetMousePosition()
	x_pos := abs(face_loc.x - m_pos.x)
	y_pos := abs(face_loc.y - m_pos.y)
	return x_pos <= 36 && y_pos <= 36
}

// checks how many bombs are left and also victory conditions
bombsAndVictory :: proc(game_data: ^GameData) {
	clear: i32 = 0
	bombs: i32 = 0
	for &i in grid {
		for &j in i {
			if game_data.victory && j.value == -1 do j.mark = .Flag
			if !game_data.victory && game_data.game_over && j.value == -1 && j.revealed && j.mark == .Clear {
				j.value -= 1
			}
			if j.mark == .Flag do bombs += 1
			if j.revealed && j.value >= 0 do clear += 1
		}
	}

	if clear == ROWS * COLS - BOMBS {
		game_data.game_over = true
		game_data.victory = true
	}

	game_data.bombs_left = BOMBS - bombs
}

// Load all textures
loadTextures :: proc(game_data: ^GameData) {
	game_data.enum_map[.Clear] = rl.LoadTexture("textures/tile.png")
	game_data.enum_map[.Flag] = rl.LoadTexture("textures/flag.png")
	game_data.enum_map[.Question] = rl.LoadTexture("textures/question.png")
	game_data.int_map[-4] = rl.LoadTexture("textures/board.png")
	game_data.int_map[-3] = rl.LoadTexture("textures/bad_marked.png")
	game_data.int_map[-2] = rl.LoadTexture("textures/exploded.png")
	game_data.int_map[-1] = rl.LoadTexture("textures/bomb.png")
	game_data.int_map[0] = rl.LoadTexture("textures/clear.png")	
	game_data.int_map[1] = rl.LoadTexture("textures/one.png")
	game_data.int_map[2] = rl.LoadTexture("textures/two.png")
	game_data.int_map[3] = rl.LoadTexture("textures/three.png")
	game_data.int_map[4] = rl.LoadTexture("textures/four.png")
	game_data.int_map[5] = rl.LoadTexture("textures/five.png")
	game_data.int_map[6] = rl.LoadTexture("textures/six.png")
	game_data.int_map[7] = rl.LoadTexture("textures/seven.png")
	game_data.int_map[8] = rl.LoadTexture("textures/eight.png")
	game_data.int_map[9] = rl.LoadTexture("textures/smile.png")
	game_data.int_map[10] = rl.LoadTexture("textures/frown.png")
	game_data.int_map[11] = rl.LoadTexture("textures/surprise.png")
	game_data.int_map[12] = rl.LoadTexture("textures/sunglasses.png")
	game_data.int_map[13] = rl.LoadTexture("textures/smile_clear.png")
}
	
// Draw Textures
drawTextures :: proc(game_data: ^GameData) {
	for &i in grid {
		for &j in i {
			drawEnumMapTiles(&j, game_data)
			drawIntMapTiles(&j, game_data)
		}
	}
	drawFaces(game_data)
}

// Draw Everything that's not revealed
drawEnumMapTiles :: proc(j: ^TileInfo, game_data: ^GameData) {
	if !j.revealed {
		switch j.mark {
		case .Clear:
			if j.grid_pos == hoverTile() && !game_data.game_over {
				rl.DrawTexture(game_data.int_map[0], i32(j.x), i32(j.y), 255)
			} else {
				rl.DrawTexture(game_data.enum_map[.Clear], i32(j.x), i32(j.y), 255)

			}
		case .Flag:
			if game_data.game_over && j.value != -1 {
				rl.DrawTexture(game_data.int_map[-3], i32(j.x), i32(j.y), 255)
			} else {
				rl.DrawTexture(game_data.enum_map[.Flag], i32(j.x), i32(j.y), 255)

			}
		case .Question:
			rl.DrawTexture(game_data.enum_map[.Question], i32(j.x), i32(j.y), 255)
		}

		if !game_data.victory && game_data.game_over && j.value == -1 && j.mark != .Flag {
			rl.DrawTexture(game_data.int_map[-1], i32(j.x), i32(j.y), 255)
		}
	}
}

// Draw Everyting revealed
drawIntMapTiles :: proc(j: ^TileInfo, game_data: ^GameData) {
	if j.revealed {
		rl.DrawTexture(game_data.int_map[j.value], i32(j.x), i32(j.y), 255)
	}
}

// Draw Faces
drawFaces :: proc(game_data: ^GameData) {
	if !game_data.game_over {
		tile := hoverTile()
		if tile.x >= 0 && tile.y >= 0 && tile.x <= 15 && tile.y <= 15 {
			rl.DrawTexture(game_data.int_map[11], 300, 20, 255)
		} else do rl.DrawTexture(game_data.int_map[9], 300, 20, 255)
	} else {
		if !game_data.victory do rl.DrawTexture(game_data.int_map[10], 300, 20, 255)
		else do rl.DrawTexture(game_data.int_map[12], 300, 20, 255)
	}

	if rl.IsMouseButtonDown(.LEFT) {
		if hoverSmiley() do rl.DrawTexture(game_data.int_map[13], 300, 20, 255)
	}
}

// Draw Bomb Tracker
drawBombTracker :: proc(game_data: GameData) {
	rect: rl.Rectangle = {30, 30, 100, 50}

	rl.DrawRectangleRec(rect, rl.BLACK)

	rl.DrawText(
		rl.TextFormat("%v", game_data.bombs_left),
		i32(rect.x + rect.width / 2) - rl.MeasureText(rl.TextFormat("%v", game_data.bombs_left), 40) / 2,
		i32(rect.y + 10),
		40,
		rl.RED,
	)
}

// Draw Timer
drawTimer :: proc(game_data: ^GameData) {
	hr, min, sec := time.clock_from_stopwatch(game_data.stopwatch)
	ttl := (hr * 60 * 60) + (min * 60) + sec
	rect: rl.Rectangle = {SCREEN_WIDTH - 135, 30, 100, 50}

	rl.DrawRectangleRec(rect, rl.BLACK)

	rl.DrawText(
		rl.TextFormat("%v", ttl),
		i32(rect.x + rect.width / 2) - rl.MeasureText(rl.TextFormat("%v", ttl), 40) / 2,
		i32(rect.y + 10),
		40,
		rl.RED,
	)

	if game_data.game_over do time.stopwatch_stop(&game_data.stopwatch)
}

// Helper Functions

// Checks if pos is within bounds of the grid
@require_results
inBounds :: proc(pos: [2]int, width, height: int) -> bool {
	return pos.x >= 0 && pos.y >= 0 && pos.x < height && pos.y < width
}

// Retrieves value from grid given [2]int pos
@require_results
fetchVal :: proc(mat: ^[16][16]TileInfo, pos: [2]int) -> ^TileInfo {
	return &mat[pos.x][pos.y]
}

// Find Indexes and values in 8 directions from a given [2]int pos
@require_results
nbrs :: proc(
	mat: ^[16][16]TileInfo,
	pos: [2]int,
) -> (
	inds: sa.Small_Array(8, [2]int),
	vals: sa.Small_Array(8, ^TileInfo),
) {
	width, height := len(mat[0]), len(mat)
	dirs: [8][2]int = {{-1, -1}, {-1, 0}, {-1, 1}, {0, -1}, {0, 1}, {1, -1}, {1, 0}, {1, 1}}

	for val, ind in dirs {
		n_pos := pos + val
		if inBounds(n_pos, width, height) {
			sa.append(&inds, n_pos)
			sa.append(&vals, fetchVal(mat, n_pos))
		}
	}

	return inds, vals
}

// Prints Grid To Console if you want to verify values.
printGridVals :: proc(mat: ^[16][16]TileInfo) {
	for i in mat {
		fmt.print("[")
		for j, ind in i {
			if ind % 15 != 0 || ind == 0 do fmt.printf("%v, ", j.value)
			else do fmt.print(j.value)
		}

		fmt.print("]\n")
	}
}

// Calculates tile pos in grid from a Vector2d
@require_results
getTilePos :: proc(pos: rl.Vector2) -> [2]int {
	x_pos := int(math.floor((pos.x - 21) / 40))
	y_pos := int(math.floor((pos.y - 116) / 40))
	return {y_pos, x_pos}
}

// Calculates how many bombs each tile touches
setTileVals :: proc(mat: ^[16][16]TileInfo) {
	for &i, c_ind in mat {
		for &j, r_ind in i {
			defer free_all(context.temp_allocator)
			if j.value != -1 {
				_, vals := nbrs(mat, {c_ind, r_ind})
				filt := len(
					slice.filter(
						sa.slice(&vals),
						proc(tile: ^TileInfo) -> bool {return tile.value == -1},
						context.temp_allocator,
					),
				)
				j.value = filt
			}
		}
	}
}

// Debug function that can print value to screen for visualization
debugGame :: proc(val: $T, col: rl.Color = rl.RED, size: i32 = 20, x: i32 = 5, y: i32 = 0) {
	rl.DrawText(rl.TextFormat("%v", val), x, y, size, col)
}

// If you click a tile it will run a dfs to see what tiles should be revealed
dfs :: proc(mat: ^[16][16]TileInfo, pos: [2]int, mp: ^map[[2]int]struct{}) {
	val := fetchVal(mat, pos)

	val.revealed = true
	val.mark = .Clear
	if val.value != 0 || pos in mp do return

	mp[pos] = {}

	inds, _ := nbrs(mat, pos)
	for i in sa.slice(&inds) {
		b := fetchVal(mat, i)
		if b.value > 0 {
			b.revealed = true
			b.mark = .Clear
		}
		dfs(mat, i, mp)
	}
}
