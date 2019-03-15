        dim bmp(16)
        dim #bmp16(8)

        const CARD_BOX       = 0
        const CARD_USB       = 1
        const CARD_PREVIEW_1 = 62
        const CARD_PREVIEW_2 = 63

        const GRID_X = 2
        const GRID_Y = 2
        const PREVIEW_X = 9
        const PREVIEW_Y = 11
        const STATUS_Y = 10

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

        const LTO_usb = $0F0F
        const LTO_tx  = $0F11

        const O_RDONLY = 1
        const O_WRONLY = 2
        const O_RDWR   = 3
        const O_APPEND = 4
        const O_CREAT  = 8
        const O_EXCL   = 16
        const O_TRUNC  = 32

        def fn fgbg(fg, bg) = ((((bg) and $b) + (((bg) and 4) * 4)) * 512 + (fg))
        def fn fgbgc(mem, card, fg, bg) = ((((bg) and $b) + (((bg) and 4) * 4)) * 512 + (fg) + (card) * 8 + (mem) * 2048)
        def fn digit(n) = (16 + (n))
        def fn scrn(x, y) = #backtab((x) + (y) * SCREEN_WIDTH)
        def fn position(x, y) = ((x) + (y) * SCREEN_WIDTH)
        def fn send_char(x) = ch = x + 32: gosub dispatch_char : if err then goto fail
        def fn send_ctrl(x) = ch = x : gosub dispatch_char : if err then goto fail

        cls
        mode FG_BG_MODE
        wait
        define CARD_BOX, 2, box_card
        wait
        cursor_x = 0
        cursor_y = 0
        err = 0

        for i = 0 to 7
            #tmp16 = fgbgc(GROM, digit(i + 1), GREEN, BLACK)
            x = i + GRID_X
            y = GRID_Y - 1
            scrn(x, y) = #tmp16
            #tmp16 = fgbgc(GROM, digit(i + 1), TAN, BLACK)
            x = i + 8 + GRID_X
            scrn(x, y) = #tmp16
            #tmp16 = fgbgc(GROM, digit(i + 1), BLUE, BLACK)
            x = GRID_X - 1
            y = i + GRID_Y
            scrn(x, y) = #tmp16
        next i

        scrn(PREVIEW_X, PREVIEW_Y) = fgbgc(GRAM, CARD_PREVIEW_1, WHITE, BROWN)
        scrn(PREVIEW_X + 1, PREVIEW_Y) = fgbgc(GRAM, CARD_PREVIEW_2, WHITE, DARK_GREEN)

        #emu = usr inty_emu_detect

main_loop:
        gosub show_usb_card

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
                        #tmp16 = fgbgc(GRAM, CARD_BOX, RED, bg)
                    else
                        #tmp16 = fgbgc(GROM, " ", RED, bg)
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

        define CARD_PREVIEW_1, 2, #bmp16

        wait

        cnt = cont
        disc = cnt and $1f
        upper = cnt and $e0
        if (upper = $80) + (upper = $40) + (upper = $20) then
            key_pressed = 1
        else
            key_pressed = 0
        end if

        if (cont.b0 + cont.b1 + cont.b2) then
            btn = 1
        else
            btn = 0
        end if

        if key_pressed = 0 then
            on disc gosub ,move_down,move_right,move_down,move_up,,move_right,,move_left,move_left,,,move_up,,,,,move_down,move_right,move_down_right,move_up,,move_up_right,,move_left,move_down_left,,,move_up_left
        end if

        if ((btn = 1) and (old_btn = 0)) then
            gosub invert
        end if
        old_btn = btn

        if cnt = $81 then
            gosub save_bitmap
            while cont = $81
                wait
            wend
        end if

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

save_bitmap: procedure
        print at position(0, STATUS_Y) color fgbg(YELLOW, BLACK), "DUMPING TO SERIAL"
        err = 0

        if #emu <> -1 then
            gosub open_file
            if err then goto fail
        end if

        send_ctrl(13)
        send_ctrl(10)
        for i = 0 to 1
            send_char("c")
            send_char("a")
            send_char("r")
            send_char("d")
            send_char(17 + i)
            send_char(":")
            send_ctrl(13)
            send_ctrl(10)
            for j = 0 to 7
                tmp = bmp (j + i * 8)
                for k = 1 to 4
                    send_char(" ")
                next k
                send_char("B")
                send_char("I")
                send_char("T")
                send_char("M")
                send_char("A")
                send_char("P")
                send_char(" ")
                send_char("\"")
                for k = 0 to 7
                    if (tmp > 127) then
                        send_char("X")
                    else
                        send_char(".")
                    end if
                    tmp = tmp * 2
                next k
                send_char("\"")
                send_ctrl(13)
                send_ctrl(10)
            next j
        next i

        if #emu <> -1 then
            gosub close_file
            if err then goto fail
        end if

        for i = 0 to 19
            scrn(i, STATUS_Y) = 0
        next i
        return

fail:   for i = 0 to 19
            scrn(i, STATUS_Y) = 0
        next i
        if (#emu = -1) then
            print at position(0, STATUS_Y) color fgbg(RED, BLACK), "NO USB"
        else
            print at position(0, STATUS_Y) color fgbg(RED, BLACK), "ERRNO = ", <>#errno
        end if
        end

dispatch_char: procedure
            if #emu = -1 then
                gosub serial_char
            else
                gosub write_char
            end if
        end

serial_char: procedure
            if peek(LTO_usb) <> 1 then err = 1 : return
            while peek(LTO_tx)
                if peek(LTO_usb) <> 1 then err = 1 : return
            wend
            poke LTO_tx, ch
        end

open_file: procedure
            #fd = usr inty_open(varptr filename, O_WRONLY + O_APPEND + O_CREAT)
            if (#fd = -1) then err = 1
        end

write_char: procedure
            #ret = usr inty_write(#fd, varptr ch, 1)
            if (#ret = -1) then err = 1
        end

close_file: procedure
            #ret = usr inty_close(#fd)
            if (#ret = -1) then err = 1
        end

show_usb_card: procedure
        if #emu = -1 then
            if (peek(LTO_usb) = 1) then
                #tmp16 = fgbgc(GRAM, CARD_USB, WHITE, BLACK)
            else
                #tmp16 = fgbgc(GROM, " ", WHITE, BLACK)
            end if
            scrn(19, 0) = #tmp16
        else
            tmp = ((#emu / 256) and $ff) - 32
            scrn(18, 0) = fgbgc(GROM, tmp, WHITE, BLACK)
            tmp = (#emu and $ff) - 32
            scrn(19, 0) = fgbgc(GROM, tmp, WHITE, BLACK)
        end if
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
' usb_card
        bitmap "...*...."
        bitmap "...*.*.."
        bitmap ".*.*.*.."
        bitmap ".*.*.*.."
        bitmap ".*.**..."
        bitmap "..**...."
        bitmap "...*...."
        bitmap "...*...."

filename:
        data "bitmap.bas"
        data 0

        asm include "fileio.asm"
