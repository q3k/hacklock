#include <avr/io.h>
#include <avr/interrupt.h>

#include "io.h"

IMPORT_IO(BUZZER);

void buzzer_init(void)
{
    // Set up Timer1 - CTC and /256 prescaler
    TCCR1A = 0;
    TCCR1B = _BV(WGM12) | _BV(CS12);
    TCNT1 = 0;
    OCR1A = 4;
    OCR1B = 0xFFFF;
}

void buzzer_start(uint16_t ticks)
{
    cli();
    TIMSK &= ~_BV(OCIE1A);
    OCR1A = ticks;
    TIMSK = _BV(OCIE1A);
    TCNT1 = 0;
    sei();
}

void buzzer_stop(void)
{
    cli();
    TIMSK &= ~_BV(OCIE1A);
    sei();
}

ISR(TIMER1_COMPA_vect)
{
    IO_TOGGLE(BUZZER);
}
