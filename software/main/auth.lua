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


require('socket')
local sha2 = require('libsha2')
local https = require('ssl.https')

q3k.Auth = {}

-- the PIN is a table like { 1, 2, 3, 4 }
-- the NFC ID is a table like { 0xde, 0xad, 0xbe, 0xef }
local CalculateHash = function(PIN, NFCID)
    local PINString = string.format("%i%i%i%i", PIN[1], PIN[2], PIN[3], PIN[4])
    local PINNumber = tonumber(PINString)
    local IDString = string.format("%02x%02x%02x%02x", NFCID[4], NFCID[3], NFCID[2], NFCID[1])
    local Source = string.format("%08x:%s", PINNumber, IDString)
    return sha2.sha256hex(Source)
end

local GetUserFromHash = function(Hash)
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


----------------
-- Public API --
----------------

q3k.Auth.CardStatus = {
    -- No such card in the system - disallow
    NO_MATCH=1,
    -- Card okay - allow
    OKAY=2,
    -- Card okay, but member should pay soon - allow, but notify
    PAYMENT_DUE=3,
    -- Card okay, but member is way behing in payments - disallow
    PAYMENT_REQUIRED=4
}

q3k.Auth.GetCardStatus = function(PIN, NFCID)
    local Hash = CalculateHash(PIN, NFCID)
    local User = GetUserFromHash(Hash)

    if User == nil then
        return { Status = q3k.Auth.CardStatus.NO_MATCH }
    end
    return { Status = q3k.Auth.CardStatus.OKAY, User = User }
end
