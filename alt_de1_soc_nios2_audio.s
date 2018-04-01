.equ AUDIO_CORE, 0xff203040
.equ AUDIO_CORE_IRQ, 6

.data
.align 2
audio_callbacks:
	.skip 8, 0
	
.text
.global reset_audio
.global clear_audio_input_fifo
.global clear_audio_output_fifo
.global register_audio_read_callback
.global register_audio_write_callback
.global unregister_audio_read_callback
.global unregister_audio_write_callback

.global read_audio_left
.global read_audio_right
.global write_audio_left
.global write_audio_right

reset_audio:
	addi sp, sp, -20
	stw ra, 16(sp)
	stw r19, 12(sp)
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)
	
	#ATOMIC BEGIN
	call is_master_interrupt_enabled
	mov r19, r2
	call disable_master_interrupt
	
	#disable read and write interrupt
	#this is only needed because unregister functions
	#are not implemented
	movia r16, AUDIO_CORE
	ldwio r17, 0(r16)
	movi r18, 0b11
	sub r18, r0, r18
	subi r18, r18, 1
	and r17, r17, r18
	stwio r17, 0(r16)
	
	#call unregister_audio_read_callback
	#call unregister_audio_write_callback
	
	#clear audio callback table
	movia r16, audio_callbacks
	stw r0, 0(r16)
	stw r0, 4(r16)
	
	#unregister interrupts with the handler
	movia r4, AUDIO_CORE_IRQ
	call unregister_interrupt_callback
	
	#clear the fifo queues
	call clear_audio_input_fifo
	call clear_audio_output_fifo
	
	#ATOMIC END
	mov r4, r19
	call toggle_master_interrupt
	
	ldw ra, 16(sp)
	ldw r19, 12(sp)
	ldw r18, 8(sp)
	ldw r17, 4(sp)
	ldw r16, 0(sp)
	addi sp, sp, 20
	ret

#0 - input
#1 - output
clear_audio_input_or_output_fifo:
	addi sp, sp, -20
	stw ra, 16(sp)
	stw r19, 12(sp)
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)
	
	mov r16, r4
	
	#ATOMIC BEGIN
	call is_master_interrupt_enabled
	mov r19, r2
	call disable_master_interrupt

	movia r17, AUDIO_CORE
	ldwio r18, 0(r17)
	addi r16, r16, 1
	slli r16, r16, 2
	or r18, r18, r16
	stwio r18, 0(r17)
	sub r18, r18, r16
	stwio r18, 0(r17)
	
	#ATOMIC END
	mov r4, r19
	call toggle_master_interrupt
	
	ldw ra, 16(sp)
	ldw r19, 12(sp)
	ldw r18, 8(sp)
	ldw r17, 4(sp)
	ldw r16, 0(sp)
	addi sp, sp, 20
	ret
	
clear_audio_input_fifo:
	addi sp, sp, -4 
	stw ra, 0(sp)
	
	mov r4, r0
	call clear_audio_input_or_output_fifo
	
	ldw ra, 0(sp)
	addi sp, sp, 4 
	ret
	
clear_audio_output_fifo:
	addi sp, sp, -4 
	stw ra, 0(sp)

	movi r4, 1
	call clear_audio_input_or_output_fifo
	
	ldw ra, 0(sp)
	addi sp, sp, 4 
	ret

