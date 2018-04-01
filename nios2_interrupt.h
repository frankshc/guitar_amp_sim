#ifndef NIOS2_INTERRUPT_H
#define NIOS2_INTERRUPT_H
/*! 
 *  \brief     		This is a NIOS II interrupt handler interface
 *  \details   	Each IRQ line has equal priority. Requests are serviced in a 
						round-robin format, starting from the lowest-numbered IRQ
						request. 
 *  \author    	Frank Chen
 *  \date      	2018-04-01
 */

/*! \brief 	Registers a callback function for an IRQ line.
 * 				
 *	Registering a callback for an IRQ line also enables interrupt request listening
 *	on that IRQ line.
 *
 *	\note
 *	Each IRQ line has at most one callback; registering a new callback overwites
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
 *	but they won't be serviced. Does not affect already registered callbacks.
 */
void disable_master_interrupt(void);

/*! \brief 	Returns the current master interrupt state.
 *
 *	Use this function with toggle_master_interrupt to implement atomic sections.
 */
int is_master_interrupt_enabled(void);

/*! \brief  Toggles the master interrupt enable switch.
 * 	
 *	Use this function with is_master_interrupt_enabled to implement atomic sections.
 */
void toggle_master_interrupt(int toggle);
#endif /*NIOS2_INTERRUPT_H*/
