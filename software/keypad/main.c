#include <avr/io.h>
#include <avr/wdt.h>
#include <avr/interrupt.h>

/////////////////////
// I/O ports setup //
/////////////////////

typedef struct
{
    volatile uint8_t *DDR;
    volatile uint8_t *PORT;
    volatile uint8_t *PIN;
    uint8_t Bitmap;
} TIOPort;

#define DECLARE_IO(name, port, bit) TIOPort g_IO_##name = { &DDR##port, &PORT##port, &PIN##port, (1 << bit) }
#define IO_SET_OUTPUT(name) do { *g_IO_##name.DDR |= g_IO_##name.Bitmap; } while(0)
#define IO_SET_INPUT(name) do { *g_IO_##name.DDR &= ~g_IO_##name.Bitmap; } while(0)
#define IO_INPUT_PULLUP(name) do { *g_IO_##name.PORT |= g_IO_##name.Bitmap; } while(0)

#define IO_OUT(name, value) do { if (value) \
        *g_IO_##name.PORT |= g_IO_##name.Bitmap; \
    else \
        *g_IO_##name.PORT &= ~g_IO_##name.Bitmap; } while(0)
#define IO_TOGGLE(name) do { *g_IO_##name.PORT ^= g_IO_##name.Bitmap; } while(0)
#define IO_IN(name) (*g_IO_##name.PIN & g_IO_##name.Bitmap)

// Buzzer on PC2
DECLARE_IO(BUZZER, C, 2);
// Red LED pn PC1
DECLARE_IO(LED_RED, C, 1);
// Green LED on PC0
DECLARE_IO(LED_GREEN, C, 0);

// Keypad
DECLARE_IO(KPAD_COL3, D, 0);
DECLARE_IO(KAPD_ROW3, D, 1);
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

    IO_OUT(LED_GREEN, 1);
    IO_OUT(LED_RED, 1);

    for (;;) {}
    return 0;
}
