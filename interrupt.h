#ifndef INTERRUPT_H
#define INTERRUPT_H
/*! 
 *  \brief     	This is a C interface for NIOS II interrupts
 *  \details   	This interface employs a simple, priority-less interrupt service 
 *				routine (ISR). If multiple interrupt requests are active at the   
 *				beginning of a handling cycle, each request is service starting from
 *				the lowest IRQ number.  				
 *  \author    	Frank Chen
 *  \version   	0.1
 *  \date      	2018-03-22
 *  \pre       	Set linker section presets to "Exceptions" in the Monitor Program.
 *  \bug       	The ISR does not save all states.
 */

/*! \brief 	Registers a callback function for an IRQ line.
 * 				
 *	Each IRQ line has exactly one callback; registering a new callback overwrites
 *	the existing one. 
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
 *	Enables the interrupt service routine. Callbacks for each IRQ line will
 *	not be invoked unless the interrupt service routine is enabled. 
 * 
 *	\warning
 *	Enabling master interrupt inside an interrupt callback has undefined behavior.		
 */
void enable_master_interrupt(void);

/*! \brief 	Disables master interrupt.
 * 	
 *	Disables the interrupt service routine. Devices may still emit interrupt requests, 
 * 	but they won't be serviced. 
 */
void disable_master_interrupt(void);

#endif /*INTERRUPT_H*/
