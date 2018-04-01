#ifndef ALT_DE1_SOC_NIOS2_AUDIO_H
#define ALT_DE1_SOC_NIOS2_AUDIO_H
/*! 
 *  \brief     		This is a NIOS II interrupt-driven audio core interface
 *  \details   	The user can register an audio read or write callback function, which
 *						will be invoked when the input fifo is 75% full, or when the output fifo 
 *						is 75% empty. 
 *  \author    	Frank Chen
 *  \date   		2018-04-01
 */

 /*! \brief 	Resets all audio states.
 * 	
 *	Disables audio interrupts, unregisters all audio callbacks and clears
 *	the input and output fifo. 
 */
void reset_audio(void);

 /*! \brief 	Clears both the left and right audio input fifo.
 */
void clear_audio_input_fifo(void);

 /*! \brief 	Clears both the left and right audio output fifo. 	
 */
void clear_audio_output_fifo(void);

 /*! \brief 	Registers an audio read callback function.
 *
 *	This callback is invoked when the input fifo is 75% full.  	
 */
void register_audio_read_callback(void (*callback)(void));

 /*! \brief 	Registers an audio write callback function.
 *
 *	The callback is invoked when the output fifo is 75% empty. 	
 */
void register_audio_write_callback(void (*callback)(void));

 /*! \brief 	Not implemented.
 */
void unregister_audio_read_callback(void);

 /*! \brief 	Not implemented.
 */
void unregister_audio_write_callback(void);

 /*! \brief 	Read up to buffer_size number of samples from the right
 *					input fifo. Returns the number of samples read.	
 */
int read_audio_right(int* buffer, unsigned int buffer_size);

 /*! \brief 	Read up to buffer_size number of samples from the left
 *					input fifo. Returns the number of samples read.	
 */
int read_audio_left(int* buffer, unsigned int buffer_size);

 /*! \brief 	Write up to buffer_size number of samples to the right
 *					input fifo. Returns the number of samples written.
 */
int write_audio_right(int* buffer, unsigned int buffer_size);

 /*! \brief 	Write up to buffer_size number of samples to the left
 *				input fifo. Returns the number of samples written.
 */
int write_audio_left(int* buffer, unsigned int buffer_size);

#endif /*ALT_DE1_SOC_NIOS2_AUDIO_H*/