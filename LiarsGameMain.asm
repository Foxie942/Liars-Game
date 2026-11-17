
# Mathias Lugert
main:
 li $t0, 0
 # need to jump to check conditions for game somewhere in the main block
 addi $t0, $t0, 1
 bge $t0, 10, exit # replace exit with name of actual exit block in code
 
 exit:
 
 