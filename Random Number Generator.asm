.text
.globl random_generator

random_generator:
li $v0, 30
syscall

move $a1, $a0
li $a0, 0
li $v0, 40
syscall #Generates seed

li $a0, 1
li $a1, 101
li $v0, 42
syscall #Generates random int
