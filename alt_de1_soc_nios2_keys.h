#ifndef ALT_DE1_SOC_NIOS2_KEYS_H
#define ALT_DE1_SOC_NIOS2_KEYS_H
/*! 
 *  \brief     		This is an interrupt-driven NIOS II keys/pushbutton interface
 *  \details   	Keys are numbered 0 through 3. If multiple keys are pressed
 *						at the same time, the lowest-numbered key callback is invoked
 * 					first. 
 *  \author    	Frank Chen
 *  \date      	2018-04-01
 */
 
/*! \brief 	Resets all key states.
 * 				
 *	Calling this function disables interrupts on all keys and clears
 *	the Edge Capture Register. 
 */
void reset_keys(void);

/*! \brief 	Registers a callback for a key.
 * 				 
 *	Each key has at most one callback; registering a new callback on the same
 *	key overwrites the previous callback. 
 *
 *	\warning
 *	key number must be an integer in [0...3].
 */
void register_key_callback(int key, void (*callback)(void));

/*! \brief 	Unregisters an existing callback associated with a key, if it exists.
 *
 *	\warning
 *	key number must be an integer in [0...3].
 */
void unregister_key_callback(int key);
#endif /*ALT_DE1_SOC_NIOS2_KEYS_H*/
