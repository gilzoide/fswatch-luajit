local ffi = require 'ffi'
local bit = require 'bit'

ffi.cdef[[
// TODO: check compatibility and possibly define time_t conditionally based on OS
typedef int32_t time_t;

static const int FSW_OK =                            0;         /**< The call was successful. */
static const int FSW_ERR_UNKNOWN_ERROR =             (1 << 0);  /**< An unknown error has occurred. */
static const int FSW_ERR_SESSION_UNKNOWN =           (1 << 1);  /**< The session specified by the handle is unknown. */
static const int FSW_ERR_MONITOR_ALREADY_EXISTS =    (1 << 2);  /**< The session already contains a monitor. */
static const int FSW_ERR_MEMORY =                    (1 << 3);  /**< An error occurred while invoking a memory management routine. */
static const int FSW_ERR_UNKNOWN_MONITOR_TYPE =      (1 << 4);  /**< The specified monitor type does not exist. */
static const int FSW_ERR_CALLBACK_NOT_SET =          (1 << 5);  /**< The callback has not been set. */
static const int FSW_ERR_PATHS_NOT_SET =             (1 << 6);  /**< The paths to watch have not been set. */
static const int FSW_ERR_MISSING_CONTEXT =           (1 << 7);  /**< The callback context has not been set. */
static const int FSW_ERR_INVALID_PATH =              (1 << 8);  /**< The path is invalid. */
static const int FSW_ERR_INVALID_CALLBACK =          (1 << 9);  /**< The callback is invalid. */
static const int FSW_ERR_INVALID_LATENCY =           (1 << 10); /**< The latency is invalid. */
static const int FSW_ERR_INVALID_REGEX =             (1 << 11); /**< The regular expression is invalid. */
static const int FSW_ERR_MONITOR_ALREADY_RUNNING =   (1 << 12); /**< A monitor is already running in the specified session. */
static const int FSW_ERR_UNKNOWN_VALUE =             (1 << 13); /**< The value is unknown. */
static const int FSW_ERR_INVALID_PROPERTY =          (1 << 14); /**< The property is invalid. */

struct FSW_SESSION;
typedef struct FSW_SESSION *FSW_HANDLE;
typedef int FSW_STATUS;

enum fsw_event_flag {
    NoOp = 0,                     /**< No event has occurred. */
    PlatformSpecific = (1 << 0),  /**< Platform-specific placeholder for event type that cannot currently be mapped. */
    Created = (1 << 1),           /**< An object was created. */
    Updated = (1 << 2),           /**< An object was updated. */
    Removed = (1 << 3),           /**< An object was removed. */
    Renamed = (1 << 4),           /**< An object was renamed. */
    OwnerModified = (1 << 5),     /**< The owner of an object was modified. */
    AttributeModified = (1 << 6), /**< The attributes of an object were modified. */
    MovedFrom = (1 << 7),         /**< An object was moved from this location. */
    MovedTo = (1 << 8),           /**< An object was moved to this location. */
    IsFile = (1 << 9),            /**< The object is a file. */
    IsDir = (1 << 10),            /**< The object is a directory. */
    IsSymLink = (1 << 11),        /**< The object is a symbolic link. */
    Link = (1 << 12),             /**< The link count of an object has changed. */
    Overflow = (1 << 13)          /**< The event queue has overflowed. */
};
extern enum fsw_event_flag FSW_ALL_EVENT_FLAGS[15];

FSW_STATUS fsw_get_event_flag_by_name(const char *name, enum fsw_event_flag *flag);
const char *fsw_get_event_flag_name(const enum fsw_event_flag flag);
typedef struct fsw_cevent {
    const char * path;
    time_t evt_time;
    enum fsw_event_flag * flags;
    unsigned int flags_num;
} fsw_cevent;

typedef void (*FSW_CEVENT_CALLBACK)(fsw_cevent const *const events, const unsigned int event_num, void *data);

enum fsw_filter_type {
    filter_include,
    filter_exclude
};

typedef struct fsw_cmonitor_filter {
    const char * text;
    enum fsw_filter_type type;
    bool case_sensitive;
    bool extended;
} fsw_cmonitor_filter;

typedef struct fsw_event_type_filter {
    enum fsw_event_flag flag;
} fsw_event_type_filter;

enum fsw_monitor_type {
    system_default_monitor_type = 0, /**< System default monitor. */
    fsevents_monitor_type,           /**< OS X FSEvents monitor. */
    kqueue_monitor_type,             /**< BSD `kqueue` monitor. */
    inotify_monitor_type,            /**< Linux `inotify` monitor. */
    windows_monitor_type,            /**< Windows monitor. */
    poll_monitor_type,               /**< `stat()`-based poll monitor. */
    fen_monitor_type                 /**< Solaris/Illumos monitor. */
};

FSW_STATUS fsw_init_library();
FSW_HANDLE fsw_init_session(const enum fsw_monitor_type type);
FSW_STATUS fsw_add_path(const FSW_HANDLE handle, const char * path);
FSW_STATUS fsw_add_property(const FSW_HANDLE handle, const char * name, const char * value);
FSW_STATUS fsw_set_allow_overflow(const FSW_HANDLE handle, const bool allow_overflow);
FSW_STATUS fsw_set_callback(const FSW_HANDLE handle, const FSW_CEVENT_CALLBACK callback, void * data);
FSW_STATUS fsw_set_latency(const FSW_HANDLE handle, const double latency);
FSW_STATUS fsw_set_recursive(const FSW_HANDLE handle, const bool recursive);
FSW_STATUS fsw_set_directory_only(const FSW_HANDLE handle, const bool directory_only);
FSW_STATUS fsw_set_follow_symlinks(const FSW_HANDLE handle, const bool follow_symlinks);
FSW_STATUS fsw_add_event_type_filter(const FSW_HANDLE handle, const fsw_event_type_filter event_type);
FSW_STATUS fsw_add_filter(const FSW_HANDLE handle, const fsw_cmonitor_filter filter);
FSW_STATUS fsw_start_monitor(const FSW_HANDLE handle);
FSW_STATUS fsw_stop_monitor(const FSW_HANDLE handle);
bool       fsw_is_running(const FSW_HANDLE handle);
FSW_STATUS fsw_destroy_session(const FSW_HANDLE handle);
FSW_STATUS fsw_last_error();
bool       fsw_is_verbose();
void       fsw_set_verbose(bool verbose);
]]

local libfswatch = ffi.load('fswatch')
do
    local status = libfswatch.fsw_init_library()
    assert(status == libfswatch.FSW_OK, "fsw_init_library() failed with error " .. status)
end

return libfswatch