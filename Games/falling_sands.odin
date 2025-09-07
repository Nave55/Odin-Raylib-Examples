package falling_sands

import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

Particles :: enum {
	None,
	Sand,
	Rock,
	Water,
	Steam,
	Fire,
	Wood,
	Smoke,
}

Particle :: struct {
	color:     rl.Color, // color of the particle
	type:      Particles, // type of the particle
	updated:   bool, // flag to prevent multiple updates per frame
	disp_rate: int, // how quickly the particle moves horizontally
	health:    f32, // health of the particle
	moveable:  bool,
}

// Constants
SCREEN_WIDTH :: 800
SCREEN_HEIGHT :: 600
FPS :: 120
CELL_SIZE :: 4
ROWS: int : int(SCREEN_HEIGHT / CELL_SIZE)
COLS: int : int(SCREEN_WIDTH / CELL_SIZE)

// Colors
GREY :: rl.Color{29, 29, 29, 255}
LIGHT_GREY :: rl.Color{55, 55, 55, 255}
SAND_COLOR :: rl.Color{167, 137, 82, 255}
ROCK_COLOR :: rl.Color{115, 104, 101, 255}
WATER_COLOR :: rl.Color{43, 103, 179, 255}
STEAM_COLOR :: rl.Color{180, 156, 151, 255}
FIRE_COLOR :: rl.Color{197, 100, 12, 255}
WOOD_COLOR :: rl.Color{52, 31, 26, 255}
SMOKE_COLOR :: rl.Color{57, 53, 52, 255}

// Variables
cells: [ROWS][COLS]Particle // array for all the particles on screen
p_type: [7]Particles // array containing all the particle enum types
p_num: u8 // index for the p_type array 
m_pos: rl.Vector2 // mouse position
last_m_pos: rl.Vector2 // mouse position
paused: bool // checks if paused
showFPS: bool // shows the fps
brush_size: int // size of the brush

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Falling Sands Simulation")
	rl.SetTargetFPS(FPS)
	defer rl.CloseWindow()

	initGame()
	rl.HideCursor()

	for !rl.WindowShouldClose() do updateGame()
}

// Initialize game state
initGame :: proc() {
	for &row in cells {
		for &cell in row {
			cell = Particle{LIGHT_GREY, .None, false, 0, 1, true}
		}
	}

	p_num = 0
	p_type = {.Sand, .Rock, .Water, .Steam, .Fire, .Wood, .Smoke}
	paused = false
	showFPS = false
	brush_size = 3
	m_pos = {0, 0}
	last_m_pos = {0, 0}
}

// Handle controls
controls :: proc() {
	m_pos = rl.GetMousePosition()
	row := int(m_pos.y / CELL_SIZE)
	col := int(m_pos.x / CELL_SIZE)

	// Interpolate between the last and current mouse positions
	steps := math.max(
		math.max(
			int(math.abs(m_pos.x - last_m_pos.x) / CELL_SIZE),
			int(math.abs(m_pos.y - last_m_pos.y) / CELL_SIZE),
		),
		1,
	)

	for step in 0 ..< steps {
		interp_pos := last_m_pos + (m_pos - last_m_pos) * (f32(step) / f32(steps))
		interp_row := int(interp_pos.y / CELL_SIZE)
		interp_col := int(interp_pos.x / CELL_SIZE)

		if inBounds(interp_row, interp_col) {
			if rl.IsMouseButtonDown(.LEFT) {
				applyBrush(interp_row, interp_col, 'a', p_type[p_num])
			}
			if rl.IsMouseButtonDown(.RIGHT) {
				applyBrush(interp_row, interp_col, 'e')
			}
		}
	}

	last_m_pos = m_pos

	if rl.IsKeyPressed(.R) {
		initGame()
	}

	if rl.IsKeyPressed(.D) {
		p_num = (p_num + 1) %% len(p_type)
	}

	if rl.IsKeyPressed(.A) {
		if p_num > 0 do p_num -= 1
		else do p_num = len(p_type) - 1
	}

	if rl.IsKeyPressed(.SPACE) {
		paused = !paused
	}

	if rl.IsKeyPressed(.F) {
		showFPS = !showFPS
	}

	if rl.IsKeyPressed(.W) {
		brush_size *= 2
	}

	if rl.IsKeyPressed(.S) {
		if brush_size > 1 {
			brush_size /= 2
		}
	}
}

