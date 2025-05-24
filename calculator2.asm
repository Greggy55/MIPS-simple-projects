# $t0 – 1st number and result
# $t1 – operation code (0 = add, 1 = subtract, 2 = divide, 3 = multiply)
# $t2 – 2nd number
# $v0 – used for syscall codes and to receive syscall return values
# $a0 – syscall argument register (for printing messages and integers)

.data
    msgNumber1: .asciiz "Enter the 1st number: \n"
    msgOperation: .asciiz "Choose operation(0 +, 1 -, 2 /, 3 *): \n"
    msgNumber2: .asciiz "Enter the 2nd number: \n"
    msgResult: .asciiz "Result: "
    msgContinue: .asciiz "\nContinue? (1 Yes, 0 No) \n"
    msgIncorrectInput: .asciiz "Error: Incorrect input\n"
    msgZeroDiv: .asciiz "Error: Division by zero\n"

.text
main:
	main_loop:
		# 1st number
    		la $a0, msgNumber1
    		jal print_string
    		li $v0, 5
    		syscall
    		move $t0, $v0

		# operation
    		la $a0, msgOperation
    		jal print_string
    		li $v0, 5
    		syscall
    		move $t1, $v0

		# 2nd number
    		la $a0, msgNumber2
    		jal print_string
    		li $v0, 5
    		syscall
    		move $t2, $v0

		# switch operation
    		beq $t1, 0, myAdd
    		beq $t1, 1, mySub
    		beq $t1, 2, myDiv
    		beq $t1, 3, myMult

    		la $a0, msgIncorrectInput
    		jal print_string
    		j ask_continue

	myAdd:
    		add $t0, $t0, $t2
    		j print_result
    		
	mySub:
    		sub $t0, $t0, $t2
    		j print_result
    		
	myMult:
    		mul $t0, $t0, $t2
    		j print_result
    		
	myDiv:
    		beqz $t2, div_by_zero
    		div $t0, $t0, $t2
    		j print_result  
    		
	print_result:
    		la $a0, msgResult
    		jal print_string
    		li $v0, 1
    		move $a0, $t0
    		syscall
    		j ask_continue
    		
	div_by_zero:
   		 la $a0, msgZeroDiv
   		 jal print_string
   		 j ask_continue
   		 
	print_error_input:
    		la $a0, msgIncorrectInput
    		jal print_string
    		j ask_continue

	ask_continue:
    		la $a0, msgContinue
   		 jal print_string
    		li $v0, 5
    		syscall
    		beqz $v0, exit
    		j main_loop
    		
	print_string:
    		li $v0, 4
    		syscall
    		jr $ra
    		
	exit:
    		li $v0, 10
    		syscall
