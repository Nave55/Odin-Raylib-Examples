package asteroids

import rl "vendor:raylib"

score: int
last_score: int

drawText :: proc() {
    // Draw Score
    rl.DrawText(rl.TextFormat("Score: %v", score), 0, 0, 30, rl.DARKPURPLE)

    // Draw Game Over Text
    if pause && game_over {
        text := rl.TextFormat("GAME OVER -- SCORE: %v", last_score)
        rl.DrawText(text, 
                    WIDTH / 2 - rl.MeasureText(text, 40) / 2, 
                    HEIGHT / 2 - 70, 
                    40, 
                    rl.RED)
    }

    // Draw Pause Text
    if pause do rl.DrawText("PRESS ENTER TO CONTINUE", 
                             WIDTH / 2 - rl.MeasureText("PRESS ENTER TO CONTINUE", 40) / 2, 
                             HEIGHT / 2 - 30, 
                             40, 
                             rl.DARKGRAY)
    
    // Draw immune text
    if immune < 10 do rl.DrawText("IMMUNE", 
                                   WIDTH / 2 - rl.MeasureText("IMMUNE", 40) / 2, 
                                   0, 
                                   40, 
                                   rl.GREEN)
}