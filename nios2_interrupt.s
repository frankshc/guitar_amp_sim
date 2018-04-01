.data
.align 2
interrupt_callback_lookup_table:
	.skip 128, 0
	
de_Bruijn_lookup_table:
	.byte 0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8, 31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9
	
.text
.global register_interrupt_callback
.global unregister_interrupt_callback
.global enable_master_interrupt
.global disable_master_interrupt
.global is_master_interrupt_enabled
.global toggle_master_interrupt

#r4 - IRQ line
#r5 - callback function pointer
register_interrupt_callback:	
	addi sp, sp, -24
	stw ra, 20(sp)
	stw r20, 16(sp)
	stw r19, 12(sp)
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)
	
	#back up incoming arguments
	mov r16, r4
	mov r17, r5
	
	#ATOMIC BEGIN
	call is_master_interrupt_enabled
	mov r20, r2
	call disable_master_interrupt
	
	#enable the IRQ line
	rdctl r18, ctl3
	movi r19, 1
	sll r19, r19, r16
	or r18, r18, r19
	wrctl ctl3, r18
	
	#calculate offset from interrupt_callback_lookup_table head
	#store the callback pointer there
	movia r18, interrupt_callback_lookup_table
	slli r19, r4, 2
	add r18, r18, r19
	stw r17, 0(r18)
	
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

#r4 - IRQ line	
unregister_interrupt_callback:
	addi sp, sp, -24
	stw ra, 20(sp)
	stw r20, 16(sp)
	stw r19, 12(sp)
	stw r18, 8(sp)
	stw r17, 4(sp)
	stw r16, 0(sp)

	mov r16, r4
	
	#ATOMIC BEGIN
	call is_master_interrupt_enabled
	mov r20, r2
	call disable_master_interrupt
	
	#disable the IRQ line
	rdctl r17, ctl3
	movi r18, 1
	sll r18, r18, r16
	movi r19, -1
	sub r18, r19, r18
	and r17, r17, r18
	wrctl ctl3, r17

	#set the callback function pointer to NULL
	movia r17, interrupt_callback_lookup_table
	slli r18, r16, 2
	add r17, r17, r18
	stw r0, 0(r17)
	
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
	
enable_master_interrupt:
	movi r4, 1
	wrctl ctl0, r4
	ret

disable_master_interrupt:
	wrctl ctl0, r0
	ret
	
is_master_interrupt_enabled:
	rdctl r2, ctl0
	andi r2, r2, 1
	ret
	
toggle_master_interrupt:
	cmpne r4, r4, r0
	wrctl ctl0, r4
	ret

.align 2	
.section .exceptions, "ax"
#there is a fixed 78 instruction overhead for
#each invocation of the interrupt handler

#each unique IRQ request has an additional
#16 instruction overhead

#overhead = 78 + 16 * n
interrupt_handler:
	addi sp, sp, -128
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
		#r24 = et, already saved above
		stwio r25, 100(sp)
		stwio r26, 104(sp)
		#r27 = sp, no need to save 
		stwio r28, 112(sp)
		stwio r29, 116(sp)
		stwio r30, 120(sp)
		stwio r31, 124(sp)
		addi fp, sp, 128
	
	#const ipending mask 
	movi r16, -1
	
	#const de Bruijn sequence number
	movia r19, 0x077cb531
	
	#const de Bruijn lookup table pointer
	movia r20, de_Bruijn_lookup_table
	
	#const interrupt callback table pointer
	movia r21, interrupt_callback_lookup_table
	
	#ipending mask
	movi r22, -1
	
	interrupt_loop:
		#must mask the ipending register
		#so that an IRQ line is only serviced once
		rdctl r17, ctl4
		and r17, r17, r22
		beq r17, r0, interrupt_handler_ret
		
		#clear all bits except the 
		#least significant bit
		sub r18, r0, r17
		and r17, r17, r18
		
		#multiply with de Bruijn sequence 
		#to find the position of the set bit
		mul r17, r17, r19
		srli r17, r17, 27
		#r17 contains the index to de Bruijn lookup table
		add r17, r20, r17
		ldbu r17, 0(r17)
		#r17 contains the position of the set ipending bit
		#use r17 as index to the callback table
		
		#save r17 because we need it to increment some
		#loop variables later
		mov r23, r17
		
		slli r17, r17, 2
		add r17, r21, r17 
		#r17 contains the pointer to the appropriate callback
		ldw r17, 0(r17)
		
		#normally, the function pointer should not be NULL
		#it is safe for an earlier interrupt handled in the same
		#service cycle to modify the interrupt states of a later
		#one, provided that it uses the nios2_interrupt interface
		#to do so. 
		#
		#for example, if an earlier interrupt unregisters a later
		#interrupt's callback, but the later interrupt was already 
		#received, this should not cause any problems because
		#the unregister function will disable interrupt on that 
		#IRQ line, in which case the ipending bit for that IRQ would
		#be cleared. Because the interrupt loop re-loads the 
		#ipending register in each iteration, the later interrupt, which
		#was received earlier, would not be called. 

		callr r17
		
		#update the interrupt mask r22
		#r22 should be the const r16 mask shifted
		#left by r23 bits
		sll r22, r16, r23
		br interrupt_loop	
			
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
		ldwio r24, 96(sp)
		ldwio r25, 100(sp)
		ldwio r26, 104(sp)
		#r27 = sp, no need to save 
		ldwio r28, 112(sp)
		ldwio r29, 116(sp)
		ldwio r30, 120(sp)
		ldwio r31, 124(sp)
		addi sp, sp, 128
		eret
