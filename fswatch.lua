local ffi = require 'ffi'
local libfswatch = require 'libfswatch'

local function create_enum(...)
    local enum = {}
    for i = 1, select('#', ...) do
        local key = i - 1
        local value = select(i, ...)
        enum[key] = value
        enum[value] = key
    end
    return enum
end
local function create_enum_options(indexed_zero, ...)
    local enum = {
        [0] = indexed_zero,
        [indexed_zero] = 0,
    }
    for i = 1, select('#', ...) do
        local key = bit.lshift(1, i - 1)
        local value = select(i, ...)
        enum[key] = value
        enum[value] = key
    end
    return enum
end

FSW_STATUS = create_enum_options(
    'OK', 'ERR_UNKNOWN_ERROR', 'ERR_SESSION_UNKNOWN', 'ERR_MONITOR_ALREADY_EXISTS',
    'ERR_MEMORY', 'ERR_UNKNOWN_MONITOR_TYPE', 'ERR_CALLBACK_NOT_SET',
    'ERR_PATHS_NOT_SET', 'ERR_MISSING_CONTEXT', 'ERR_INVALID_PATH',
    'ERR_INVALID_CALLBACK', 'ERR_INVALID_LATENCY', 'ERR_INVALID_REGEX',
    'ERR_MONITOR_ALREADY_RUNNING', 'ERR_UNKNOWN_VALUE', 'ERR_INVALID_PROPERTY'
)

fsw_event_flag = create_enum_options(
    'NoOp', 'PlatformSpecific', 'Created', 'Updated', 'Removed', 'Renamed',
    'OwnerModified', 'AttributeModified', 'MovedFrom', 'MovedTo', 'IsFile',
    'IsDir', 'IsSymLink', 'Link', 'Overflow'
)

fsw_monitor_type = create_enum('system_default', 'fsevents', 'kqueue', 'inotify', 'windows', 'poll', 'fen')

local events_array_wrapper = {}

function events_array_wrapper.new(events_array, event_num)
    return setmetatable({
        events = events_array,
        n = event_num,
    }, events_array_wrapper)
end

function events_array_wrapper:__index(index)
    if type(index) == 'number' and index >= 1 and index <= self.n then
        return self.events[index - 1]
    end
    return events_array_wrapper[index]
end

function events_array_wrapper.pack_flags(flags_array, flags_num)
    local result = {}
    for i = 0, flags_num - 1 do
        local name = fsw_event_flag[tonumber(flags_array[i])]
        result[name] = true
        result[i + 1] = name
    end
    return result
end

function events_array_wrapper:iter()
    return coroutine.wrap(function()
        for i = 0, self.n - 1 do
            local event = self.events[i]
            coroutine.yield(ffi.string(event.path), event.evt_time, events_array_wrapper.pack_flags(event.flags, event.flags_num))
        end
    end)
end

-- @warning LuaJIT without Lua 5.2 compatibility will not call this method
function events_array_wrapper:__len()
    return self.n
end

local function wrap_lua_callback(callback)
    return function(events, event_num, data)
        return callback(events_array_wrapper.new(events, event_num), event_num)
    end
end

local function FSW_STATUS_to_lua_returns(status)
    if status == FSW_STATUS.OK then
        return true
    else
        return false, FSW_STATUS[status]
    end
end

local function wrap_FSW_STATUS_returns(f)
    return function(...)
        local status = f(...)
        return FSW_STATUS_to_lua_returns(status)
    end
end

local FSW = {
    STATUS = FSW_STATUS,
    event_flag = fsw_event_flag,
    monitor_type = fsw_monitor_type,

    init_session = function(type)
        type = type or fsw_monitor_type.system_default
        return libfswatch.fsw_init_session(type)
    end,
    add_path = wrap_FSW_STATUS_returns(libfswatch.fsw_add_path),
    add_property = wrap_FSW_STATUS_returns(libfswatch.fsw_add_property),
    set_allow_overflow = wrap_FSW_STATUS_returns(libfswatch.fsw_set_allow_overflow),
    set_callback = function(handle, callback)
        local status = libfswatch.fsw_set_callback(handle, wrap_lua_callback(callback), nil)
        return FSW_STATUS_to_lua_returns(status)
    end,
    set_latency = wrap_FSW_STATUS_returns(libfswatch.fsw_set_latency),
    set_recursive = wrap_FSW_STATUS_returns(libfswatch.fsw_set_recursive),
    set_directory_only = wrap_FSW_STATUS_returns(libfswatch.fsw_set_directory_only),
    set_follow_symlinks = wrap_FSW_STATUS_returns(libfswatch.fsw_set_follow_symlinks),
    add_event_type_filter = wrap_FSW_STATUS_returns(libfswatch.fsw_add_event_type_filter),
    add_filter = wrap_FSW_STATUS_returns(libfswatch.fsw_add_filter),
    start_monitor = wrap_FSW_STATUS_returns(libfswatch.fsw_start_monitor),
    stop_monitor = wrap_FSW_STATUS_returns(libfswatch.fsw_stop_monitor),
    is_running = libfswatch.fsw_is_running,
    destroy_session = wrap_FSW_STATUS_returns(libfswatch.fsw_destroy_session),
    last_error = libfswatch.fsw_last_error,
    is_verbose = libfswatch.fsw_is_verbose,
    set_verbose = libfswatch.fsw_set_verbose,
}

local methods = {
    add_path = FSW.add_path,
    add_property = FSW.add_property,
    set_allow_overflow = FSW.set_allow_overflow,
    set_callback = FSW.set_callback,
    set_latency = FSW.set_latency,
    set_recursive = FSW.set_recursive,
    set_directory_only = FSW.set_directory_only,
    set_follow_symlinks = FSW.set_follow_symlinks,
    add_event_type_filter = FSW.add_event_type_filter,
    add_filter = FSW.add_filter,
    start_monitor = FSW.start_monitor,
    stop_monitor = FSW.stop_monitor,
    is_running = FSW.is_running,
}

local FSW_HANDLE_mt = {
    __index = methods,
    __gc = FSW.destroy_session,
}

ffi.metatype('struct FSW_SESSION', FSW_HANDLE_mt)

return FSW