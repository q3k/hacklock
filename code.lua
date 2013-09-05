-- The MIT License (MIT)
-- 
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

-- This is the HSWAW lock mk2. source code. WIP. refucktor badly needed.

local i2c = require("libluai2c")
require('bit')
require('socket')
require('posix')
local sha2 = require('libsha2')
local https = require('ssl.https')

q3k = {}
q3k.Config = {}

q3k.Config.I2CBus = 0

q3k.Config.I2CGPIO = 0x40
q3k.Config.I2CNFC = 0x24

q3k.I2CWrite = function(Address, ...)
    local Data = {...}
    local Bytes = string.format("%02x ", Address)
    for _, Byte in pairs(Data) do
        Bytes = Bytes .. string.format("%02x ", Byte)
    end
    local DataString = string.char(unpack(Data))
    return i2c.write(q3k.Config.I2CBus, Address, DataString)
end

q3k.I2CRead = function(Address, BytesOut, ...)
    local Data = {...}
    local DataString = string.char(unpack(Data))
    local Status, Data = i2c.read(q3k.Config.I2CBus, Address, BytesOut, DataString)
    local Return = {}

    if Status == 0 then
        Data:gsub(".", function(c)
            Return[#Return+1] = string.byte(c)
        end)
        return Return
    end
end

-- sigh. luaposix on openwrt doesn't have nanosleep()
q3k.Sleep = function(Seconds)
    socket.select(nil, nil, Seconds)
end

-- GPIO Functions
q3k.SetupGPIO = function()
    -- Set up pins 28, 29, 30, 31 as output
    q3k.I2CWrite(q3k.Config.I2CGPIO, 0x0F, 0x55)
    q3k.DoorClose()
    -- Set up pins 12, 13, 14, 15 as input without pullups
    q3k.I2CWrite(q3k.Config.I2CGPIO, 0x0B, 0xAA)

    -- Turn on GPIO Multiplexer
    q3k.I2CWrite(q3k.Config.I2CGPIO, 0x04, 0x01)
end

q3k.DoorOpen = function()
     -- Turn on pin 31 (door)
        q3k.I2CWrite(q3k.Config.I2CGPIO, 0x3F, 0x01)
end

q3k.DoorClose = function()
     -- Turn off pin 31 (door)
        q3k.I2CWrite(q3k.Config.I2CGPIO, 0x3F, 0x00)
end

-- NFC (PN532) functions
local PN532_PREAMBLE = 0x00
local PN532_STARTCODE1 = 0x00
local PN532_STARTCODE2 = 0xFF
local PN532_POSTAMBLE = 0x00

local PN532_HOSTTOPN532 = 0xD4
local PN532_PN532TOHOST = 0xD5

q3k.NFCIRQRead = function()
    local Data = q3k.I2CRead(q3k.Config.I2CGPIO, 1, 0x2C)
    if Data then
        return Data[1]
    else
        return 1
    end
end

q3k.NFCWaitForIRQ = function(Timeout)
    local Timeout = Timeout or 5
    local WaitStart = os.time()
    while os.time() < WaitStart + Timeout do
        local IRQStatus = q3k.NFCIRQRead()
          if IRQStatus == 0 then
            break
        end
        q3k.Sleep(0.2)
    end
    local IRQStatus = q3k.NFCIRQRead()
        if IRQStatus ~= 0 then
                return false
        end
    return true
end

q3k.NFCWriteCommand = function(...)
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

    q3k.I2CWrite(q3k.Config.I2CNFC, unpack(WireCommand))
end

q3k.NFCSendAndAck = function(...)
    q3k.NFCWriteCommand(...)
    local IRQArrived = q3k.NFCWaitForIRQ()
    if not IRQArrived then
        return false
    end
    local ACK = q3k.I2CRead(q3k.Config.I2CNFC, 8)
    if ACK[1] == 1 and ACK[2] == 0 and ACK[3] == 0 and ACK[4] == 255 
        and ACK[5] == 0 and ACK[6] == 255 and ACK[7] == 0 then
        return true
    else
        return false
    end
end

q3k.NFCReadFrame = function(Count)
    local Bytes = q3k.I2CRead(q3k.Config.I2CNFC, Count+2)
    table.remove(Bytes, 1)
    table.remove(Bytes, #Bytes)
    return Bytes
end

-- Mock until we have a keypad
q3k.ReadPIN = function()
    print "[mock] Entering PIN..."
    q3k.Sleep(2)
    print "[mock] PIN entered."
    return { 0, 0, 0, 0 }
end

-- API stuff

-- the PIN is a table like { 1, 2, 3, 4 }
-- the NFC ID is a table like { 0xde, 0xad, 0xbe, 0xef }
q3k.CalculateHash = function(PIN, NFCID)
    local PINString = string.format("%i%i%i%i", PIN[1], PIN[2], PIN[3], PIN[4])
    local PINNumber = tonumber(PINString)
    local IDString = string.format("%02x%02x%02x%02x", NFCID[4], NFCID[3], NFCID[2], NFCID[1])
    local Source = string.format("%08x:%s", PINNumber, IDString)
    return sha2.sha256hex(Source)
end

q3k.GetUserFromHash = function(Hash)
    local Body, Code, Headers, Status = https.request('https://auth.hackerspace.pl/mifare', 'hash=' .. Hash)
    if Code ~= 200 then
        return nil
    end
    if #Body > 100 then
        -- probably an error code
        return nil
    end
    return Body
end

-- debug bytes
local db = function(Data)
    local s = ""
    for _, Byte in pairs(Data) do
        s = s .. string.format("%02x ", Byte)
    end
    print(s)
end

local main = function()
    q3k.SetupGPIO()
    q3k.NFCSendAndAck(0x14, 0x01, 0x14, 0x01)

    while true do
        q3k.NFCSendAndAck(0x4A, 1, 0)
        if q3k.NFCWaitForIRQ(120) then
            print "Card arrived in field"
            local Bytes = q3k.NFCReadFrame(20)
            if Bytes ~= nil and #Bytes == 20 then
                local NFCID = { Bytes[14], Bytes[15], Bytes[16], Bytes[17] }
                local Hash = q3k.CalculateHash(q3k.ReadPIN(), NFCID)
                local User = q3k.GetUserFromHash(Hash) 
                if User == nil then
                    print "FAILED! no such user!"
                else
                    print(string.format("User: %s", User))
                end
            end
        end
    end
end

main()
