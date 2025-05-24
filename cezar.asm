.data
prompt_op:      .asciiz "Rodzaj operacji (0 - szyfrowanie, 1 - odszyfrowanie): "
prompt_err:	.asciiz "Bledna operacja."
prompt_shift:   .asciiz "Podaj przesuniecie (moze byc ujemne): "
prompt_text:    .asciiz "Podaj tekst do szyfrowania/odszyfrowywania (max 16 znakow): "
result_msg:     .asciiz "Wynik: "
newline:        .asciiz "\n"

message:        .space 18

.text
.globl main

# t0 - operacja (0 - szyfruj, 1 - deszyfruj)
# t1 - przesuniêcie
# t2 - pozycja w wiadomosci
# t3 - aktualny znak ASCII
# t4 - 'A' 65
# t5 - 'Z' 90
# t6 - 'a' 97
# t7 - 'z' 122
# t8 - 26 (dlugosc alfabetu)

main:
# Rodzaj operacji
ask_operation:
	# Pytanie
	li $v0, 4
	la $a0, prompt_op
	syscall

	# Wczytanie
	li $v0, 5
	syscall
	move $t0, $v0 
    
	beq $t0, 0, ask_shift
	beq $t0, 1, ask_shift
    
	li $v0, 4
	la $a0, prompt_err
	syscall
		
	j ask_operation

ask_shift:
	# Pytanie
	li $v0, 4
	la $a0, prompt_shift
	syscall

	# Wczytanie
	li $v0, 5
	syscall
	move $t1, $v0 
	
	beq $t0, 0, input_text
negate_shift:
	sub $t1, $zero, $t1

input_text:
    	# Pytanie
	li $v0, 4
    	la $a0, prompt_text
	syscall

    	# Wczytanie (18B = 16 znaków + \n + \0)
    	li $v0, 8
    	la $a0, message
    	li $a1, 18
    	syscall

process_text:
    	la $t2, message
loop:
    	lb $t3, 0($t2)
    	beqz $t3, done

    	li $t4, 65         # 'A'
    	li $t5, 90         # 'Z'
    	li $t6, 97         # 'a'
    	li $t7, 122        # 'z'
    
# nie 1 < 'A' <= wielkie <= 'Z' < nie 2 < 'a' <= male <= 'z' < nie 3

    	# A-Z
    	blt $t3, $t4, increment_char	# nie 1
    	ble $t3, $t5, convert		# wielkie

    	# a-z
    	blt $t3, $t6, increment_char	# nie 2
    	ble $t3, $t7, to_upper		# male

    	j increment_char		# nie 3

to_upper:
    	sub $t3, $t3, 32   # 'a' - 'A' = 32

convert:
    	sub $t3, $t3, 65   # 'A' -> 0
    	add $t3, $t3, $t1  # dodaj przesuniecie
    	li $t8, 26
modulo_loop:
    	blt $t3, 0, add_26
    	bge $t3, $t8, sub_26
    	j back_to_char

add_26:
    	add $t3, $t3, 26
    	j modulo_loop

sub_26:
    	sub $t3, $t3, 26
    	j modulo_loop

back_to_char:
    	add $t3, $t3, 65   # 0 -> 'A'
    	sb $t3, 0($t2)

increment_char:
    	addi $t2, $t2, 1
    	j loop

done:
    	# Wypisanie wyniku
    	li $v0, 4
    	la $a0, result_msg
    	syscall

    	li $v0, 4
    	la $a0, message
    	syscall

    	li $v0, 10
    	syscall
