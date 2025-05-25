.data
	prompt_number:		.asciiz "Podaj liczbe ciagow tekstowych: "
	prompt_strings1:	.asciiz "Podaj "
	prompt_strings2: 	.asciiz " ciagow tekstowych:\n"
	
	string:			.space 128
	space:			.byte  ' '
	new_line:		.byte  '\n'
.text

# s0 - number of strings
# s1 - string begin
# s2 - string end
# s3 - stack bottom

# t0 - main iterator
# t1 - string iterator
# t2 - current char
# t3 - stack char

main:
	# save stack bottom
	move $s3, $sp
	
	# print "Podaj liczbe ciagow tekstowych: "
	li $v0, 4
	la $a0, prompt_number
	syscall
	
	# input number of strings
	li $v0, 5
	syscall
	move $s0, $v0
	
	# print "Podaj $s0 ciagow tekstowych:\n"
	li $v0, 4
	la $a0, prompt_strings1
	syscall
	
	li $v0, 1
	move $a0, $s0
	syscall
	
	li $v0, 4
	la $a0, prompt_strings2
	syscall
	
	li $t0, 0
loop_input_string:
	beq $t0, $s0, exit
	
	# input string
	li $v0, 8
	la $a0, string
	li $a1, 128
	syscall
	
	li $t1, 0
loop_import_word:
	# import word begining
	move $s1, $t1
loop_find_word_end:
	lb $t2, string($t1)
	beq $t2, ' ', save_word	  # words separated by spaces
	beq $t2, '\n', save_word  # string end
	
	addi $t1, $t1, 1
	j loop_find_word_end

save_word:
	move $s2, $t1
	addi $s2, $s2, -1  # skip space

	jal loop_save_word
	
	addi $t1, $t1, 1
	beq $t2, '\n', next_string
	j loop_import_word

next_string:
	addi $t0, $t0, 1
	lb $t3, new_line
    	sb $t3, 0($sp)
    	addi $sp, $sp, -1
	j loop_input_string
	
loop_save_word:
	bgt $s1, $s2, save_space
	
	# save word to stack backwards
	lb $t3, string($s2)
	sb $t3, 0($sp)
	
	addi $s2, $s2, -1
	addi $sp, $sp, -1
	
	j loop_save_word
	
save_space:
	beq $t2, '\n', skip_save_space
	
	lb $t3, space
	sb $t3, 0($sp)
	addi $sp, $sp, -1
skip_save_space:
	jr $ra
	
exit:
	addi $sp, $sp, 2
loop_print_string:
    	bgt $sp, $s3, end
    	
    	# print word not backwards
    	lb $a0, 0($sp)
    	li $v0, 11
    	syscall
    	
    	addi $sp, $sp, 1
    	j loop_print_string

end:
	li $v0, 10
	syscall
