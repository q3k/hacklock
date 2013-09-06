-- Copyright (c) 2013 Sergiusz 'q3k' Bazański <q3k@q3k.org>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

-- This is the HSWAW lock mk2. source code.

-- System libraries
require('posix')

-- Configuration
q3k = {}
q3k.Config = {}
q3k.Config.I2CBus = 0
q3k.Config.I2CGPIO = 0x40
q3k.Config.I2CNFC = 0x24

-- Code libraries
require('i2c')
require('nfc')
require('auth')

-- GPIO Functions
q3k.SetupGPIO = function()
    -- Set up pins 28, 29, 30, 31 as output
    q3k.I2C.Write(q3k.Config.I2CGPIO, 0x0F, 0x55)
    q3k.DoorClose()
    -- Set up pins 12, 13, 14, 15 as input without pullups
    q3k.I2C.Write(q3k.Config.I2CGPIO, 0x0B, 0xAA)

    -- Turn on GPIO Multiplexer
    q3k.I2C.Write(q3k.Config.I2CGPIO, 0x04, 0x01)
end

q3k.DoorOpen = function()
     -- Turn on pin 31 (door)
        q3k.I2C.Write(q3k.Config.I2CGPIO, 0x3F, 0x01)
end

q3k.DoorClose = function()
     -- Turn off pin 31 (door)
        q3k.I2C.Write(q3k.Config.I2CGPIO, 0x3F, 0x00)
end

-- Mock until we have a keypad
q3k.ReadPIN = function()
    print "[mock] Entering PIN..."
    posix.sleep(2)
    print "[mock] PIN entered."
    return { 0, 0, 0, 0 }
end

local main = function()
    q3k.SetupGPIO()
    q3k.NFC.Setup()

    while true do
        q3k.NFC.WaitForCard(120, function(NFCID)
            local PIN = q3k.ReadPIN()
            local Result = q3k.Auth.GetCardStatus(PIN, NFCID)
            local Status = Result.Status
            local CS = q3k.Auth.CardStatus
            if Status == CS.NO_MATCH then
                print "No such user!"
            elseif Status == CS.OKAY then
                print(string.format("Hello %s!", Result.User))
            else
                print "Unknown status."
            end
        end)
    end
end

main()
