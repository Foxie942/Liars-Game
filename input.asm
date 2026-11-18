# Liar's Number - Person 7 (Input, Menus, Replay)
# File: input.asm
# Author: Kalan Sims
# Designed to integrate with the uploaded group source as of Nov 18, 2026.
#
# SHARED DATA (defined by Person 6's endgame.asm in the current upload):
#   guessCount, maxGuesses, difficulty, guesses, hints, ruleOut,
#   score, lieCalled

#
# Public procedures (called by Person 1's main loop):
#   print_rules:        input none; output none
#   read_guess:         input none; $v0 = valid, new number (1..100)
#   choose_difficulty:  input none; updates difficulty and maxGuesses
#   ask_play_again:     input none; $v0 = 1 (yes) or 0 (no)
#   reset_game:         input none; clears round state, not secret/lieIndex
#
# Integration note: Person 1 must call record_guess AFTER read_guess
# returns; read_guess intentionally does not increment guessCount.
#

.data
p7_title:       .asciiz "\n=== LIAR'S NUMBER ===\n"
p7_rule1:       .asciiz "Guess the secret number between 1 and 100.\n"
p7_rule2:       .asciiz "Easy: 12 guesses; Normal: 10; Hard: 7.\n"
p7_rule3:       .asciiz "After a wrong guess, the computer says Higher or Lower.\n"
p7_rule4:       .asciiz "One scheduled hint may be a lie; correct guesses are never lies.\n"
p7_rule5:       .asciiz "Use the color grid and hint history to find contradictions.\n"
p7_rule6:       .asciiz "Win quickly and call the lie to earn bonus points.\n"
p7_rule7:       .asciiz "Invalid or repeated guesses do not use an attempt.\n\n"
p7_guess_a:     .asciiz "Guess "
p7_guess_b:     .asciiz " of "
p7_guess_c:     .asciiz ": "
p7_invalid:     .asciiz "Invalid entry. Enter a whole number from 1 to 100.\n"
p7_duplicate:   .asciiz "You've already guessed that number. Try again.\n"
p7_again:       .asciiz "Play again? (1 = yes, 0 = no): "
p7_again_bad:   .asciiz "Please enter only 1 or 0.\n"
p7_diff_menu:   .asciiz "\nChoose difficulty:\n1) Easy (12 guesses)\n2) Normal (10 guesses)\n3) Hard (7 guesses)\nSelection: "
p7_diff_bad:    .asciiz "Please enter 1, 2, or 3.\n"
p7_input_line:  .space 64

.text
.globl print_rules
.globl read_guess
.globl ask_play_again
.globl reset_game
.globl choose_difficulty

# ------------------------------------------------------------------
# print_rules(): no arguments; no return value.
# ------------------------------------------------------------------
print_rules:
    li   $v0, 4
    la   $a0, p7_title
    syscall
    la   $a0, p7_rule1
    syscall
    la   $a0, p7_rule2
    syscall
    la   $a0, p7_rule3
    syscall
    la   $a0, p7_rule4
    syscall
    la   $a0, p7_rule5
    syscall
    la   $a0, p7_rule6
    syscall
    la   $a0, p7_rule7
    syscall
    jr   $ra

# ------------------------------------------------------------------
# read_guess(): $v0 returns a valid guess not already recorded.
# Does not modify guessCount; Person 3's record_guess does that.
# ------------------------------------------------------------------
read_guess:
    addiu $sp, $sp, -8
    sw    $s0, 0($sp)
    sw    $ra, 4($sp)
