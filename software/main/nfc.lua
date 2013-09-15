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


-- NFC-related functions.
-- This implementation is for the PN532 chip.

require('socket')
require('bit')

q3k.NFC = {}

local PN532_PREAMBLE = 0x00
local PN532_STARTCODE1 = 0x00
local PN532_STARTCODE2 = 0xFF
local PN532_POSTAMBLE = 0x00

local PN532_HOSTTOPN532 = 0xD4
local PN532_PN532TOHOST = 0xD5

------------------------
-- Internal functions --
------------------------

-- sigh. luaposix on openwrt doesn't have nanosleep()
local Sleep = function(Seconds)
    socket.select(nil, nil, Seconds)
end

-- Get the IRQ pin status
local IRQRead = function()
    local Data = q3k.I2C.Read(q3k.Config.I2CGPIO, 1, 0x2C)
    if Data then
        return Data[1]
    else
        return 1
    end
end

-- Wait „Timeout” seconds for IRQ (or 5, if not given)
local WaitForIRQ = function(Timeout)
    local Timeout = Timeout or 5
    local WaitStart = os.time()
    while os.time() < WaitStart + Timeout do
        local IRQStatus = IRQRead()
          if IRQStatus == 0 then
            break
        end
        Sleep(0.2)
    end
    local IRQStatus = IRQRead()
        if IRQStatus ~= 0 then
                return false
        end
    return true
end

-- Write a PN532 command
local WriteCommand = function(...)
    local Command = {...}
    local Checksum = PN532_PREAMBLE + PN532_STARTCODE1 + PN532_STARTCODE2
    local WireCommand = { PN532_PREAMBLE, PN532_STARTCODE1, PN532_STARTCODE2 }

    WireCommand[#WireCommand+1] = (#Command + 1)
    WireCommand[#WireCommand+1] = bit.band(bit.bnot(#Command +1) + 1, 0xFF)

    Checksum = Checksum + PN532_HOSTTOPN532
    WireCommand[#WireCommand+1] = PN532_HOSTTOPN532

    for _, Byte in pairs(Command) do
        Checksum = Checksum + Byte
        WireCommand[#WireCommand+1] = Byte
    end

    WireCommand[#WireCommand+1] = bit.band(bit.bnot(Checksum), 0xFF)
    WireCommand[#WireCommand+1] = PN532_POSTAMBLE

    q3k.I2C.Write(q3k.Config.I2CNFC, unpack(WireCommand))
end

-- Send a PN532 and see if we get an ACK
local SendAndAck = function(...)
    WriteCommand(...)
    local IRQArrived = WaitForIRQ()
    if not IRQArrived then
        return false
    end
    local ACK = q3k.I2C.Read(q3k.Config.I2CNFC, 8)
    if ACK[1] == 1 and ACK[2] == 0 and ACK[3] == 0 and ACK[4] == 255
        and ACK[5] == 0 and ACK[6] == 255 and ACK[7] == 0 then
        return true
    else
        return false
    end
end

-- Read a PN532 frame
local ReadFrame = function(Count)
    local Bytes = q3k.I2C.Read(q3k.Config.I2CNFC, Count+2)
    table.remove(Bytes, 1)
    table.remove(Bytes, #Bytes)
    return Bytes
end

----------------
-- Public API --
----------------

-- Call this once the I2C bus and GPIO multiplexer are ready
q3k.NFC.Setup = function()
    -- enable SAM with stuff.
    if SendAndAck(0x14, 0x01, 0x14, 0x01) == false then
        print "SAM configuration failed!"
        return false
    end
    return true
end

-- Waits for a NFC card to appear in the field
-- „Seconds” is how long the reader will block
-- „Callback” is a callback which is called when a card appears, and takes
-- a single argument which is the NFC ID like this: { 0x00, 0x01, 0x02, 0x03 }
q3k.NFC.WaitForCard = function(Seconds, Callback)
    if SendAndAck(0x4A, 0x01, 0x0) == false then
        print "Sending card read command failed!"
        return false
    end
    if WaitForIRQ(Seconds) then
        local Bytes = ReadFrame(20)
        if Bytes ~= nil and #Bytes == 20 then
            local NFCID = { Bytes[14], Bytes[15], Bytes[16], Bytes[17] }
            Callback(NFCID)
        end
        return true
    end
    return true
end
