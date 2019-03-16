AS1600 = as1600
INTYBASIC = intybasic
JZINTV = jzintv
CC = gcc
CFLAGS = -O3 -Wall

all: editor.rom show-serial

editor.asm: editor.bas
	$(INTYBASIC) --title "Bitmap Editor" editor.bas editor.asm $(INTY_LIB_PATH)

editor.rom: editor.asm fileio.asm emu_link.mac el_fileio.mac
	$(AS1600) -o editor.rom editor.asm

run: editor.rom
	$(JZINTV) -z3 --file-io . editor.rom

show-serial: show-serial.c
	$(CC) $(CFLAGS) -o show-serial show-serial.c
