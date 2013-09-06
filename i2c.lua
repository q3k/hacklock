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

-- This is a thin, Lua-y wrapper around libluai2c.

local i2c = require('libluai2c')

----------------
-- Public API --
----------------

q3k.I2C = {}

-- Write to „Address” on the I2C bus
q3k.I2C.Write = function(Address, ...)
    local Data = {...}
    local Bytes = string.format("%02x ", Address)
    for _, Byte in pairs(Data) do
        Bytes = Bytes .. string.format("%02x ", Byte)
    end
    local DataString = string.char(unpack(Data))
    return i2c.write(q3k.Config.I2CBus, Address, DataString)
end

-- Read „BytesOut” bytes from „Address” on the I2C bus
q3k.I2C.Read = function(Address, BytesOut, ...)
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

