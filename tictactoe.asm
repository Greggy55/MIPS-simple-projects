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
	game_over:		.asciiz "Koniec Gry!\n"
	winner:			.asciiz "Wygrywa gracz "
	draw:			.asciiz "Remis"
	debug_prompt:		.asciiz "\nDEBUG\n"
# -------

# GUI
	v_bar:			.asciiz "|"
	new_line:		.asciiz "\n"
	player1_char:		.word 79
	player2_char:		.word 88
# ---

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
	
	jal print_board
	
	game_loop:
		jal check_game_end
		move $t0, $v0
		bnez $t0, print_results
	
		li $a0, 1
		li $a1, 1
		jal player_a0_move
		
		li $a0, 2
		li $a1, 1
		jal player_a0_move
		
		jal print_board
		
		j game_loop
	
	print_results:
	li $v0, 4
	la $a0, game_over
	syscall
	
	beq $t0, 1, game_draw
	game_winner:
		li $v0, 4
		la $a0, winner
		syscall
		li $v0, 11
		move $a0, $t0
		syscall
		j game_end
	game_draw:
		li $v0, 4
		la $a0, draw
		syscall
		j game_end
	
	game_end:
	# body end
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Check ame end
# v0 - (0 - not end, p1_char - p1_wins, p2_char - p2_wins, 1 - draw)
check_game_end:
    	addi $sp, $sp, -16
	sw $ra, 0($sp)
   	sw $s0, 4($sp)
    	sw $s1, 8($sp)
    	sw $s2, 12($sp)

    	lw $s2, row_col_size     # bound
    	lw $t2, player1_char
    	lw $t3, player2_char
    	li $t4, 1                # assume draw

#### Check rows
	check_rows1:
    	li $s0, 0	# row index
	check_rows_loop:
    		beq $s0, $s2, check_cols
    		li $s1, 0		# col index
    		li $t5, -1              # prev char
    		li $t6, 0               # counter
		row_loop:
   			beq $s1, $s2, next_row
   			move $a0, $s0
    			move $a1, $s1
    			jal get_ij_element_address
    			lw $t1, 0($v0)
    			
    			bge $t1, 'A', row_field_not_empty
    			li $t4, 0
    			j row_continue 
    			
			row_field_not_empty:
    			beq $t1, $t5, row_same
    			move $t5, $t1
    			li $t6, 1
    			j row_continue    			
		row_same:
    			addi $t6, $t6, 1
    			beq $t6, $s2, row_win
		row_continue:
    			addi $s1, $s1, 1
    			j row_loop
		next_row:
    			addi $s0, $s0, 1
    			j check_rows_loop
		row_win:
    			move $v0, $t1
    			j end_check

#### Check columns
	check_cols:
	li $s1, 0
	check_cols_loop:
    		beq $s1, $s2, check_diag1
    		li $s0, 0
    		li $t5, -1
    		li $t6, 0
		col_loop:
    			beq $s0, $s2, next_col
    			move $a0, $s0
    			move $a1, $s1
    			jal get_ij_element_address
			lw $t1, 0($v0)
			
    			bge $t1, 'A', col_field_not_empty
    			li $t4, 0
    			j col_continue 
    			
			col_field_not_empty:
    			beq $t1, $t5, col_same
    			move $t5, $t1
    			li $t6, 1
    			j col_continue
		col_same:
    			addi $t6, $t6, 1
    			beq $t6, $s2, col_win
		col_continue:
  		  	addi $s0, $s0, 1
    			j col_loop
		next_col:
    			addi $s1, $s1, 1
    			j check_cols_loop
		col_win:
   			move $v0, $t1
    			j end_check

