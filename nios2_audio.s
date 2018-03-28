.equ AUDIO_CORE, 0xff203040
.equ AUDIO_CORE_IRQ, 6

.data
.align 2
audio_read_callback:
	.skip 4, 0
audio_write_callback:
	.skip 4, 0

.global initialize_audio	
.global register_audio_read_interrupt
.global unregister_audio_read_interrupt
.global register_audio_write_interrupt
.global unregister_audio_write_interrupt
