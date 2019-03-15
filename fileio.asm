        include "emu_link.mac"
        include "el_fileio.mac"

inty_emu_detect: proc
        begin
        EL_EMU_DETECT
        bnc @@done
        mvii #$ffff, r0         ; return -1 if no emulator
@@done:
        return
        endp

inty_open: proc
        begin
        movr r0, r2             ; pointer to ASCIIZ filename
        movr r1, r3             ; flags
        ELFI_OPEN R2, R3
        bc @@fail
        movr r2, r0             ; return file descriptor on success
        return
@@fail:
        mvii #$ffff, r0         ; return -1 on error
        return
        endp

inty_close: proc
        begin
        movr r0, r2             ; file descriptor
        ELFI_CLOSE
        bc @@fail
        mvii #0, r0             ; return 0 on success
        return
@@fail:
        mvii #$ffff, r0         ; return -1 on error
        return
        endp

inty_write: proc
        begin
        movr r2, r4             ; number of bytes to write
        movr r1, r3             ; pointer to buffer
        movr r0, r2             ; file descriptor
        ELFI_WRITE R3, R4
        bc @@fail
        movr r1, r0             ; return number of bytes written on success
        return
@@fail:
        mvii #$ffff, r0         ; return -1 on error
        return
        endp
