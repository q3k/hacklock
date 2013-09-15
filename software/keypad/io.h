#ifndef _Q__IO_H__
#define _Q__IO_H__

typedef struct
{
    volatile uint8_t *DDR;
    volatile uint8_t *PORT;
    volatile uint8_t *PIN;
    uint8_t Bitmap;
} TIOPort;

#define DECLARE_IO(name, port, bit) TIOPort g_IO_##name = { &DDR##port, &PORT##port, &PIN##port, (1 << bit) }
#define IMPORT_IO(name) extern TIOPort g_IO_##name
#define IO_SET_OUTPUT(name) do { *g_IO_##name.DDR |= g_IO_##name.Bitmap; } while(0)
#define IO_SET_INPUT(name) do { *g_IO_##name.DDR &= ~g_IO_##name.Bitmap; } while(0)
#define IO_INPUT_PULLUP(name) do { *g_IO_##name.PORT |= g_IO_##name.Bitmap; } while(0)

#define IO_OUT(name, value) do { if (value) \
        *g_IO_##name.PORT |= g_IO_##name.Bitmap; \
    else \
        *g_IO_##name.PORT &= ~g_IO_##name.Bitmap; } while(0)
#define IO_TOGGLE(name) do { *g_IO_##name.PORT ^= g_IO_##name.Bitmap; } while(0)
#define IO_IN(name) (*g_IO_##name.PIN & g_IO_##name.Bitmap)


#endif