#### Check main diagonal (top-left to bottom-right)
	check_diag1:
   	li $s0, 0
	li $t5, -1
    	li $t6, 0
	diag1_loop:
    		beq $s0, $s2, check_diag2
    		move $a0, $s0
    		move $a1, $s0
    		jal get_ij_element_address
    		lw $t1, 0($v0)
    		
		bge $t1, 'A', diag1_field_not_empty
    		li $t4, 0
    		j diag1_continue 
    			
		diag1_field_not_empty:
    		beq $t1, $t5, diag1_same
		move $t5, $t1
    		li $t6, 1
    		j diag1_continue
	diag1_same:
		addi $t6, $t6, 1
    		beq $t6, $s2, diag1_win
	diag1_continue:
    		addi $s0, $s0, 1
    		j diag1_loop
	diag1_win:
    		move $v0, $t1
    		j end_check

#### Check anti-diagonal (top-right to bottom-left)
	check_diag2:
    	li $s0, 0
    	li $t5, -1
    	li $t6, 0
	diag2_loop:
    		beq $s0, $s2, end_check_with_no_winner
    		move $a0, $s0
    		sub $a1, $s2, $s0
    		subi $a1, $a1, 1
    		jal get_ij_element_address
    		lw $t1, 0($v0)
    		
    		bge $t1, 'A', diag2_field_not_empty
    		li $t4, 0
    		j diag2_continue 
    			
		diag2_field_not_empty:
    		beq $t1, $t5, diag2_same
    		move $t5, $t1
    		li $t6, 1
    		j diag2_continue
	diag2_same:
    		addi $t6, $t6, 1
    		beq $t6, $s2, diag2_win
	diag2_continue:
    		addi $s0, $s0, 1
    		j diag2_loop
	diag2_win:
    		move $v0, $t1
    		j end_check

	end_check_with_no_winner:
    	move $v0, $t4  # if still 1, it's a draw; else 0
	end_check:
    	lw $ra, 0($sp)
    	lw $s0, 4($sp)
    	lw $s1, 8($sp)
    	lw $s2, 12($sp)
    	addi $sp, $sp, 16
    	jr $ra


# Player a0 move
# a0 - player number (1-2)
# a1 - is human true/false (false = 0, true != 0)
player_a0_move:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# body start
	
	set_char:
		beq $a0, 1, set_p1_char
		set_p2_char:
			lw $a2, player2_char
			j set_player_type
		set_p1_char:
			lw $a2, player1_char
	
	set_player_type:
		beqz $a1, ai
		human:
			jal human_move
			j set_ij
		ai:
			jal ai_move
			
	set_ij:
		move $a0, $v0	# from human_move
		move $a1, $v1	# - || -
		jal set_ij_element
	
	# body end
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


# Human move
# v0 - field i
# v1 - field j
human_move:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# body start
	
	li $v0, 4
	la $a0, input_field_number
	syscall
	
	li $v0, 5
	syscall
	
	move $a0, $v0
	jal convert_to_ij
	
	# body end
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


# TODO
ai_move:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# body start

	# body end
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


# Convert n to [i][j]
# a0 - n (1-9)
# v0 - i
# v1 - j
convert_to_ij:
	# body start
	
	addi $t0, $a0, -1	# t0 = n - 1
	divu $t0, $t0, 3	# t0 = (n - 1) / 3
	move $v0, $t0		# x = v0
	
	mul $t1, $t0, 3		# t1 = x * 3
	addi $t2, $a0, -1	# t2 = n - 1
	sub $v1, $t2, $t1	# y = (n - 1) - (x * 3)
	
	# body end
	jr $ra


# Get [i][j] element address
# a0 - row index
# a1 - col index
# v0 - return address
get_ij_element_address:
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
	
	jal get_ij_element_address
	
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
	
	jal get_ij_element_address
	
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
		bgt $s0, $s2, exit_print_loop
		
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
	exit_print_loop:
	
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

debug:
move $t9, $v0
move $t8, $a0
li $v0, 4
la $a0, debug_prompt
syscall
move $v0, $t9 
move $a0, $t8 
jr $ra

