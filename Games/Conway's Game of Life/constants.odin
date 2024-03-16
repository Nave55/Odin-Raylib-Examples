package conway

import rl "vendor:raylib"

WIDTH :: 750
HEIGHT :: 750
CELL_SIZE :: 6
ROWS :: int(HEIGHT / CELL_SIZE)
COLUMNS :: int(WIDTH / CELL_SIZE)
GREY: rl.Color = {29, 29, 29, 255}
DARK_GREY: rl.Color = {55, 55, 55, 255}