#r4 : callback
#r5 : 0 - read, 1 - write
register_audio_read_or_write_callback:
	addi sp, sp, -24
	stw ra, 20(sp)
	stw r20, 16(sp)
	stw r19, 12(sp)
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)
	
	#save r4 and r5
	mov r16, r4
	mov r17, r5
	
	#ATOMIC BEGIN
	call is_master_interrupt_enabled
	mov r20, r2
	call disable_master_interrupt
	
	#check if both audio callbacks are NULL
	#if false, audio_callback_wrapper is already registered with the interrupt handler
	call are_audio_callbacks_null
	beq r2, r0, store_audio_read_or_write_callback_pointer
	
	#register audio_callback_wrapper with the interrupt handler
	movia r4, AUDIO_CORE_IRQ
	movia r5, audio_callback_wrapper
	call register_interrupt_callback
	
	#store the audio read or write callback pointer
	store_audio_read_or_write_callback_pointer:
		movia r18, audio_callbacks
		slli r19, r17, 2
		add r18, r18, r19
		stw r16, 0(r18)
		
	#clear the read or write fifo
	mov r4, r17
	call clear_audio_input_or_output_fifo
	
	#enable audio read or write interrupt bit
	movia r18, AUDIO_CORE
	ldwio r19, 0(r18)
	addi r17, r17, 1
	or r19, r19, r17
	stwio r19, 0(r18)
	
	#ATOMIC END
	mov r4, r20
	call toggle_master_interrupt
	
	ldw ra, 20(sp)
	ldw r20, 16(sp)
	ldw r19, 12(sp)
	ldw r18, 8(sp)
	ldw r17, 4(sp)
	ldw r16, 0(sp)
	addi sp, sp, 24
	ret
	
register_audio_read_callback:
	addi sp, sp, -4 
	stw ra, 0(sp)
	
	mov r5, r0
	call register_audio_read_or_write_callback
	
	ldw ra, 0(sp)
	addi sp, sp, 4 
	ret
	
register_audio_write_callback:
	addi sp, sp, -4 
	stw ra, 0(sp)
	
	movi r5, 1
	call register_audio_read_or_write_callback
	
	ldw ra, 0(sp)
	addi sp, sp, 4 
	ret
	
unregister_audio_read_or_write_callback:
	#not implemented
	ret

unregister_audio_read_callback:
	#not implemented
	ret

unregister_audio_write_callback:
	#not implemented
	ret	
	
#return 1 if both audio read/write callbacks are null
#return 0 otherwise
are_audio_callbacks_null:
	addi sp, sp, -16
	stw ra, 12(sp)
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)
	
	movia r16, audio_callbacks
	ldw r17, 0(r16)
	ldw r16, 4(r16)
	or r16, r16, r17
	cmpeq r2, r0, r16
	
	ldw ra, 12(sp)
	ldw r18, 8(sp)
	ldw r17, 4(sp)
	ldw r16, 0(sp)
	addi sp, sp, 16
	ret

audio_callback_wrapper:
	addi sp, sp, -20
	stw ra, 16(sp)
	stw r19, 12(sp)
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)
	
	#do not alter these registers
	movia r16, AUDIO_CORE
	movia r18, audio_callbacks
	
	check_audio_read_interrupt_pending:
	ldwio r17, 0(r16)
	andi r17, r17, 0x100
	beq r17, r0, check_audio_write_interrupt_pending
	
	#call the audio read callback, if the function
	#pointer is not NULL
	ldw r19, 0(r18)
	beq r19, r0, check_audio_write_interrupt_pending
	callr r19
	
	check_audio_write_interrupt_pending:
	ldwio r17, 0(r16)
	andi r17, r17, 0x200
	beq r17, r0, audio_callback_wrapper_ret
	
	ldw r19, 4(r18)
	beq r19, r0, audio_callback_wrapper_ret
	callr r19
	
	audio_callback_wrapper_ret:
		ldw ra, 16(sp)
		ldw r19, 12(sp)
		ldw r18, 8(sp)
		ldw r17, 4(sp)
		ldw r16, 0(sp)
		addi sp, sp, 20
		ret
	
#r4: 0 - input, 1 - output
#r5: 0 - right, 1 - left
space_available_in_input_or_output_left_or_right_fifo:
	#decode r4, r5 into the byte position 
	#we wish to check in Fifospace Register
	slli r4, r4, 1
	add r4, r4, r5
	#IR = 0, IL = 1
	#OR = 2, OL = 3
	
	#find the number of bits we must shift right
	#the Fifospace Register by
	#i.e. convert the byte position to bit count
	slli r4, r4, 3
	
	#shift the Fifospace Register value right by r4 bits
	#then, return the least significant byte
	movia r2, AUDIO_CORE
	ldwio r2, 4(r2)
	srl r2, r2, r4
	andi r2, r2, 0xff
	
	ret
		
