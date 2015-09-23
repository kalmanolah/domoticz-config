-- {{ Log something with the check name as a prefix
function check_log(str)
    print(check_name .. ': ' .. str)
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

check_name = 'AggregatePresenceDetection'
device_name = 'Presence (Any)'
check_interval = 30
commandArray = {}

check_log('Attempting to execute')
local difference = last_update(device_name)

if (difference > check_interval) then
    check_log('Last ran ' .. difference .. ' seconds ago, running again..')

    -- {{  Check-specific logic here

    -- Loop through presence devices list and detect presences
    local presence = nil
    -- local presence_last_update_threshold = tonumber(uservariables['PRESENCE_AGGREGATION_DEVICE_LAST_UPDATE_THRESHOLD'])

    for i in string.gmatch(uservariables['PRESENCE_AGGREGATION_DEVICES'], "[^;]+") do
        -- Only continue if the value of this device hasn't changed within THRESHOLD seconds
        -- if last_update(i) > presence_last_update_threshold then
            local presence_check = otherdevices[i] == 'On'
            check_log('Device "' .. i .. '" active: ' .. tostring(presence_check))

            -- If our presence value is still unset, set it to false
            -- This lets us know when a device has been checked after a threshold match
            if presence == nil then
                presence = false
            end

            if presence_check then
                presence = true
            end
        -- else
            -- check_log('Device "' .. i .. '" was updated less than "' .. tostring(presence_last_update_threshold) .. '" seconds ago, skipping value')
        -- end
    end

    if presence == nil then
        check_log('No devices were checked')
    else
        check_log('Presence detected: ' .. tostring(presence))
        local device_state = presence and 'On' or 'Off'

        if otherdevices[device_name] ~= device_state then
            commandArray[device_name] = device_state
            check_log('Setting value of device "' .. device_name .. '" to "' .. device_state .. '"')
        else
            check_log('Value of device "' .. device_name .. '" is already set to "' .. device_state .. '"')
        end
    end
    -- }}

else
    print('Last ran ' .. difference .. ' seconds ago, not running..')
end

return commandArray
