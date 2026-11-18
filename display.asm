# Name: Manav Patel
# Module: Colors and Grid Redraw

# color_for: $a0 = number, $v0 = color
# redraw_grid: no input or output
# print_legend: no input or output

.text
.globl color_for
.globl redraw_grid
.globl print_legend

color_for:
    addi $sp, $sp, -8
    sw $ra, 4($sp)
    sw $s0, 0($sp)

    move $s0, $a0

    jal is_guessed
    bne $v0, $zero, gray

    la $t0, ruleOut
    addi $t1, $s0, -1
    sll $t1, $t1, 2
    add $t0, $t0, $t1
    lw $t2, 0($t0)

    beq $t2, $zero, green

    li $t3, 1
    beq $t2, $t3, yellow

    li $t3, 2
    beq $t2, $t3, orange

    li $v0, 0x00CC0000
    j color_done

gray:
    li $v0, 0x00606060
    j color_done

green:
    li $v0, 0x0033CC33
    j color_done

yellow:
    li $v0, 0x00FFCC00
    j color_done

orange:
    li $v0, 0x00FF6600

color_done:
    lw $s0, 0($sp)
    lw $ra, 4($sp)
    addi $sp, $sp, 8
    jr $ra


redraw_grid:
    addi $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s1, 0($sp)

    li $s0, 1

grid_loop:
    bgt $s0, 100, grid_done

    move $a0, $s0
    jal color_for

    move $s1, $v0

    move $a0, $s0
    move $a1, $s1
    jal draw_cell

    addi $s0, $s0, 1
    j grid_loop

grid_done:
    lw $t0, guessCount
    beq $t0, $zero, redraw_done

    addi $t0, $t0, -1
    sll $t0, $t0, 2

    la $t1, guesses
    add $t1, $t1, $t0
    lw $a0, 0($t1)

    li $a1, 0x000066FF
    jal draw_outline

redraw_done:
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra

.data
legend_text: .asciiz "\nGrid Color Legend:\nGray: Already guessed\nGreen: No hints rule it out\nYellow: One hint rules it out\nOrange: Two hints rule it out\nRed: Three or more hints rule it out\nBlue outline: Last guess\n"

.text
print_legend:
    li $v0, 4
    la $a0, legend_text
    syscall
    jr $ra
