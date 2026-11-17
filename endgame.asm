# Author: Micah Gordon (P6)
# Module: Hint log, end screen, score

# == Procedures == #

.data
 .globl secret, lieIndex, guessCount, maxGuesses, difficulty, guesses, hints
 .globl ruleOut, score, lieCalled, debugMode
secret: .word 0 # the secret number, 1-100 (Person 2)
lieIndex: .word 0 # which guess (0 to maxGuesses-1) gets the lie (Person 2)
guessCount: .word 0 # how many guesses have been recorded (Person 3)
maxGuesses: .word 10 # 12 = Easy, 10 = Normal, 7 = Hard (Person 7)
difficulty: .word 2 # 1 = Easy, 2 = Normal, 3 = Hard (Person 7)
guesses: .space 48 # 12 words: the guesses, in order (Person 3)
hints: .space 48 # 12 words: hint GIVEN for each guess (Person 3)
 # 1 = "Higher" -1 = "Lower" 0 = "Correct"
ruleOut: .space 400 # 100 words: ruleOut[n-1] = hints ruling out n (Person 3)
score: .word 0 # final score (Person 6)
lieCalled: .word 0 # 1 if the player correctly named the lie (Person 3)


# Module 6 Constants
.eqv EASY 1
.eqv NORMAL 2
.eqv HARD 3
.eqv UNUSED_BONUS 10
.eqv LIE_BONUS 25

.text

# compute_score () -> score [int]
# args: $a0 = win / loss
# return: $v0 (score)
compute_score:
	li $t7, 0 # score sum
	lw $t0, difficulty
	lw $t1, maxGuesses
	lw $t2, guessCount
	lw $t3, lieCalled
	
	beqz $a0, compute_score_lie_bonus
	
	# compute guess bonus
	sub $t5, $t1, $t2 # unused guess count
	li $t6, UNUSED_BONUS
	mult $t6, $t5
	mflo $t7 # unused guess bonus
	
	# add win bonus
	addi $t7, 50
	
	
compute_score_lie_bonus:
beqz $t3, compute_difficulty_multiplier
addi $t7 LIE_BONUS

compute_difficulty_multiplier:

mult $t7, $t0
mflo $v0 # final score
sw $v0, score
