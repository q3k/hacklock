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