// Update game
updateGame :: proc() {
	controls()

	if !paused do particleSimulation()

	drawGame()
}

// Draw all elements
drawGame :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.BLACK)

	drawGrid()
	drawBrush()

	if showFPS do rl.DrawFPS(10, 10)
}

// Draw particles
drawGrid :: proc() {
	for row in 0 ..< ROWS {
		for col in 0 ..< COLS {
			particle := cells[row][col]

			if particle.type != .None {
				rl.DrawRectangle(
					i32(col * CELL_SIZE),
					i32(row * CELL_SIZE),
					CELL_SIZE,
					CELL_SIZE,
					particle.color,
				)
			}
		}
	}
}

// Draw brush 
drawBrush :: proc() {
	col := int(m_pos.x / CELL_SIZE)
	row := int(m_pos.y / CELL_SIZE)

	brush_size := i32(brush_size * CELL_SIZE)
	color: rl.Color

	#partial switch p_type[p_num] {
	case .Sand:
		color = SAND_COLOR
	case .Rock:
		color = ROCK_COLOR
	case .Water:
		color = WATER_COLOR
	case .Steam:
		color = STEAM_COLOR
	case .Fire:
		color = FIRE_COLOR
	case .Wood:
		color = WOOD_COLOR
	case .Smoke:
		color = SMOKE_COLOR
	}

	rl.DrawRectangle(i32(col * CELL_SIZE), i32(row * CELL_SIZE), brush_size, brush_size, color)
}

// brush that allows you to add or remove particles
applyBrush :: proc(row, col: int, type: rune, particle: Particles = .None) {
	for r in 0 ..< brush_size {
		for c in 0 ..< brush_size {
			c_row := row + r
			c_col := col + c

			if inBounds(c_row, c_col) {
				if type == 'e' {
					removeParticle(c_row, c_col)
				} else if type == 'a' {
					addParticle(c_row, c_col, particle)
				}
			}
		}
	}
}

// Creates rand collors using hsv values
randColor :: proc(h1, h2, s1, s2, v1, v2: f32) -> rl.Color {
	hue := rand.float32_uniform(h1, h2)
	saturation := rand.float32_uniform(s1, s2)
	value := rand.float32_uniform(v1, v2)
	return rl.ColorFromHSV(hue, saturation, value)
}

// set particles color
setParticleColor :: proc(particle: Particles) -> rl.Color {
	#partial switch particle {
	case .None:
		return LIGHT_GREY
	case .Sand:
		return randColor(37, 42, .5, .7, .6, .7)
	case .Rock:
		return randColor(8, 12, .1, .15, .3, .5)
	case .Water:
		return randColor(213, 214, .75, .76, .70, .71)
	case .Steam:
		return randColor(10, 18, .05, .15, .60, .64)
	case .Fire:
		return randColor(25, 40, .80, .95, .70, .90)
	case .Wood:
		return randColor(10, 12, .5, .52, .19, .25)
	case .Smoke:
		return randColor(8, 12, .05, .10, .20, .25)
	}

	return LIGHT_GREY
}

// Utility functions

// checks if particle is in bounds
inBounds :: proc(row, col: int) -> bool {
	return (row >= 0 && row < ROWS) && (col >= 0 && col < COLS)
}

// checks if cells is in bounds and not .None
isEmptyCell :: proc(row, col: int) -> bool {
	return inBounds(row, col) && cells[row][col].type == .None
}

// adds particles
addParticle :: proc(row, col: int, type: Particles) {
	if isEmptyCell(row, col) {
		rate := setDispRate(cells[row][col])
		if type != .Rock && type != .Wood {
			if rand.float32() < 0.15 {
				cells[row][col] = Particle{setParticleColor(type), type, false, rate, 1, true}
			}
		} else {
			cells[row][col] = Particle{setParticleColor(type), type, false, rate, 1, false}
		}
	}
}

// removes particles
removeParticle :: proc(row, col: int) {
	if !isEmptyCell(row, col) {
		cells[row][col] = Particle{LIGHT_GREY, .None, false, 0, 0, true}
	}
}

// sets particles disp rate
setDispRate :: proc(particle: Particle) -> int {
	#partial switch particle.type {
	case .None:
		return 0
	case .Water:
		return 5
	case .Sand:
		return 1
	case .Rock:
		return 0
	case .Steam:
		return 5
	case .Fire:
		return 12
	case .Smoke:
		return 5
	case:
		return 0
	}
	return 0
}

