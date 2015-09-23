-- {{ Log something with the check name as a prefix
function check_log(str)
    print(check_name .. ': ' .. str)
end
-- }}

-- {{ See http://stackoverflow.com/a/326715
function os.capture(cmd, raw)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    if raw then return s end
    s = string.gsub(s, '^%s+', '')
    s = string.gsub(s, '%s+$', '')
    s = string.gsub(s, '[\n\r]+', ' ')
    return s
end
-- }}

-- {{ Fetch the amount of seconds since a device was updated
function last_update(device_name)
    local t1 = os.time()
    local s = otherdevices_lastupdate[device_name]
    local year = string.sub(s, 1, 4)
    local month = string.sub(s, 6, 7)
    local day = string.sub(s, 9, 10)
    local hour = string.sub(s, 12, 13)
    local minutes = string.sub(s, 15, 16)
    local seconds = string.sub(s, 18, 19)
    local t2 = os.time{year=year, month=month, day=day, hour=hour, min=minutes, sec=seconds}
    local difference = (os.difftime (t1, t2))

    return difference
end
-- }}

check_name = 'DetectPresenceViaEthernetMAC'
device_name = 'Presence (Ethernet MAC)'
variable_name = 'MAC_ADDRESSES_ETHERNET'
check_interval = 30
commandArray = {}

check_log('Attempting to execute')
local difference = last_update(device_name)

if (difference > check_interval) then
    check_log('Last ran ' .. difference .. ' seconds ago, running again..')

    -- {{  Check-specific logic here

    -- Grab the main network address and netmask
    local network_address = os.capture("ip -o -f inet addr show | awk '/scope global/ {print $4}'")
    commandArray['Variable:NETWORK_ADDRESS_ETHERNET'] = network_address
    check_log('Network address determined to be "' .. network_address .. '"')

    -- Clear the ARP cache because we don't really like outdated entries
    local clear_result = os.execute('ip -s -s neigh flush all')
    check_log('ARP table clear successful: ' .. tostring(clear_result))

    -- Attempt to ARP scan the local network
    local scan_result = os.execute('sudo nmap -n -sn -T3 ' .. network_address)
    check_log('Host discovery scan execution successful: ' .. tostring(scan_result))

    -- Loop through presence MAC address list and detect presences
    local presence = false

    for i in string.gmatch(uservariables['PRESENCE_MAC_ADDRESSES_ETHERNET'], "[^;]+") do
        local presence_check = os.execute('arp -n | grep -i "' .. i .. '"')
        check_log('MAC address "' .. i .. '" present: ' .. tostring(presence_check))

        if presence_check then
            presence = true
        end
    end

    check_log('Presence detected: ' .. tostring(presence))
    local device_state = presence and 'On' or 'Off'

    if otherdevices[device_name] ~= device_state then
        commandArray[device_name] = device_state
        check_log('Setting value of device "' .. device_name .. '" to "' .. device_state .. '"')
    else
        check_log('Value of device "' .. device_name .. '" is already set to "' .. device_state .. '"')
    end
    -- }}

else
    print('Last ran ' .. difference .. ' seconds ago, not running..')
end

return commandArray
