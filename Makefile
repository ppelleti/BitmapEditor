AS1600 = as1600
INTYBASIC = intybasic
JZINTV = jzintv

all: editor.rom

editor.asm: editor.bas
	$(INTYBASIC) --title "Bitmap Editor" editor.bas editor.asm $(INTY_LIB_PATH)

editor.rom: editor.asm fileio.asm emu_link.mac el_fileio.mac
	$(AS1600) -o editor.rom editor.asm

run: editor.rom
	$(JZINTV) -z3 editor.rom
