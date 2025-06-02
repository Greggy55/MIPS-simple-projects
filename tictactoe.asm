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
	draw:			.asciiz "Remis\n"
	debug_prompt:		.asciiz "\nDEBUG\n"
	prompt_ai_move:		.asciiz "Wcisnij dowolny przycisk aby kontynuowac..."
# -------

# GUI
	v_bar:			.asciiz "|"
	new_line:		.asciiz "\n"
	player1_char:		.word 79
	player2_char:		.word 88
# ---

# Random
	seed:       .word 1
	a_const:    .word 1103515245
	c_const:    .word 12345
	mod_mask:   .word 0x7FFFFFFF
# ------

.text

main:
	# seed
	li $v0, 30         
    	syscall              
    	sw $a0, seed

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
		
		jal print_board
		
		jal check_game_end
		move $t0, $v0
		bnez $t0, print_results
		
		li $a0, 2
		li $a1, 0
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
    	# body start

    	lw $s2, row_col_size     # bound
    	lw $t2, player1_char
    	lw $t3, player2_char
    	li $t4, 1                # assume draw

	check_rows:
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

	check_diag1:	# main diagonal
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

	check_diag2:	# anti-diagonal
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
    	move $v0, $t4  # 1 - draw; 0 - no settlement
    	
    	# body end
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
			j do_not_set_ij
			
	set_ij:
		move $a0, $v0	# from human_move
		move $a1, $v1	# - || -
		jal set_ij_element
	do_not_set_ij:
	
	# body end
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


# Human move
# v0 - field i
# v1 - field j
human_move:
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	# body start
	
	loop_until_valid_field_given:
		li $v0, 4
		la $a0, input_field_number
		syscall
	
		li $v0, 5
		syscall
		
		bgt $v0, 9, loop_until_valid_field_given
		blt $v0, 1, loop_until_valid_field_given
	
		move $a0, $v0
		jal convert_to_ij
	
		move $s0, $v0
		move $s1, $v1
	
		move $a0, $v0
		move $a1, $v1
		jal is_occupied
	
    		beq $v0, 1, loop_until_valid_field_given
    	
    	move $v0, $s0
    	move $v1, $s1
	
	# body end
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra


# AI move
# a0 - player number
ai_move:
    	addi $sp, $sp, -32
    	sw $ra, 0($sp)
    	sw $s0, 4($sp)
    	sw $s1, 8($sp)
    	sw $s2, 12($sp)
    	sw $s3, 16($sp)
    	sw $s4, 20($sp)
    	sw $s5, 24($sp)
    	sw $s6, 28($sp)
    	# body start
    	
    	move $t0, $a0
    	
    	li $v0, 4
	la $a0, prompt_ai_move
	syscall
	li $v0, 8
	li $a0, 0
	li $a1, 0
	syscall
	li $v0, 4
	la $a0, new_line
	syscall

    	lw $s2, row_col_size         # bound
    	
    	beq $t0, 1, ai_is_p1
    	ai_is_p2:
    		lw $s3, player1_char         # opponent
    		lw $s4, player2_char         # ai
    		j check_ai_win
    	ai_is_p1:
    		lw $s4, player1_char         # ai
    		lw $s3, player2_char         # opponent
    		j check_ai_win

# Win if possible
	check_ai_win:
    	li $s0, 0        # i
	check_ai_win_row:
    		beq $s0, $s2, check_block_player
    		li $s1, 0        # j
	check_ai_win_col:
    		beq $s1, $s2, ai_win_next_row

    		move $a0, $s0
    		move $a1, $s1
    		jal is_occupied
    		bnez $v0, ai_win_continue

    		# temporary AI move
    		move $s5, $v1	# save address
    		lw $s6, 0($s5)	# save value
    		sw $s4, 0($s5)	# override value
    		jal check_game_end
    		move $t2, $v0	# get game result
    		move $a0, $s5	# argument for ai move
    		beq $t2, $s4, do_ai_move   # win
    		sw $s6, 0($s5)             # restore value (empty => index nnumber)

	ai_win_continue:
    		addi $s1, $s1, 1
    		j check_ai_win_col
	ai_win_next_row:
    		addi $s0, $s0, 1
    		j check_ai_win_row