#Parameters:	
#	r4: 0 - read input, 1 - write output
#	r5: 0 - right, 1 - left
#	r6: buffer pointer
#	r7: max number of samples
#Return:
#	r2: number of samples operated on
read_or_write_input_or_output_left_or_right_fifo:	
	addi sp, sp, -32
	stw ra, 28(sp)
	stw r22, 24(sp)
	stw r21, 20(sp)
	stw r20, 16(sp)
	stw r19, 12(sp)
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)
	
	mov r16, r4
	mov r17, r5
	mov r18, r6
	mov r19, r7
	
	#ATOMIC BEGIN
	call is_master_interrupt_enabled
	mov r22, r2
	call disable_master_interrupt
	
	#check space available for read/write
	mov r4, r16
	mov r5, r17
	call space_available_in_input_or_output_left_or_right_fifo
	bgtu r19, r2, read_or_write_space_available_bound
	br read_or_write_buffer_size_bound
	
	#buffer_size > space_available
	#r19 = number of samples we will operate on = space_available
	read_or_write_space_available_bound:
		mov r19, r2 
	
	#buffer_size <= space_available
	#r19 = number of samples we will operate on = buffer_size
	read_or_write_buffer_size_bound:
		#do nothing
		
	#Left Data Register = base + 8
	#Right Data Register = base + 12
	#we must invert left/right parameter
	#so that left = 0, right = 1
	movia r20, AUDIO_CORE
	sub r21, r0, r17
	addi r21, r21, 1
	
	#calculate the Data Register pointer
	#for the correct channel
	addi r20, r20, 8
	slli r21, r21, 2
	add r20, r20, r21
	
	#find the buffer tail pointer
	#stop read/write when reached
	slli r21, r19, 2
	add r21, r18, r21
		
	#r18 - Buffer Head
	#r19 - Number of Samples (const)
	#r20 - Data Register Pointer (const)
	#r21 - Buffer Tail (const)
	
	#determine read or write operation
	beq r16, r0, read_audio_fifo_loop
	br write_audio_fifo_loop
	
	#read from fifo, write to buffer
	read_audio_fifo_loop:
		beq r18, r21, read_or_write_input_or_output_left_or_right_fifo_ret
		ldwio r17, 0(r20)
		stw r17, 0(r18)
		addi r18, r18, 4
		br read_audio_fifo_loop
	
	#read from buffer, write to fifo	
	write_audio_fifo_loop:
		beq r18, r21, read_or_write_input_or_output_left_or_right_fifo_ret
		ldw r17, 0(r18)
		stwio r17, 0(r20)
		addi r18, r18, 4
		br write_audio_fifo_loop
	
	read_or_write_input_or_output_left_or_right_fifo_ret:
		#ATOMIC END
		mov r4, r22
		call toggle_master_interrupt
		
		#r19 = number of samples we operated on
		#this is the return value
		mov r2, r19

		ldw ra, 28(sp)
		ldw r22, 24(sp)
		ldw r21, 20(sp)
		ldw r20, 16(sp)
		ldw r19, 12(sp)
		ldw r18, 8(sp)
		ldw r17, 4(sp)
		ldw r16, 0(sp)
		addi sp, sp, 32
		ret
		
read_audio_right:	
	addi sp, sp, -4
	stw ra, 0(sp)
	
	mov r6, r4
	mov r7, r5
	
	mov r4, r0
	mov r5, r0
	call read_or_write_input_or_output_left_or_right_fifo
	
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
	
read_audio_left:
	addi sp, sp, -4
	stw ra, 0(sp)
	
	mov r6, r4
	mov r7, r5

	mov r4, r0
	movi r5, 1
	call read_or_write_input_or_output_left_or_right_fifo
	
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
	
write_audio_left:
	addi sp, sp, -4
	stw ra, 0(sp)
	
	mov r6, r4	
	mov r7, r5
	
	movi r4, 1
	mov r5, r0
	call read_or_write_input_or_output_left_or_right_fifo
	
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
	
write_audio_right:
	addi sp, sp, -4
	stw ra, 0(sp)
		
	mov r6, r4
	mov r7, r5
	
	movi r4, 1
	movi r5, 1
	call read_or_write_input_or_output_left_or_right_fifo
	
	ldw ra, 0(sp)
	addi sp, sp, 4
	ret
