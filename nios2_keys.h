#ifndef NIOS2_KEYS_H
#define NIOS2_KEYS_H

/*! \brief 	Resets the keys.
 * 				
 *	Calling this function disables interrupts on all keys and clears
 *	the Edge Capture Register. 
 */
void reset_keys(void);

/*! \brief 	Registers a callback for a key.
 * 				 
 *	\note 
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

#endif /*NIOS2_KEYS_H*/