// controls movement based on the disp_rate
dispMovement :: proc(row, col, x, y: int) {
	col := col
	row := row
	moves := 0
	max_moves := cells[row][col].disp_rate

	for moves < max_moves {
		cell := cells[row][col]
		new_col := col + x
		new_row := row + y
		if isEmptyCell(new_row, new_col) {
			swapParticles(row, col, new_row, new_col)
			col = new_col
			row = new_row
			moves += 1
		} else {
			return
		}
	}
}

//check particle
checkParticle :: proc(row, col, r, c: int, type: Particles) -> bool {
	if inBounds(row + r, col + c) {
		return cells[row + r][col + c].type == type ? true : false
	}
	return false
}

particleHealthZero :: proc(
	row, col, r, c: int,
	type, typeto: Particles,
	h_add_s: f32,
	h_add_p: f32,
	extra: rune,
	primary, secondary: bool,
) {
	if checkParticle(row, col, r, c, type) {

		cells[row + r][col + c].health += h_add_s

		if cells[row][col].health < 1 do cells[row][col].health += h_add_p

		if cells[row + r][col + c].health <= .10 {
			if extra == 's' do addSmoke(row + r, col + c)
		}

		if cells[row + r][col + c].health <= 0 {
			// if extra == 's' do addSmoke(row + r, col + c)
			changeParticle(row, col, r, c, 0, type, typeto, primary, secondary)
		}
	}
}

// change particle
changeParticle :: proc(
	row, col, r, c, chance: int,
	typeof, typeto: Particles,
	primary := true,
	secondary := true,
) {
	if inBounds(row + r, col + c) {
		s_part := cells[row + r][col + c]

		if s_part.type == typeof {
			if primary do removeParticle(row, col)
			if secondary do removeParticle(row + r, col + c)
			if chance == 0 {
				if secondary do addParticle(row + r, col + c, typeto)
				else do addParticle(row, col, typeto)
			} 
		}
	}
}

// Swap two particles
swapParticles :: proc(row1, col1, row2, col2: int) {
	if inBounds(row1, col1) && inBounds(row2, col2) {
		temp := cells[row1][col1]
		cells[row1][col1] = cells[row2][col2]
		cells[row2][col2] = temp

		// Updates Particles 
		cells[row1][col1].updated = true
		cells[row2][col2].updated = true
	}
}

checkThenSwap :: proc(row, col, r, c: int, type: Particles) {
	if checkParticle(row, col, r, c, type) {
		swapParticles(row, col, row + r, col + c)
	}
}

// Moves particles. If 'b' move down, if 'd' move diagonally, if 'h' move horizontally 
moveParticle :: proc(row, col: int, type: rune, dirs: []int = {}, update := true) {
	if update && isEmptyCell(row, col) {
		if cells[row][col].updated do return
	}

	switch type {
	case 'b':
		// Below
		if isEmptyCell(row + 1, col) {
			swapParticles(row, col, row + 1, col)
		}
	case 'a':
		// Above
		if isEmptyCell(row - 1, col) {
			swapParticles(row, col, row - 1, col)
		}
	case 'd':
		// Diagonal Down
		for dir in dirs {
			new_col := col + dir

			if !inBounds(row, new_col) || cells[row][new_col].moveable == false do continue

			// **Move Diagonally if the space is empty**
			if isEmptyCell(row + 1, new_col) {
				swapParticles(row, col, row + 1, new_col)
			}
		}
	case 'r':
		// Diagonal Up
		for dir in dirs {
			new_col := col + dir

			if !inBounds(row, new_col) || cells[row][new_col].moveable == false do continue

			// **Move Diagonally if the space is empty**
			if isEmptyCell(row - 1, new_col) {
				swapParticles(row, col, row - 1, new_col)
			}
		}
	case 'h':
		// Horizontal
		for dir in dirs {
			dispMovement(row, col, dir, 0)
		}
	}
}

sandInteractions :: proc(row, col: int) {
	// **Swap with Water and Steam Directly Below**
	if inBounds(row + 1, col) {
		s_part := cells[row + 1][col]

		if (s_part.type == .Water || s_part.type == .Steam || s_part.type == .Smoke) &&
		   !s_part.updated {
			swapParticles(row, col, row + 1, col)
		}
	}
}

