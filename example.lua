local ffi = require 'ffi'
local fswatch = require 'fswatch'

local session = fswatch.init_session()
assert(session:set_callback(function(events, event_num)
    for i = 1, event_num do
        local event = events[i - 1]
        print(ffi.string(event.path), event.evt_time)
    end
end))
session:add_path(".")
assert(session:start_monitor())

while true do end