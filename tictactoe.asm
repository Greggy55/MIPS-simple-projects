.data

# board array
	board:		.word '1','2','3'
			.word '4','5','6'
			.word '7','8','9'

	row_col_size:	.word 3
	size:		.word 9
	.eqv DATA_SIZE	4
# -----

# Prompts
	input_number_of_rounds:	.asciiz	"Podaj liczbe rund: "
	input_field_number:	.asciiz "Podaj numer wolnego pola: "
	v_bar:			.asciiz "|"
	new_line:		.asciiz "\n"
# -------

.text

main:
	li $v0, 4
	la $a0, input_number_of_rounds
	syscall
	
	li $v0, 5
	syscall
	move $s0, $v0
	
	main_loop:
		beqz $s0, end
		jal new_game
		sub $s0, $s0, 1
		j main_loop
	
new_game:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# body start
	
	game_loop:
		#jal check_winner
		#jal check_draw
		jal print_board
	
		jal player_move
		#jal pc_move
		
		j game_loop
	
	print_results:
		
	
	# body end
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

player_move:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# body start
	
	li $v0, 4
	la $a0, input_field_number
	syscall
	
	li $v0, 5
	syscall
	move $s1, $v0
		
	#jal convert_ij
	jal set_ij_element
	
	# body end
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


# Get [i][j] element
# a0 - row index
# a1 - col index
# v0 - return value
get_ij_element:
	addi $sp, $sp, -8
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	# body start
	
	lw $s0, row_col_size
	la $s1, board
	mul $v0, $s0, $a0	# v0 = colSize * rowIndex
	add $v0, $v0, $a1	#		+ colIndex
	mul $v0, $v0, DATA_SIZE	#		* DATA_SIZE
	add $v0, $v0, $s1	#		+ base address
	
	# body end
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	jr $ra


# Set [i][j] element
# a0 - row index
# a1 - col index
# a2 - value
set_ij_element:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# body start
	
	jal get_ij_element
	
	sw $a2, 0($v0)
	
	# body end
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


# Print [i][j] element
# a0 - row index
# a1 - col index
print_ij_element:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# body start
	
	jal get_ij_element
	
	lw $a0, 0($v0)
	li $v0, 11
	syscall
	
	# body end
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


# Print board 
print_board:
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	# body start
	
	li $s0, 0	# row index
	li $s1, 0	# col index
	lw $s2, row_col_size	# main loop range
	subi $s2, $s2, 1	# row loop range
	print_loop:
		bgt $s0, $s2, end_print_board
		
		move $a0, $s0
		move $a1, $s1
		jal print_ij_element	
		
		beq $s1, $s2, print_new_line
        
        	print_bar:
        		li $v0, 4
           	 	la $a0, v_bar
           	 	syscall
           	 	addi $s1, $s1, 1	# next col
           	 	j print_loop
       	 	print_new_line:
       	 		li $v0, 4
        	    	la $a0, new_line
          	  	syscall
          	  	li $s1, 0		# reset col
          	  	addi $s0, $s0, 1	# next row
          	  	j print_loop
	end_print_board:
	
	# body end	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	jr $ra


# End 
end:
	li $v0, 10
	syscall