p7_guess_loop:
    li    $v0, 4
    la    $a0, p7_guess_a
    syscall
    lw    $a0, guessCount
    addiu $a0, $a0, 1
    li    $v0, 1
    syscall
    li    $v0, 4
    la    $a0, p7_guess_b
    syscall
    lw    $a0, maxGuesses
    li    $v0, 1
    syscall
    li    $v0, 4
    la    $a0, p7_guess_c
    syscall

    jal   p7_read_int_line      # $v0 = parsed integer, $v1 = valid flag
    beq   $v1, $zero, p7_bad_guess
    move  $s0, $v0
    slti  $t0, $s0, 1
    bne   $t0, $zero, p7_bad_guess
    slti  $t0, $s0, 101
    beq   $t0, $zero, p7_bad_guess

    move  $a0, $s0
    jal   p7_was_guessed       # uses the same guesses/guessCount as P3
    bne   $v0, $zero, p7_repeat_guess

    move  $v0, $s0
    lw    $s0, 0($sp)
    lw    $ra, 4($sp)
    addiu $sp, $sp, 8
    jr    $ra

p7_bad_guess:
    li    $v0, 4
    la    $a0, p7_invalid
    syscall
    jal   p7_invalid_sound
    j     p7_guess_loop

p7_repeat_guess:
    li    $v0, 4
    la    $a0, p7_duplicate
    syscall
    jal   p7_invalid_sound
    j     p7_guess_loop

# ------------------------------------------------------------------
# p7_was_guessed($a0=number): $v0=1 if the guess appears in
# guesses[0..guessCount-1]; otherwise $v0=0.
# Local helper avoids a missing label while tracking.asm is unfinished.
# ------------------------------------------------------------------
p7_was_guessed:
    la    $t0, guesses
    lw    $t1, guessCount
    move  $v0, $zero
p7_check_repeated:
    blez  $t1, p7_duplicate_done
    lw    $t2, 0($t0)
    beq   $t2, $a0, p7_duplicate_found
    addiu $t0, $t0, 4
    addiu $t1, $t1, -1
    j     p7_check_repeated
p7_duplicate_found:
    li    $v0, 1
p7_duplicate_done:
    jr    $ra

# ------------------------------------------------------------------
# ask_play_again(): $v0=1 (yes) or 0 (no). Invalid input repeats.
# ------------------------------------------------------------------
ask_play_again:
    addiu $sp, $sp, -4
    sw    $ra, 0($sp)
p7_replay_loop:
    li    $v0, 4
    la    $a0, p7_again
    syscall
    jal   p7_read_int_line
    beq   $v1, $zero, p7_replay_invalid
    beq   $v0, $zero, p7_replay_done
    li    $t0, 1
    beq   $v0, $t0, p7_replay_done
p7_replay_invalid:
    li    $v0, 4
    la    $a0, p7_again_bad
    syscall
    j     p7_replay_loop
p7_replay_done:
    lw    $ra, 0($sp)
    addiu $sp, $sp, 4
    jr    $ra

# ------------------------------------------------------------------
# reset_game(): resets round state only. Person 2's initialization
# generates a new secret number and lieIndex for the next round.
# ------------------------------------------------------------------
reset_game:
    sw    $zero, guessCount
    sw    $zero, score
    sw    $zero, lieCalled

    la    $t0, guesses
    la    $t1, hints
    li    $t2, 12
p7_reset_guess_loop:
    sw    $zero, 0($t0)
    sw    $zero, 0($t1)
    addiu $t0, $t0, 4
    addiu $t1, $t1, 4
    addiu $t2, $t2, -1
    bgtz  $t2, p7_reset_guess_loop

    la    $t0, ruleOut
    li    $t2, 100
p7_reset_ruleout_loop:
    sw    $zero, 0($t0)
    addiu $t0, $t0, 4
    addiu $t2, $t2, -1
    bgtz  $t2, p7_reset_ruleout_loop
    jr    $ra

# ------------------------------------------------------------------
# choose_difficulty(): sets globals difficulty and maxGuesses.
# Easy=1/12, Normal=2/10, Hard=3/7. Reject other inputs.
# ------------------------------------------------------------------
choose_difficulty:
    addiu $sp, $sp, -4
    sw    $ra, 0($sp)
