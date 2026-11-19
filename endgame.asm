# Author: Micah Gordon (P6)
# Module: Hint log, end screen, score
# Assemble with MARS. Set TEST_MODE to 0 for project integration.

.eqv EASY 1
.eqv NORMAL 2
.eqv HARD 3
.eqv UNUSED_BONUS 10
.eqv LIE_BONUS 25
.eqv WIN_BONUS 50
.eqv SND_WIN 1          # Replace with shared project sound constants
.eqv SND_LOSE 2
.eqv TEST_MODE 1       # 1 = standalone tests; 0 = integrated module

.data
.globl secret, lieIndex, guessCount, maxGuesses, difficulty, guesses, hints
.globl ruleOut, score, lieCalled, bestScore
secret: .word 0
lieIndex: .word 0      # zero-based index
 guessCount: .word 0
maxGuesses: .word 10
difficulty: .word 2
 guesses: .space 48
hints: .space 48       # 1 Higher, -1 Lower, 0 Correct
ruleOut: .space 400
score: .word 0
lieCalled: .word 0
bestScore: .word 0

summaryText: .asciiz "Hints so far: "
higherMark: .asciiz ">"
lowerMark: .asciiz "<"
spaceText: .asciiz "  "
newlineText: .asciiz "\n"
guessText: .asciiz "Guess "
colonText: .asciiz ": "
arrowText: .asciiz " -> "
higherText: .asciiz "Higher"
lowerText: .asciiz "Lower"
correctText: .asciiz "Correct"
lieText: .asciiz " <-- LIE"
winText: .asciiz "You got it in "
winEndText: .asciiz " guesses!\n"
loseText: .asciiz "Out of guesses! The number was "
loseEndText: .asciiz ".\n"
winBonusText: .asciiz "Win bonus:        "
unusedText: .asciiz "Unused guesses:   "
timesText: .asciiz " x "
equalsText: .asciiz " = "
lieBonusText: .asciiz "Caught the lie:   "
difficultyText: .asciiz "Difficulty:       x"
easyText: .asciiz " (Easy)"
normalText: .asciiz " (Normal)"
hardText: .asciiz " (Hard)"
totalText: .asciiz "TOTAL SCORE:      "
newBestText: .asciiz "New best!\n"
testOneText: .asciiz "\n--- Test 1: lieIndex = 2 ---\n"
testTwoText: .asciiz "\n--- Test 2: lieIndex = 9 ---\n"

.text
.globl print_round_summary, print_history, compute_score, end_game

# print_round_summary ()
# Prints all nonzero hints for recorded guesses, on one line.
print_round_summary:
    li $v0, 4
    la $a0, summaryText
    syscall
    li $t0, 0
    lw $t1, guessCount
summary_loop:
    bge $t0, $t1, summary_done
    sll $t2, $t0, 2
    lw $t3, hints($t2)
    beqz $t3, summary_next
    li $v0, 4
    bltz $t3, summary_lower
    la $a0, higherMark
    j summary_mark
summary_lower:
    la $a0, lowerMark
summary_mark:
    syscall
    li $v0, 1
    lw $a0, guesses($t2)
    syscall
    li $v0, 4
    la $a0, spaceText
    syscall
summary_next:
    addiu $t0, $t0, 1
    j summary_loop
summary_done:
    li $v0, 4
    la $a0, newlineText
    syscall
    jr $ra

# print_history ()
# Prints one line per guess; lieIndex is zero-based.
print_history:
    li $t0, 0
    lw $t1, guessCount
    lw $t7, lieIndex
history_loop:
    bge $t0, $t1, history_done
    sll $t2, $t0, 2
    li $v0, 4
    la $a0, guessText
    syscall
    li $v0, 1
    addiu $a0, $t0, 1
    syscall
    li $v0, 4
    la $a0, colonText
    syscall
    li $v0, 1
    lw $a0, guesses($t2)
    syscall
    li $v0, 4
    la $a0, arrowText
    syscall
    lw $t3, hints($t2)
    beqz $t3, history_correct
    bltz $t3, history_lower
    la $a0, higherText
    j history_hint
history_lower:
    la $a0, lowerText
    j history_hint
history_correct:
    la $a0, correctText
history_hint:
    li $v0, 4
    syscall
    bne $t0, $t7, history_newline
    li $v0, 4
    la $a0, lieText
    syscall
history_newline:
    li $v0, 4
    la $a0, newlineText
    syscall
    addiu $t0, $t0, 1
    j history_loop
history_done:
    jr $ra

# compute_score (win/loss) -> score [int]
# args: $a0 = 1 if won, 0 if lost
# return: $v0 = score
compute_score:
    li $t7, 0
    lw $t0, difficulty
    lw $t1, maxGuesses
    lw $t2, guessCount
    lw $t3, lieCalled
    beqz $a0, compute_score_lie_bonus
    subu $t5, $t1, $t2
    bgez $t5, compute_score_unused_valid
    move $t5, $zero
compute_score_unused_valid:
    li $t6, UNUSED_BONUS
    mult $t6, $t5
    mflo $t7
    addiu $t7, $t7, WIN_BONUS
compute_score_lie_bonus:
    beqz $t3, compute_difficulty_multiplier
    addiu $t7, $t7, LIE_BONUS
