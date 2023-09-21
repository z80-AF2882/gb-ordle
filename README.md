# Wordle clone

## Project structure
Everything should be in project, including compiler etc. 

bin/Make.ps1
    build / run script for the project

bin/rgbds/**
    Place RGBASM binaries in here. Download from https://github.com/gbdev/rgbds/releases/ page.

bin/bgb/**
    Place BGB emulator here. Download from https://bgb.bircd.org/.

bin/bgb/*.bin
    You also gonna need them DMG and GBC rom images.

src/
    Source folder - all asm files will be compiled into .o

inc/
    Include folder.

gfx/
    Graphics folder
