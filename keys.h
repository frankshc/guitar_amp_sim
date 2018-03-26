#ifndef KEYS_H
#define KEYS_H

/*! \brief 	Initializes the keys.
 * 				
 *	Calling this function disables interrupts on all keys and clears
 *	the Edge Capture Register. 
 */
void initialize_keys(void);

/*! \brief 	Registers a callback for a key.
 * 				
 *	The callback function pointer must have return type void and no parameters. 
 *	Each key may only have one callback; registering a new callback on the same
 *	key overwrites the previous callback. Undefined behavior for key numbers not
 *	between 0 and 3.
 */
void register_key_press_callback(int key, void (*callback)());

/*! \brief 	Unregisters an existing callback associated with a key.
 * 				
 *	If a key does not have an existing callback, unregistering callback 
 *	does nothing.
 */
void unregister_key_press_callback(int key);

#endif /*KEYS_H*/
