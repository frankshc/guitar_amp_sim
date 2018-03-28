#ifndef AUDIO_EXTENDED_H
#define AUDIO_EXTENDED_H

void register_audio_read_interrupt(void (*callback)(void));
void unregister_audio_read_interrupt(void);
void register_audio_write_interrupt(void (*callback)(void));
void unregister_audio_write_interrupt(void);

void initialize_audio(void);

int read_audio_left_channel(int* buffer, unsigned buffer_size);
int read_audio_right_channel(int* buffer, unsigned buffer_size);

int write_audio_left_channel(int* buffer, unsigned buffer_size);
int write_audio_right_channel(int* buffer, unsigned buffer_size);

#endif /*AUDIO_EXTENDED_H*/
