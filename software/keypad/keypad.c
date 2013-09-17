#include <avr/io.h>
#include <avr/interrupt.h>

#include "io.h"

IMPORT_IO(KPAD_ROW1);
IMPORT_IO(KPAD_ROW2);
IMPORT_IO(KPAD_ROW3);
IMPORT_IO(KPAD_ROW4);
IMPORT_IO(KPAD_COL1);
IMPORT_IO(KPAD_COL2);
IMPORT_IO(KPAD_COL3);

IMPORT_IO(LED_RED);
IMPORT_IO(LED_GREEN);

void _keypad_update_column(void);

void keypad_init(void)
{
    TCCR0 = _BV(CS02);
    TCNT0 = 0;
    TIMSK |= _BV(TOIE0);

    IO_OUT(KPAD_ROW1, 1);
    IO_OUT(KPAD_ROW2, 1);
    IO_OUT(KPAD_ROW3, 1);
    IO_OUT(KPAD_ROW4, 1);
}

uint8_t g_KeypadColumn = 0;

void _keypad_update_column(void)
{
    g_KeypadColumn++;
    if (g_KeypadColumn > 2)
        g_KeypadColumn = 0;

    switch(g_KeypadColumn)
    {
        case 0:
            IO_SET_OUTPUT(KPAD_COL1);
            IO_SET_INPUT(KPAD_COL2);
            IO_SET_INPUT(KPAD_COL3);
            IO_OUT(KPAD_COL1, 0);
            IO_OUT(KPAD_COL2, 1);
            IO_OUT(KPAD_COL3, 1);
            break;
        case 1:
            IO_SET_INPUT(KPAD_COL1);
            IO_SET_OUTPUT(KPAD_COL2);
            IO_SET_INPUT(KPAD_COL3);
            IO_OUT(KPAD_COL1, 1);
            IO_OUT(KPAD_COL2, 0);
            IO_OUT(KPAD_COL3, 1);
            break;
        case 2:
            IO_SET_INPUT(KPAD_COL1);
            IO_SET_INPUT(KPAD_COL2);
            IO_SET_OUTPUT(KPAD_COL3);
            IO_OUT(KPAD_COL1, 1);
            IO_OUT(KPAD_COL2, 1);
            IO_OUT(KPAD_COL3, 0);
            break;
    }
}

// all the buttons of the matrix in a bitfield
uint16_t g_KeypadState = 0;
uint16_t g_NewKeypadState = 0;;

uint8_t _keypad_read_rows(void)
{
    uint8_t Result = 0;
    Result |= (IO_IN(KPAD_ROW1) << 0);
    Result |= (IO_IN(KPAD_ROW2) << 1);
    Result |= (IO_IN(KPAD_ROW3) << 2);
    Result |= (IO_IN(KPAD_ROW4) << 3);
    Result |= 0b11110000;
    return ~Result;
}

ISR(TIMER0_OVF_vect)
{
    _keypad_update_column();
    if (g_KeypadColumn == 0)
    {
        g_KeypadState = g_NewKeypadState;
        g_NewKeypadState = 0;
    }
    uint8_t State = _keypad_read_rows();
    g_NewKeypadState |= (State << (4 * g_KeypadColumn));
    
    IO_OUT(LED_GREEN, (g_KeypadState >> 0) & 1);
    IO_OUT(LED_RED, (g_KeypadState >> 1) & 1);
}

