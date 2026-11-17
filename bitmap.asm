# bitmap.asm - Liar's Number
# Finley Sullivan (Person 4) - bitmap drawing + title screen
#
# Display: 8x8 units, 512x512, base 0x10008000 ($gp)
#
# clear_display                         fill screen with background gray
# cell_xy      a0=n            v0=x, v1=y   top-left unit of cell n
# unit_addr    a0=x, a1=y      v0=address
# fill_rect    a0=x, a1=y, a2=size, a3=color
# draw_cell    a0=n, a1=color             ignores n outside 1-100 per game rules
# draw_outline a0=n, a1=color             ignores n outside 1-100 per game rules
# title_screen                          draws title, waits for Enter to start the game
# draw_glyph   a0=glyph addr, a1=x, a2=y, a3=color  (scale in glyph_scale)

        .eqv    BASE    0x10008000
        .eqv    BG      0x00202020

        .data
glyph_scale:    .word   2

# 5x7 letters, one word per row
glyph_L:  .word 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F
glyph_I:  .word 0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x1F
glyph_A:  .word 0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11
glyph_R:  .word 0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11
glyph_Q:  .word 0x0E, 0x11, 0x01, 0x02, 0x04, 0x00, 0x04

letters:        .word   glyph_L, glyph_I, glyph_A, glyph_R
border_colors:  .word   0x0033CC33, 0x00FFCC00, 0x00FF6600, 0x00CC0000
row_colors:     .word   0x0033CC33, 0x0033CC33, 0x00FFCC00, 0x00606060, 0x0033CC33
                .word   0x00FFCC00, 0x00FF6600, 0x00CC0000, 0x00606060, 0x00FFCC00
prompt:         .asciiz "\n=== LIAR'S NUMBER ===\nPress Enter to start\n"

        .text
        .globl  clear_display, cell_xy, unit_addr, fill_rect
        .globl  draw_cell, draw_outline, title_screen, draw_glyph

clear_display:
        li      $t0, BASE
        li      $t1, 4096
        li      $t2, BG
cd_loop:
        sw      $t2, 0($t0)
        addi    $t0, $t0, 4
        addi    $t1, $t1, -1
        bnez    $t1, cd_loop
        jr      $ra

# x = 2 + col*6, y = 2 + row*6
cell_xy:
        addi    $t0, $a0, -1
        li      $t1, 10
        div     $t0, $t1
        mflo    $t2             # row
        mfhi    $t3             # col
        li      $t1, 6
        mul     $t3, $t3, $t1
        mul     $t2, $t2, $t1
        addi    $v0, $t3, 2
        addi    $v1, $t2, 2
        jr      $ra

# BASE + (y*64 + x)*4
unit_addr:
        sll     $v0, $a1, 6
        add     $v0, $v0, $a0
        sll     $v0, $v0, 2
        li      $t0, BASE
        add     $v0, $v0, $t0
        jr      $ra

fill_rect:
        li      $t3, BASE
        li      $t0, 0          # row
fr_row:
        bge     $t0, $a2, fr_done
        add     $t1, $a1, $t0
        sll     $t1, $t1, 6
        add     $t1, $t1, $a0
        sll     $t1, $t1, 2
        add     $t1, $t1, $t3
        li      $t2, 0          # col
fr_col:
        bge     $t2, $a2, fr_next
        sw      $a3, 0($t1)
        addi    $t1, $t1, 4
        addi    $t2, $t2, 1
        j       fr_col
fr_next:
        addi    $t0, $t0, 1
        j       fr_row
fr_done:
        jr      $ra

draw_cell:
        addi    $sp, $sp, -8
        sw      $ra, 4($sp)
        sw      $s0, 0($sp)
        blt     $a0, 1, dc_ret
        bgt     $a0, 100, dc_ret
        move    $s0, $a1
        jal     cell_xy
        move    $a0, $v0
        move    $a1, $v1
        li      $a2, 5
        move    $a3, $s0
        jal     fill_rect
dc_ret:
        lw      $s0, 0($sp)
        lw      $ra, 4($sp)
        addi    $sp, $sp, 8
        jr      $ra

# top = A+4k, bottom = A+1024+4k, left = A+256k, right = A+16+256k
draw_outline:
        addi    $sp, $sp, -8
        sw      $ra, 4($sp)
        sw      $s0, 0($sp)
        blt     $a0, 1, do_ret
        bgt     $a0, 100, do_ret
        move    $s0, $a1
        jal     cell_xy
        move    $a0, $v0
        move    $a1, $v1
        jal     unit_addr
        move    $t1, $v0
        move    $t2, $v0
        li      $t0, 0
do_loop:
        sw      $s0, 0($t1)
        sw      $s0, 1024($t1)
        sw      $s0, 0($t2)
        sw      $s0, 16($t2)
        addi    $t1, $t1, 4
        addi    $t2, $t2, 256
        addi    $t0, $t0, 1
        blt     $t0, 5, do_loop
