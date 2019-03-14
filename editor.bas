        dim bmp(16)
        dim #bmp16(8)

        const BOX = 0
        const PREVIEW_1 = 1
        const PREVIEW_2 = 2

        const GRID_X = 2
        const GRID_Y = 2
        const PREVIEW_X = 9
        const PREVIEW_Y = 11

        const FG_BG_MODE = 1
        const SCREEN_WIDTH = 20
        const GROM = 0
        const GRAM = 1

        const BLACK = 0
        const BLUE = 1
        const RED = 2
        const TAN = 3
        const DARK_GREEN = 4
        const GREEN = 5
        const YELLOW = 6
        const WHITE = 7
        const BROWN = 11

        def fn fgbg(mem, card, fg, bg) = ((((bg) and $b) + (((bg) and 4) * 4)) * 512 + (fg) + (card) * 8 + (mem) * 2048)
        def fn digit(n) = (16 + (n))
        def fn scrn(x, y) = #backtab((x) + (y) * SCREEN_WIDTH)

        cls
        mode FG_BG_MODE
        wait
        define BOX, 1, box_card
        wait
        cursor_x = 0
        cursor_y = 0

        for i = 0 to 7
            #tmp16 = fgbg(GROM, digit(i + 1), GREEN, BLACK)
            x = i + GRID_X
            y = GRID_Y - 1
            scrn(x, y) = #tmp16
            #tmp16 = fgbg(GROM, digit(i + 1), TAN, BLACK)
            x = i + 8 + GRID_X
            scrn(x, y) = #tmp16
            #tmp16 = fgbg(GROM, digit(i + 1), BLUE, BLACK)
            x = GRID_X - 1
            y = i + GRID_Y
            scrn(x, y) = #tmp16
        next i

        scrn(PREVIEW_X, PREVIEW_Y) = fgbg(GRAM, PREVIEW_1, WHITE, BROWN)
        scrn(PREVIEW_X + 1, PREVIEW_Y) = fgbg(GRAM, PREVIEW_2, WHITE, DARK_GREEN)

main_loop:
        for i = 0 to 1
            for j = 0 to 7
                tmp = bmp (j + i * 8)
                for k = 7 to 0 step -1
                    x = k + i * 8
                    y = j
                    if 1 = (1 and tmp) then
                        bg = WHITE
                    elseif 0 = (1 and (x xor y)) then
                        bg = BROWN
                    else
                        bg = DARK_GREEN
                    end if
                    if (x = cursor_x) and (y = cursor_y) then
                        #tmp16 = fgbg(GRAM, BOX, RED, bg)
                    else
                        #tmp16 = fgbg(GROM, " ", RED, bg)
                    end if
                    x = x + GRID_X
                    y = y + GRID_Y
                    scrn(x, y) = #tmp16
                    tmp = tmp / 2
                next k
            next j
        next i

        for i = 0 to 7
            #bmp16(i) = bmp(i * 2) + bmp(i * 2 + 1) * 256
        next i

        define PREVIEW_1, 2, #bmp16

        wait

        on (cont and $1f) gosub ,move_down,move_right,move_down,move_up,,move_right,,move_left,move_left,,,move_up,,,,,move_down,move_right,move_down_right,move_up,,move_up_right,,move_left,move_down_left,,,move_up_left

        if (cont.b0 + cont.b1 + cont.b2) then
            btn = 1
        else
            btn = 0
        end if

        if ((btn = 1) and (old_btn = 0)) then
            gosub invert
        end if
        old_btn = btn

        goto main_loop

invert: procedure
            idx = cursor_y
            bt = cursor_x
            if (bt > 7) then
                idx = idx + 8
                bt = bt - 8
            end if
            tmp = 1
            while (bt < 7)
                tmp = tmp * 2
                bt = bt + 1
            wend
            bmp(idx) = bmp(idx) xor tmp
        end

move_up: procedure
        if (cursor_y > 0) then cursor_y = cursor_y - 1 : old_btn = 0
        end

move_down: procedure
        if (cursor_y < 7) then cursor_y = cursor_y + 1 : old_btn = 0
        end

move_left: procedure
        if (cursor_x > 0) then cursor_x = cursor_x - 1 : old_btn = 0
        end

move_right: procedure
        if (cursor_x < 15) then cursor_x = cursor_x + 1 : old_btn = 0
        end

move_up_left: procedure
        gosub move_up
        gosub move_left
        end

move_up_right: procedure
        gosub move_up
        gosub move_right
        end

move_down_left: procedure
        gosub move_down
        gosub move_left
        end

move_down_right: procedure
        gosub move_down
        gosub move_right
        end

box_card:
        bitmap "********"
        bitmap "*......*"
        bitmap "*......*"
        bitmap "*......*"
        bitmap "*......*"
        bitmap "*......*"
        bitmap "*......*"
        bitmap "********"
