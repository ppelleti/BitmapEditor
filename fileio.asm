        ; fileio.asm - wrappers to allow IntyBASIC to call EmuLink
        ; Copyright (C) 2019 Patrick Pelletier <code@funwithsoftware.org>
        ;
        ; This program is free software: you can redistribute it and/or modify
        ; it under the terms of the GNU General Public License as published by
        ; the Free Software Foundation, either version 3 of the License, or
        ; (at your option) any later version.
        ;
        ; This program is distributed in the hope that it will be useful,
        ; but WITHOUT ANY WARRANTY; without even the implied warranty of
        ; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        ; GNU General Public License for more details.
        ;
        ; You should have received a copy of the GNU General Public License
        ; along with this program.  If not, see <https://www.gnu.org/licenses/>.

        include "emu_link.mac"
        include "el_fileio.mac"

        ;; #emu = usr inty_emu_detect
INTY_EMU_DETECT: proc
        begin
        EL_EMU_DETECT
        bnc @@done
        mvii #$ffff, r0         ; return -1 if no emulator
@@done:
        return
        endp

        ;; #fd = usr inty_open(varptr filename(0), flags)
INTY_OPEN: proc
        begin
        movr r0, r2             ; pointer to ASCIIZ filename
        movr r1, r3             ; flags
        ELFI_OPEN R2, R3
        bc @@fail
        movr r2, r0             ; return file descriptor on success
        return
@@fail:
        mvo r0, var_&ERRNO
        mvii #$ffff, r0         ; return -1 on error
        return
        endp

        ;; #ret = usr inty_close(#fd)
INTY_CLOSE: proc
        begin
        movr r0, r2             ; file descriptor
        ELFI_CLOSE
        bc @@fail
        mvii #0, r0             ; return 0 on success
        return
@@fail:
        mvo r0, var_&ERRNO
        mvii #$ffff, r0         ; return -1 on error
        return
        endp

        ;; #ret = usr inty_write(#fd, varptr buf(0), len)
INTY_WRITE: proc
        begin
        movr r2, r4             ; number of bytes to write
        movr r1, r3             ; pointer to buffer
        movr r0, r2             ; file descriptor
        ELFI_WRITE R3, R4
        bc @@fail
        movr r1, r0             ; return number of bytes written on success
        return
@@fail:
        mvo r0, var_&ERRNO
        mvii #$ffff, r0         ; return -1 on error
        return
        endp