do_ret:
        lw      $s0, 0($sp)
        lw      $ra, 4($sp)
        addi    $sp, $sp, 8
        jr      $ra

title_screen:
        addi    $sp, $sp, -16
        sw      $ra, 12($sp)
        sw      $s0, 8($sp)
        sw      $s1, 4($sp)
        sw      $s2, 0($sp)

        jal     clear_display

        # border, 2x2 blocks cycling through 4 colors
        li      $s0, 0
ts_border:
        andi    $t0, $s0, 3
        sll     $t0, $t0, 2
        la      $t1, border_colors
        add     $t1, $t1, $t0
        lw      $s1, 0($t1)
        sll     $s2, $s0, 1

        move    $a0, $s2
        li      $a1, 0
        li      $a2, 2
        move    $a3, $s1
        jal     fill_rect
        move    $a0, $s2
        li      $a1, 62
        li      $a2, 2
        move    $a3, $s1
        jal     fill_rect
        li      $a0, 0
        move    $a1, $s2
        li      $a2, 2
        move    $a3, $s1
        jal     fill_rect
        li      $a0, 62
        move    $a1, $s2
        li      $a2, 2
        move    $a3, $s1
        jal     fill_rect

        addi    $s0, $s0, 1
        blt     $s0, 32, ts_border

        # LIAR, shadow then letter
        li      $t0, 2
        sw      $t0, glyph_scale
        la      $s0, letters
        li      $s1, 0
ts_letter:
        li      $t0, 12
        mul     $s2, $s1, $t0
        addi    $s2, $s2, 9

        lw      $a0, 0($s0)
        addi    $a1, $s2, 1
        li      $a2, 9
        li      $a3, 0x00805000
        jal     draw_glyph
        lw      $a0, 0($s0)
        move    $a1, $s2
        li      $a2, 8
        li      $a3, 0x00FFCC00
        jal     draw_glyph

        addi    $s0, $s0, 4
        addi    $s1, $s1, 1
        blt     $s1, 4, ts_letter

        # ?
        li      $t0, 3
        sw      $t0, glyph_scale
        la      $a0, glyph_Q
        li      $a1, 26
        li      $a2, 28
        li      $a3, 0x000066FF
        jal     draw_glyph
        la      $a0, glyph_Q
        li      $a1, 25
        li      $a2, 27
        li      $a3, 0x0000FFFF
        jal     draw_glyph

        # row of sample cells
        la      $s0, row_colors
        li      $s1, 0
ts_cell:
        sll     $a0, $s1, 2
        addi    $a0, $a0, 12
        li      $a1, 52
        li      $a2, 3
        lw      $a3, 0($s0)
        jal     fill_rect
        addi    $s0, $s0, 4
        addi    $s1, $s1, 1
        blt     $s1, 10, ts_cell

        li      $v0, 4
        la      $a0, prompt
        syscall
ts_wait:
        li      $v0, 12
        syscall
        bne     $v0, 10, ts_wait

        lw      $s2, 0($sp)
        lw      $s1, 4($sp)
        lw      $s0, 8($sp)
        lw      $ra, 12($sp)
        addi    $sp, $sp, 16
        jr      $ra

draw_glyph:
        addi    $sp, $sp, -36
        sw      $ra, 32($sp)
        sw      $s0, 28($sp)
        sw      $s1, 24($sp)
        sw      $s2, 20($sp)
        sw      $s3, 16($sp)
        sw      $s4, 12($sp)
        sw      $s5, 8($sp)
        sw      $s6, 4($sp)
        sw      $s7, 0($sp)

        move    $s0, $a0        # row ptr
        move    $s7, $a1        # start x
        move    $s5, $a2        # y
        move    $s6, $a3        # color
        li      $s1, 7
dg_row:
        lw      $s2, 0($s0)
        li      $s3, 0x10       # mask
        move    $s4, $s7
dg_col:
        and     $t0, $s2, $s3
        beqz    $t0, dg_skip
        move    $a0, $s4
        move    $a1, $s5
        lw      $a2, glyph_scale
        move    $a3, $s6
        jal     fill_rect
dg_skip:
        lw      $t0, glyph_scale
        add     $s4, $s4, $t0
        srl     $s3, $s3, 1
        bnez    $s3, dg_col

        lw      $t0, glyph_scale
        add     $s5, $s5, $t0
        addi    $s0, $s0, 4
        addi    $s1, $s1, -1
        bnez    $s1, dg_row

        lw      $s7, 0($sp)
        lw      $s6, 4($sp)
        lw      $s5, 8($sp)
        lw      $s4, 12($sp)
        lw      $s3, 16($sp)
        lw      $s2, 20($sp)
        lw      $s1, 24($sp)
        lw      $s0, 28($sp)
        lw      $ra, 32($sp)
        addi    $sp, $sp, 36
        jr      $ra
