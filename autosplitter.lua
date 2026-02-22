obs = obslua

local enabled = true
local interval = 600
local split_timer = nil
local splitting = false
local event_registered = false

function script_description()
    return "Automatically splits recordings at a configurable time interval."
end

function script_author()
    return "JuacOHI"
end

function script_version()
    return "1.0"
end

local function getInterval(settings)
    local seconds = obs.obs_data_get_int(settings, "interval_s")
    local minutes = obs.obs_data_get_int(settings, "interval_m")
    local hours = obs.obs_data_get_int(settings, "interval_h")
    return hours, minutes, seconds
end

local function setInterval(settings, hours, minutes, seconds)
    obs.obs_data_set_int(settings, "interval_s", seconds)
    obs.obs_data_set_int(settings, "interval_m", minutes)
    obs.obs_data_set_int(settings, "interval_h", hours)
end

local function toSeconds(hours, minutes, seconds)
    return seconds + (minutes + hours * 60) * 60
end

local function fromSeconds(interval)
    local seconds = interval % 60
    local minutes = math.floor(interval / 60) % 60
    local hours = math.floor(interval / 3600)
    return hours, minutes, seconds
end

local function cancel_split_timer()
    if split_timer then
        obs.timer_remove(split_timer)
        split_timer = nil
    end
end

local function start_split_timer()
    cancel_split_timer()
    split_timer = function()
        if not enabled then
            cancel_split_timer()
            return
        end
        if obs.obs_frontend_recording_active() and not obs.obs_frontend_recording_paused() then
            splitting = true
            obs.obs_frontend_recording_stop()
        end
    end
    obs.timer_add(split_timer, interval * 1000)
end

local function on_event(event)
    if not enabled then
        return
    end

    if event == obs.OBS_FRONTEND_EVENT_RECORDING_STARTED then
        if splitting then
            splitting = false
        end
        start_split_timer()
    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_STOPPED then
        cancel_split_timer()
        if splitting then
            local function restart()
                obs.timer_remove(restart)
                splitting = false
                obs.obs_frontend_recording_start()
            end
            obs.timer_add(restart, 100)
        end
    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_PAUSED then
        cancel_split_timer()
    elseif event == obs.OBS_FRONTEND_EVENT_RECORDING_UNPAUSED then
        start_split_timer()
    end
end

function script_update(settings)
    enabled = obs.obs_data_get_bool(settings, "enabled")
    interval = toSeconds(getInterval(settings))
    if interval <= 0 then
        interval = 1
    end

    cancel_split_timer()

    if enabled and obs.obs_frontend_recording_active() and not obs.obs_frontend_recording_paused() then
        start_split_timer()
    end
end

function script_defaults(settings)
    obs.obs_data_set_default_bool(settings, "enabled", enabled)

    local hours, minutes, seconds = fromSeconds(interval)
    obs.obs_data_set_default_int(settings, "interval_s", seconds)
    obs.obs_data_set_default_int(settings, "interval_m", minutes)
    obs.obs_data_set_default_int(settings, "interval_h", hours)
end

function script_properties()
    local props = obs.obs_properties_create()

    obs.obs_properties_add_bool(props, "enabled", "Enabled")
    local prop_interval_s = obs.obs_properties_add_int(props, "interval_s", "Seconds", -1, 60, 1)
    local prop_interval_m = obs.obs_properties_add_int(props, "interval_m", "Minutes", -1, 60, 1)
    local prop_interval_h = obs.obs_properties_add_int(props, "interval_h", "Hours", 0, 240, 1)

    local function validate(props, prop, settings)
        local hours, minutes, seconds = getInterval(settings)
        local iv = toSeconds(hours, minutes, seconds)
        if iv <= 0 then
            iv = 1
        end
        local newHours, newMinutes, newSeconds = fromSeconds(iv)

        if hours == newHours and
                minutes == newMinutes and
                seconds == newSeconds then
            return false
        else
            setInterval(settings, newHours, newMinutes, newSeconds)
            return true
        end
    end

    obs.obs_property_set_modified_callback(prop_interval_s, validate)
    obs.obs_property_set_modified_callback(prop_interval_m, validate)
    obs.obs_property_set_modified_callback(prop_interval_h, validate)

    return props
end

function script_load(settings)
    obs.obs_frontend_add_event_callback(on_event)
    event_registered = true
end

function script_unload()
    cancel_split_timer()
    splitting = false
    if event_registered then
        obs.obs_frontend_remove_event_callback(on_event)
        event_registered = false
    end
end
