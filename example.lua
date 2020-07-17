local ffi = require 'ffi'
local fswatch = require 'fswatch'

fswatch.set_verbose(arg[1] == '--verbose')

local session = fswatch.init_session()
assert(session:set_callback(function(events, event_num)
    for path, time, flags in events:iter() do
        print(path, time, table.concat(flags, ' | '))
    end
end))
session:add_path(".")
session:add_filter{ '.git', 'filter_exclude', false, false }
assert(session:start_monitor())

while session:is_running() do end