p7_difficulty_loop:
    li    $v0, 4
    la    $a0, p7_diff_menu
    syscall
    jal   p7_read_int_line
    beq   $v1, $zero, p7_difficulty_invalid
    li    $t0, 1
    beq   $v0, $t0, p7_easy
    li    $t0, 2
    beq   $v0, $t0, p7_normal
    li    $t0, 3
    beq   $v0, $t0, p7_hard
p7_difficulty_invalid:
    li    $v0, 4
    la    $a0, p7_diff_bad
    syscall
    j     p7_difficulty_loop
p7_easy:
    li    $t0, 1
    sw    $t0, difficulty
    li    $t0, 12
    sw    $t0, maxGuesses
    j     p7_difficulty_done
p7_normal:
    li    $t0, 2
    sw    $t0, difficulty
    li    $t0, 10
    sw    $t0, maxGuesses
    j     p7_difficulty_done
p7_hard:
    li    $t0, 3
    sw    $t0, difficulty
    li    $t0, 7
    sw    $t0, maxGuesses
p7_difficulty_done:
    lw    $ra, 0($sp)
    addiu $sp, $sp, 4
    jr    $ra

# ------------------------------------------------------------------
# p7_read_int_line(): MARS syscall 8 reads a line as a string.
# Returns $v0=parsed integer and $v1=1 for an integer-only entry;
# otherwise $v1=0. Accepts an optional leading + or -.
# Rejects extremely large numbers before arithmetic can overflow.
# ------------------------------------------------------------------
p7_read_int_line:
    li    $v0, 8
    la    $a0, p7_input_line
    li    $a1, 64
    syscall

    la    $t0, p7_input_line
    move  $t1, $zero          # accumulated absolute value
    move  $t2, $zero          # 1 when negative
    move  $t3, $zero          # count of digits
    lbu   $t4, 0($t0)
    li    $t5, 45             # '-'
    bne   $t4, $t5, p7_test_plus
    li    $t2, 1
    addiu $t0, $t0, 1
    j     p7_parse_loop
p7_test_plus:
    li    $t5, 43             # '+'
    bne   $t4, $t5, p7_parse_loop
    addiu $t0, $t0, 1
p7_parse_loop:
    lbu   $t4, 0($t0)
    beq   $t4, $zero, p7_parse_end
    li    $t5, 10             # newline
    beq   $t4, $t5, p7_parse_end
    li    $t5, 13             # carriage return
    beq   $t4, $t5, p7_parse_end

    slti  $t6, $t4, 48        # must be ASCII 0..9
    bne   $t6, $zero, p7_parse_invalid
    slti  $t6, $t4, 58
    beq   $t6, $zero, p7_parse_invalid

    slti  $t6, $t1, 1001      # prevent overflow on huge input
    beq   $t6, $zero, p7_parse_invalid
    sll   $t7, $t1, 3
    sll   $t8, $t1, 1
    addu  $t1, $t7, $t8       # number = number * 10
    addiu $t4, $t4, -48
    addu  $t1, $t1, $t4
    addiu $t3, $t3, 1
    addiu $t0, $t0, 1
    j     p7_parse_loop
p7_parse_end:
    beq   $t3, $zero, p7_parse_invalid
    beq   $t2, $zero, p7_parse_ok
    subu  $t1, $zero, $t1
p7_parse_ok:
    move  $v0, $t1
    li    $v1, 1
    jr    $ra
p7_parse_invalid:
    move  $v0, $zero
    move  $v1, $zero
    jr    $ra

# ------------------------------------------------------------------
# p7_invalid_sound(): MARS syscall 31 MIDI beep for invalid entry.
# The group may later replace this with Person 2's play_sound(3).
# ------------------------------------------------------------------
p7_invalid_sound:
    li    $a0, 40             # pitch
    li    $a1, 100            # milliseconds
    li    $a2, 80             # instrument
    li    $a3, 100            # volume
    li    $v0, 31
    syscall
    jr    $ra