sandMovement :: proc(row, col: int) {

	directions: []int = {-1, 1}
	rand.shuffle(directions)

	// **Attempt to Move Down**
	moveParticle(row, col, 'b')

	// **Attempt Diagonal Movement into Empty Spaces Only**
	moveParticle(row, col, 'd', directions)
}

// Update sand particle with desired logic
updateSand :: proc(row, col: int) {
	if !inBounds(row, col) || cells[row][col].type != .Sand {
		return
	} else {
		cells[row][col].disp_rate = setDispRate(cells[row][col])

		sandInteractions(row, col)
	}

	if cells[row][col].updated {
		return // Skip if already updated
	}

	sandMovement(row, col)

	// **No Movement Possible**
	cells[row][col].updated = true
}

waterMovement :: proc(row, col: int) {
	directions := []int{-1, 1}
	rand.shuffle(directions)

	// **Attempt to Move Down**
	moveParticle(row, col, 'b')

	// **Attempt Diagonal Down Movement**
	moveParticle(row, col, 'd', directions)

	// **Move Horizontally if Possible**
	moveParticle(row, col, 'h', directions)

}

// Update water particle
updateWater :: proc(row, col: int) {
	if !inBounds(row, col) || cells[row][col].type != .Water {
		return
	} else {
		cells[row][col].disp_rate = setDispRate(cells[row][col])
	}

	if cells[row][col].updated {
		return // Skip if already updated
	}

	waterMovement(row, col)

	// **No Movement Possible**
	cells[row][col].updated = true
}

steamInteractions :: proc(row, col: int) {
	// Water
	side := rand.choice(([]int){-1, 1})
	chance := rand.int_max(5)

	// **Condense with Water Above**
	changeParticle(row, col, -1, 0, chance, .Water, .Water, true, false)
	// **Condense with Water Side**
	changeParticle(row, col, 0, side, chance, .Water, .Water, true, false)
	// **Condense with Water Side**
	changeParticle(row, col, 0, -side, chance, .Water, .Water, true, false)
}

steamMovement :: proc(row, col: int) {
	directions := []int{-1, 1}
	rand.shuffle(directions)

	// **Attempt to Move Up**
	moveParticle(row, col, 'a')

	// **Attempt Diagonal Down Movement**
	moveParticle(row, col, 'd', directions)

	// **Attempt Diagonal Up Movement**
	moveParticle(row, col, 'r', directions)

	// **Move Horizontally if Possible**
	moveParticle(row, col, 'h', directions, false)
}

// Update steam particle
updateSteam :: proc(row, col: int) {
	if !inBounds(row, col) || cells[row][col].type != .Steam {
		return
	} else {
		cells[row][col].disp_rate = setDispRate(cells[row][col])
		cells[row][col].health -= rand.float32_uniform(.00001, .001)

		steamInteractions(row, col)
	}

	if cells[row][col].updated {
		return // Skip if already updated
	}

	// chance to condense on health 0
	if cells[row][col].health <= 0 {
		removeParticle(row, col)
		if rand.int_max(20) == 0 do addParticle(row, col, .Water)
	}

	steamMovement(row, col)

	// **No Movement Possible**
	cells[row][col].updated = true
}

fireInteractions :: proc(row, col: int) {
	side := rand.choice(([]int){-1, 1})

	// Steam
	checkThenSwap(row, col, 1, 0, .Steam)

	// smoke
	checkThenSwap(row, col, 1, 0, .Smoke)

	// Water
	changeParticle(row, col, -1, 0, 0, .Water, .Steam) // Above
	changeParticle(row, col, 1, 0, 0, .Water, .Steam) // Below
	changeParticle(row, col, 0, side, 0, .Water, .Steam) // Side
	changeParticle(row, col, 0, -side, 0, .Water, .Steam) // Side

	// Sand
	changeParticle(row, col, -1, 0, 0, .Sand, .None, true, false) // Above

	// Wood
	particleHealthZero(row, col, -1, 0, .Wood, .Fire, -.01, .01, 's', false, true) // Above
	particleHealthZero(row, col, 1, 0, .Wood, .Fire, -.01, .01, 's', false, true) // Below
	particleHealthZero(row, col, 0, -1, .Wood, .Fire, -.01, .01, 's', false, true) // Side
	particleHealthZero(row, col, 0, 1, .Wood, .Fire, -.01, .01, 's', false, true) // Side
}