compute_difficulty_multiplier:
    mult $t7, $t0
    mflo $v0
    sw $v0, score
    jr $ra

# end_game (win/loss)
# args: $a0 = 1 if won, 0 if lost
# Calls play_sound with SND_WIN or SND_LOSE.
end_game:
    addiu $sp, $sp, -12
    sw $ra, 8($sp)
    sw $s0, 4($sp)
    sw $s1, 0($sp)
    move $s0, $a0
    beqz $s0, end_game_loss
    li $v0, 4
    la $a0, winText
    syscall
    li $v0, 1
    lw $a0, guessCount
    syscall
    li $v0, 4
    la $a0, winEndText
    syscall
    li $a0, SND_WIN
    jal play_sound
    j end_game_history
end_game_loss:
    li $v0, 4
    la $a0, loseText
    syscall
    li $v0, 1
    lw $a0, secret
    syscall
    li $v0, 4
    la $a0, loseEndText
    syscall
    li $a0, SND_LOSE
    jal play_sound
end_game_history:
    jal print_history
    move $a0, $s0
    jal compute_score
    move $s1, $v0

    li $v0, 4
    la $a0, winBonusText
    syscall
    li $a0, 0
    beqz $s0, end_game_print_win_bonus
    li $a0, WIN_BONUS
end_game_print_win_bonus:
    li $v0, 1
    syscall
    jal print_newline

    li $v0, 4
    la $a0, unusedText
    syscall
    li $t0, 0
    beqz $s0, end_game_unused_count
    lw $t0, maxGuesses
    lw $t1, guessCount
    subu $t0, $t0, $t1
    bgez $t0, end_game_unused_count
    move $t0, $zero
end_game_unused_count:
    move $a0, $t0
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, timesText
    syscall
    li $v0, 1
    li $a0, UNUSED_BONUS
    syscall
    li $v0, 4
    la $a0, equalsText
    syscall
    lw $t0, maxGuesses
    lw $t1, guessCount
    subu $t0, $t0, $t1
    bgez $t0, end_game_unused_nonnegative
    move $t0, $zero
end_game_unused_nonnegative:
    bnez $s0, end_game_unused_product
    move $t0, $zero
end_game_unused_product:
    li $t1, UNUSED_BONUS
    mult $t0, $t1
    mflo $a0
    li $v0, 1
    syscall
    jal print_newline

    li $v0, 4
    la $a0, lieBonusText
    syscall
    li $a0, 0
    lw $t0, lieCalled
    beqz $t0, end_game_print_lie_bonus
    li $a0, LIE_BONUS
end_game_print_lie_bonus:
    li $v0, 1
    syscall
    jal print_newline

    li $v0, 4
    la $a0, difficultyText
    syscall
    li $v0, 1
    lw $a0, difficulty
    syscall
    lw $t0, difficulty
    li $t1, EASY
    beq $t0, $t1, end_game_easy
    li $t1, HARD
    beq $t0, $t1, end_game_hard
    la $a0, normalText
    j end_game_print_difficulty
end_game_easy:
    la $a0, easyText
    j end_game_print_difficulty
end_game_hard:
    la $a0, hardText
end_game_print_difficulty:
    li $v0, 4
    syscall
    jal print_newline

    li $v0, 4
    la $a0, totalText
    syscall
    li $v0, 1
    move $a0, $s1
    syscall
    jal print_newline

    lw $t0, bestScore
    ble $s1, $t0, end_game_done
    sw $s1, bestScore
    li $v0, 4
    la $a0, newBestText
    syscall
end_game_done:
    lw $s1, 0($sp)
    lw $s0, 4($sp)
    lw $ra, 8($sp)
    addiu $sp, $sp, 12
    jr $ra

print_newline:
    li $v0, 4
    la $a0, newlineText
    syscall
    jr $ra

# Standalone test driver. Remove this section in the integrated project.
# If your project already defines play_sound, remove the stub below.
.globl main
main:
    li $t0, 40
    sw $t0, guesses
    li $t0, 70
    sw $t0, guesses+4
    li $t0, 55
    sw $t0, guesses+8
    li $t0, 48
    sw $t0, guesses+12
    li $t0, 1
    sw $t0, hints
    li $t0, -1
    sw $t0, hints+4
    li $t0, 1
    sw $t0, hints+8
    li $t0, -1
    sw $t0, hints+12
    li $t0, 4
    sw $t0, guessCount
    li $t0, 2
    sw $t0, lieIndex
    sw $t0, difficulty
    li $t0, 10
    sw $t0, maxGuesses
    li $t0, 1
    sw $t0, lieCalled
    li $t0, 60
    sw $t0, secret
    li $v0, 4
    la $a0, testOneText
    syscall
    jal print_round_summary
    li $a0, 1
    jal end_game

    li $t0, 9
    sw $t0, lieIndex
    li $t0, 0
    sw $t0, lieCalled
    li $v0, 4
    la $a0, testTwoText
    syscall
    jal print_round_summary
    li $a0, 0
    jal end_game
    li $v0, 10
    syscall

# Standalone no-op substitute for the shared sound routine.
play_sound:
    li $v0, 10
    syscall
