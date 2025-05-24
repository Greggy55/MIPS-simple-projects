.data
	sequence:	.space 11	# 10 chars + \0
.text
# t1 - iterator
# t2 - inner iterator
# t3 - letter

main:
	# system time
	li $v0, 30
	syscall
	move $a1, $a0
	
	# set seed (id, seed), seed = system time
	li $v0, 40
	li $a0, 1
	syscall
	
	li $t1, 0 # iterator
	
loop_print_sequence:
	bge $t1, 10, end
	
	jal generate_sequence
	
	# print
	li $v0, 4
	la $a0, sequence
	syscall
	
	# new line
	li $v0, 11
	li $a0, '\n'
	syscall
	
	addi $t1, $t1, 1
	j loop_print_sequence

generate_sequence:
	li $t2, 0 # inner iterator
	# stack magic
	addi $sp, $sp, -4
   	sw $ra, 0($sp)
loop_generate_sequence:
	bge $t2, 10, end_generating_sequence
	
	jal generate_char
		
	sb $t3, sequence($t2)
	
	addi $t2, $t2, 1
	j loop_generate_sequence
		
end_generating_sequence:
	# make sequence null terminated
	li $t3, 0
	sb $t3, sequence($t2)

	# stack unmagic
	lw $ra, 0($sp)     
   	addi $sp, $sp, 4 
	jr $ra

generate_char:
	# random int range (id, bound)
	li $v0, 42
	li $a0, 1
	li $a1, 26
	syscall
	
	# letterify
	add $t3, $a0, 'a' 
	
	jr $ra

end:
	li $v0, 10
	syscall