fireMovement :: proc(row, col: int) {

	directions := []int{-1, 1}
	rand.shuffle(directions)

	// **Move Down if Possible**
	moveParticle(row, col, 'b')

	// **Move Diagonally Up if Possible**
	moveParticle(row, col, 'r', directions)

	// **Move Horizontally if Possible**
	moveParticle(row, col, 'h', directions, false)

	// **Move Up if Possible**
	dispMovement(row, col, 0, -1)

	if checkParticle(row, col, 1, 0, .Fire) {
		moveParticle(row, col, 'a', {}, false)
	}
}

// Update fire particle
updateFire :: proc(row, col: int) {
	if !inBounds(row, col) || cells[row][col].type != .Fire {
		return
	} else {
		cells[row][col].disp_rate = setDispRate(cells[row][col])
		if !checkParticle(row, col, -1, 0, .Fire) {
			cells[row][col].health -= rand.float32_uniform(.002, .0025)
		}
		fireInteractions(row, col)
	}

	if cells[row][col].updated {
		return // Skip if already updated
	}

	// on health 0
	if cells[row][col].health <= 0 {
		removeParticle(row, col)
	}

	fireMovement(row, col)

	// **No Movement Possible**
	cells[row][col].updated = true
}

addSmoke :: proc(row, col: int) {
	up := -1
	for row + up > 0 {
		if checkParticle(row, col, up, 0, .None) {
			addParticle(row + up, col, .Smoke)
			break
		}
		if cells[row + up][col].type != .Fire {
			break
		}
		up -= 1
	}
}

smokeInteractions :: proc(row, col: int) {
	// water
	if checkParticle(row, col, -1, 0, .Water) {
		swapParticles(row, col, row - 1, col)
	}
}

smokeMovement :: proc(row, col: int) {
	directions := []int{-1, 1}
	rand.shuffle(directions)

	// **Attempt to Move Up**
	moveParticle(row, col, 'a')

	// **Attempt Diagonal Down Movement**
	moveParticle(row, col, 'd', directions)

	// **Attempt Diagonal Up Movement**
	moveParticle(row, col, 'r', directions)

	// **Move Horizontally if Possible**
	moveParticle(row, col, 'h', directions, false)
}

// Update steam particle
updateSmoke :: proc(row, col: int) {
	if !inBounds(row, col) || cells[row][col].type != .Smoke {
		return
	} else {
		cells[row][col].disp_rate = setDispRate(cells[row][col])
		cells[row][col].health -= rand.float32_uniform(.00001, .001)

		smokeInteractions(row, col)
	}

	if cells[row][col].updated {
		return // Skip if already updated
	}

	if cells[row][col].health <= 0 {
		removeParticle(row, col)
	}

	steamMovement(row, col)

	// **No Movement Possible**
	cells[row][col].updated = true
}

// Update particle positions
updateParticle :: proc(row, col: int) {
	particle := &cells[row][col]
	if particle.type == .None || particle.updated {
		return // Skip empty or already updated particles
	}

	#partial switch particle.type {
	case .Sand:
		updateSand(row, col)
	case .Water:
		updateWater(row, col)
	case .Steam:
		updateSteam(row, col)
	case .Fire:
		updateFire(row, col)
	case .Smoke:
		updateSmoke(row, col)
	case:
		particle.updated = true
	}
}

// Simulation passes for particles
simulationPasses :: proc(type: Particles) {
	for row := ROWS - 1; row >= 0; row -= 1 {
		if row %% 2 == 0 {
			for col in 0 ..< COLS {
				if cells[row][col].type == type {
					updateParticle(row, col)
				}
			}
		} else {
			for col := COLS - 1; col >= 0; col -= 1 {
				if cells[row][col].type == type {
					updateParticle(row, col)
				}
			}
		}
	}
}

// run simulation
particleSimulation :: proc() {
	// **Reset update flags**
	for &row in cells {
		for &cell in row {
			cell.updated = false
		}
	}

	// **First Pass: Update Sand Particles**
	simulationPasses(.Sand)

	// **Second Pass: Update Water Particles**
	simulationPasses(.Water)

	// **Third Pass: Update Steam Particles**
	simulationPasses(.Steam)

	// **Third Pass: Update Fire Particles**
	simulationPasses(.Fire)

	// **Fourth Pass: Update Smoke Particles**
	simulationPasses(.Smoke)
}
