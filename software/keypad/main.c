#include <avr/io.h>
#include <avr/wdt.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#include "io.h"
#include "buzzer.h"
#include "keypad.h"

/////////////////////
// I/O ports setup //
/////////////////////

// Buzzer on PC2
DECLARE_IO(BUZZER, C, 2);
// Red LED pn PC1
DECLARE_IO(LED_RED, C, 1);
// Green LED on PC0
DECLARE_IO(LED_GREEN, C, 0);

// Keypad
DECLARE_IO(KPAD_COL3, D, 0);
DECLARE_IO(KPAD_ROW3, D, 1);
DECLARE_IO(KPAD_COMMON, D, 2);
DECLARE_IO(KPAD_COL2, D, 3);
DECLARE_IO(KPAD_ROW1, D, 4);
DECLARE_IO(KPAD_ROW2, D, 5);
DECLARE_IO(KPAD_ROW4, D, 6);
DECLARE_IO(KPAD_COL1, D, 7);


int main (void)
{
    // Setup outputs
    IO_SET_OUTPUT(BUZZER);
    IO_SET_OUTPUT(LED_RED);
    IO_SET_OUTPUT(LED_GREEN);

    buzzer_init();
    keypad_init();
    sei();

    // Flash LEDs and buzz buzzer for debug
    IO_OUT(LED_GREEN, 1);
    IO_OUT(LED_RED, 1);
    buzzer_signal_boot();
    IO_OUT(LED_GREEN, 0);
    IO_OUT(LED_RED, 0);

    for (;;) {}
    return 0;
}
