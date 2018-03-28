#ifndef NIOS2_INTERRUPT_H
#define NIOS2_INTERRUPT_H
/*! 
 *  \brief     	This is a NIOS II interrupt handler interface
 *  \details   	This interface employs a simple, priority-less interrupt handler.
 *				If multiple interrupt requests are active at the beginning of a handling   
 *				cycle, each request is service starting from the lowest IRQ number.
 *  \author    	Frank Chen
 *  \version   	0.1
 *  \date      	2018-03-22
 *  \pre       	Set linker section presets to "Exceptions" in the Monitor Program.
 */

/*! \brief 	Registers a callback function for an IRQ line.
 * 				
 *	Registering a callback for an IRQ line also enables interrupt request listening
 *	on that IRQ line.
 *
 * 	\note
 *	Each IRQ line has at most one callback; registering a new callback overwites
 * 	the existing one.
 *
 *	\warning
 *	IRQ line must be an integer in [0...32].
 */
void register_interrupt_callback(int IRQ, void (*callback)(void));

/*! \brief 	Unregisters the callback function for an IRQ line, if it exists.
 * 	
 *	\warning
 *	IRQ line must be an integer in [0...32]. 
 */
void unregister_interrupt_callback(int IRQ);

/*! \brief 	Enables master interrupt.
 * 	
 *	Enables the interrupt handler. Callbacks for each IRQ line will not be invoked
 *	unless the interrupt handler is enabled.
 * 
 *	\warning
 *	Enabling master interrupt inside an interrupt callback has undefined behavior.		
 */
void enable_master_interrupt(void);

/*! \brief 	Disables master interrupt.
 * 	
 *	Disables the interrupt service routine. Devices may still emit interrupt requests, 
 * 	but they won't be serviced. Does not affect registered callbacks.
 */
void disable_master_interrupt(void);

#endif /*NIOS2_INTERRUPT_H*/