# Block if possible
	check_block_player:
    		li $s0, 0
	block_loop_row:
    		beq $s0, $s2, check_center
    		li $s1, 0
	block_loop_col:
    		beq $s1, $s2, block_next_row

    		move $a0, $s0
    		move $a1, $s1
    		jal is_occupied
    		bnez $v0, block_continue

    		# temporary opponent move
    		move $s5, $v1
    		lw $s6, 0($s5)
    		sw $s3, 0($s5)
    		jal check_game_end
    		move $t2, $v0
    		move $a0, $s5
    		beq $t2, $s3, do_block_move   # block
    		sw $s6, 0($s5)

	block_continue:
    		addi $s1, $s1, 1
    		j block_loop_col
	block_next_row:
    		addi $s0, $s0, 1
    		j block_loop_row
	do_block_move:
    		sw $s4, 0($s5)
    		j ai_move_done

# Take the center if possible
	check_center:
    		move $t0, $s2
    		srl $t0, $t0, 1   # t0 = s2 / 2
    
    		move $a0, $t0
    		move $a1, $t0
    		jal is_occupied
    		bnez $v0, check_corners  # nie pusty
    
    	# Take the center
    	sw $s4, 0($v1)
    	j ai_move_done

# Take the corner if possible
	check_corners:
    		li $s5, 0
	corner_loop:
    		li $t0, 0
    		li $t1, 0
    		beq $s5, 1, c1
    		beq $s5, 2, c2
    		beq $s5, 3, c3
    		j c0
    		
		c0: 
			li $t0, 0        # (0,0)
    			li $t1, 0
    			j corner_check
		c1: 
			li $t0, 0        # (0, N-1)
    			sub $t1, $s2, 1
    			j corner_check
		c2: 
			sub $t0, $s2, 1  # (N-1, 0)
    			li $t1, 0
    			j corner_check
		c3: 
			sub $t0, $s2, 1  # (N-1, N-1)
    			sub $t1, $s2, 1
		corner_check:
    			move $a0, $t0
    			move $a1, $t1
    			jal is_occupied
    			move $a0, $v1
    			beqz $v0, do_ai_move     # puste? ? ruch

    		addi $s5, $s5, 1
    		blt $s5, 4, corner_loop

# Take any
    	li $s0, 0
	any_row:
    		beq $s0, $s2, ai_move_done
    		li $s1, 0
	any_col:
    		beq $s1, $s2, any_next
    
    		move $a0, $s0
    		move $a1, $s1
    		jal is_occupied
    		move $a0, $v1
    		beqz $v0, do_ai_move     # puste? ? ruch
    
    		addi $s1, $s1, 1
    		j any_col
	any_next:
    		addi $s0, $s0, 1
    		j any_row

# Make move
	do_ai_move:
    		sw $s4, 0($a0)
		j ai_move_done

# End ai move
	ai_move_done:
	
	# body end
    	lw $ra, 0($sp)
    	lw $s0, 4($sp)
    	lw $s1, 8($sp)
    	lw $s2, 12($sp)
    	lw $s3, 16($sp)
    	lw $s4, 20($sp)
    	lw $s5, 24($sp)
    	lw $s6, 28($sp)
    	addi $sp, $sp, 32
    	jr $ra


# Checks if a field is occupied
# a0 - i
# a1 - j
# v0 - is occupied 0/1
# v1 - [i][j] address
is_occupied:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    # body start
    
    jal get_ij_element_address
    lw $s0, 0($v0)
    move $v1, $v0	# retrun address

    lw $s1, player1_char
    lw $s2, player2_char
    li $v0, 0
    beq $s0, $s1, set_occupied
    beq $s0, $s2, set_occupied
    j end_is_occupied
set_occupied:
    li $v0, 1
end_is_occupied:
    
    # body end
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
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


# Rand
# a0 - low
# a1 - high
# v0 - element of [a0, a1]
rand:
	# body start
    	lw  $t0, seed
    	lw  $t1, a_const
    	lw  $t2, c_const
    	lw  $t3, mod_mask

    	mul $t4, $t0, $t1	# seed * a
    	add $t4, $t4, $t2	# seed * a + c
    	and $t4, $t4, $t3	# (seed * a + c) % 2^31

    	sw  $t4, seed

	move $t0, $a0		# low
	move $t1, $a1        	# high
    	sub  $t2, $t1, $t0	# high - low
    	addi $t2, $t2, 1      	# high - low + 1

	div  $t4, $t2
    	mfhi $t4              # rand() % (high - low + 1)
    	add  $t4, $t4, $t0    # rand() % (high - low + 1) + low

	move $v0, $t4
	# body end
    	jr   $ra


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

