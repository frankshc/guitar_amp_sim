.equ KEYS, 0xff200050
.equ KEYS_IRQ, 1

.data
.align 2
raw_key_press_callback_table:
	.skip 16, 0

.text
.global initialize_keys
.global register_key_press_callback
.global unregister_key_press_callback

initialize_keys:
	addi sp, sp, -12
	stw r17, 8(sp)
	stw r16, 4(sp)
	stw ra, 0(sp)

	movia r16, KEYS
	stwio r0, 8(r16)	#disable interrupt for all buttons
	movi r17, 0x0f		
	stwio r17, 12(r16)	#clear Edge Capture Register
	
	movia r4, KEYS_IRQ
	movia r5, key_press_callback
	call register_interrupt_callback
	
	ldw r17, 8(sp)
	ldw r16, 4(sp)
	ldw ra, 0(sp)
	addi sp, sp, 12
	ret

register_key_press_callback: 
	#r4 - key number
	#r5 - callback function pointer
	#undefined behavior for key number > 3
	addi sp, sp, -12
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)
	
	#set interrupt mask for key
	movia r16, KEYS
	ldwio r17, 8(r16)
	movi r18, 1
	sll r18, r18, r4
	or r17, r17, r18
	stwio r17, 8(r16)
	
	#store the callback function pointer for	
	#the corresponding key in the callback table
	movia r16, raw_key_press_callback_table
	slli r4, r4, 2
	add r16, r16, r4
	stw r5, 0(r16)
	
	ldw r18, 8(sp) 
	ldw r17, 4(sp)
	ldw r16, 0(sp)
	addi sp, sp, 12
	ret

unregister_key_press_callback:
	#do nothing for now
	ret


key_press_callback:
	#this is the callback function registered with the interrupt handler
	#it wraps the raw callback function passed in through register_key_press_callback
	#it is neccesary to wrap the raw callback function because:
	#	1. all 4 keys share the same IRQ line, so additional logic is needed to determine which key was pressed
	#	2. interrupts must be acknowledged
	
	addi sp, sp, -28
	stw r21, 24(sp)
	stw r20, 20(sp)
	stw r19, 16(sp)
	stw r18, 12(sp)
	stw r17, 8(sp)
	stw r16, 4(sp)
	stw ra, 0(sp)
	
	movia r16, KEYS
	ldwio r20, 12(r16)
	andi r20, r20, 0x0f
	movi r18, -1
		
	key_iterate:
		beq r20, r0, key_press_callback_ret
		andi r17, r20, 1
		srli r20, r20, 1
		addi r18, r18, 1
		beq r17, r0, key_iterate
		
		movia r17, raw_key_press_callback_table
		slli r19, r18, 2
		add r17, r17, r19
		ldw r17, 0(r17)
		callr r17
	
		#acknowledge interrupt
		movi r17, 1
		sll r17, r17, r18
		ldwio r21, 12(r16)
		or r21, r21, r17
		stwio r21, 12(r16)
		
		br key_iterate

	key_press_callback_ret:
		ldw r21, 24(sp)
		ldw r20, 20(sp)
		ldw r19, 16(sp)
		ldw r18, 12(sp)
		ldw r17, 8(sp)
		ldw r16, 4(sp)
		ldw ra, 0(sp)
		addi sp, sp, 28
		ret
