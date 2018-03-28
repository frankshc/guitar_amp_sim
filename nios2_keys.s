.equ KEYS, 0xff200050
.equ KEYS_IRQ, 1

.data
.align 2
key_callback_table:
	.skip 16, 0
keys_interrupt_is_enabled:
	.word 0
	
.text
.global reset_keys
.global register_key_callback
.global unregister_key_callback

reset_keys:
	addi sp, sp, -12
	stw r17, 8(sp)
	stw r16, 4(sp)
	stw ra, 0(sp)

	#disable keys interrupt
	movia r16, KEYS
	stwio r0, 8(r16)
	
	#clear Edge Capture Register
	movi r17, 0x0f		
	stwio r17, 12(r16)
	
	#unregister keys_callback_wrapper with the interrupt handler
	movia r4, KEYS_IRQ
	call unregister_interrupt_callback
	
	#clear key_callback_table
	movia r16, key_callback_table
	movi r17, 4
	
	clear_key_callback_table_loop:
		stw r0, 0(r16)
		addi r16, r16, 4
		subi r17, r17, 1
		bne r17, r0, clear_key_callback_table_loop
	
	#set the keys_interrupt_is_enabled flag to 0
	movia r16, keys_interrupt_is_enabled
	stw r0, 0(r16)
	
	ldw r17, 8(sp)
	ldw r16, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 12
	ret

register_key_callback: 
	addi sp, sp, -16
	stw ra, 12(sp)
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)
	
	#set interrupt mask for the key
	movia r16, KEYS
	ldwio r17, 8(r16)
	movi r18, 1
	sll r18, r18, r4
	or r17, r17, r18
	stwio r17, 8(r16)
	
	#store the callback function in key_callback_table
	movia r16, key_callback_table
	slli r4, r4, 2
	add r16, r16, r4
	stw r5, 0(r16)
	
	#check the keys_interrupt_is_enabled flag
	#if the flag is 0, keys_callback_wrapper is not registered with the interrupt handler
	movia r16, keys_interrupt_is_enabled
	ldw r17, 0(r16)
	beq r0, r17, enable_keys_interrupt
	
	enable_keys_interrupt:
		#register keys_callback_wrapper with the interrupt handler
		movia r4, KEYS_IRQ 
		movia r5, keys_callback_wrapper
		call register_interrupt_callback
		
		#set the keys_interrupt_is_enabled flag to 1
		movi r17, 1
		stw r17, 0(r16)
		
	ldw ra, 12(sp)	
	ldw r18, 8(sp) 
	ldw r17, 4(sp)
	ldw r16, 0(sp)
	addi sp, sp, 16
	ret

unregister_key_callback:
	addi sp, sp, -16
	stw ra, 12(sp)
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)
	
	#set the key callback to NULL
	movia r16, key_callback_table
	slli r4, r4, 2
	add r17, r16, r4
	stw r0, 0(r17)
	
	#r17 is the key counter
	movi r17, 4
	
	check_key_callback_table_empty_loop:
		ldw r18, 0(r16)
		addi r16, r16, 4
		subi r17, r17, 1
		bne r18, r0, unregister_key_callback_ret
		bne r17, r0, check_key_callback_table_empty_loop
		
	#unregister keys_callback_wrapper with the interrupt handler
	movia r4, KEYS_IRQ
	call unregister_interrupt_callback
	
	#set the keys_interrupt_is_enabled flag to 0
	movia r16, keys_interrupt_is_enabled
	stw r0, 0(r16)
	
	unregister_key_callback_ret:
		ldw ra, 12(sp)	
		ldw r18, 8(sp) 
		ldw r17, 4(sp)
		ldw r16, 0(sp)
		addi sp, sp, 16
		ret
		
#this subroutine wraps the callback function for each key
#wrapping is necessary because:
	#1. all keys share the same IRQ line; need additional logic to determine which keys were pressed
	#2. must acknowledge the interrupt
keys_callback_wrapper:
	addi sp, sp, -28
	stw ra, 24(sp)
	stw r21, 20(sp)
	stw r20, 16(sp)
	stw r19, 12(sp)
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)

	#read the least significant byte of the Edge Capture Register
	#r17 contains the Edge Capture Register
	movia r16, KEYS
	ldwio r17, 12(r16)
	andi r17, r17, 0x0f
	
	#r18 is key_callback_table pointer
	#initial value is offset by -4 to simplify loop 
	movia r18, key_callback_table
	subi r18, r18, 4
	
	#r20 is the key counter
	#initial value is offset by -1 to simplify loop
	movi r20, -1
	
	#it is possible that multiple keys are pressed at the same time
	#in which case the Edge Capture Register will contain more than 1 set bit
	#as such, it is neccesary to iterate through each set bit and invoke
	#the callback function associated with that key
	key_iterate_loop:
		#if no more edges, done
		beq r17, r0, key_press_callback_ret
		
		#r19 is the least significant edge bit
		andi r19, r17, 1
		
		#shift the Edge Capture Register right
		srli r17, r17, 1
		
		#increment the key counter
		addi r20, r20, 1

		#increment the key_callback_table pointer
		addi r18, r18, 4
		
		#edge bit is 0 for this key, check next key
		beq r19, r0, key_iterate_loop
		
		#key was pressed
		#invoke the callback function for this key
		ldw r19, 0(r18)
		callr r19
		
		#acknowledge interrupt for this key
		movi r19, 1
		sll r19, r19, r20
		ldwio r21, 12(r16)
		or r21, r21, r19
		stwio r21, 12(r16)
		
		br key_iterate_loop
		
	key_press_callback_ret:
		ldw ra, 24(sp)
		ldw r21, 20(sp)
		ldw r20, 16(sp)
		ldw r19, 12(sp)
		ldw r18, 8(sp)
		ldw r17, 4(sp)
		ldw r16, 0(sp)
		addi sp, sp, 28
		ret
