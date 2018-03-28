.data
.align 2
interrupt_callback_lookup_table:
	#by default, all callback function pointers are NULL
	.skip 128, 0

de_Bruijn_lookup_table:
	.word 0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8, 31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9
	
.text
.global enable_master_interrupt
.global disable_master_interrupt
.global register_interrupt_callback
.global unregister_interrupt_callback

register_interrupt_callback:	
	#r4 - IRQ line
	#r5 - callback function pointer
	addi sp, sp, -8
	stw r17, 4(sp)
	stw r16, 0(sp)
	
	#enable the r4-th IRQ line
	rdctl r16, ctl3
	movi r17, 1
	sll r17, r17, r4
	or r16, r16, r17
	wrctl ctl3, r16 
	
	#store the callback function pointer
	#as the r4-th entry in the callback lookup table 
	movia r16, interrupt_callback_lookup_table
	slli r4, r4, 2
	add r16, r16, r4
	stw r5, 0(r16)
	
	ldw r17, 4(sp)
	ldw r16, 0(sp)
	addi sp, sp, 8
	ret
	
unregister_interrupt_callback:
	#r4 - IRQ line
	addi sp, sp, -12
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)
	
	#disable the r4-th IRQ line
	rdctl r16, ctl3
	movi r17, 1
	sll r17, r17, r4
	movia r18, 0xffffffff
	sub r18, r18, r17
	and r16, r16, r18
	wrctl ctl3, r16
	
	#set the callback function pointer to NULL
	movia r16, interrupt_callback_lookup_table
	slli r4, r4, 2
	add r16, r16, r4
	stw r0, 0(r16)
	
	ldw r18, 8(sp)
	ldw r17, 4(sp)
	ldw r16, 0(sp)
	addi sp, sp, 12
	ret
	
enable_master_interrupt:
	addi sp, sp, -4
	stw r16, 0(sp)
	
	movi r16, 1
	wrctl ctl0, r16

	ldw r16, 0(sp)
	addi sp, sp, 4
	ret

disable_master_interrupt:
	wrctl ctl0, r0
	ret
	
de_Bruijn_index_lookup:
	#note: 0 has undefined output
	addi sp, sp, -4
	stw r16, 0(sp)
	
	sub r16, r0, r4
	and r16, r16, r4
	movia r4, 0x077CB531
	mul r16, r16, r4
	srli r16, r16, 27
	
	movia r4, de_Bruijn_lookup_table
	slli r16, r16, 2
	add r4, r4, r16
	ldw r2, 0(r4)
	
	ldw r16, 0(sp)
	addi sp, sp, 4
	ret
	
.section .exceptions, "ax"

interrupt_handler:
	addi sp, sp, 128
	stwio et, 96(sp)
	rdctl et, ctl4
	beq et, r0, skip_ea_decrement
	subi ea, ea, 4
	
	skip_ea_decrement:
		stwio r1, 4(sp)
		stwio r2, 8(sp)
		stwio r3, 12(sp)
		stwio r4, 16(sp)
		stwio r5, 20(sp)
		stwio r6, 24(sp)
		stwio r7, 28(sp)
		stwio r8, 32(sp)
		stwio r9, 36(sp)
		stwio r10, 40(sp)
		stwio r11, 44(sp)
		stwio r12, 48(sp)
		stwio r13, 52(sp)
		stwio r14, 56(sp)
		stwio r15, 60(sp)
		stwio r16, 64(sp)
		stwio r17, 68(sp)
		stwio r18, 72(sp)
		stwio r19, 76(sp)
		stwio r20, 80(sp)
		stwio r21, 84(sp)
		stwio r22, 88(sp)
		stwio r23, 92(sp)
		#r24 = et, already saved
		stwio r25, 100(sp)
		stwio r26, 104(sp)
		#r27 = sp, no need to save 
		stwio r28, 112(sp)
		stwio r29, 116(sp)
		stwio r30, 120(sp)
		stwio r31, 124(sp)
		addi fp, sp, 128

	rdctl r16, ctl4	#each bit of r16 corresponds to each IRQ line				
	
	IRQ_iterate:
		#de Bruijn index lookup assumes that the input is non-zero
		#Because the interrupt handler was invoked, we can safely assume ctl4 to be non-zero
		sub r17, r0, r16	
		and r18, r16, r17	#r18 contains the least significant bit of ctl4
		mov r4, r18
		call de_Bruijn_index_lookup
	
		movia r17, interrupt_callback_lookup_table
		slli r2, r2, 2
		add r17, r17, r2
		ldw r17, 0(r17)
		callr r17
		
		xor r16, r18, r16						#clears the least significant bit of ctl4
		beq r16, r0, interrupt_handler_ret		#if r16 = 0, we have serviced all interrupt requests
		br IRQ_iterate
	
	interrupt_handler_ret:
		ldwio r1, 4(sp)
		ldwio r2, 8(sp)
		ldwio r3, 12(sp)
		ldwio r4, 16(sp)
		ldwio r5, 20(sp)
		ldwio r6, 24(sp)
		ldwio r7, 28(sp)
		ldwio r8, 32(sp)
		ldwio r9, 36(sp)
		ldwio r10, 40(sp)
		ldwio r11, 44(sp)
		ldwio r12, 48(sp)
		ldwio r13, 52(sp)
		ldwio r14, 56(sp)
		ldwio r15, 60(sp)
		ldwio r16, 64(sp)
		ldwio r17, 68(sp)
		ldwio r18, 72(sp)
		ldwio r19, 76(sp)
		ldwio r20, 80(sp)
		ldwio r21, 84(sp)
		ldwio r22, 88(sp)
		ldwio r23, 92(sp)
		#r24 = et, already saved
		ldwio r25, 100(sp)
		ldwio r26, 104(sp)
		#r27 = sp, no need to save 
		ldwio r28, 112(sp)
		ldwio r29, 116(sp)
		ldwio r30, 120(sp)
		ldwio r31, 124(sp)
		addi sp, sp, 128
		eret
