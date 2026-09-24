-- ============================================================
-- AFK CAMERA
-- Phase 6 - Menu and crash fixes
-- MADE BY DEBARGHYA BASAK
-- ============================================================


-- ============================================================
-- VERSION
-- ============================================================
--
-- Bump this when releasing. The update check compares it with
-- the latest version on afkcamera.vercel.app, and it is shown
-- in the settings window and written to the log.
--
-- Format is one decimal: "1.0", "1.1", "1.2" ... After "1.9"
-- go to "2.0". The part after the dot is read as a whole
-- number, so "1.10" would count as newer than "1.9", not as
-- the same as "1.1".

local AFK_CAMERA_VERSION = "1.3"


-- ============================================================
-- SETTINGS
-- ============================================================

-- ============================================================
-- DEFAULT USER SETTINGS
-- ============================================================
--
-- Change these values to define what "Restore Defaults" uses.
-- These are intentionally kept separate from the live settings.
--
-- Examples:
--   true  = AFK Camera starts enabled
--   false = AFK Camera starts disabled
--
-- AFK timeout is in seconds.

local DEFAULT_AFK_ENABLED = true
local DEFAULT_AFK_TIMEOUT = 30.0

-- Debug HUD (the on-screen status text drawn every frame).
--   true  = shown
--   false = hidden
local DEFAULT_AFK_DEBUG_HUD = false

-- Cockpit head movement, as a percentage of the built-in
-- motion. 100 is the tuned default.
--
--   size  = how far the head moves, and how much idle life
--           (breathing, sway, tremor) it carries. Lower is
--           more subtle.
--   speed = how quickly it travels between looks. Lower is
--           more relaxed. Dwell times are not affected.
local DEFAULT_AFK_HEAD_SIZE = 100.0
local DEFAULT_AFK_HEAD_SPEED = 100.0

-- How AFK starts.
--   true  = automatic, when the idle timer runs out
--   false = manual only, when the bound key/button is pressed
local DEFAULT_AFK_AUTO_ENTRY = true

-- Mouse movement (cursor moving, no button) counts as activity.
--   true  = moving the mouse resets the timer / ends AFK
--   false = only clicks, wheel and the mouse-yoke modes count
local DEFAULT_AFK_MOUSE_MOVE_RETURN = false

-- Joystick dead zone, in percent of full axis travel. Axis
-- changes smaller than this between two frames are ignored, so
-- the idle jitter of cheap sticks does not end AFK. Raise it if
-- the HUD shows "Joystick ..." activity while nothing is touched.
local DEFAULT_AFK_JOYSTICK_DEADZONE = 1.0


local AFK_TIMEOUT = DEFAULT_AFK_TIMEOUT


-- ------------------------------------------------------------
-- USER SETTINGS / PERSISTENCE
-- ------------------------------------------------------------
--
-- Settings are stored next to this Lua script so they survive
-- X-Plane/FlyWithLua reloads. The UI changes the live value
-- immediately; "Save Settings" writes it to disk.
--
-- File:
--   AFKCamera_settings.ini

local AFK_SETTINGS_FILE =
    SCRIPT_DIRECTORY
    .. "/AFKCamera_settings.ini"

local afk_enabled = true

local afk_debug_hud_visible = DEFAULT_AFK_DEBUG_HUD

local afk_auto_entry = DEFAULT_AFK_AUTO_ENTRY

local afk_head_size = DEFAULT_AFK_HEAD_SIZE
local afk_head_speed = DEFAULT_AFK_HEAD_SPEED

local AFK_HEAD_SIZE_MIN = 25.0
local AFK_HEAD_SIZE_MAX = 150.0

local AFK_HEAD_SPEED_MIN = 50.0
local AFK_HEAD_SPEED_MAX = 150.0

local afk_mouse_move_return = DEFAULT_AFK_MOUSE_MOVE_RETURN

-- Percent. Divide by 100 before comparing with raw axis values.
local afk_joystick_deadzone = DEFAULT_AFK_JOYSTICK_DEADZONE

local AFK_TIMEOUT_MIN = 3.0
local AFK_TIMEOUT_MAX = 300.0

local AFK_JOYSTICK_DEADZONE_MIN = 0.1
local AFK_JOYSTICK_DEADZONE_MAX = 25.0


function clamp_afk_timeout(value)

    local v =
        tonumber(value)

    if v == nil then
        return 3.0
    end

    if v < AFK_TIMEOUT_MIN then
        v = AFK_TIMEOUT_MIN
    end

    if v > AFK_TIMEOUT_MAX then
        v = AFK_TIMEOUT_MAX
    end

    return v

end


function clamp_afk_percent(value, min_value, max_value, fallback)

    local v =
        tonumber(value)

    if v == nil then
        return fallback
    end

    if v < min_value then
        v = min_value
    end

    if v > max_value then
        v = max_value
    end

    return v

end


function clamp_afk_joystick_deadzone(value)

    local v =
        tonumber(value)

    if v == nil then
        return DEFAULT_AFK_JOYSTICK_DEADZONE
    end

    if v < AFK_JOYSTICK_DEADZONE_MIN then
        v = AFK_JOYSTICK_DEADZONE_MIN
    end

    if v > AFK_JOYSTICK_DEADZONE_MAX then
        v = AFK_JOYSTICK_DEADZONE_MAX
    end

    return v

end


function load_afk_settings()

    local file =
        io.open(
            AFK_SETTINGS_FILE,
            "r"
        )

    if not file then
        return
    end


    for line in file:lines() do

        local key, value =
            line:match(
                "^%s*([^=]+)%s*=%s*(.-)%s*$"
            )

        if key and value then

            key =
                key:lower()

            if key == "enabled" then

                local normalized =
                    value:lower()

                afk_enabled =
                    normalized == "1"
                    or normalized == "true"
                    or normalized == "yes"

            elseif key == "timeout" then

                AFK_TIMEOUT =
                    clamp_afk_timeout(
                        value
                    )

            elseif key == "debug_hud" then

                local normalized =
                    value:lower()

                afk_debug_hud_visible =
                    normalized == "1"
                    or normalized == "true"
                    or normalized == "yes"

            elseif key == "auto_entry" then

                local normalized =
                    value:lower()

                afk_auto_entry =
                    normalized == "1"
                    or normalized == "true"
                    or normalized == "yes"

            elseif key == "head_size" then

                afk_head_size =
                    clamp_afk_percent(
                        value,
                        AFK_HEAD_SIZE_MIN,
                        AFK_HEAD_SIZE_MAX,
                        DEFAULT_AFK_HEAD_SIZE
                    )

            elseif key == "head_speed" then

                afk_head_speed =
                    clamp_afk_percent(
                        value,
                        AFK_HEAD_SPEED_MIN,
                        AFK_HEAD_SPEED_MAX,
                        DEFAULT_AFK_HEAD_SPEED
                    )

            elseif key == "mouse_move" then

                local normalized =
                    value:lower()

                afk_mouse_move_return =
                    normalized == "1"
                    or normalized == "true"
                    or normalized == "yes"

            elseif key == "joystick_deadzone" then

                afk_joystick_deadzone =
                    clamp_afk_joystick_deadzone(
                        value
                    )

            end

        end

    end

    file:close()

end


function restore_afk_defaults()

    afk_enabled =
        DEFAULT_AFK_ENABLED

    AFK_TIMEOUT =
        clamp_afk_timeout(
            DEFAULT_AFK_TIMEOUT
        )

    afk_debug_hud_visible =
        DEFAULT_AFK_DEBUG_HUD

    afk_auto_entry =
        DEFAULT_AFK_AUTO_ENTRY

    afk_head_size =
        DEFAULT_AFK_HEAD_SIZE

    afk_head_speed =
        DEFAULT_AFK_HEAD_SPEED

    afk_mouse_move_return =
        DEFAULT_AFK_MOUSE_MOVE_RETURN

    afk_joystick_deadzone =
        clamp_afk_joystick_deadzone(
            DEFAULT_AFK_JOYSTICK_DEADZONE
        )

    idle_time =
        0.0

    -- Restoring defaults while AFK should immediately leave AFK
    -- so the user gets a clean, predictable state.
    if afk_active then

        afk_active =
            false

        afk_status =
            "ACTIVE"

        current_shot =
            "NONE"

        stop_afk_camera()

        last_activity =
            "Defaults restored"

    end

    logMsg(
        "AFK CAMERA: DEFAULTS RESTORED | "
        .. "Enabled="
        .. tostring(
            afk_enabled
        )
        .. " | Timeout="
        .. string.format(
            "%.0f",
            AFK_TIMEOUT
        )
        .. " s"
        .. " | DebugHUD="
        .. tostring(
            afk_debug_hud_visible
        )
        .. " | AutoEntry="
        .. tostring(
            afk_auto_entry
        )
        .. " | Head="
        .. string.format(
            "%.0f",
            afk_head_size
        )
        .. "/"
        .. string.format(
            "%.0f",
            afk_head_speed
        )
        .. " %"
        .. " | MouseMove="
        .. tostring(
            afk_mouse_move_return
        )
        .. " | JoystickDeadzone="
        .. string.format(
            "%.1f",
            afk_joystick_deadzone
        )
        .. " %"
    )

end


function save_afk_settings()

    local file =
        io.open(
            AFK_SETTINGS_FILE,
            "w"
        )

    if not file then

        logMsg(
            "AFK CAMERA: ERROR - "
            .. "Could not save settings to "
            .. AFK_SETTINGS_FILE
        )

        return false

    end


    file:write(
        "enabled=",
        afk_enabled and "1" or "0",
        "\n"
    )

    file:write(
        "timeout=",
        string.format(
            "%.0f",
            AFK_TIMEOUT
        ),
        "\n"
    )

    file:write(
        "debug_hud=",
        afk_debug_hud_visible and "1" or "0",
        "\n"
    )

    file:write(
        "auto_entry=",
        afk_auto_entry and "1" or "0",
        "\n"
    )

    file:write(
        "head_size=",
        string.format(
            "%.0f",
            afk_head_size
        ),
        "\n"
    )

    file:write(
        "head_speed=",
        string.format(
            "%.0f",
            afk_head_speed
        ),
        "\n"
    )

    file:write(
        "mouse_move=",
        afk_mouse_move_return and "1" or "0",
        "\n"
    )

    file:write(
        "joystick_deadzone=",
        string.format(
            "%.1f",
            afk_joystick_deadzone
        ),
        "\n"
    )

    file:close()


    logMsg(
        "AFK CAMERA: SETTINGS SAVED | "
        .. "Enabled="
        .. tostring(afk_enabled)
        .. " | Timeout="
        .. string.format(
            "%.0f",
            AFK_TIMEOUT
        )
        .. " s"
        .. " | DebugHUD="
        .. tostring(
            afk_debug_hud_visible
        )
        .. " | AutoEntry="
        .. tostring(
            afk_auto_entry
        )
        .. " | Head="
        .. string.format(
            "%.0f",
            afk_head_size
        )
        .. "/"
        .. string.format(
            "%.0f",
            afk_head_speed
        )
        .. " %"
        .. " | MouseMove="
        .. tostring(
            afk_mouse_move_return
        )
        .. " | JoystickDeadzone="
        .. string.format(
            "%.1f",
            afk_joystick_deadzone
        )
        .. " %"
    )

    return true

end


load_afk_settings()

-- Camera ownership policy:
-- NORMAL FLIGHT: AFK Camera NEVER controls the camera.
--                 XPRealistic / X-Plane remains in charge.
-- AFK MODE:      AFK Camera takes camera control.
-- EXIT AFK:      AFK Camera explicitly releases control.
--
-- X-Plane SDK camera-control duration:
--   1 = until view changes
--   2 = forever / until another plugin forcibly takes control
--
-- The exterior camera uses "until view changes" so X-Plane can
-- safely revoke camera ownership as soon as the user selects
-- another view.
local AFK_CAMERA_CONTROL_DURATION = 1

-- AFK exterior cinematic camera settings.
--
-- Angles are relative to the aircraft heading:
--   0    = rear
--   +90  = left side
--   180  = nose
--   -90  = right side
--
-- Each shot slowly moves toward its target position, holds,
-- then cuts instantly to the next shot.
local AFK_EXTERNAL_ZOOM = 1.0
-- Height of the aircraft-attached point the camera falls back
-- to when a shot does not name its own subject.
local AFK_EXTERNAL_TARGET_HEIGHT = 1.5

-- Aircraft-size adaptive exterior camera.
--
-- X-Plane exposes this value as the aircraft's shadow/viewing-distance
-- size. Every coordinate below is authored against a reference
-- aircraft of this size and scaled to whatever is loaded, so a
-- close-up of the gear sits proportionally close on a light
-- single and on an airliner alike.
local AFK_EXTERNAL_REFERENCE_SIZE = 10.0

-- Prevent unusual aircraft/add-ons with extreme size values from
-- producing unusably close or distant cinematic cameras.
local AFK_EXTERNAL_MIN_SCALE = 0.70
local AFK_EXTERNAL_MAX_SCALE = 4.00

-- Every exterior move runs for exactly this long and travels
-- at a constant speed from beginning to end. No easing, no
-- length-derived timing: each shot gets the same ten seconds
-- and covers its path at one steady rate.
local AFK_EXTERIOR_SHOT_DURATION = 10.0

-- How finely a curved path is measured to hold that constant
-- speed. See the arc-length table in external_prepare_shot.
local AFK_EXTERIOR_ARC_SAMPLES = 24

-- ============================================================
-- CINEMATIC CAMERA MOVE
-- ============================================================
--
-- Camera float. Even a crane or drone shot is never perfectly
-- rigid, and that tiny drift is most of what separates a camera
-- move from a slideshow. These are metres and degrees at the
-- reference aircraft size, scaled per shot by its own "float".
local AFK_EXTERIOR_FLOAT_POS = 0.075
local AFK_EXTERIOR_FLOAT_ANGLE = 0.11

-- Closest the camera may get to the ground, in metres at the
-- reference size.
--
-- Shots are authored relative to the aircraft, which says
-- nothing about where the ground is. A low pass framed for
-- cruise puts the camera underground on a taxiway, and a shot
-- deliberately under the belly does it every time. Clamping
-- against the real surface height keeps every shot usable at
-- any altitude: in the air nothing is touched, and near the
-- ground the same move flattens into a low skimming pass
-- instead of burying itself in the tarmac.
local AFK_EXTERIOR_GROUND_CLEARANCE = 0.60

-- There is deliberately no easing here. Every move runs at one
-- steady rate, so the time fraction is used directly. If soft
-- starts and stops are ever wanted again, they belong on the
-- progress value in the camera callback, not on the arc-length
-- mapping below, which exists precisely to remove speed change.


-- ============================================================
-- SHOT FORMAT
-- ============================================================
--
-- Coordinates are aircraft-relative, in metres at the reference
-- size above:  X right, Y up, Z toward the tail.
-- So the nose is negative Z and the tail is positive Z.
--
--   name     shown on the debug HUD
--   from     where the camera starts
--   to       where it ends
--   look     the point on the aircraft it frames
--   look_to  optional second point. Given one, the framing
--            slides from "look" to "look_to" during the move,
--            which is what makes a tracking pan rather than a
--            camera staring at one spot
--   zoom     optional {start, end}. A slow push in is the
--            cheapest cinematic trick there is
--   roll     optional dutch angle in degrees
--   float    optional handheld multiplier, 0 locks the camera
--            off entirely
--   via      optional curve control point. Given one, the
--            camera flies an arc through it instead of a
--            straight line
--
-- Duration is not a per-shot setting: every move takes
-- AFK_EXTERIOR_SHOT_DURATION seconds at a constant speed.
--
-- Anything omitted falls back to a sensible default, so a new
-- shot can be as short as name/from/to.


-- ============================================================
-- PARKED SHOTS
-- ============================================================
--
-- Used when the aircraft is stopped on the ground. Close, slow
-- and detail-led: the sort of coverage a walkaround gets.
--
-- Part positions cannot be read from X-Plane in any way that
-- holds across every aircraft, so these frame regions of the
-- airframe proportionally rather than tracking named parts.
-- On an unusual layout a shot may frame near a part rather
-- than dead on it; the coordinates are here to be nudged.
--
-- FRAMING DISTANCE
--
-- Each shot is built from the point it frames ("look") plus a
-- direction and a distance, rather than by placing the camera
-- and the subject independently. Authored the loose way the
-- two drift together and the camera ends up almost touching
-- the aircraft.
--
-- Closest approach is about 60% of the aircraft's size, out to
-- 150% for the establishing shots, so a detail shot fills the
-- frame with the gear or the window and still shows enough of
-- the airframe around it to read. Lens pushes are kept to 1.08
-- at most for the same reason: zoom tightens the framing on
-- top of the distance.

local AFK_EXTERIOR_PARKED_SHOTS = {

    {
        name = "NOSE CONE",
        from = { 5.48, 3.09, -12.47 },
        to = { 2.86, 3.11, -10.99 },
        look = { 0.00, 1.30, -4.30 },
        zoom = { 1.00, 1.06 },
    },

    {
        name = "NOSE LOW HERO",
        from = { 5.03, 0.69, -13.53 },
        to = { 2.28, 0.68, -11.92 },
        look = { 0.00, 1.70, -3.80 },
        zoom = { 1.02, 1.08 },
        roll = -1.2,
    },

    {
        name = "SPINNER AND NOSE",
        from = { 1.33, 2.35, -13.56 },
        to = { 0.42, 1.82, -11.17 },
        look = { 0.00, 1.40, -4.20 },
        zoom = { 1.00, 1.08 },
    },

    {
        name = "LEFT MAIN GEAR",
        from = { -8.12, 3.78, -3.73 },
        to = { -7.73, 2.37, -1.27 },
        look = { -2.00, 0.55, 1.20 },
        float = 0.7,
    },

    {
        name = "RIGHT MAIN GEAR",
        from = { 8.12, 3.78, -3.73 },
        to = { 7.73, 2.37, -1.27 },
        look = { 2.00, 0.55, 1.20 },
        float = 0.7,
    },

    {
        name = "NOSE GEAR",
        from = { 4.64, 3.65, -9.08 },
        to = { 2.17, 2.26, -8.70 },
        look = { 0.00, 0.45, -3.40 },
        float = 0.7,
    },

    {
        name = "LEFT WING TIP",
        from = { -10.70, 4.24, 7.81 },
        to = { -10.37, 2.94, 5.07 },
        look = { -5.20, 1.40, 0.60 },
        zoom = { 1.00, 1.06 },
    },

    {
        name = "RIGHT WING TIP",
        from = { 10.70, 4.24, 7.81 },
        to = { 10.37, 2.94, 5.07 },
        look = { 5.20, 1.40, 0.60 },
        zoom = { 1.00, 1.06 },
    },

    {
        name = "LEFT WING ROOT",
        from = { -9.41, 5.60, -6.11 },
        to = { -8.72, 3.56, -3.74 },
        look = { -2.40, 1.60, -0.20 },
    },

    {
        name = "ENGINE INTAKE",
        from = { 9.43, 3.90, -4.76 },
        to = { 8.41, 2.64, -2.58 },
        look = { 2.30, 1.55, 0.20 },
        zoom = { 1.00, 1.08 },
    },

    {
        name = "PILOT WINDOW",
        from = { -7.13, 5.26, -7.54 },
        to = { -6.37, 3.89, -5.69 },
        look = { -0.85, 2.20, -2.70 },
        zoom = { 1.00, 1.08 },
        float = 0.8,
    },

    {
        name = "CABIN DOOR",
        from = { -9.05, 4.63, -3.56 },
        to = { -7.93, 3.29, -1.91 },
        look = { -1.50, 1.75, 0.40 },
    },

    {
        name = "UNDER WING",
        from = { -7.96, 0.64, 8.42 },
        to = { -7.68, 0.53, 5.96 },
        look = { -3.00, 1.70, 1.60 },
        float = 0.8,
    },

    {
        name = "FUSELAGE TRACK",
        from = { -9.00, 1.85, -6.00 },
        to = { -9.00, 1.85, 6.00 },
        look = { 0.00, 1.60, -3.60 },
        look_to = { 0.00, 1.60, 3.60 },
    },

    {
        name = "TAIL AND RUDDER",
        from = { -5.27, 6.25, 14.62 },
        to = { -2.54, 7.13, 12.60 },
        look = { 0.00, 3.40, 5.40 },
        zoom = { 1.00, 1.06 },
    },

    {
        name = "TAIL LOW ANGLE",
        from = { 4.75, 0.76, 14.38 },
        to = { 2.07, 1.01, 12.76 },
        look = { 0.00, 2.60, 5.20 },
        roll = 1.4,
    },

    {
        name = "WINGTIP TO FUSELAGE",
        from = { 13.97, 3.85, 3.29 },
        to = { 8.96, 4.37, -4.40 },
        look = { 1.60, 1.60, 0.00 },
    },

    {
        name = "REAR THREE QUARTER LOW",
        from = { -7.85, 0.95, 12.74 },
        to = { -5.27, 2.23, 11.46 },
        look = { 0.00, 1.60, 2.40 },
        roll = -1.0,
    },

    {
        name = "HIGH THREE QUARTER",
        from = { 10.21, 9.16, -11.83 },
        to = { 7.82, 6.53, -11.07 },
        look = { 0.00, 1.50, -0.60 },
        zoom = { 1.00, 1.06 },
    },

    {
        name = "WALKAROUND ARC",
        from = { -13.53, 5.23, -6.56 },
        to = { -13.75, 5.05, 6.10 },
        look = { 0.00, 1.60, -1.20 },
        look_to = { 0.00, 1.60, 1.20 },
        zoom = { 1.00, 1.04 },
    }

}


-- ============================================================
-- FLIGHT SHOTS
-- ============================================================
--
-- Used in the air, on the runway and while taxiing. These are
-- the original framings, now with the push-ins, dutch angles,
-- tracking pans and float that make a move read as a shot.

local AFK_EXTERIOR_FLIGHT_SHOTS = {

    {
        name = "RIGHT REAR CLOSE",
        from = { 19.99, 6.67, 17.13 },
        to = { 8.06, 5.48, 16.76 },
        via = { 14.32, 6.36, 18.41 },
        look = { 0.00, 1.50, 2.00 },
        look_to = { 0.00, 1.50, -1.00 },
        zoom = { 1.00, 1.08 }
    },
    {
        name = "LEFT NOSE CLOSE",
        from = { -18.18, 6.77, -0.16 },
        to = { -10.95, 4.83, -9.62 },
        via = { -15.38, 6.07, -5.87 },
        look = { 0.00, 1.50, 0.00 },
        look_to = { 0.00, 1.40, -3.00 },
        zoom = { 1.00, 1.08 },
        roll = { 0.0, -1.4 }
    },
    {
        name = "TOP NOSE DIAGONAL",
        from = { -7.59, 15.23, -13.49 },
        to = { 1.32, 11.01, -16.12 },
        via = { -3.08, 13.96, -15.96 },
        look = { 0.00, 1.20, -2.00 },
        zoom = { 1.00, 1.10 }
    },
    {
        name = "LOW SIDE SWEEP",
        from = { 20.28, 4.69, 3.84 },
        to = { 11.87, 5.23, -11.16 },
        via = { 18.51, 5.67, -5.33 },
        look = { 0.00, 1.60, 1.00 },
        look_to = { 0.00, 1.60, -2.00 },
        roll = { 0.0, 2.0 },
        float = 1.3
    },
    {
        name = "LEFT WING CLOSE",
        from = { -23.86, 7.42, -0.00 },
        to = { -13.65, 7.04, 7.22 },
        via = { -19.77, 7.64, 4.14 },
        look = { -6.00, 1.80, 1.00 },
        look_to = { 0.00, 1.60, 0.00 },
        zoom = { 1.00, 1.10 }
    },
    {
        name = "TAIL DIAGONAL",
        from = { -8.23, 6.92, 25.12 },
        to = { 2.16, 5.63, 17.65 },
        via = { -2.72, 6.57, 22.68 },
        look = { 0.00, 2.40, 5.00 },
        look_to = { 0.00, 1.60, 0.00 },
        zoom = { 1.00, 1.08 }
    },
    {
        name = "NOSE LOW TO HIGH",
        from = { 0.00, 4.19, -22.85 },
        to = { 0.00, 9.93, -18.54 },
        via = { 0.00, 7.46, -21.22 },
        look = { 0.00, 1.40, -3.00 },
        zoom = { 1.02, 1.12 }
    },
    {
        name = "HIGH RIGHT PASS",
        from = { 22.43, 15.34, 8.25 },
        to = { 15.05, 11.82, -7.69 },
        via = { 20.29, 14.70, -0.91 },
        look = { 0.00, 1.50, 1.00 },
        look_to = { 0.00, 1.50, -2.00 },
        roll = { -0.5, -2.2 },
        float = 1.2
    },
    {
        name = "RIGHT FRONT CLOSE",
        from = { 20.33, 5.23, -6.58 },
        to = { 11.75, 6.94, -15.06 },
        via = { 16.86, 6.56, -11.85 },
        look = { 0.00, 1.50, -1.00 },
        look_to = { 0.00, 1.40, -3.50 },
        zoom = { 1.00, 1.10 }
    },
    {
        name = "LOW LEFT DIAGONAL",
        from = { -19.64, 2.98, 2.63 },
        to = { -11.40, 4.71, -2.68 },
        via = { -16.08, 4.32, -0.74 },
        look = { 0.00, 1.60, 0.00 },
        roll = { 0.5, 2.2 },
        float = 1.2
    },
    {
        name = "OVERHEAD CLOSE",
        from = { 6.78, 21.94, 9.17 },
        to = { -1.25, 15.48, -3.96 },
        via = { 2.15, 20.58, 1.82 },
        look = { 0.00, 1.00, 2.00 },
        look_to = { 0.00, 1.00, -2.00 },
    },
    {
        name = "LEFT REAR CLOSE",
        from = { -19.30, 7.49, 17.86 },
        to = { -7.25, 4.31, 16.40 },
        via = { -13.44, 6.02, 18.67 },
        look = { 0.00, 1.50, 2.00 },
        look_to = { 0.00, 1.50, -1.00 },
        zoom = { 1.00, 1.08 }
    },
    {
        name = "WINGTIP CHASE",
        from = { -26.48, 4.64, 11.07 },
        to = { -17.02, 3.83, -1.13 },
        via = { -22.82, 4.37, 4.79 },
        look = { -8.00, 1.80, 2.00 },
        look_to = { 0.00, 1.50, -1.00 },
        zoom = { 1.00, 1.08 },
        float = 1.4
    },
    {
        name = "BELLY PASS",
        from = { 4.18, -14.31, 8.52 },
        to = { -0.08, -7.63, -5.88 },
        via = { 1.80, -13.09, -0.07 },
        look = { 0.00, 0.60, 2.00 },
        look_to = { 0.00, 0.60, -3.00 },
        roll = { -2.5, 0.5 },
        float = 1.3
    },
    {
        name = "LEAD AND LOOK BACK",
        from = { -6.45, 4.25, -25.45 },
        to = { 4.73, 3.09, -18.61 },
        via = { 0.11, 3.79, -23.59 },
        look = { 0.00, 1.60, -2.00 },
        zoom = { 1.00, 1.10 },
        float = 1.2
    },
    {
        name = "HIGH SLOW ORBIT",
        from = { 25.45, 12.74, 13.81 },
        to = { 5.86, 10.63, 24.75 },
        via = { 17.63, 13.40, 23.14 },
        look = { 0.00, 1.50, 0.00 },
        zoom = { 1.00, 1.06 },
    },
    {
        name = "LOW NOSE RISE",
        from = { -6.77, 2.09, -20.08 },
        to = { -3.26, 7.00, -14.10 },
        via = { -5.08, 4.79, -17.59 },
        look = { 0.00, 1.50, -3.00 },
        look_to = { 0.00, 1.50, 1.00 },
        zoom = { 1.02, 1.12 }
    },
    {
        name = "TAIL CHASE HIGH",
        from = { 5.62, 11.98, 27.02 },
        to = { -4.95, 6.46, 18.79 },
        via = { -0.21, 9.49, 24.28 },
        look = { 0.00, 2.20, 4.00 },
        look_to = { 0.00, 1.60, -1.00 },
        zoom = { 1.00, 1.10 }
    },

    -- Arc-led additions.

    {
        name = "LOW ORBIT LEFT",
        from = { -21.71, 3.66, -7.88 },
        to = { -18.27, 4.94, 10.57 },
        via = { -23.38, 4.82, 2.01 },
        look = { 0.00, 1.50, -1.00 },
        look_to = { 0.00, 1.50, 1.00 },
        roll = { 1.5, -1.5 },
        float = 1.2,
    },
    {
        name = "CRANE OVER WING",
        from = { 12.89, 6.32, 5.18 },
        to = { 7.24, 13.00, -3.91 },
        via = { 11.74, 11.14, 0.76 },
        look = { 0.00, 1.60, 1.00 },
        look_to = { 0.00, 1.40, -2.00 },
        zoom = { 1.00, 1.08 },
    },
    {
        name = "NOSE ARC TO PROFILE",
        from = { 8.22, 5.01, -19.48 },
        to = { 19.89, 5.94, -6.82 },
        via = { 16.19, 6.14, -15.55 },
        look = { 0.00, 1.50, -2.00 },
        look_to = { 0.00, 1.50, 0.00 },
        roll = { -1.0, 1.0 },
        float = 1.2,
    }

}


-- ------------------------------------------------------------
-- RANDOM NO-REPEAT SHOT BAG
-- ------------------------------------------------------------
--
-- Each cycle plays every shot in the active library exactly
-- once, in a random order, then reshuffles. The first shot of a
-- new cycle is forced to differ from the last of the previous
-- one. Switching between parked and flight coverage rebuilds
-- the bag from the other library.

local external_shot_bag = {}
local external_shot_bag_position = 0
local external_last_shot_index = nil

-- Which library the current bag was built from.
local external_bag_parked = nil

-- The library the running shot came from.
local external_current_library = AFK_EXTERIOR_FLIGHT_SHOTS

math.randomseed(os.time())


function external_active_library()

    if afk_exterior_parked then
        return AFK_EXTERIOR_PARKED_SHOTS
    end

    return AFK_EXTERIOR_FLIGHT_SHOTS

end


function shuffle_external_shot_bag(library)

    external_shot_bag = {}

    for i = 1, #library do
        external_shot_bag[i] = i
    end

    -- Fisher-Yates shuffle.
    for i = #external_shot_bag, 2, -1 do
        local j = math.random(i)

        external_shot_bag[i],
        external_shot_bag[j] =
            external_shot_bag[j],
            external_shot_bag[i]
    end

    -- Prevent an immediate repeat across cycle boundaries.
    if #external_shot_bag > 1
       and external_last_shot_index ~= nil
       and external_shot_bag[1] == external_last_shot_index then

        local swap_index =
            math.random(2, #external_shot_bag)

        external_shot_bag[1],
        external_shot_bag[swap_index] =
            external_shot_bag[swap_index],
            external_shot_bag[1]
    end

    external_shot_bag_position = 0
end


-- Returns the library to use and the index within it.
function get_next_external_shot()

    local parked_now =
        afk_exterior_parked and true or false

    local library =
        external_active_library()

    if external_bag_parked ~= parked_now
       or external_shot_bag_position >= #external_shot_bag
       or #external_shot_bag == 0 then

        -- A library change starts a fresh cycle, and the
        -- no-repeat guard does not carry across libraries.
        if external_bag_parked ~= parked_now then
            external_last_shot_index = nil
        end

        shuffle_external_shot_bag(library)

        external_bag_parked = parked_now
    end

    external_shot_bag_position =
        external_shot_bag_position + 1

    local shot_index =
        external_shot_bag[external_shot_bag_position]

    external_last_shot_index =
        shot_index

    return library, shot_index
end


local CAMERA_MOVEMENT_THRESHOLD = 0.01


-- ============================================================
-- STATE
-- ============================================================

local idle_time = 0.0

local afk_active = false

local last_update_time = os.clock()

local camera_status = "INITIALIZING"

local afk_status = "ACTIVE"

local last_activity = "None"

local director_mode = "NONE"

local current_shot = "NONE"

local mouse_input_detected = false


-- ------------------------------------------------------------
-- MANUAL TRIGGER INPUT GRACE
-- ------------------------------------------------------------
--
-- The control that starts AFK is itself input. A joystick
-- button bound to the trigger fires the command AND registers
-- as joystick activity, which would end AFK on the very next
-- frame. The same is true of a keyboard key or a mouse button.
--
-- So after a manual trigger, input is swallowed for a short
-- window instead of being treated as a wake-up. The window
-- extends while the control is still held, so holding the
-- button does not immediately cancel AFK, and it is hard
-- capped so a control left pressed cannot wedge AFK on.

local AFK_MANUAL_GRACE = 1.0
local AFK_MANUAL_GRACE_TAIL = 0.4
local AFK_MANUAL_GRACE_MAX = 5.0

local afk_input_grace_until = 0.0
local afk_input_grace_limit = 0.0

-- Set by the bound command, acted on by the frame loop. The
-- command fires from X-Plane's command dispatch, and entering
-- AFK takes camera ownership, so the request is recorded here
-- and carried out from the normal flight loop instead. This is
-- the same rule the exterior camera already follows when
-- X-Plane hands ownership back.
local afk_manual_request = false


-- ============================================================
-- COCKPIT HEAD REALISM
-- ============================================================
--
-- A real pilot's head does not glide between fixed angles on a
-- fixed timetable, which is what makes a simple eased
-- interpolation read as robotic. Four things are modelled here.
--
--   1. MUSCLE DYNAMICS
--      The head is pulled toward the target by a spring and
--      resisted by a damper instead of following a symmetric
--      ease curve. A turn starts quickly, decelerates as it
--      arrives and settles with a slight overshoot. Yaw and
--      pitch use different stiffness, so the two axes never
--      arrive in perfect lockstep.
--
--   2. IDLE LIFE
--      Breathing, slow postural sway and micro tremor, so the
--      head is never perfectly still during a hold.
--
--   3. COUPLING
--      The head tilts into a turn, and because the neck pivot
--      sits below and behind the eyes, looking around also
--      translates the eye point slightly.
--
--   4. WIND-UP
--      A brief counter-movement before a large turn, the way a
--      real head loads against the neck before moving.
--
-- Every value below is safe to tune. Set realism = false to get
-- the plain spring motion with no breathing, sway or tremor.

local COCKPIT_HEAD = {

    realism = true,

    -- Spring frequency in Hz and damping ratio. Higher
    -- frequency is snappier. Damping below 1.0 overshoots
    -- slightly and settles back, which is what a head does.
    spring_frequency = 0.55,
    spring_damping = 0.72,

    -- Neck pitch muscles are slower than yaw.
    pitch_spring_scale = 0.88,

    -- Most the neck will turn, in degrees per second.
    --
    -- A plain spring reaches its target in the same time no
    -- matter how far it has to go, so a wide look ends up
    -- whipping round far faster than a small one. Capping the
    -- rate means a longer look simply takes longer, which is
    -- how a real neck behaves, and it is what keeps the wide
    -- shoulder checks from feeling rushed.
    --
    -- Set to 0 for no limit.
    max_yaw_rate = 30.0,
    max_pitch_rate = 24.0,

    -- Counter-movement before a turn, as a fraction of the
    -- turn size. 0 disables it.
    windup = 0.07,

    -- Head tilt into a turn, degrees of roll per degree/second
    -- of yaw, and the most tilt allowed. Negate roll_coupling
    -- to tilt the other way.
    roll_coupling = 0.055,
    roll_coupling_max = 2.2,

    -- Neck pivot: the eyes sit this far above and forward of
    -- the point the head actually rotates about (metres).
    neck_up = 0.11,
    neck_forward = 0.05,

    -- Breathing: rate in Hz, vertical travel in metres, and
    -- the small pitch nod that goes with it in degrees.
    breath_rate = 0.23,
    breath_y = 0.0035,
    breath_pitch = 0.14,

    -- Slow postural sway, in degrees and metres.
    drift_psi = 0.45,
    drift_the = 0.32,
    drift_phi = 0.35,
    drift_pos = 0.0040,

    -- Micro tremor, in degrees.
    tremor = 0.030,

    -- Seconds for the idle-life layer to fade up from nothing
    -- when AFK begins. Without this the breathing, sway and
    -- tremor all switch on at full amplitude on a single frame,
    -- which reads as a jolt. 0 disables the fade.
    life_fade_in = 1.2

}


-- Spring state. These hold the "muscle" pose, before any of the
-- idle-life layers are added on top.
local cockpit_anim_psi = 0.0
local cockpit_anim_the = 0.0

local cockpit_anim_psi_velocity = 0.0
local cockpit_anim_the_velocity = 0.0

-- 0 at AFK entry, ramping to 1 over COCKPIT_HEAD.life_fade_in.
-- Scales every idle-life layer.
local cockpit_life_blend = 0.0


-- ------------------------------------------------------------
-- IDLE LIFE NOISE
-- ------------------------------------------------------------
--
-- Summing sine waves whose frequencies share no common multiple
-- gives smooth motion that never audibly repeats, at a fraction
-- of the cost of real noise. Phases are randomised at load, so
-- two sessions never drift identically.

local cockpit_noise_time = 0.0

local cockpit_noise_phase = {}

-- 1..18 drive the cockpit head, 19..36 the exterior float.
for i = 1, 36 do

    cockpit_noise_phase[i] =
        math.random()
        * math.pi
        * 2.0

end


local function cockpit_wave(t, f1, f2, f3, phase_index)

    return
        math.sin(
            t * f1
            + cockpit_noise_phase[phase_index]
        ) * 0.55
        + math.sin(
            t * f2
            + cockpit_noise_phase[phase_index + 1]
        ) * 0.31
        + math.sin(
            t * f3
            + cockpit_noise_phase[phase_index + 2]
        ) * 0.14

end


-- ============================================================
-- X-PLANE CAMERA FFI
-- ============================================================

local ffi = require("ffi")

ffi.cdef[[
typedef struct {
    float x;
    float y;
    float z;
    float pitch;
    float heading;
    float roll;
    float zoom;
} XPLMCameraPosition_t;

typedef int (*XPLMCameraControl_f)(
    XPLMCameraPosition_t *outCameraPosition,
    int inIsLosingControl,
    void *inRefcon
);

void XPLMControlCamera(
    int inHowLong,
    XPLMCameraControl_f inControlFunc,
    void *inRefcon
);

void XPLMDontControlCamera(void);

void XPLMReadCameraPosition(
    XPLMCameraPosition_t *outCameraPosition
);
]]

local XPLM = ffi.load("XPLM_64")

-- ============================================================
-- X-PLANE VIEW COMMANDS
-- ============================================================

ffi.cdef[[
typedef void *XPLMCommandRef;

typedef int XPLMCommandPhase;

typedef int (*XPLMCommandCallback_f)(
    XPLMCommandRef inCommand,
    XPLMCommandPhase inPhase,
    void *inRefcon
);

XPLMCommandRef XPLMFindCommand(
    const char *inName
);

void XPLMCommandOnce(
    XPLMCommandRef inCommand
);

void XPLMRegisterCommandHandler(
    XPLMCommandRef inCommand,
    XPLMCommandCallback_f inHandler,
    int inBefore,
    void *inRefcon
);

void XPLMUnregisterCommandHandler(
    XPLMCommandRef inCommand,
    XPLMCommandCallback_f inHandler,
    int inBefore,
    void *inRefcon
);
]]

-- Every view command we successfully hook, so shutdown can
-- unregister exactly what was registered. Leaving a handler
-- attached to a torn-down Lua state crashes X-Plane on the next
-- press, the same hazard the key sniffer has.
--
-- These are declared here, well above the shutdown cleanup that
-- reads them. Declared next to the registration further down
-- they would be out of scope there, and the cleanup would
-- silently read nil globals instead.
local afk_view_command_refs = {}

local afk_view_command_callback

-- ============================================================
-- UPDATE CHECK
-- ============================================================
--
-- The installed version, AFK_CAMERA_VERSION, is set at the
-- top of the file.

-- Everything the update check needs, in one table so it costs
-- a single Lua local. This file is close to the 200 local
-- limit the language imposes on a chunk.
--
-- The check reads the site's version endpoint, which serves
-- just the current release:
--
--     {
--       "version": "1.1.0",
--       "summary": "Realism improved",
--       "downloadPage": "https://afkcamera.vercel.app/download",
--       "latestRelease": "https://github.com/.../releases/latest",
--       ...
--     }
--
-- Only "version" is needed; everything else is optional and
-- anything unrecognised is ignored, so the endpoint can grow
-- without breaking copies of this script already in the wild.
--
-- The whole-array changelog is still understood as well. If
-- the address is ever pointed back at a releases.json, the
-- entry flagged "latest": true wins, falling back to the first
-- entry since that list runs newest first.

local AFK_UPDATE = {

    url = "https://afkcamera.vercel.app/api/version.json",

    -- Fallback link, used only if the endpoint names none.
    page = "https://afkcamera.vercel.app",

    -- Written to the system temp directory rather than the
    -- script folder, which is read-only when X-Plane is
    -- installed under Program Files.
    file =
        (
            os.getenv("TEMP")
            or os.getenv("TMP")
            or SCRIPT_DIRECTORY
        )
        .. "/AFKCamera_update.txt",

    -- Seconds before the check is called off. curl is given a
    -- shorter limit of its own, so this only matters if curl
    -- never runs at all.
    timeout = 15.0,

    -- "idle", "checking", "current", "available" or "failed".
    state = "idle",

    message = "",
    latest = "",

    -- Where to get the new version, taken from the endpoint.
    download = "",

    started = 0.0,
    next_poll = 0.0,

    -- Size of the response the last poll saw. Used to tell a
    -- half-written file from a finished one.
    last_size = -1

}


-- Used to start curl without a console window. X-Plane is a
-- full-screen application and may be in VR; a console flashing
-- up over it is not acceptable, which rules out os.execute and
-- io.popen.
--
-- Kept in AFK_UPDATE rather than its own local: the main chunk
-- is at the 200 local limit, and going over it stops the whole
-- script compiling, which FlyWithLua answers with quarantine.
AFK_UPDATE.kernel32 = ffi.load("kernel32")

ffi.cdef[[
typedef struct {
    unsigned long  cb;
    char *lpReserved;
    char *lpDesktop;
    char *lpTitle;
    unsigned long  dwX;
    unsigned long  dwY;
    unsigned long  dwXSize;
    unsigned long  dwYSize;
    unsigned long  dwXCountChars;
    unsigned long  dwYCountChars;
    unsigned long  dwFillAttribute;
    unsigned long  dwFlags;
    unsigned short wShowWindow;
    unsigned short cbReserved2;
    unsigned char *lpReserved2;
    void *hStdInput;
    void *hStdOutput;
    void *hStdError;
} AFK_STARTUPINFOA;

typedef struct {
    void *hProcess;
    void *hThread;
    unsigned long dwProcessId;
    unsigned long dwThreadId;
} AFK_PROCESS_INFORMATION;

int CreateProcessA(
    const char *lpApplicationName,
    char *lpCommandLine,
    void *lpProcessAttributes,
    void *lpThreadAttributes,
    int bInheritHandles,
    unsigned long dwCreationFlags,
    void *lpEnvironment,
    const char *lpCurrentDirectory,
    AFK_STARTUPINFOA *lpStartupInfo,
    AFK_PROCESS_INFORMATION *lpProcessInformation
);

int CloseHandle(void *hObject);
]]


-- Used by the Download button to open the download page in the
-- user's default browser. Also kept in AFK_UPDATE for the local
-- limit.
AFK_UPDATE.shell32 = ffi.load("shell32")

ffi.cdef[[
void *ShellExecuteA(
    void *hwnd,
    const char *lpOperation,
    const char *lpFile,
    const char *lpParameters,
    const char *lpDirectory,
    int nShowCmd
);
]]


-- True only while this script is issuing a view command itself.
--
-- The exterior director starts by firing sim/view/circle, which
-- is one of the commands hooked below. Without this flag the
-- handler sees AFK active, assumes the user just changed view,
-- and cancels AFK in the same breath that started it.
local afk_view_command_internal = false


local external_circle_command =
    XPLM.XPLMFindCommand(
        "sim/view/circle"
    )

if external_circle_command == nil then
    logMsg(
        "AFK CAMERA: FAILED TO FIND sim/view/circle"
    )
else
    logMsg(
        "AFK CAMERA: EXTERNAL CIRCLE COMMAND FOUND"
    )
end


-- ============================================================
-- AIRCRAFT-SIZE ADAPTIVE EXTERNAL CAMERA
-- ============================================================
--
-- This is X-Plane's aircraft shadow/viewing-distance size value.
-- It changes with the loaded aircraft, allowing the same cinematic
-- shot definitions to be reused across very different aircraft sizes.

dataref(
    "afk_aircraft_view_size_z",
    "sim/aircraft/view/acf_size_z",
    "readonly"
)


-- ============================================================
-- PARKED DETECTION
-- ============================================================
--
-- Parked gets its own close, detail-led coverage; everything
-- else (taxi, runway, air) gets the flight shots.
--
-- Hysteresis keeps a gust rocking the aircraft, or a creep
-- forward against the brakes, from flipping the library back
-- and forth mid-sequence: it takes a sustained stop to become
-- parked, and a clearly higher speed to stop being parked.

dataref(
    "afk_ground_speed",
    "sim/flightmodel/position/groundspeed",
    "readonly"
)

dataref(
    "afk_on_ground",
    "sim/flightmodel/failures/onground_any",
    "readonly"
)

-- Height of the aircraft above the surface, used to work out
-- where the ground is so the camera can be kept above it.
dataref(
    "afk_plane_y_agl",
    "sim/flightmodel/position/y_agl",
    "readonly"
)

local AFK_PARKED_SPEED_ENTER = 0.5
local AFK_PARKED_SPEED_EXIT = 1.5
local AFK_PARKED_SETTLE_TIME = 2.0

-- Global on purpose: the shot bag above is defined earlier in
-- the file and reads this.
afk_exterior_parked = false

local afk_parked_timer = 0.0


function afk_update_parked_state(delta_time)

    local on_ground =
        tonumber(afk_on_ground) or 0

    local speed =
        math.abs(
            tonumber(afk_ground_speed) or 0.0
        )


    if on_ground ~= 1 then

        afk_exterior_parked = false
        afk_parked_timer = 0.0

        return

    end


    if afk_exterior_parked then

        if speed > AFK_PARKED_SPEED_EXIT then

            afk_exterior_parked = false
            afk_parked_timer = 0.0

        end

        return

    end


    if speed < AFK_PARKED_SPEED_ENTER then

        afk_parked_timer =
            afk_parked_timer + delta_time

        if afk_parked_timer >= AFK_PARKED_SETTLE_TIME then
            afk_exterior_parked = true
        end

    else

        afk_parked_timer = 0.0

    end

end

function get_external_aircraft_scale()

    local aircraft_size =
        tonumber(
            afk_aircraft_view_size_z
        )

    if aircraft_size == nil
       or aircraft_size <= 0.01
       or AFK_EXTERNAL_REFERENCE_SIZE <= 0.01 then

        return 1.0
    end

    local scale =
        aircraft_size
        / AFK_EXTERNAL_REFERENCE_SIZE

    if scale < AFK_EXTERNAL_MIN_SCALE then
        scale =
            AFK_EXTERNAL_MIN_SCALE
    end

    if scale > AFK_EXTERNAL_MAX_SCALE then
        scale =
            AFK_EXTERNAL_MAX_SCALE
    end

    return scale

end


local external_camera_controlled =
    false

-- Set by the native XPLM camera callback when X-Plane takes
-- ownership back, normally because the user changed the view.
-- Cleanup is performed from the normal FlyWithLua frame loop,
-- never from the camera callback itself.
local external_camera_ownership_lost =
    false

local external_camera_callback

local external_last_callback_time =
    os.clock()

local external_shot_index =
    1

local external_shot_phase =
    "MOVE"

local external_shot_time =
    0.0

local external_current_x = 20.0
local external_current_y = 8.0
local external_current_z = 24.0

local external_start_x = 20.0
local external_start_y = 8.0
local external_start_z = 24.0

local external_target_x = 10.0
local external_target_y = 6.0
local external_target_z = 15.0

local external_shot_distance = 0.0
local external_shot_duration = 1.0

-- Resolved once per shot so the camera callback stays cheap:
-- no table lookups, no nil checks, no string comparisons.
local external_look_start_x = 0.0
local external_look_start_y = 1.5
local external_look_start_z = 0.0

local external_look_end_x = 0.0
local external_look_end_y = 1.5
local external_look_end_z = 0.0

local external_zoom_start = 1.0
local external_zoom_end = 1.0

local external_roll_start = 0.0
local external_roll_end = 0.0

local external_shot_float = 1.0

-- Cumulative distance along a curved path, sampled at
-- AFK_EXTERIOR_ARC_SAMPLES points. Index 0 is the start.
local external_arc_length = {}

-- Optional curve control point. A straight line between two
-- points reads as a slider on rails; an arc reads as a crane
-- or a drone, and it is the difference between an orbit and
-- the chord across one.
local external_shot_curved = false
local external_via_x = 0.0
local external_via_y = 0.0
local external_via_z = 0.0

-- Runs continuously so the float does not jump at a cut.
local external_noise_time = 0.0

local external_aircraft_scale = 1.0


-- ============================================================
-- KEYBOARD INPUT DETECTION
-- ============================================================

ffi.cdef[[
typedef int XPLMKeyFlags;

typedef int (*XPLMKeySniffer_f)(
    char inChar,
    XPLMKeyFlags inFlags,
    char inVirtualKey,
    void *inRefcon
);

int XPLMRegisterKeySniffer(
    XPLMKeySniffer_f inCallback,
    int inBeforeWindows,
    void *inRefcon
);

int XPLMUnregisterKeySniffer(
    XPLMKeySniffer_f inCallback,
    int inBeforeWindows,
    void *inRefcon
);
]]

local keyboard_input_detected = false
local keyboard_callback

keyboard_callback = ffi.cast(
    "XPLMKeySniffer_f",
    function(inChar, inFlags, inVirtualKey, inRefcon)

        keyboard_input_detected = true

        return 1
    end
)

local keyboard_sniffer_result =
    XPLM.XPLMRegisterKeySniffer(
        keyboard_callback,
        0,
        nil
    )

if keyboard_sniffer_result == 1 then
    logMsg("AFK CAMERA: KEYBOARD SNIFFER REGISTERED")
else
    logMsg("AFK CAMERA: KEYBOARD SNIFFER REGISTRATION FAILED")
end

-- ============================================================
-- WINDOWS MOUSE BUTTON DETECTION
-- ============================================================
--
-- FlyWithLua's normal mouse callback does not catch the
-- right-button camera drag in this setup.
--
-- Poll the actual Windows mouse button state instead.
-- Both left and right buttons are treated as activity while
-- held, so a continuous camera drag keeps the AFK timer at 0.
--
-- The buttons are only observed; nothing is consumed or changed.

local user32 =
    ffi.load("user32")

ffi.cdef[[
short GetAsyncKeyState(int vKey);

typedef struct {
    long x;
    long y;
} AFK_POINT;

int GetCursorPos(AFK_POINT *lpPoint);
]]

local VK_LBUTTON =
    0x01

local VK_RBUTTON =
    0x02

local right_mouse_was_down =
    false

local right_mouse_input_detected =
    false


function poll_mouse_buttons()

    local left_mouse_down =
        bit.band(
            tonumber(
                user32.GetAsyncKeyState(
                    VK_LBUTTON
                )
            ),
            0x8000
        ) ~= 0


    local right_mouse_down =
        bit.band(
            tonumber(
                user32.GetAsyncKeyState(
                    VK_RBUTTON
                )
            ),
            0x8000
        ) ~= 0


    -- LEFT BUTTON:
    -- Keep the normal FlyWithLua mouse handler alive for
    -- clicks, and also treat a held button as continuous
    -- activity during a camera drag.
    if left_mouse_down then

        mouse_input_detected =
            true

    end


    -- RIGHT BUTTON:
    -- FlyWithLua's normal callback does not see this button
    -- in the user's camera drag setup, so handle it here.
    if right_mouse_down then

        right_mouse_input_detected =
            true

    end


    right_mouse_was_down =
        right_mouse_down

end


function handle_right_mouse_activity()

    if not right_mouse_input_detected then
        return false
    end

    right_mouse_input_detected =
        false

    idle_time =
        0.0

    last_activity =
        "Right mouse drag"

    if afk_active then

        afk_active =
            false

        afk_status =
            "ACTIVE"

        current_shot =
            "NONE"

        stop_afk_camera()

        logMsg(
            "AFK CAMERA: "
            .. "EXITED AFK MODE - "
            .. "RIGHT MOUSE INPUT"
        )

    end

    return true

end


-- ============================================================
-- WINDOWS MOUSE MOVEMENT DETECTION
-- ============================================================
--
-- Plain cursor movement with no button held. Optional, because
-- some users prefer that only deliberate input (click, wheel,
-- stick) ends AFK. The baseline is refreshed every frame even
-- while the option is off, so enabling it mid-flight can never
-- fire on a stale delta.

-- Cursor must move at least this many pixels between frames.
local MOUSE_MOVE_THRESHOLD_PX =
    2

local mouse_move_point =
    ffi.new("AFK_POINT[1]")

local mouse_move_previous_x =
    nil

local mouse_move_previous_y =
    nil

local mouse_move_input_detected =
    false


function poll_mouse_movement()

    if user32.GetCursorPos(mouse_move_point) == 0 then
        return
    end

    local x =
        tonumber(
            mouse_move_point[0].x
        ) or 0

    local y =
        tonumber(
            mouse_move_point[0].y
        ) or 0


    if mouse_move_previous_x == nil then

        mouse_move_previous_x =
            x

        mouse_move_previous_y =
            y

        return

    end


    local dx =
        math.abs(
            x
            - mouse_move_previous_x
        )

    local dy =
        math.abs(
            y
            - mouse_move_previous_y
        )

    mouse_move_previous_x =
        x

    mouse_move_previous_y =
        y


    if not afk_mouse_move_return then
        return
    end

    if dx >= MOUSE_MOVE_THRESHOLD_PX
    or dy >= MOUSE_MOVE_THRESHOLD_PX then

        mouse_move_input_detected =
            true

    end

end


function handle_mouse_move_activity()

    if not mouse_move_input_detected then
        return false
    end

    mouse_move_input_detected =
        false

    idle_time =
        0.0

    last_activity =
        "Mouse movement"

    if afk_active then

        afk_active =
            false

        afk_status =
            "ACTIVE"

        current_shot =
            "NONE"

        stop_afk_camera()

        logMsg(
            "AFK CAMERA: "
            .. "EXITED AFK MODE - "
            .. "MOUSE MOVEMENT"
        )

    end

    return true

end



-- ============================================================
-- X-PLANE MOUSE JOYSTICK INPUT
-- ============================================================
--
-- X-Plane has a separate "mouse acting as a joystick" mode.
-- These are bound using FlyWithLua's normal dataref() syntax:
-- dataref("Lua variable", "X-Plane DataRef", "readonly")
--
-- Do not assign the return value of dataref() to a local. The
-- function binds the named Lua variable to the DataRef.
--
-- This mode provides mouse-yoke pitch/roll input when enabled.
-- It is intentionally kept separate from the physical joystick
-- layer below.

dataref(
    "afk_mouse_is_joystick",
    "sim/joystick/mouse_is_joystick",
    "readonly"
)

dataref(
    "afk_mouse_yoke_pitch",
    "sim/joystick/yoke_pitch_ratio",
    "readonly"
)

dataref(
    "afk_mouse_yoke_roll",
    "sim/joystick/yoke_roll_ratio",
    "readonly"
)


local MOUSE_YOKE_CHANGE_THRESHOLD =
    0.01

local mouse_yoke_previous_pitch =
    nil

local mouse_yoke_previous_roll =
    nil

local mouse_yoke_initialised =
    false

local mouse_yoke_input_detected =
    false

local mouse_yoke_input_type =
    "Mouse Yoke"


function initialise_mouse_yoke_values()

    mouse_yoke_previous_pitch =
        tonumber(
            afk_mouse_yoke_pitch
        )

    mouse_yoke_previous_roll =
        tonumber(
            afk_mouse_yoke_roll
        )

    mouse_yoke_initialised =
        true

end


function poll_mouse_yoke_input()

    local active =
        tonumber(
            afk_mouse_is_joystick
        ) == 1


    local pitch =
        tonumber(
            afk_mouse_yoke_pitch
        )

    local roll =
        tonumber(
            afk_mouse_yoke_roll
        )


    if pitch == nil then
        pitch = 0.0
    end

    if roll == nil then
        roll = 0.0
    end


    if not mouse_yoke_initialised then

        mouse_yoke_previous_pitch =
            pitch

        mouse_yoke_previous_roll =
            roll

        mouse_yoke_initialised =
            true

        return

    end


    if active then

        local pitch_change =
            math.abs(
                pitch
                - mouse_yoke_previous_pitch
            )

        local roll_change =
            math.abs(
                roll
                - mouse_yoke_previous_roll
            )


        if pitch_change >
            MOUSE_YOKE_CHANGE_THRESHOLD then

            mouse_yoke_input_detected =
                true

            mouse_yoke_input_type =
                "Mouse Yoke Pitch"

        elseif roll_change >
            MOUSE_YOKE_CHANGE_THRESHOLD then

            mouse_yoke_input_detected =
                true

            mouse_yoke_input_type =
                "Mouse Yoke Roll"

        end

    end


    mouse_yoke_previous_pitch =
        pitch

    mouse_yoke_previous_roll =
        roll

end


function handle_mouse_yoke_activity()

    if not mouse_yoke_input_detected then
        return false
    end


    mouse_yoke_input_detected =
        false


    idle_time =
        0.0


    last_activity =
        mouse_yoke_input_type


    if afk_active then

        afk_active =
            false

        afk_status =
            "ACTIVE"

        current_shot =
            "NONE"

        stop_afk_camera()

        logMsg(
            "AFK CAMERA: "
            .. "EXITED AFK MODE - "
            .. mouse_yoke_input_type
        )

    end


    return true

end


initialise_mouse_yoke_values()


-- ============================================================
-- BETTER MOUSE YOKE INPUT
-- ============================================================
--
-- Better Mouse Yoke uses these X-Plane control DataRefs:
--   sim/cockpit2/controls/yoke_pitch_ratio
--   sim/cockpit2/controls/yoke_roll_ratio
--
-- Its flight loop derives those values directly from the
-- Windows mouse position. We therefore require BOTH:
--   1) the cursor to move, and
--   2) the yoke ratio to change.
--
-- This makes the AFK timer recognize actual Better Mouse Yoke
-- movement without treating ordinary autopilot/aircraft yoke
-- changes as mouse input.

dataref(
    "afk_bmy_yoke_pitch",
    "sim/cockpit2/controls/yoke_pitch_ratio",
    "readonly"
)

dataref(
    "afk_bmy_yoke_roll",
    "sim/cockpit2/controls/yoke_roll_ratio",
    "readonly"
)

local BETTER_MOUSE_YOKE_CHANGE_THRESHOLD =
    0.0025

local better_mouse_yoke_initialised =
    false

local better_mouse_yoke_previous_pitch =
    0.0

local better_mouse_yoke_previous_roll =
    0.0

local better_mouse_yoke_previous_cursor_x =
    0

local better_mouse_yoke_previous_cursor_y =
    0

local better_mouse_yoke_input_detected =
    false

local better_mouse_yoke_input_type =
    "Better Mouse Yoke"


function initialise_better_mouse_yoke_values()

    local point =
        ffi.new("AFK_POINT[1]")

    if user32.GetCursorPos(point) == 0 then
        return
    end

    better_mouse_yoke_previous_pitch =
        tonumber(
            afk_bmy_yoke_pitch
        ) or 0.0

    better_mouse_yoke_previous_roll =
        tonumber(
            afk_bmy_yoke_roll
        ) or 0.0

    better_mouse_yoke_previous_cursor_x =
        tonumber(
            point[0].x
        ) or 0

    better_mouse_yoke_previous_cursor_y =
        tonumber(
            point[0].y
        ) or 0

    better_mouse_yoke_initialised =
        true

end


function poll_better_mouse_yoke_input()

    local point =
        ffi.new("AFK_POINT[1]")

    if user32.GetCursorPos(point) == 0 then
        return
    end


    local pitch =
        tonumber(
            afk_bmy_yoke_pitch
        ) or 0.0

    local roll =
        tonumber(
            afk_bmy_yoke_roll
        ) or 0.0

    local cursor_x =
        tonumber(
            point[0].x
        ) or 0

    local cursor_y =
        tonumber(
            point[0].y
        ) or 0


    if not better_mouse_yoke_initialised then

        better_mouse_yoke_previous_pitch =
            pitch

        better_mouse_yoke_previous_roll =
            roll

        better_mouse_yoke_previous_cursor_x =
            cursor_x

        better_mouse_yoke_previous_cursor_y =
            cursor_y

        better_mouse_yoke_initialised =
            true

        return

    end


    local cursor_moved =
        cursor_x
            ~= better_mouse_yoke_previous_cursor_x
        or cursor_y
            ~= better_mouse_yoke_previous_cursor_y


    if cursor_moved then

        local pitch_change =
            math.abs(
                pitch
                    - better_mouse_yoke_previous_pitch
            )

        local roll_change =
            math.abs(
                roll
                    - better_mouse_yoke_previous_roll
            )


        if pitch_change >
            BETTER_MOUSE_YOKE_CHANGE_THRESHOLD then

            better_mouse_yoke_input_detected =
                true

            better_mouse_yoke_input_type =
                "Better Mouse Yoke Pitch"

        elseif roll_change >
            BETTER_MOUSE_YOKE_CHANGE_THRESHOLD then

            better_mouse_yoke_input_detected =
                true

            better_mouse_yoke_input_type =
                "Better Mouse Yoke Roll"

        end

    end


    better_mouse_yoke_previous_pitch =
        pitch

    better_mouse_yoke_previous_roll =
        roll

    better_mouse_yoke_previous_cursor_x =
        cursor_x

    better_mouse_yoke_previous_cursor_y =
        cursor_y

end


function handle_better_mouse_yoke_activity()

    if not better_mouse_yoke_input_detected then
        return false
    end


    better_mouse_yoke_input_detected =
        false

    idle_time =
        0.0

    last_activity =
        better_mouse_yoke_input_type


    if afk_active then

        afk_active =
            false

        afk_status =
            "ACTIVE"

        current_shot =
            "NONE"

        stop_afk_camera()

        logMsg(
            "AFK CAMERA: "
            .. "EXITED AFK MODE - "
            .. better_mouse_yoke_input_type
        )

    end

    return true

end


initialise_better_mouse_yoke_values()


-- ============================================================
-- JOYSTICK INPUT DETECTION
-- ============================================================
--
-- Detect real joystick changes from X-Plane's raw joystick
-- axis/button values.
--
-- IMPORTANT:
-- Do not assume a default axis center when no joystick is
-- connected. Instead, compare the raw axis value from one
-- frame to the next. Aircraft attitude cannot change these
-- raw joystick values.
--
-- EVERY axis is watched, whatever X-Plane has it assigned to
-- (pitch, roll, yaw, throttle, prop, mixture, brakes, sliders,
-- even unassigned). Moving anything on any connected device is
-- player activity. The assignment is only used to label the
-- activity in the HUD.
--
-- Buttons are treated as activity when they change, not merely
-- because they read as pressed. See JOYSTICK_BUTTONS below.

local joystick_axis_values =
    dataref_table(
        "sim/joystick/joystick_axis_values"
    )

local joystick_axis_assignments =
    dataref_table(
        "sim/joystick/joystick_axis_assignments"
    )

local joystick_button_values =
    dataref_table(
        "sim/joystick/joystick_button_values"
    )


local JOYSTICK_AXIS_COUNT =
    500

-- ------------------------------------------------------------
-- LATCHING SWITCHES
-- ------------------------------------------------------------
--
-- Plenty of hardware reports a switch position as a button that
-- stays pressed for as long as the switch is in that position:
-- the Honeycomb Alpha magneto key and master switches, Bravo
-- toggles, WinCtrl mode and detent switches, and so on. Read
-- naively, those look like a button held down forever, and AFK
-- can never start.
--
-- So a button is activity when it CHANGES, press or release,
-- and while held only for the first hold_limit seconds. That
-- still covers a trim or brake button held down on purpose.
-- Past the limit the button is taken to be a latched switch and
-- ignored until it changes again. Buttons already on when the
-- script loads are treated as latched from the start.
--
-- Kept in one table to cost a single local; the main chunk is
-- at the 200 local limit.
local JOYSTICK_BUTTONS = {

    count = 3200,

    -- Seconds a held button keeps counting as activity.
    hold_limit = 30.0,

    -- previous[i] is true while button i is down. Only down
    -- buttons are stored, so the table stays tiny.
    previous = {},

    -- down_since[i] is when button i went down, or nil once it
    -- has been written off as a latched switch.
    down_since = {}

}

-- The change threshold is the user's dead zone setting
-- (afk_joystick_deadzone, percent) converted to a 0..1 fraction
-- at poll time.

-- Largest frame-to-frame axis change seen on the last poll,
-- as a 0..1 fraction. Shown in the settings window so a user
-- can read off their stick's idle jitter and set the dead zone
-- just above it.
local joystick_last_max_difference =
    0.0

-- X-Plane axis assignment codes -> HUD label. Anything not
-- listed is still detected; it is simply reported generically.
local JOYSTICK_AXIS_NAMES = {
    [1] = "Joystick Pitch",
    [2] = "Joystick Roll",
    [3] = "Joystick Yaw",
    [4] = "Joystick Throttle",
    [5] = "Joystick Collective",
    [6] = "Joystick Left Brake",
    [7] = "Joystick Right Brake",
    [8] = "Joystick Prop",
    [9] = "Joystick Mixture"
}


function get_joystick_axis_name(assignment)

    local name =
        JOYSTICK_AXIS_NAMES[assignment]

    if name == nil then
        return "Joystick Axis"
    end

    return name

end


local joystick_previous_axis_values = {}

local joystick_input_detected =
    false

local joystick_input_type =
    "NONE"


local joystick_initialised =
    false


function initialise_joystick_values()

    joystick_previous_axis_values =
        {}

    for i = 0, JOYSTICK_AXIS_COUNT - 1 do

        local value =
            tonumber(
                joystick_axis_values[i]
            )

        if value ~= nil then

            joystick_previous_axis_values[i] =
                value

        end

    end

    -- Anything already on at load is a switch position, not
    -- someone pressing a button, so it starts out latched.
    JOYSTICK_BUTTONS.previous = {}
    JOYSTICK_BUTTONS.down_since = {}

    for i = 0, JOYSTICK_BUTTONS.count - 1 do

        local pressed =
            tonumber(
                joystick_button_values[i]
            )

        if pressed ~= nil
        and pressed ~= 0 then

            JOYSTICK_BUTTONS.previous[i] =
                true

        end

    end

    joystick_initialised =
        true

end


-- Returns true if any button counts as activity this frame.
-- Every button is visited every frame, even after one is found,
-- so the stored states never go stale.
function poll_joystick_buttons()

    local buttons =
        JOYSTICK_BUTTONS

    local now =
        os.clock()

    local detected =
        false

    for i = 0, buttons.count - 1 do

        local value =
            tonumber(
                joystick_button_values[i]
            )

        local pressed =
            value ~= nil
            and value ~= 0

        local was_pressed =
            buttons.previous[i] == true

        if pressed ~= was_pressed then

            -- Pressed or released: a real, deliberate change,
            -- including a latched switch being flipped.
            if pressed then

                buttons.previous[i] = true
                buttons.down_since[i] = now

            else

                buttons.previous[i] = nil
                buttons.down_since[i] = nil

            end

            detected =
                true

        elseif pressed then

            local since =
                buttons.down_since[i]

            if since ~= nil then

                if now - since <= buttons.hold_limit then

                    detected =
                        true

                else

                    buttons.down_since[i] =
                        nil

                    logMsg(
                        "AFK CAMERA: JOYSTICK BUTTON "
                        .. tostring(i)
                        .. " HELD OVER "
                        .. string.format(
                            "%.0f",
                            buttons.hold_limit
                        )
                        .. " S - TREATED AS A LATCHED SWITCH"
                    )

                end

            end

        end

    end

    return detected

end


function poll_joystick_input()

    -- --------------------------------------------------------
    -- First frame: establish a baseline.
    -- --------------------------------------------------------
    --
    -- This is critical when no joystick is attached. X-Plane
    -- may still expose default values/assignments; those values
    -- are not treated as player input until they actually change.

    if not joystick_initialised then

        initialise_joystick_values()

        return

    end


    -- --------------------------------------------------------
    -- Any axis movement
    -- --------------------------------------------------------
    --
    -- Every axis baseline is updated every frame, even after a
    -- change has been found, so a second axis moving at the same
    -- time is not reported again next frame with a stale baseline.

    local axis_detected =
        false

    local axis_threshold =
        afk_joystick_deadzone
        / 100.0

    local frame_max_difference =
        0.0

    for i = 0, JOYSTICK_AXIS_COUNT - 1 do

        local current_value =
            tonumber(
                joystick_axis_values[i]
            )

        if current_value ~= nil then

            local previous_value =
                joystick_previous_axis_values[i]

            joystick_previous_axis_values[i] =
                current_value

            if previous_value ~= nil then

                local difference =
                    math.abs(
                        current_value
                        - previous_value
                    )

                if difference > frame_max_difference then

                    frame_max_difference =
                        difference

                end

                if not axis_detected
                and difference > axis_threshold then

                    axis_detected =
                        true

                    joystick_input_type =
                        get_joystick_axis_name(
                            tonumber(
                                joystick_axis_assignments[i]
                            )
                        )

                end

            end

        end

    end

    joystick_last_max_difference =
        frame_max_difference

    -- --------------------------------------------------------
    -- Joystick buttons
    -- --------------------------------------------------------
    --
    -- Polled even when an axis already moved, so button states
    -- stay current. A latched switch is ignored; see
    -- JOYSTICK_BUTTONS.

    local button_detected =
        poll_joystick_buttons()

    if axis_detected then

        joystick_input_detected =
            true

    elseif button_detected then

        joystick_input_detected =
            true

        joystick_input_type =
            "Joystick Button"

    end

end


function handle_joystick_activity()

    if not joystick_input_detected then
        return false
    end


    joystick_input_detected =
        false


    idle_time =
        0.0


    last_activity =
        joystick_input_type


    if afk_active then

        afk_active =
            false

        afk_status =
            "ACTIVE"

        current_shot =
            "NONE"

        stop_afk_camera()

        logMsg(
            "AFK CAMERA: "
            .. "EXITED AFK MODE - "
            .. joystick_input_type
        )

    end


    return true

end


initialise_joystick_values()




-- ============================================================
-- CAMERA STATE
-- ============================================================

-- Retain this flag name to minimize changes elsewhere in the
-- project. In cockpit mode it now means "AFK cockpit director
-- active", not "AFK Camera owns the camera".
local cockpit_camera_controlled = false

local cockpit_base_head_x = 0.0
local cockpit_base_head_y = 0.0
local cockpit_base_head_z = 0.0

local cockpit_base_head_psi = 0.0
local cockpit_base_head_the = 0.0
local cockpit_base_head_phi = 0.0

-- The view type present when AFK starts. Cockpit AFK does not
-- own the XPLM camera, so this lets us cleanly detect a manual
-- view change while the cockpit director is active.
local afk_entry_view_type = nil



-- ------------------------------------------------------------
-- RETURN TO PRE-AFK VIEW
-- ------------------------------------------------------------
--
-- When cockpit AFK ends, the pilot head is driven back to the
-- exact pose captured at AFK entry over this many seconds, using
-- the same per-frame writes as the director itself. A single
-- one-frame write is not enough: X-Plane and other camera
-- add-ons can write the head in the same frame.
--
-- 0 = snap back instantly.
local COCKPIT_RETURN_TIME = 0.75

local cockpit_return_active = false
local cockpit_return_time = 0.0

-- The pose the return animation starts from. All six channels
-- are captured, so leaving AFK mid-breath or mid-tilt cannot
-- pop the view.
local cockpit_return_start_psi = 0.0
local cockpit_return_start_the = 0.0
local cockpit_return_start_phi = 0.0
local cockpit_return_start_x = 0.0
local cockpit_return_start_y = 0.0
local cockpit_return_start_z = 0.0

-- Exactly what was written to the head last frame. Angles are
-- absolute; x/y/z are offsets from the pose captured at AFK
-- entry.
local cockpit_displayed_psi = 0.0
local cockpit_displayed_the = 0.0
local cockpit_displayed_phi = 0.0
local cockpit_displayed_x = 0.0
local cockpit_displayed_y = 0.0
local cockpit_displayed_z = 0.0


-- ============================================================
-- CAMERA DATAREFS
-- ============================================================

dataref(
    "afk_view_heading",
    "sim/graphics/view/view_heading"
)

dataref(
    "afk_view_pitch",
    "sim/graphics/view/view_pitch"
)

dataref(
    "afk_view_roll",
    "sim/graphics/view/view_roll"
)

dataref(
    "afk_view_type",
    "sim/graphics/view/view_type"
)

-- ============================================================
-- NORMAL X-PLANE COCKPIT CAMERA / PILOT HEAD
-- ============================================================
--
-- Cockpit AFK does NOT take camera ownership. X-Plane's normal
-- cockpit camera remains in charge while we animate only the
-- virtual pilot's head. This lets other camera systems continue
-- to operate normally.

dataref(
    "afk_pilot_head_x",
    "sim/graphics/view/pilots_head_x"
)

dataref(
    "afk_pilot_head_y",
    "sim/graphics/view/pilots_head_y"
)

dataref(
    "afk_pilot_head_z",
    "sim/graphics/view/pilots_head_z"
)

dataref(
    "afk_pilot_head_psi",
    "sim/graphics/view/pilots_head_psi"
)

dataref(
    "afk_pilot_head_the",
    "sim/graphics/view/pilots_head_the"
)

dataref(
    "afk_pilot_head_phi",
    "sim/graphics/view/pilots_head_phi"
)

dataref(
    "afk_plane_local_x",
    "sim/flightmodel/position/local_x"
)

dataref(
    "afk_plane_local_y",
    "sim/flightmodel/position/local_y"
)

dataref(
    "afk_plane_local_z",
    "sim/flightmodel/position/local_z"
)

dataref(
    "afk_plane_pitch",
    "sim/flightmodel/position/theta"
)

dataref(
    "afk_plane_roll",
    "sim/flightmodel/position/phi"
)

dataref(
    "afk_plane_heading",
    "sim/flightmodel/position/psi"
)


-- ============================================================
-- VIEW TYPE
-- ============================================================

function update_director_mode()

    if afk_view_type == 1026 then

        director_mode = "COCKPIT"

    elseif afk_view_type == 1018
        or afk_view_type == 1028
        or afk_view_type == 1015
        or afk_view_type == 1020 then

        director_mode = "EXTERNAL"

    else

        director_mode = "UNKNOWN"

    end

end


-- ============================================================
-- COCKPIT CAMERA DIRECTOR - PHASE 6
-- CENTER -> LEFT -> CENTER
-- ============================================================

local cockpit_shot = "CENTER"

local cockpit_shot_time = 0.0

local cockpit_shot_duration = 2.5

-- Where the spring is currently pulling the head. There is no
-- matching "start" angle any more: the spring carries whatever
-- pose the head happens to be in when a new target is set.
local cockpit_target_heading = 0.0
local cockpit_target_pitch = 0.0


-- How long to stay centered
local COCKPIT_CENTER_HOLD = 2.0


-- ============================================================
-- COCKPIT LOOK LIBRARY
-- ============================================================
--
-- Every place the pilot can look. Adding one is a single row;
-- nothing else in the script needs to change.
--
--   name     shown on the debug HUD
--   heading  {min, max} degrees from the resting head, negative
--            is left, positive is right
--   pitch    {min, max} degrees, negative is down
--   weight   how often it is picked, relative to the others
--   hold     optional {min, max} seconds to dwell there. Left
--            out, the default skewed dwell time is used.
--
-- The angles are randomised within their range every time, so a
-- look is never repeated exactly.
--
-- Note that overhead and pedestal geometry differs a lot
-- between aircraft. These ranges are deliberately moderate so
-- they read correctly in most cockpits rather than being exact
-- for one airframe.

local AFK_COCKPIT_LOOKS = {

    -- --------------------------------------------------------
    -- BACK TO CENTRE
    -- --------------------------------------------------------
    --
    -- Returning to the resting pose is just another place to
    -- look, picked by the same weighted draw as everything
    -- else. It carries a much heavier weight than any single
    -- look, so it is still the most common destination by far,
    -- but the head no longer passes through centre after every
    -- single movement. Sometimes it runs straight on from the
    -- pedestal to the overhead and back out the window.
    --
    -- no_history keeps it out of the recently-used list, which
    -- would otherwise lock it out for several picks at a time
    -- and force an unnaturally regular rhythm. An immediate
    -- repeat is still blocked.

    {
        name = "CENTER",
        heading = { 0.0, 0.0 },
        pitch = { 0.0, 0.0 },
        weight = 14.0,
        no_history = true
    },

    -- --------------------------------------------------------
    -- SUBTLE MOVEMENT
    -- --------------------------------------------------------
    --
    -- Small, frequent, unhurried. These carry most of the
    -- running time and are what stops the head from looking
    -- like it is cycling through a list of poses.

    {
        name = "SETTLE",
        heading = { -2.2, 2.2 },
        pitch = { -1.5, 1.2 },
        weight = 7.0,
    },
    {
        name = "GLANCE LEFT",
        heading = { -9.0, -4.5 },
        pitch = { -2.0, 1.2 },
        weight = 6.0,
    },
    {
        name = "GLANCE RIGHT",
        heading = { 4.5, 9.0 },
        pitch = { -2.0, 1.2 },
        weight = 6.0,
    },
    {
        name = "SMALL NOD DOWN",
        heading = { -3.0, 3.0 },
        pitch = { -6.0, -3.0 },
        weight = 5.0,
    },
    {
        name = "EASE UP",
        heading = { -3.0, 3.0 },
        pitch = { 2.0, 4.5 },
        weight = 4.0,
    },

    -- --------------------------------------------------------
    -- OUTSIDE
    -- --------------------------------------------------------

    {
        name = "LOOK LEFT",
        heading = { -27.0, -18.0 },
        pitch = { -3.0, 2.0 },
        weight = 5.0
    },
    {
        name = "LOOK RIGHT",
        heading = { 18.0, 27.0 },
        pitch = { -3.0, 2.0 },
        weight = 5.0
    },
    {
        name = "SHOULDER CHECK LEFT",
        heading = { -48.0, -36.0 },
        pitch = { -4.5, 2.0 },
        weight = 1.6,
    },
    {
        name = "SHOULDER CHECK RIGHT",
        heading = { 36.0, 48.0 },
        pitch = { -4.5, 2.0 },
        weight = 1.6,
    },
    {
        name = "HORIZON SCAN",
        heading = { -7.0, 7.0 },
        pitch = { 1.5, 4.5 },
        weight = 5.0
    },
    {
        name = "SKY CHECK",
        heading = { -9.0, 9.0 },
        pitch = { 8.0, 14.0 },
        weight = 2.2,
    },
    {
        name = "DOWN LEFT WINDOW",
        heading = { -33.0, -22.0 },
        pitch = { -18.0, -10.0 },
        weight = 2.0
    },
    {
        name = "DOWN RIGHT WINDOW",
        heading = { 22.0, 33.0 },
        pitch = { -18.0, -10.0 },
        weight = 2.0
    },

    -- --------------------------------------------------------
    -- MAIN PANEL
    -- --------------------------------------------------------

    {
        name = "PRIMARY FLIGHT DISPLAY",
        heading = { -7.0, 3.0 },
        pitch = { -17.0, -10.0 },
        weight = 6.0,
    },
    {
        name = "LOOK PANEL LEFT",
        heading = { -19.0, -11.0 },
        pitch = { -11.0, -5.5 },
        weight = 4.0
    },
    {
        name = "LOOK PANEL RIGHT",
        heading = { 11.0, 19.0 },
        pitch = { -11.0, -5.5 },
        weight = 4.0
    },
    {
        name = "STANDBY INSTRUMENTS",
        heading = { -14.0, -6.0 },
        pitch = { -19.0, -13.0 },
        weight = 2.0,
    },

    -- --------------------------------------------------------
    -- OVERHEAD PANEL
    -- --------------------------------------------------------

    {
        name = "OVERHEAD PANEL",
        heading = { -7.0, 7.0 },
        pitch = { 23.0, 33.0 },
        weight = 2.0,
    },
    {
        name = "OVERHEAD LEFT",
        heading = { -16.0, -7.0 },
        pitch = { 21.0, 30.0 },
        weight = 1.4,
    },
    {
        name = "OVERHEAD RIGHT",
        heading = { 7.0, 16.0 },
        pitch = { 21.0, 30.0 },
        weight = 1.4,
    },

    -- --------------------------------------------------------
    -- CENTER PEDESTAL
    -- --------------------------------------------------------

    {
        name = "CENTER PEDESTAL",
        heading = { -6.0, 6.0 },
        pitch = { -36.0, -26.0 },
        weight = 2.6,
    },
    {
        name = "THROTTLE QUADRANT",
        heading = { -9.0, 1.0 },
        pitch = { -33.0, -24.0 },
        weight = 2.2,
    },
    {
        name = "PEDESTAL RADIOS",
        heading = { 2.0, 12.0 },
        pitch = { -34.0, -25.0 },
        weight = 2.0,
    },
    {
        name = "TRIM AND FLAPS",
        heading = { -12.0, -3.0 },
        pitch = { -38.0, -29.0 },
        weight = 1.5,
    }

}


-- How many recent looks are blocked from being picked again.
local COCKPIT_LOOK_HISTORY = 5

local cockpit_look_history = {}

local cockpit_current_look = 0

-- Blocks an immediate repeat even for looks kept out of the
-- recently-used list.
local cockpit_last_look = 0

-- "CENTER" only until the first look is picked, then
-- "MOVE" while travelling and "HOLD" while dwelling.
local cockpit_shot_phase = "CENTER"

local cockpit_look_weight_total = 0.0

for i = 1, #AFK_COCKPIT_LOOKS do

    cockpit_look_weight_total =
        cockpit_look_weight_total
        + (AFK_COCKPIT_LOOKS[i].weight or 1.0)

end

math.randomseed(os.time())


-- ============================================================
-- SMOOTHSTEP
-- ============================================================

function cockpit_smoothstep(t)

    if t < 0 then
        t = 0
    end

    if t > 1 then
        t = 1
    end

    return t * t * (3.0 - 2.0 * t)

end


-- ============================================================
-- START NEW COCKPIT SHOT
-- ============================================================

-- Passing nil for duration lets the move time be derived from
-- how far the head actually has to travel, so a short glance
-- does not take as long as a full shoulder check.
function cockpit_set_shot(
    shot_name,
    target_heading,
    target_pitch,
    duration
)

    cockpit_shot = shot_name
    current_shot = shot_name

    cockpit_shot_time = 0.0


    local delta_heading =
        target_heading
        - cockpit_target_heading

    local delta_pitch =
        target_pitch
        - cockpit_target_pitch


    if duration == nil then

        duration =
            cockpit_estimate_move_time(
                delta_heading,
                delta_pitch
            )

    end

    cockpit_shot_duration =
        duration

    cockpit_target_heading =
        target_heading

    cockpit_target_pitch =
        target_pitch


    -- WIND-UP
    -- Kicking the spring velocity backwards produces the brief
    -- counter-movement a real head makes as it loads against
    -- the neck before a large turn.
    if COCKPIT_HEAD.realism
    and COCKPIT_HEAD.windup > 0 then

        cockpit_anim_psi_velocity =
            cockpit_anim_psi_velocity
            - delta_heading * COCKPIT_HEAD.windup

        cockpit_anim_the_velocity =
            cockpit_anim_the_velocity
            - delta_pitch * COCKPIT_HEAD.windup

    end

end

-- ============================================================
-- AIRCRAFT-ATTACHED CAMERA TRANSFORM
-- ============================================================

local function cockpit_deg_to_rad(value)
    return value * math.pi / 180.0
end


-- X-Plane's aircraft coordinate convention:
-- X = right, Y = up, Z = toward the tail.
-- This follows the documented OpenGL/aircraft-coordinate rotation order.

local function cockpit_aircraft_to_world(
    x,
    y,
    z,
    pitch,
    roll,
    heading
)

    local phi =
        cockpit_deg_to_rad(roll)

    local theta =
        cockpit_deg_to_rad(pitch)

    local psi =
        cockpit_deg_to_rad(heading)


    -- Roll
    local x_phi =
        x * math.cos(phi)
        + y * math.sin(phi)

    local y_phi =
        y * math.cos(phi)
        - x * math.sin(phi)

    local z_phi =
        z


    -- Pitch
    local x_theta =
        x_phi

    local y_theta =
        y_phi * math.cos(theta)
        - z_phi * math.sin(theta)

    local z_theta =
        z_phi * math.cos(theta)
        + y_phi * math.sin(theta)


    -- Heading
    local x_world =
        x_theta * math.cos(psi)
        - z_theta * math.sin(psi)

    local y_world =
        y_theta

    local z_world =
        z_theta * math.cos(psi)
        + x_theta * math.sin(psi)


    return
        x_world,
        y_world,
        z_world

end


-- ============================================================
-- COCKPIT CAMERA CALLBACK
-- ============================================================

-- ============================================================
-- COCKPIT SHOT SELECTION
-- ============================================================
--
-- These were previously declared inside the director function,
-- which rebuilt all six closures on every rendered frame. They
-- are ordinary module-level functions now.

function cockpit_random_range(min_value, max_value)

    return min_value
        + math.random()
        * (max_value - min_value)

end


-- How long the pilot dwells before looking somewhere else.
-- Real dwell times are strongly skewed: mostly short glances,
-- with the occasional long stare. A flat 5-30 s spread is one
-- of the things that made the old motion feel mechanical.
function cockpit_random_hold()

    local roll =
        math.random()

    if roll < 0.55 then

        -- Quick glance.
        return cockpit_random_range(2.5, 6.5)

    elseif roll < 0.88 then

        -- Ordinary look.
        return cockpit_random_range(6.5, 16.0)

    end

    -- Occasional long stare out of the window.
    return cockpit_random_range(16.0, 34.0)

end


-- Roughly how long the spring needs to carry the head across a
-- given angular distance and settle, so the shot state machine
-- changes state about when the head actually arrives.
function cockpit_estimate_move_time(delta_heading, delta_pitch)

    local distance =
        math.sqrt(
            delta_heading * delta_heading
            + delta_pitch * delta_pitch
        )

    -- Fitted against the rate-limited spring: a short look
    -- settles in about 1.7 s and a wide one in about 2.1 s.
    local move_time =
        1.70
        + distance * 0.010

    -- Nobody moves at exactly the same speed twice.
    move_time =
        move_time
        * cockpit_random_range(0.92, 1.20)


    -- A slower head needs proportionally longer to arrive, so
    -- the phase change still lands when the movement finishes.
    local speed =
        afk_head_speed / 100.0

    if speed < 0.1 then
        speed = 0.1
    end

    move_time =
        move_time / speed


    if move_time < 1.60 / speed then
        move_time = 1.60 / speed
    end

    if move_time > 2.80 / speed then
        move_time = 2.80 / speed
    end

    return move_time

end


-- Every look carries a little movement on the other axis too.
-- Purely horizontal or purely vertical head turns look wrong.
function cockpit_look_was_recent(index)

    -- Never twice in a row, whatever the entry.
    if index == cockpit_last_look then
        return true
    end

    for i = 1, #cockpit_look_history do

        if cockpit_look_history[i] == index then
            return true
        end

    end

    return false

end


function cockpit_remember_look(index)

    cockpit_last_look =
        index

    local look =
        AFK_COCKPIT_LOOKS[index]

    -- Entries flagged no_history stay eligible. Centre is the
    -- one that matters: parking it in the recently-used list
    -- would cap how often the head can come back to rest.
    if look ~= nil
    and look.no_history then
        return
    end

    cockpit_look_history[#cockpit_look_history + 1] =
        index

    while #cockpit_look_history > COCKPIT_LOOK_HISTORY do
        table.remove(cockpit_look_history, 1)
    end

end


-- Weighted pick that skips anything used recently, so the same
-- few looks cannot cluster together.
function cockpit_pick_look()

    local count =
        #AFK_COCKPIT_LOOKS

    if count == 0 then
        return nil
    end


    for attempt = 1, 12 do

        local target =
            math.random()
            * cockpit_look_weight_total

        local accumulated =
            0.0

        local picked =
            count

        for i = 1, count do

            accumulated =
                accumulated
                + (AFK_COCKPIT_LOOKS[i].weight or 1.0)

            if target <= accumulated then
                picked = i
                break
            end

        end

        if not cockpit_look_was_recent(picked) then
            return picked
        end

    end


    -- Every draw came back recent. Scan from a random start so
    -- the fallback is not always the same entry.
    local offset =
        math.random(count)

    for i = 0, count - 1 do

        local index =
            ((offset + i - 1) % count) + 1

        if not cockpit_look_was_recent(index) then
            return index
        end

    end

    return math.random(count)

end


-- ============================================================
-- COCKPIT SHOT PHASES
-- ============================================================
--
-- MOVE   travelling to a look
-- HOLD   dwelling on it
-- RETURN travelling back to the resting pose
-- CENTER resting before the next look

function cockpit_apply_look(index)

    local look =
        AFK_COCKPIT_LOOKS[index]

    if look == nil then

        -- Should not happen. Rest at the entry pose.
        cockpit_shot_phase =
            "MOVE"

        cockpit_set_shot(
            "CENTER",
            cockpit_base_head_psi,
            cockpit_base_head_the,
            nil
        )

        return

    end

    cockpit_current_look =
        index

    cockpit_remember_look(index)

    cockpit_shot_phase =
        "MOVE"

    -- The size setting scales how far from the resting pose
    -- each look reaches. At low settings the head only hints
    -- toward the overhead panel or pedestal rather than fully
    -- turning to face it, which is the point of a subtle
    -- setting.
    local size =
        afk_head_size / 100.0

    cockpit_set_shot(
        look.name,

        cockpit_base_head_psi
        + cockpit_random_range(
            look.heading[1],
            look.heading[2]
        ) * size,

        cockpit_base_head_the
        + cockpit_random_range(
            look.pitch[1],
            look.pitch[2]
        ) * size,

        nil
    )

end


function cockpit_begin_hold()

    local look =
        AFK_COCKPIT_LOOKS[cockpit_current_look]

    local hold_time

    if look ~= nil
    and look.hold ~= nil then

        hold_time =
            cockpit_random_range(
                look.hold[1],
                look.hold[2]
            )

    else

        hold_time =
            cockpit_random_hold()

    end

    cockpit_shot_phase =
        "HOLD"

    -- Same target as the move that just finished, so the head
    -- simply settles where it arrived.
    cockpit_set_shot(
        "HOLD "
        .. (
            look ~= nil
            and look.name
            or "CENTER"
        ),
        cockpit_target_heading,
        cockpit_target_pitch,
        hold_time
    )

end


function cockpit_director_update(delta_time)

    if not afk_active then
        return
    end

    if director_mode ~= "COCKPIT" then
        return
    end


    -- Normal FlyWithLua frame time. No camera callback is involved.
    if delta_time < 0 then
        delta_time = 0
    end

    if delta_time > 0.1 then
        delta_time = 0.1
    end

    cockpit_shot_time =
        cockpit_shot_time
        + delta_time


    -- ----------------------------------------------------
    -- Change shot
    -- ----------------------------------------------------

    if cockpit_shot_time >= cockpit_shot_duration then

        -- Arrive, dwell, then pick somewhere new. Coming back
        -- to centre is one of the things that can be picked,
        -- so there is no separate return step any more.
        if cockpit_shot_phase == "MOVE" then

            cockpit_begin_hold()

        else

            cockpit_apply_look(
                cockpit_pick_look()
            )

        end

    end

        -- ----------------------------------------------------
        -- MUSCLE DYNAMICS
        -- ----------------------------------------------------
        --
        -- Sub-stepping keeps the spring stable if the frame rate
        -- drops or the spring is tuned much stiffer.

        local steps =
            math.ceil(delta_time / 0.02)

        if steps < 1 then
            steps = 1
        end

        if steps > 8 then
            steps = 8
        end

        local step_time =
            delta_time / steps

        local head_speed =
            afk_head_speed / 100.0

        if head_speed < 0.1 then
            head_speed = 0.1
        end

        local omega_psi =
            2.0
            * math.pi
            * COCKPIT_HEAD.spring_frequency
            * head_speed

        local omega_the =
            omega_psi
            * COCKPIT_HEAD.pitch_spring_scale

        -- Hoisted out of the step loop below.
        local max_yaw_rate =
            COCKPIT_HEAD.max_yaw_rate
            * head_speed

        local max_pitch_rate =
            COCKPIT_HEAD.max_pitch_rate
            * head_speed


        for step = 1, steps do

            local psi_accel =
                omega_psi
                * omega_psi
                * (
                    cockpit_target_heading
                    - cockpit_anim_psi
                )
                - 2.0
                * COCKPIT_HEAD.spring_damping
                * omega_psi
                * cockpit_anim_psi_velocity

            cockpit_anim_psi_velocity =
                cockpit_anim_psi_velocity
                + psi_accel * step_time

            if max_yaw_rate > 0 then

                if cockpit_anim_psi_velocity
                    > max_yaw_rate then

                    cockpit_anim_psi_velocity =
                        max_yaw_rate

                elseif cockpit_anim_psi_velocity
                    < -max_yaw_rate then

                    cockpit_anim_psi_velocity =
                        -max_yaw_rate

                end

            end

            cockpit_anim_psi =
                cockpit_anim_psi
                + cockpit_anim_psi_velocity * step_time


            local the_accel =
                omega_the
                * omega_the
                * (
                    cockpit_target_pitch
                    - cockpit_anim_the
                )
                - 2.0
                * COCKPIT_HEAD.spring_damping
                * omega_the
                * cockpit_anim_the_velocity

            cockpit_anim_the_velocity =
                cockpit_anim_the_velocity
                + the_accel * step_time

            if max_pitch_rate > 0 then

                if cockpit_anim_the_velocity
                    > max_pitch_rate then

                    cockpit_anim_the_velocity =
                        max_pitch_rate

                elseif cockpit_anim_the_velocity
                    < -max_pitch_rate then

                    cockpit_anim_the_velocity =
                        -max_pitch_rate

                end

            end

            cockpit_anim_the =
                cockpit_anim_the
                + cockpit_anim_the_velocity * step_time

        end


        -- ----------------------------------------------------
        -- IDLE LIFE
        -- ----------------------------------------------------

        local psi_out =
            cockpit_anim_psi

        local the_out =
            cockpit_anim_the

        local phi_out =
            cockpit_base_head_phi

        local offset_x = 0.0
        local offset_y = 0.0
        local offset_z = 0.0


        if COCKPIT_HEAD.realism then

            cockpit_noise_time =
                cockpit_noise_time
                + delta_time

            local t =
                cockpit_noise_time


            -- ------------------------------------------------
            -- FADE IN
            -- ------------------------------------------------
            --
            -- Every wave below is a sine with a randomised
            -- phase, so on the first AFK frame it evaluates to
            -- an arbitrary point in its cycle rather than to
            -- zero. Applied at full amplitude that arrives as a
            -- single visible step the instant AFK begins.
            --
            -- Ramping the whole layer up from nothing fixes it.
            -- Smoothstep means the rate of change starts at
            -- zero as well, so the head comes alive gradually
            -- instead of switching on.

            if cockpit_life_blend < 1.0 then

                if COCKPIT_HEAD.life_fade_in > 0 then

                    cockpit_life_blend =
                        cockpit_life_blend
                        + delta_time
                        / COCKPIT_HEAD.life_fade_in

                else

                    cockpit_life_blend =
                        1.0

                end

                if cockpit_life_blend > 1.0 then
                    cockpit_life_blend = 1.0
                end

            end

            -- The size setting rides on the fade-in blend, so
            -- it scales breathing, sway, tremor, and through
            -- them the neck pivot, all in one place.
            local life =
                cockpit_smoothstep(
                    cockpit_life_blend
                )
                * (afk_head_size / 100.0)


            -- Slow postural sway.
            psi_out =
                psi_out
                + cockpit_wave(t, 0.41, 0.67, 1.13, 1)
                * COCKPIT_HEAD.drift_psi
                * life

            the_out =
                the_out
                + cockpit_wave(t, 0.37, 0.71, 1.07, 4)
                * COCKPIT_HEAD.drift_the
                * life

            phi_out =
                phi_out
                + cockpit_wave(t, 0.29, 0.53, 0.97, 7)
                * COCKPIT_HEAD.drift_phi
                * life

            offset_x =
                offset_x
                + cockpit_wave(t, 0.31, 0.59, 0.83, 10)
                * COCKPIT_HEAD.drift_pos
                * life

            offset_z =
                offset_z
                + cockpit_wave(t, 0.27, 0.61, 0.89, 13)
                * COCKPIT_HEAD.drift_pos
                * life


            -- Micro tremor: far too small to see as motion,
            -- but it stops the image from ever locking solid.
            psi_out =
                psi_out
                + math.sin(
                    t * 7.3
                    + cockpit_noise_phase[16]
                )
                * COCKPIT_HEAD.tremor
                * life

            the_out =
                the_out
                + math.sin(
                    t * 9.1
                    + cockpit_noise_phase[17]
                )
                * COCKPIT_HEAD.tremor
                * life


            -- Breathing.
            local breath =
                math.sin(
                    t
                    * 2.0
                    * math.pi
                    * COCKPIT_HEAD.breath_rate
                    + cockpit_noise_phase[18]
                )
                * life

            offset_y =
                offset_y
                + breath * COCKPIT_HEAD.breath_y

            the_out =
                the_out
                + breath * COCKPIT_HEAD.breath_pitch


            -- Tilt into the turn, driven by how fast the head
            -- is actually yawing, so it appears during a move
            -- and vanishes on a hold by itself.
            local roll_couple =
                cockpit_anim_psi_velocity
                * COCKPIT_HEAD.roll_coupling

            if roll_couple > COCKPIT_HEAD.roll_coupling_max then
                roll_couple = COCKPIT_HEAD.roll_coupling_max
            end

            if roll_couple < -COCKPIT_HEAD.roll_coupling_max then
                roll_couple = -COCKPIT_HEAD.roll_coupling_max
            end

            phi_out =
                phi_out
                + roll_couple


            -- ------------------------------------------------
            -- NECK PIVOT
            -- ------------------------------------------------
            --
            -- The eyes are not at the centre of rotation, so
            -- rotating the head also swings the eye point. The
            -- rest vector from pivot to eyes is rotated by the
            -- head angles relative to the AFK entry pose, and
            -- the difference is the translation.
            --
            -- This reuses the transform the exterior camera
            -- already uses, which follows the same X-Plane
            -- convention: X right, Y up, Z toward the tail.

            local neck_x,
                  neck_y,
                  neck_z =
                cockpit_aircraft_to_world(
                    0.0,
                    COCKPIT_HEAD.neck_up,
                    -COCKPIT_HEAD.neck_forward,
                    the_out - cockpit_base_head_the,
                    phi_out - cockpit_base_head_phi,
                    psi_out - cockpit_base_head_psi
                )

            offset_x =
                offset_x
                + neck_x

            offset_y =
                offset_y
                + neck_y
                - COCKPIT_HEAD.neck_up

            offset_z =
                offset_z
                + neck_z
                + COCKPIT_HEAD.neck_forward

        end


        -- ----------------------------------------------------
        -- X-PLANE NORMAL COCKPIT CAMERA OUTPUT
        -- ----------------------------------------------------
        --
        -- Only the pilot-head values are written. X-Plane itself
        -- remains responsible for placing the cockpit camera
        -- with the aircraft.

        cockpit_write_head_pose(
            psi_out,
            the_out,
            phi_out,
            offset_x,
            offset_y,
            offset_z
        )

end


-- ============================================================
-- PILOT HEAD WRITER
-- ============================================================
--
-- The single place the pilot head is written. The angles are
-- absolute; x/y/z are offsets from the pose captured at AFK
-- entry. Whatever is written is remembered, so the return
-- animation can start from the exact displayed pose.

function cockpit_write_head_pose(
    psi,
    the,
    phi,
    offset_x,
    offset_y,
    offset_z
)

    offset_x = offset_x or 0.0
    offset_y = offset_y or 0.0
    offset_z = offset_z or 0.0


    set(
        "sim/graphics/view/pilots_head_x",
        cockpit_base_head_x + offset_x
    )

    set(
        "sim/graphics/view/pilots_head_y",
        cockpit_base_head_y + offset_y
    )

    set(
        "sim/graphics/view/pilots_head_z",
        cockpit_base_head_z + offset_z
    )

    set(
        "sim/graphics/view/pilots_head_psi",
        psi
    )

    set(
        "sim/graphics/view/pilots_head_the",
        the
    )

    set(
        "sim/graphics/view/pilots_head_phi",
        phi
    )


    cockpit_displayed_psi = psi
    cockpit_displayed_the = the
    cockpit_displayed_phi = phi
    cockpit_displayed_x = offset_x
    cockpit_displayed_y = offset_y
    cockpit_displayed_z = offset_z

end


-- Put the head exactly where it was when AFK started and end
-- any return animation.
function cockpit_restore_head_pose()

    cockpit_write_head_pose(
        cockpit_base_head_psi,
        cockpit_base_head_the,
        cockpit_base_head_phi,
        0.0,
        0.0,
        0.0
    )

    cockpit_return_active =
        false

    cockpit_return_time =
        0.0

end


-- Runs every frame from the main loop, whether or not AFK is
-- active, until the head is back at the pre-AFK pose.
--
-- All six channels ease out together, from whatever was on
-- screen the instant AFK ended. The idle-life layers are not
-- re-applied here: they are already baked into the starting
-- pose and fade out with it, so the head settles rather than
-- twitching on the way home.
function cockpit_return_update(delta_time)

    if not cockpit_return_active then
        return
    end

    -- The user left the cockpit view: no point animating.
    if afk_view_type ~= 1026 then

        cockpit_restore_head_pose()

        return

    end

    cockpit_return_time =
        cockpit_return_time
        + delta_time

    local progress =
        cockpit_return_time
        / COCKPIT_RETURN_TIME

    if progress >= 1.0 then

        cockpit_restore_head_pose()

        logMsg(
            "AFK CAMERA: COCKPIT VIEW RETURNED TO PRE-AFK POSE"
        )

        return

    end

    local blend =
        cockpit_smoothstep(progress)

    local remaining =
        1.0 - blend

    cockpit_write_head_pose(
        cockpit_return_start_psi
        + (
            cockpit_base_head_psi
            - cockpit_return_start_psi
        ) * blend,

        cockpit_return_start_the
        + (
            cockpit_base_head_the
            - cockpit_return_start_the
        ) * blend,

        cockpit_return_start_phi
        + (
            cockpit_base_head_phi
            - cockpit_return_start_phi
        ) * blend,

        cockpit_return_start_x * remaining,
        cockpit_return_start_y * remaining,
        cockpit_return_start_z * remaining
    )

end


-- ============================================================
-- START COCKPIT CAMERA
-- ============================================================

function start_cockpit_camera()

    if cockpit_camera_controlled then
        return
    end

    if cockpit_return_active then

        -- Still animating back from the previous AFK session.
        -- The head is not at the user's pose yet, so keep the
        -- base captured last time instead of re-capturing, and
        -- start the spring from what is currently on screen so
        -- the interrupted return does not jump.
        cockpit_return_active =
            false

        cockpit_return_time =
            0.0

        cockpit_anim_psi =
            cockpit_displayed_psi

        cockpit_anim_the =
            cockpit_displayed_the

    else

        -- Capture the exact normal X-Plane pilot-head pose.
        cockpit_base_head_x =
            tonumber(afk_pilot_head_x) or 0.0

        cockpit_base_head_y =
            tonumber(afk_pilot_head_y) or 0.0

        cockpit_base_head_z =
            tonumber(afk_pilot_head_z) or 0.0

        cockpit_base_head_psi =
            tonumber(afk_pilot_head_psi) or 0.0

        cockpit_base_head_the =
            tonumber(afk_pilot_head_the) or 0.0

        cockpit_base_head_phi =
            tonumber(afk_pilot_head_phi) or 0.0

        cockpit_anim_psi =
            cockpit_base_head_psi

        cockpit_anim_the =
            cockpit_base_head_the

    end


    cockpit_anim_psi_velocity =
        0.0

    cockpit_anim_the_velocity =
        0.0

    -- Breathing, sway and tremor all start from nothing, so
    -- entering AFK does not land as a step. The roll coupling
    -- needs no fade: it is driven by spring velocity, which is
    -- zero here by definition.
    cockpit_life_blend =
        0.0

    cockpit_displayed_psi =
        cockpit_anim_psi

    cockpit_displayed_the =
        cockpit_anim_the

    cockpit_displayed_phi =
        cockpit_base_head_phi

    cockpit_displayed_x = 0.0
    cockpit_displayed_y = 0.0
    cockpit_displayed_z = 0.0


    cockpit_camera_controlled = true


    -- The spring starts pulling toward the pose the user left
    -- the head in.
    cockpit_target_heading =
        cockpit_base_head_psi

    cockpit_target_pitch =
        cockpit_base_head_the


    cockpit_shot =
        "CENTER"

    current_shot =
        "CENTER"

    cockpit_shot_phase =
        "CENTER"

    cockpit_current_look =
        0

    -- Fresh session, so nothing counts as recently used.
    cockpit_look_history = {}

    cockpit_last_look =
        0

    cockpit_shot_time = 0.0

    cockpit_shot_duration =
        COCKPIT_CENTER_HOLD


    -- IMPORTANT:
    -- Do not call XPLMControlCamera() here.
    -- X-Plane's normal cockpit camera remains active.
    logMsg(
        "AFK CAMERA: "
        .. "COCKPIT DIRECTOR STARTED - "
        .. "NORMAL X-PLANE CAMERA / XPREALISTIC COMPATIBLE"
    )

end


-- ============================================================
-- STOP COCKPIT CAMERA
-- ============================================================

-- immediate = true snaps the head back this frame (plugin
-- disabled, view changed, script unloading). Otherwise the head
-- glides back over COCKPIT_RETURN_TIME.
function stop_cockpit_camera(immediate)

    if not cockpit_camera_controlled then

        -- Not directing, but possibly still gliding back.
        if immediate
        and cockpit_return_active then

            cockpit_restore_head_pose()

        end

        return

    end


    cockpit_camera_controlled = false


    -- No XPLMDontControlCamera() call here because cockpit AFK
    -- never took control of the X-Plane camera.

    if immediate
    or COCKPIT_RETURN_TIME <= 0
    or afk_view_type ~= 1026 then

        cockpit_restore_head_pose()

        logMsg(
            "AFK CAMERA: "
            .. "COCKPIT DIRECTOR STOPPED - "
            .. "VIEW RESTORED TO PRE-AFK POSE"
        )

        return

    end


    cockpit_return_active =
        true

    cockpit_return_time =
        0.0

    cockpit_return_start_psi =
        cockpit_displayed_psi

    cockpit_return_start_the =
        cockpit_displayed_the

    cockpit_return_start_phi =
        cockpit_displayed_phi

    cockpit_return_start_x =
        cockpit_displayed_x

    cockpit_return_start_y =
        cockpit_displayed_y

    cockpit_return_start_z =
        cockpit_displayed_z


    -- HOLD THE POSE FOR THIS FRAME
    --
    -- cockpit_return_update() already ran earlier in this frame,
    -- before the activity handler noticed the input, and that
    -- handler returns from the frame loop before the director
    -- would run. Without this write the pilot head goes unwritten
    -- for exactly one frame, so whatever else owns those DataRefs
    -- (XPRealistic, X-Plane's own view code) shows through for a
    -- single frame before the return animation snaps the head
    -- back and glides it home.
    --
    -- Re-writing the pose that is already on screen makes the
    -- exit frame identical to the frame before it.
    cockpit_write_head_pose(
        cockpit_return_start_psi,
        cockpit_return_start_the,
        cockpit_return_start_phi,
        cockpit_return_start_x,
        cockpit_return_start_y,
        cockpit_return_start_z
    )


    logMsg(
        "AFK CAMERA: "
        .. "COCKPIT DIRECTOR STOPPED - "
        .. "RETURNING TO PRE-AFK POSE OVER "
        .. string.format("%.2f", COCKPIT_RETURN_TIME)
        .. " S"
    )

end


-- ============================================================
-- STOP EXTERNAL CIRCLE CAMERA
-- ============================================================

function stop_external_circle_camera()

    if not external_camera_controlled then

        external_camera_ownership_lost =
            false

        return

    end

    external_camera_controlled =
        false

    external_camera_ownership_lost =
        false

    -- We still own the camera here, so releasing ownership is safe.
    XPLM.XPLMDontControlCamera()

    logMsg(
        "AFK CAMERA: EXTERNAL CIRCLE CAMERA RELEASED - "
        .. "HANDING CAMERA BACK TO XPREALISTIC/X-PLANE"
    )

end


-- ============================================================
-- UNIFIED AFK CAMERA RELEASE
-- ============================================================

function stop_afk_camera(immediate)

    stop_cockpit_camera(immediate)
    stop_external_circle_camera()

end


-- ============================================================
-- EXTERNAL CINEMATIC SHOT HELPERS
-- ============================================================

function external_prepare_shot(library, index)

    local shot =
        library[index]

    if shot == nil then
        return
    end

    external_current_library =
        library

    external_shot_index =
        index

    external_shot_phase =
        "MOVE"

    external_shot_time =
        0.0


    -- --------------------------------------------------------
    -- AIRCRAFT-SIZE SCALING
    -- --------------------------------------------------------
    --
    -- Every authored coordinate is multiplied around the
    -- aircraft CG, so the same shot frames a light single and
    -- an airliner the same way.

    external_aircraft_scale =
        get_external_aircraft_scale()

    local scale =
        external_aircraft_scale


    -- --------------------------------------------------------
    -- CAMERA PATH
    -- --------------------------------------------------------
    --
    -- HARD CUT: the camera teleports to the start of the shot.

    external_start_x = shot.from[1] * scale
    external_start_y = shot.from[2] * scale
    external_start_z = shot.from[3] * scale

    external_target_x = shot.to[1] * scale
    external_target_y = shot.to[2] * scale
    external_target_z = shot.to[3] * scale

    external_current_x = external_start_x
    external_current_y = external_start_y
    external_current_z = external_start_z


    -- --------------------------------------------------------
    -- SUBJECT
    -- --------------------------------------------------------
    --
    -- What the shot frames. Without "look" it falls back to the
    -- old fixed point above the CG. With "look_to" the framing
    -- slides across the airframe during the move, which is what
    -- turns a static stare into a tracking pan.

    local look =
        shot.look

    if look == nil then

        external_look_start_x = 0.0
        external_look_start_y = AFK_EXTERNAL_TARGET_HEIGHT * scale
        external_look_start_z = 0.0

    else

        external_look_start_x = look[1] * scale
        external_look_start_y = look[2] * scale
        external_look_start_z = look[3] * scale

    end

    local look_to =
        shot.look_to

    if look_to == nil then

        external_look_end_x = external_look_start_x
        external_look_end_y = external_look_start_y
        external_look_end_z = external_look_start_z

    else

        external_look_end_x = look_to[1] * scale
        external_look_end_y = look_to[2] * scale
        external_look_end_z = look_to[3] * scale

    end


    -- --------------------------------------------------------
    -- LENS AND FRAMING
    -- --------------------------------------------------------

    if shot.zoom == nil then

        external_zoom_start = AFK_EXTERNAL_ZOOM
        external_zoom_end = AFK_EXTERNAL_ZOOM

    else

        external_zoom_start = shot.zoom[1]
        external_zoom_end = shot.zoom[2]

    end

    -- roll takes a single angle to hold, or {start, end} to
    -- tilt slowly across the shot.
    if shot.roll == nil then

        external_roll_start = 0.0
        external_roll_end = 0.0

    elseif type(shot.roll) == "table" then

        external_roll_start = shot.roll[1]
        external_roll_end = shot.roll[2]

    else

        external_roll_start = shot.roll
        external_roll_end = shot.roll

    end


    if shot.via == nil then

        external_shot_curved = false

        external_via_x = 0.0
        external_via_y = 0.0
        external_via_z = 0.0

    else

        external_shot_curved = true

        external_via_x = shot.via[1] * scale
        external_via_y = shot.via[2] * scale
        external_via_z = shot.via[3] * scale

    end

    if shot.float == nil then
        external_shot_float = 1.0
    else
        external_shot_float = shot.float
    end

    -- --------------------------------------------------------
    -- DURATION
    -- --------------------------------------------------------
    --
    -- Every shot runs for the same fixed time.

    if external_shot_curved then

        -- ARC-LENGTH TABLE
        --
        -- A Bezier walked with an evenly increasing parameter
        -- does not travel at an even speed: it runs quicker
        -- through the bend and slower at the ends, by as much
        -- as half again on a tight curve. Measuring the curve
        -- here lets the callback ask for a distance rather than
        -- a parameter, which is what makes the move constant
        -- speed instead of merely constant in time.
        local length = 0.0

        external_arc_length[0] = 0.0

        local px = external_start_x
        local py = external_start_y
        local pz = external_start_z

        for step = 1, AFK_EXTERIOR_ARC_SAMPLES do

            local t = step / AFK_EXTERIOR_ARC_SAMPLES
            local inv = 1.0 - t

            local wa = inv * inv
            local wb = 2.0 * inv * t
            local wc = t * t

            local qx =
                wa * external_start_x
                + wb * external_via_x
                + wc * external_target_x

            local qy =
                wa * external_start_y
                + wb * external_via_y
                + wc * external_target_y

            local qz =
                wa * external_start_z
                + wb * external_via_z
                + wc * external_target_z

            local sx = qx - px
            local sy = qy - py
            local sz = qz - pz

            length =
                length
                + math.sqrt(
                    sx * sx
                    + sy * sy
                    + sz * sz
                )

            external_arc_length[step] = length

            px = qx
            py = qy
            pz = qz

        end

        external_shot_distance = length

    else

        local dx = external_target_x - external_start_x
        local dy = external_target_y - external_start_y
        local dz = external_target_z - external_start_z

        external_shot_distance =
            math.sqrt(
                dx * dx
                + dy * dy
                + dz * dz
            )

    end

    if external_shot_distance < 0.01 then
        external_shot_distance = 0.01
    end

    external_shot_duration =
        AFK_EXTERIOR_SHOT_DURATION


    current_shot =
        shot.name

    logMsg(
        "AFK CAMERA: CUT TO "
        .. (
            afk_exterior_parked
            and "PARKED"
            or "FLIGHT"
        )
        .. " SHOT "
        .. tostring(index)
        .. "/"
        .. tostring(#library)
        .. " | "
        .. shot.name
        .. " | "
        .. string.format("%.1f", external_shot_duration)
        .. " S | SIZE SCALE "
        .. string.format("%.2f", external_aircraft_scale)
    )

end


function external_advance_shot()

    -- Select the next shot from the randomized no-repeat bag.
    -- The library is re-checked here, so an aircraft that
    -- starts rolling during AFK moves to flight coverage at the
    -- next cut instead of mid-shot.
    local library, next_index =
        get_next_external_shot()

    external_prepare_shot(
        library,
        next_index
    )

end


-- ============================================================
-- EXTERNAL CINEMATIC CAMERA CALLBACK
-- ============================================================

external_camera_callback = ffi.cast(
    "XPLMCameraControl_f",
    function(
        out_camera,
        losing_control,
        refcon
    )

        if losing_control ~= 0 then

            -- X-Plane has already taken the camera back.
            -- Do not call XPLMDontControlCamera() here.
            external_camera_controlled =
                false

            external_camera_ownership_lost =
                true

            return 0

        end

        if out_camera == nil then
            return 0
        end

        if not afk_active
        or not external_camera_controlled then
            return 0
        end


        local current_time =
            os.clock()

        local delta_time =
            current_time
            - external_last_callback_time

        external_last_callback_time =
            current_time

        if delta_time < 0 then
            delta_time = 0
        end

        if delta_time > 0.1 then
            delta_time = 0.1
        end


        -- ----------------------------------------------------
        -- CAMERA MOVE
        -- ----------------------------------------------------

        external_shot_time =
            external_shot_time
            + delta_time

        external_noise_time =
            external_noise_time
            + delta_time

        local raw_progress =
            external_shot_time
            / external_shot_duration


        if raw_progress >= 1.0 then

            external_current_x = external_target_x
            external_current_y = external_target_y
            external_current_z = external_target_z

            -- Immediately prepare the next cut.
            external_advance_shot()

            raw_progress = 0.0

        end


        -- Constant speed: the fraction of the shot elapsed is
        -- used directly, with no easing applied to it.
        local progress =
            raw_progress

        if external_shot_curved then

            -- Ask the arc-length table where along the curve
            -- this much distance falls, rather than feeding the
            -- time fraction straight into the Bezier. Without
            -- this the camera accelerates through the bend.
            local curve_t =
                progress

            if external_shot_distance > 0.0001 then

                local wanted =
                    progress
                    * external_shot_distance

                local index = 1

                while index < AFK_EXTERIOR_ARC_SAMPLES
                and external_arc_length[index] < wanted do
                    index = index + 1
                end

                local behind =
                    external_arc_length[index - 1]

                local segment =
                    external_arc_length[index]
                    - behind

                local within = 0.0

                if segment > 0.0 then
                    within =
                        (wanted - behind)
                        / segment
                end

                curve_t =
                    ((index - 1) + within)
                    / AFK_EXTERIOR_ARC_SAMPLES

            end

            -- Quadratic Bezier through the control point.
            local inv = 1.0 - curve_t

            local wa = inv * inv
            local wb = 2.0 * inv * curve_t
            local wc = curve_t * curve_t

            external_current_x =
                wa * external_start_x
                + wb * external_via_x
                + wc * external_target_x

            external_current_y =
                wa * external_start_y
                + wb * external_via_y
                + wc * external_target_y

            external_current_z =
                wa * external_start_z
                + wb * external_via_z
                + wc * external_target_z

        else

            external_current_x =
                external_start_x
                + (
                    external_target_x
                    - external_start_x
                ) * progress

            external_current_y =
                external_start_y
                + (
                    external_target_y
                    - external_start_y
                ) * progress

            external_current_z =
                external_start_z
                + (
                    external_target_z
                    - external_start_z
                ) * progress

        end


        -- ----------------------------------------------------
        -- CAMERA FLOAT
        -- ----------------------------------------------------
        --
        -- A slow, aperiodic drift on the camera body. Nothing
        -- here is meant to be noticed on its own; it is what
        -- stops a move looking like it is on rails.

        local float_amount =
            external_shot_float

        if float_amount > 0.0 then

            local t =
                external_noise_time

            local position_float =
                AFK_EXTERIOR_FLOAT_POS
                * external_aircraft_scale
                * float_amount

            external_current_x =
                external_current_x
                + cockpit_wave(t, 0.82, 1.32, 2.32, 19)
                * position_float

            external_current_y =
                external_current_y
                + cockpit_wave(t, 0.71, 1.17, 2.05, 22)
                * position_float

            external_current_z =
                external_current_z
                + cockpit_wave(t, 0.93, 1.51, 2.11, 25)
                * position_float

        end


        -- ----------------------------------------------------
        -- Aircraft-relative -> world
        -- ----------------------------------------------------
        --
        -- Follow aircraft heading only so the exterior camera
        -- stays level and does not inherit pitch/roll.

        local heading_radians =
            afk_plane_heading
            * math.pi
            / 180.0

        local camera_offset_x =
            external_current_x
            * math.cos(
                heading_radians
            )
            - external_current_z
            * math.sin(
                heading_radians
            )

        local camera_offset_z =
            external_current_z
            * math.cos(
                heading_radians
            )
            + external_current_x
            * math.sin(
                heading_radians
            )

        out_camera.x =
            afk_plane_local_x
            + camera_offset_x

        out_camera.y =
            afk_plane_local_y
            + external_current_y

        out_camera.z =
            afk_plane_local_z
            + camera_offset_z


        -- ----------------------------------------------------
        -- KEEP THE CAMERA ABOVE THE GROUND
        -- ----------------------------------------------------
        --
        -- Runs before the aim is worked out, so the framing
        -- follows the camera that is actually used rather than
        -- the one underground.

        local ground_y =
            afk_plane_local_y
            - (tonumber(afk_plane_y_agl) or 0.0)

        local lowest_camera_y =
            ground_y
            + AFK_EXTERIOR_GROUND_CLEARANCE
            * external_aircraft_scale

        if out_camera.y < lowest_camera_y then
            out_camera.y = lowest_camera_y
        end


        -- ----------------------------------------------------
        -- Aim at the subject
        -- ----------------------------------------------------
        --
        -- The subject is a point attached to the airframe, so
        -- while the aircraft pitches or banks the camera keeps
        -- framing the same physical spot rather than a point in
        -- the world. When the shot names a second subject the
        -- framing slides between them as the move runs.

        local look_x =
            external_look_start_x
            + (
                external_look_end_x
                - external_look_start_x
            ) * progress

        local look_y =
            external_look_start_y
            + (
                external_look_end_y
                - external_look_start_y
            ) * progress

        local look_z =
            external_look_start_z
            + (
                external_look_end_z
                - external_look_start_z
            ) * progress


        local target_offset_x,
              target_offset_y,
              target_offset_z =
            cockpit_aircraft_to_world(
                look_x,
                look_y,
                look_z,
                afk_plane_pitch,
                afk_plane_roll,
                afk_plane_heading
            )

        local target_x =
            afk_plane_local_x
            + target_offset_x

        local target_y =
            afk_plane_local_y
            + target_offset_y

        local target_z =
            afk_plane_local_z
            + target_offset_z

        local to_target_x =
            target_x
            - out_camera.x

        local to_target_y =
            target_y
            - out_camera.y

        local to_target_z =
            target_z
            - out_camera.z

        local horizontal_distance =
            math.sqrt(
                to_target_x * to_target_x
                + to_target_z * to_target_z
            )

        if horizontal_distance < 0.1 then
            horizontal_distance = 0.1
        end

        local camera_heading =
            math.deg(
                math.atan2(
                    to_target_x,
                    -to_target_z
                )
            )

        local camera_pitch =
            math.deg(
                math.atan2(
                    to_target_y,
                    horizontal_distance
                )
            )


        -- ----------------------------------------------------
        -- Lens, dutch angle and angular float
        -- ----------------------------------------------------

        if float_amount > 0.0 then

            local t =
                external_noise_time

            local angle_float =
                AFK_EXTERIOR_FLOAT_ANGLE
                * float_amount

            camera_heading =
                camera_heading
                + cockpit_wave(t, 0.61, 1.03, 1.79, 28)
                * angle_float

            camera_pitch =
                camera_pitch
                + cockpit_wave(t, 0.57, 0.99, 1.71, 31)
                * angle_float

        end

        out_camera.heading =
            camera_heading

        out_camera.pitch =
            camera_pitch

        out_camera.roll =
            external_roll_start
            + (
                external_roll_end
                - external_roll_start
            ) * progress

        out_camera.zoom =
            external_zoom_start
            + (
                external_zoom_end
                - external_zoom_start
            ) * progress

        return 1

    end
)


-- ============================================================
-- START EXTERNAL CINEMATIC CAMERA
-- ============================================================

function start_external_circle_camera()

    if external_camera_controlled then
        return
    end

    if external_circle_command == nil then
        logMsg(
            "AFK CAMERA: CANNOT START EXTERNAL CINEMATIC - "
            .. "CIRCLE COMMAND NOT FOUND"
        )
        return
    end

    -- XPLMCommandOnce dispatches synchronously, so the hooked
    -- handler runs and returns inside this call.
    afk_view_command_internal =
        true

    XPLM.XPLMCommandOnce(
        external_circle_command
    )

    afk_view_command_internal =
        false

    external_camera_ownership_lost =
        false

    external_last_callback_time =
        os.clock()

    external_camera_controlled =
        true

    -- First shot is also selected from the randomized no-repeat
    -- bag, from whichever library matches the aircraft's state.
    local library, first_index =
        get_next_external_shot()

    external_prepare_shot(
        library,
        first_index
    )

    XPLM.XPLMControlCamera(
        AFK_CAMERA_CONTROL_DURATION,
        external_camera_callback,
        nil
    )

    logMsg(
        "AFK CAMERA: EXTERNAL CINEMATIC "
        .. "CENTERED RANDOM NO-REPEAT SHOTS STARTED"
    )

end


-- ============================================================
-- ENTER AFK
-- ============================================================

function enter_afk()

    if afk_active then
        return
    end

    -- IMPORTANT:
    -- Capture the player's actual view BEFORE starting any camera
    -- command. This prevents cockpit AFK from being redirected to
    -- the external cinematic camera.
    update_director_mode()

    afk_entry_view_type =
        afk_view_type

    afk_active = true
    afk_status = "AFK"
    last_activity = "AFK Started"

    if director_mode == "COCKPIT" then

        current_shot = "CENTER"
        start_cockpit_camera()

        logMsg(
            "AFK CAMERA: ENTERED AFK MODE | "
            .. "COCKPIT DIRECTOR"
        )

    elseif director_mode == "EXTERNAL" then

        current_shot = "EXTERNAL CINEMATIC"
        start_external_circle_camera()

        logMsg(
            "AFK CAMERA: ENTERED AFK MODE | "
            .. "EXTERNAL CINEMATIC"
        )

    else

        current_shot = "NONE"

        logMsg(
            "AFK CAMERA: ENTERED AFK MODE | "
            .. "NO CAMERA CONTROL | VIEW TYPE "
            .. tostring(afk_view_type)
        )

    end

end


-- ============================================================
-- SETTINGS UI
-- ============================================================

local afk_settings_wnd = nil

local afk_settings_save_message =
    ""

local afk_settings_save_message_time =
    0.0


function afk_settings_show_wnd()

    if not SUPPORTS_FLOATING_WINDOWS then

        logMsg(
            "AFK CAMERA: IMGUI/FLOATING WINDOWS "
            .. "ARE NOT SUPPORTED BY THIS FLYWITHLUA VERSION"
        )

        return

    end


    if afk_settings_wnd
       and float_wnd_get_visible(
           afk_settings_wnd
       ) then

        float_wnd_bring_to_front(
            afk_settings_wnd
        )

        return

    end


    afk_settings_wnd =
        float_wnd_create(
            480,
            720,
            1,
            true
        )

    float_wnd_set_title(
        afk_settings_wnd,
        "AFK Camera Settings"
    )

    float_wnd_set_imgui_builder(
        afk_settings_wnd,
        "afk_settings_on_build"
    )

    float_wnd_set_onclose(
        afk_settings_wnd,
        "afk_settings_on_close"
    )

end


function afk_settings_hide_wnd()

    if afk_settings_wnd then

        float_wnd_destroy(
            afk_settings_wnd
        )

        afk_settings_wnd =
            nil

    end

end


function afk_settings_toggle_wnd()

    if afk_settings_wnd
       and float_wnd_get_visible(
           afk_settings_wnd
       ) then

        afk_settings_hide_wnd()

    else

        afk_settings_show_wnd()

    end

end


function afk_settings_on_close(wnd)

    -- The FlyWithLua close callback must not use the window
    -- handle after the callback. We only clear our Lua reference.
    afk_settings_wnd =
        nil

end


-- ============================================================
-- UPDATE CHECK
-- ============================================================
--
-- The sim must never stall waiting on a network call, so
-- nothing here blocks. curl is started detached and writes the
-- answer to a file; the frame loop then watches for that file
-- to appear. If the network is down or the site is gone, the
-- only consequence is that the file never arrives and the
-- check times out quietly.
--
-- curl is used rather than the bundled LuaSocket because the
-- site is HTTPS and no TLS module ships with FlyWithLua.
-- Windows has included curl since Windows 10 1803, and it is
-- built with Schannel, so HTTPS works with no extra files.

function afk_update_spawn(command)

    local startup =
        ffi.new("AFK_STARTUPINFOA")

    ffi.fill(
        startup,
        ffi.sizeof("AFK_STARTUPINFOA")
    )

    startup.cb =
        ffi.sizeof("AFK_STARTUPINFOA")

    local process =
        ffi.new("AFK_PROCESS_INFORMATION")

    -- CreateProcess is allowed to write into the command line,
    -- so it has to be a mutable buffer and not a Lua string.
    local buffer =
        ffi.new("char[?]", #command + 1)

    ffi.copy(buffer, command)

    -- 0x08000000 is CREATE_NO_WINDOW.
    local kernel32 =
        AFK_UPDATE.kernel32

    local created =
        kernel32.CreateProcessA(
            nil,
            buffer,
            nil,
            nil,
            0,
            0x08000000,
            nil,
            nil,
            startup,
            process
        )

    if created == 0 then
        return false
    end

    -- Nothing here waits on curl, so both handles are closed
    -- straight away. Holding them would leak one pair of
    -- handles per check.
    kernel32.CloseHandle(process.hProcess)
    kernel32.CloseHandle(process.hThread)

    return true

end


-- Compares dotted version strings a digit group at a time, so
-- 1.10.0 correctly beats 1.9.0 where a plain string compare
-- would not. Missing groups count as zero.
function afk_version_is_newer(candidate, installed)

    local function groups(value)

        local list = {}

        for number in tostring(value):gmatch("%d+") do
            list[#list + 1] = tonumber(number)
        end

        return list

    end

    local a = groups(candidate)
    local b = groups(installed)

    local count = #a

    if #b > count then
        count = #b
    end

    for i = 1, count do

        local x = a[i] or 0
        local y = b[i] or 0

        if x > y then
            return true
        end

        if x < y then
            return false
        end

    end

    return false

end


-- Shows a version in the one-decimal style used for releases,
-- so "1.1.0" from the site reads as "1.1". Display only: the
-- comparison above still uses the full value.
function afk_version_display(value)

    local major, minor =
        tostring(value):match("(%d+)%.?(%d*)")

    if major == nil then
        return tostring(value)
    end

    if minor == "" then
        minor = "0"
    end

    return major .. "." .. minor

end


-- Returns true once the check has reached a conclusion, good
-- or bad, and polling should stop.
--
-- A half-written file is retried on the next poll. That is
-- safer here than it looks: the balanced-brace match below
-- cannot complete on a truncated release entry, so a partial
-- download simply finds nothing and waits.
--
-- A reply that has stopped growing but still holds no version
-- is a different thing, and worth saying plainly. Vercel
-- answers unknown paths with the site's own HTML and a 200
-- rather than a 404, so a file that is not actually published
-- arrives looking like a perfectly successful download.
function afk_update_read_response()

    local file =
        io.open(AFK_UPDATE.file, "rb")

    if not file then
        return false
    end

    local content =
        file:read("*a") or ""

    file:close()


    -- %b{} matches from a brace to the one that balances it,
    -- which walks the array one release at a time. The entries
    -- hold arrays of strings but no nested objects, so every
    -- match is exactly one release.
    local version
    local summary
    local download

    local first_version
    local first_summary
    local first_download

    for object in content:gmatch("%b{}") do

        local object_version =
            object:match('"version"%s*:%s*"([^"]*)"')

        if object_version ~= nil then

            -- A download page is preferred over the raw
            -- release link, being the friendlier landing spot.
            local object_download =
                object:match('"downloadPage"%s*:%s*"([^"]*)"')
                or object:match('"latestRelease"%s*:%s*"([^"]*)"')

            if first_version == nil then

                first_version = object_version

                first_summary =
                    object:match('"summary"%s*:%s*"([^"]*)"')

                first_download = object_download

            end

            if object:match('"latest"%s*:%s*true') then

                version = object_version

                summary =
                    object:match('"summary"%s*:%s*"([^"]*)"')

                download = object_download

                break

            end

        end

    end

    -- Nothing claimed to be the latest, which is the normal
    -- case for the single-release endpoint, so take the first.
    if version == nil then
        version = first_version
        summary = first_summary
        download = first_download
    end


    if version == nil
    or version == "" then

        if #content > 0
        and #content == AFK_UPDATE.last_size then

            AFK_UPDATE.state = "failed"

            AFK_UPDATE.message =
                "No version information at that address."

            logMsg(
                "AFK CAMERA: UPDATE CHECK - "
                .. "REPLY HELD NO VERSION ("
                .. tostring(#content)
                .. " BYTES FROM "
                .. AFK_UPDATE.url
                .. ")"
            )

            return true

        end

        AFK_UPDATE.last_size = #content

        return false

    end


    AFK_UPDATE.latest =
        afk_version_display(version)

    AFK_UPDATE.download =
        download or AFK_UPDATE.page

    if afk_version_is_newer(version, AFK_CAMERA_VERSION) then

        AFK_UPDATE.state = "available"

        AFK_UPDATE.message =
            "Update available: "
            .. AFK_UPDATE.latest

        if summary ~= nil
        and summary ~= "" then

            AFK_UPDATE.message =
                AFK_UPDATE.message
                .. " - "
                .. summary

        end

    else

        AFK_UPDATE.state = "current"

        AFK_UPDATE.message =
            "Up to date."

    end

    logMsg(
        "AFK CAMERA: UPDATE CHECK | INSTALLED "
        .. afk_version_display(AFK_CAMERA_VERSION)
        .. " | LATEST "
        .. AFK_UPDATE.latest
        .. " | "
        .. AFK_UPDATE.state:upper()
    )

    return true

end


function afk_update_start()

    if AFK_UPDATE.state == "checking" then
        return
    end

    -- A stale answer from a previous check would be read back
    -- immediately and look like a fresh one.
    os.remove(AFK_UPDATE.file)

    local command =
        "curl.exe -s -f -L --max-time 10 -o \""
        .. AFK_UPDATE.file
        .. "\" \""
        .. AFK_UPDATE.url
        .. "\""

    if not afk_update_spawn(command) then

        AFK_UPDATE.state = "failed"

        AFK_UPDATE.message =
            "Could not start curl.exe."

        logMsg(
            "AFK CAMERA: UPDATE CHECK FAILED - "
            .. "COULD NOT START CURL"
        )

        return

    end

    AFK_UPDATE.state = "checking"
    AFK_UPDATE.message = ""
    AFK_UPDATE.latest = ""
    AFK_UPDATE.download = ""
    AFK_UPDATE.last_size = -1
    AFK_UPDATE.started = os.clock()
    AFK_UPDATE.next_poll = AFK_UPDATE.started + 0.5

    logMsg(
        "AFK CAMERA: CHECKING FOR UPDATES AT "
        .. AFK_UPDATE.url
    )

end


-- Opens the download page in the default browser.
--
-- The address comes from the network, and ShellExecute will
-- happily run a program if handed a path to one, so only a
-- plain https web address is ever passed through. Anything else
-- falls back to the hard-coded site.
function afk_update_open_download()

    local url =
        AFK_UPDATE.download

    if type(url) ~= "string"
    or not url:match("^https://[%w%-%._~:/%?#%[%]@!%$&'%(%)%*%+,;=%%]+$") then

        url = AFK_UPDATE.page

    end

    -- 1 is SW_SHOWNORMAL.
    local result =
        AFK_UPDATE.shell32.ShellExecuteA(
            nil,
            "open",
            url,
            nil,
            nil,
            1
        )

    -- ShellExecute reports success as any value above 32.
    local opened =
        tonumber(ffi.cast("intptr_t", result)) > 32

    if opened then

        AFK_UPDATE.message =
            "Download page opened in your browser."

    else

        AFK_UPDATE.message =
            "Could not open the browser. Visit: "
            .. url

    end

    logMsg(
        "AFK CAMERA: DOWNLOAD PAGE "
        .. (opened and "OPENED" or "FAILED TO OPEN")
        .. " - "
        .. url
    )

end


-- Runs every frame and costs one comparison unless a check is
-- actually in flight.
function afk_update_poll()

    if AFK_UPDATE.state ~= "checking" then
        return
    end

    local now = os.clock()

    if now < AFK_UPDATE.next_poll then
        return
    end

    AFK_UPDATE.next_poll = now + 0.5

    if afk_update_read_response() then
        return
    end

    if now - AFK_UPDATE.started > AFK_UPDATE.timeout then

        AFK_UPDATE.state = "failed"

        AFK_UPDATE.message =
            "Could not reach the update server."

        logMsg(
            "AFK CAMERA: UPDATE CHECK TIMED OUT"
        )

    end

end


-- ============================================================
-- SETTINGS PANEL LAYOUT
-- ============================================================
--
-- Grouped so the panel can be read rather than scanned: each
-- block is one heading, its controls, and at most a couple of
-- lines saying what they do. Separators mark the boundaries.
--
--   1  ON / OFF and what the camera is doing right now
--   2  HOW AFK STARTS   entry mode, timer, manual bind
--   3  COCKPIT VIEW     head movement size and speed
--   4  WAKE-UP INPUTS   what ends AFK
--   5  DISPLAY          debug HUD
--   6  UPDATES          installed version, check button
--   7  Save / Restore / Close
--
-- Only imgui calls already proven to work in this FlyWithLua
-- build are used here: TextUnformatted, Separator, Checkbox,
-- SliderFloat, Button and SameLine. A call this build does not
-- bind would throw every frame the window is open, so tabs and
-- collapsing headers are deliberately avoided.

function afk_settings_group(title)

    imgui.TextUnformatted("")
    imgui.Separator()
    imgui.TextUnformatted("")
    imgui.TextUnformatted(title)
    imgui.TextUnformatted("")

end


function afk_settings_on_build(wnd, x, y)

    -- --------------------------------------------------------
    -- 1. ON / OFF AND CURRENT STATE
    -- --------------------------------------------------------

    imgui.TextUnformatted(
        "AFK CAMERA"
    )

    imgui.TextUnformatted(
        "Automatic cinematic camera after inactivity."
    )

    imgui.TextUnformatted("")


    local changed, new_enabled =
        imgui.Checkbox(
            "Enable AFK Camera",
            afk_enabled
        )

    if changed then

        afk_enabled =
            new_enabled

        idle_time =
            0.0

        if not afk_enabled then

            -- Disabling the plugin must immediately release
            -- any camera control and stop the AFK state.
            if afk_active then

                afk_active =
                    false

                afk_status =
                    "DISABLED"

                current_shot =
                    "NONE"

                stop_afk_camera()

                last_activity =
                    "Plugin disabled"

            else

                afk_status =
                    "DISABLED"

            end

        else

            afk_status =
                "ACTIVE"

            last_activity =
                "Plugin enabled"

        end

        logMsg(
            "AFK CAMERA: "
            .. (
                afk_enabled
                and "ENABLED"
                or "DISABLED"
            )
        )

    end


    imgui.TextUnformatted(
        "Status: "
        .. (
            afk_enabled
            and (
                afk_active
                and "AFK"
                or "ACTIVE"
            )
            or "DISABLED"
        )
        .. "    Last input: "
        .. tostring(
            last_activity
        )
    )


    -- --------------------------------------------------------
    -- 2. HOW AFK STARTS
    -- --------------------------------------------------------

    afk_settings_group("HOW AFK STARTS")

    local auto_changed, new_auto_entry =
        imgui.Checkbox(
            "Automatic (idle timer)",
            afk_auto_entry
        )

    if auto_changed then

        afk_auto_entry =
            new_auto_entry

        idle_time =
            0.0

        logMsg(
            "AFK CAMERA: AFK ENTRY SET TO "
            .. (
                afk_auto_entry
                and "AUTOMATIC"
                or "MANUAL"
            )
        )

    end


    local timeout_changed, new_timeout =
        imgui.SliderFloat(
            "Seconds of inactivity",
            AFK_TIMEOUT,
            AFK_TIMEOUT_MIN,
            AFK_TIMEOUT_MAX,
            "%.0f s"
        )

    if timeout_changed then

        AFK_TIMEOUT =
            clamp_afk_timeout(
                new_timeout
            )

    end


    if afk_auto_entry then

        imgui.TextUnformatted(
            "AFK starts on its own after "
            .. string.format(
                "%.0f",
                AFK_TIMEOUT
            )
            .. " seconds idle."
        )

    else

        imgui.TextUnformatted(
            "Manual only. The timer above is not used."
        )

    end


    imgui.TextUnformatted("")

    imgui.TextUnformatted(
        "Manual trigger, works in either mode:"
    )

    imgui.TextUnformatted(
        "  bind any key, mouse or joystick button to"
    )

    imgui.TextUnformatted(
        "  \"AFK Camera: start/stop AFK now\""
    )

    imgui.TextUnformatted(
        "  in X-Plane > Settings > Keyboard or Joystick."
    )


    -- --------------------------------------------------------
    -- 3. COCKPIT VIEW
    -- --------------------------------------------------------

    afk_settings_group("COCKPIT VIEW")

    local size_changed, new_head_size =
        imgui.SliderFloat(
            "Movement size",
            afk_head_size,
            AFK_HEAD_SIZE_MIN,
            AFK_HEAD_SIZE_MAX,
            "%.0f %%"
        )

    if size_changed then

        afk_head_size =
            clamp_afk_percent(
                new_head_size,
                AFK_HEAD_SIZE_MIN,
                AFK_HEAD_SIZE_MAX,
                DEFAULT_AFK_HEAD_SIZE
            )

    end

    local speed_changed, new_head_speed =
        imgui.SliderFloat(
            "Movement speed",
            afk_head_speed,
            AFK_HEAD_SPEED_MIN,
            AFK_HEAD_SPEED_MAX,
            "%.0f %%"
        )

    if speed_changed then

        afk_head_speed =
            clamp_afk_percent(
                new_head_speed,
                AFK_HEAD_SPEED_MIN,
                AFK_HEAD_SPEED_MAX,
                DEFAULT_AFK_HEAD_SPEED
            )

    end

    imgui.TextUnformatted(
        "How far the pilot's head turns, and how"
    )

    imgui.TextUnformatted(
        "quickly. 100% is the tuned default."
    )

    if afk_head_size <= 45.0 then

        imgui.TextUnformatted(
            "At this size the head only hints toward"
        )

        imgui.TextUnformatted(
            "the overhead panel and pedestal."
        )

    end


    -- --------------------------------------------------------
    -- 4. WAKE-UP INPUTS
    -- --------------------------------------------------------

    afk_settings_group("WAKE-UP INPUTS")

    imgui.TextUnformatted(
        "Keys, buttons and joystick axes always end AFK."
    )

    imgui.TextUnformatted("")

    local mouse_move_changed, new_mouse_move =
        imgui.Checkbox(
            "Mouse movement ends AFK",
            afk_mouse_move_return
        )

    if mouse_move_changed then

        afk_mouse_move_return =
            new_mouse_move

        logMsg(
            "AFK CAMERA: MOUSE MOVEMENT WAKE-UP "
            .. (
                afk_mouse_move_return
                and "ENABLED"
                or "DISABLED"
            )
        )

    end

    local deadzone_changed, new_deadzone =
        imgui.SliderFloat(
            "Joystick dead zone",
            afk_joystick_deadzone,
            AFK_JOYSTICK_DEADZONE_MIN,
            AFK_JOYSTICK_DEADZONE_MAX,
            "%.1f %%"
        )

    if deadzone_changed then

        afk_joystick_deadzone =
            clamp_afk_percent(
                new_deadzone,
                AFK_JOYSTICK_DEADZONE_MIN,
                AFK_JOYSTICK_DEADZONE_MAX,
                DEFAULT_AFK_JOYSTICK_DEADZONE
            )

    end

    -- Live jitter readout. Leave the stick alone and set the
    -- dead zone just above the number shown here.
    imgui.TextUnformatted(
        "Axis movement right now: "
        .. string.format(
            "%.2f",
            joystick_last_max_difference
            * 100.0
        )
        .. " %"
    )

    imgui.TextUnformatted(
        "Set the dead zone just above that number so"
    )

    imgui.TextUnformatted(
        "an idle stick's jitter does not end AFK."
    )


    -- --------------------------------------------------------
    -- 5. DISPLAY
    -- --------------------------------------------------------

    afk_settings_group("DISPLAY")

    local debug_changed, new_debug_visible =
        imgui.Checkbox(
            "Show Debug HUD",
            afk_debug_hud_visible
        )

    if debug_changed then

        afk_set_debug_hud_visible(
            new_debug_visible
        )

    end


    -- --------------------------------------------------------
    -- 6. UPDATES
    -- --------------------------------------------------------

    afk_settings_group("UPDATES")

    imgui.TextUnformatted(
        "Installed version: "
        .. afk_version_display(AFK_CAMERA_VERSION)
    )

    if AFK_UPDATE.state == "checking" then

        imgui.TextUnformatted(
            "Checking ..."
        )

    else

        if imgui.Button(
            "Check for updates",
            190,
            28
        ) then

            afk_update_start()

        end

    end

    if AFK_UPDATE.message ~= "" then

        imgui.TextUnformatted(
            AFK_UPDATE.message
        )

    end

    if AFK_UPDATE.state == "available" then

        if imgui.Button(
            "Download " .. AFK_UPDATE.latest,
            190,
            28
        ) then

            afk_update_open_download()

        end

        imgui.TextUnformatted(
            AFK_UPDATE.download
        )

    end


    -- --------------------------------------------------------
    -- 7. SAVE / RESTORE / CLOSE
    -- --------------------------------------------------------

    imgui.TextUnformatted("")
    imgui.Separator()
    imgui.TextUnformatted("")

    if imgui.Button(
        "Save Settings",
        150,
        32
    ) then

        if save_afk_settings() then

            afk_settings_save_message =
                "Settings saved."

            afk_settings_save_message_time =
                os.clock()

        else

            afk_settings_save_message =
                "Could not save settings."

            afk_settings_save_message_time =
                os.clock()

        end

    end


    imgui.SameLine()


    if imgui.Button(
        "Restore Defaults",
        150,
        32
    ) then

        restore_afk_defaults()

        -- Make the reset persistent immediately, so the restored
        -- values become the settings loaded on the next X-Plane run.
        if save_afk_settings() then

            afk_settings_save_message =
                "Defaults restored and saved."

        else

            afk_settings_save_message =
                "Defaults restored, but could not save."

        end

        afk_settings_save_message_time =
            os.clock()

    end


    imgui.SameLine()


    if imgui.Button(
        "Close",
        100,
        32
    ) then

        afk_settings_hide_wnd()

    end


    if afk_settings_save_message ~= ""
       and (
            os.clock()
            - afk_settings_save_message_time
       ) < 3.0 then

        imgui.TextUnformatted(
            afk_settings_save_message
        )

    end

end


-- ============================================================
-- FLYWITHLUA SHUTDOWN / RELOAD CLEANUP
-- ============================================================
--
-- IMPORTANT:
-- FlyWithLua stores do_on_exit() as Lua code text and executes it
-- during script shutdown/reload. Local variables are not directly
-- visible to that code text.
--
-- Therefore the actual cleanup lives in this GLOBAL function.
-- Because this function is a closure, it still has access to the
-- script's local callback handles/state when FlyWithLua executes it.
--
-- This is especially important for:
--   * XPLM key sniffer callback
--   * XPLM external camera callback
--   * floating settings window callbacks
--
-- Leaving one of those native callbacks registered against an
-- unloaded Lua state can make the next keyboard/view event jump
-- into invalid memory and crash X-Plane.

function afk_camera_shutdown_cleanup()

    logMsg(
        "AFK CAMERA: SHUTDOWN / RELOAD CLEANUP START"
    )


    -- --------------------------------------------------------
    -- Close the settings window before the Lua state disappears.
    -- --------------------------------------------------------

    if afk_settings_wnd then

        float_wnd_destroy(
            afk_settings_wnd
        )

        afk_settings_wnd =
            nil

    end


    -- --------------------------------------------------------
    -- Release external XPLM camera ownership.
    -- --------------------------------------------------------

    if external_camera_controlled then

        external_camera_controlled =
            false

        external_camera_ownership_lost =
            false

        -- We still own the camera here, therefore releasing it is
        -- valid and prevents the old FFI camera callback from being
        -- called after the Lua state is torn down.
        XPLM.XPLMDontControlCamera()

    else

        external_camera_ownership_lost =
            false

    end


    -- --------------------------------------------------------
    -- Restore the pilot-head pose used by the normal X-Plane
    -- cockpit camera.
    -- --------------------------------------------------------

    if cockpit_camera_controlled
    or cockpit_return_active then

        cockpit_restore_head_pose()

        cockpit_camera_controlled =
            false

    end


    -- --------------------------------------------------------
    -- Unregister the native keyboard sniffer.
    -- --------------------------------------------------------

    if keyboard_sniffer_result == 1 then

        XPLM.XPLMUnregisterKeySniffer(
            keyboard_callback,
            0,
            nil
        )

        keyboard_sniffer_result =
            0

    end


    -- --------------------------------------------------------
    -- Unregister the view command handlers.
    -- --------------------------------------------------------
    --
    -- Same hazard as the key sniffer: a handler still attached
    -- to an unloaded Lua state turns the next view keypress
    -- into a jump through invalid memory.

    for i = 1, #afk_view_command_refs do

        XPLM.XPLMUnregisterCommandHandler(
            afk_view_command_refs[i],
            afk_view_command_callback,
            1,
            nil
        )

    end

    afk_view_command_refs = {}


    afk_active =
        false

    afk_entry_view_type =
        nil

    logMsg(
        "AFK CAMERA: SHUTDOWN / RELOAD CLEANUP COMPLETE"
    )

end


do_on_exit(
    "afk_camera_shutdown_cleanup()"
)

-- Use a one-shot macro for opening the settings window.
-- This keeps the FlyWithLua menu item from remaining checked
-- after the window is closed with its X button.
add_macro(
    "AFK Camera: Open Settings",
    "afk_settings_show_wnd()"
)


create_command(
    "AFKCamera/settings_toggle",
    "Open/close AFK Camera settings",
    "afk_settings_toggle_wnd()",
    "",
    ""
)


-- ============================================================
-- MANUAL TRIGGER
-- ============================================================

function afk_begin_input_grace()

    local now =
        os.clock()

    afk_input_grace_until =
        now + AFK_MANUAL_GRACE

    afk_input_grace_limit =
        now + AFK_MANUAL_GRACE_MAX

end


function afk_input_grace_active()

    if afk_input_grace_until <= 0.0 then
        return false
    end

    local now =
        os.clock()

    -- os.clock() can be stepped backwards by the OS. Treat that
    -- as the window having expired rather than leaving AFK
    -- stuck ignoring input.
    if now >= afk_input_grace_until
    or now >= afk_input_grace_limit
    or now < afk_input_grace_limit - AFK_MANUAL_GRACE_MAX then

        afk_input_grace_until =
            0.0

        return false

    end

    return true

end


-- Swallow one frame of input. Every handler tests its own flag
-- first, so clearing the flags makes the whole activity chain
-- fall through without any of them firing.
function afk_clear_input_flags()

    local any_input =
        keyboard_input_detected
        or mouse_input_detected
        or right_mouse_input_detected
        or mouse_move_input_detected
        or mouse_yoke_input_detected
        or better_mouse_yoke_input_detected
        or joystick_input_detected

    keyboard_input_detected = false
    mouse_input_detected = false
    right_mouse_input_detected = false
    mouse_move_input_detected = false
    mouse_yoke_input_detected = false
    better_mouse_yoke_input_detected = false
    joystick_input_detected = false


    -- Still held: push the window out so releasing the control
    -- does not read as a fresh wake-up.
    if any_input then

        local extended =
            os.clock()
            + AFK_MANUAL_GRACE_TAIL

        if extended > afk_input_grace_limit then
            extended = afk_input_grace_limit
        end

        if extended > afk_input_grace_until then

            afk_input_grace_until =
                extended

        end

    end

end


-- Bind this command to any key, mouse button, joystick button
-- or controller button in X-Plane's own settings. It toggles,
-- so the same control starts and stops AFK.
--
-- This only records the request. See afk_process_manual_request.
function afk_manual_trigger()

    afk_manual_request =
        true

end


function afk_process_manual_request()

    if not afk_manual_request then
        return
    end

    afk_manual_request =
        false


    if not afk_enabled then

        logMsg(
            "AFK CAMERA: MANUAL TRIGGER IGNORED - "
            .. "PLUGIN DISABLED"
        )

        return

    end


    if afk_active then

        afk_active =
            false

        afk_status =
            "ACTIVE"

        current_shot =
            "NONE"

        afk_entry_view_type =
            nil

        idle_time =
            0.0

        last_activity =
            "Manual trigger"

        afk_input_grace_until =
            0.0

        stop_afk_camera()

        logMsg(
            "AFK CAMERA: EXITED AFK MODE - MANUAL TRIGGER"
        )

        return

    end


    idle_time =
        0.0

    last_activity =
        "Manual trigger"

    enter_afk()

    -- The control that just fired this is almost certainly
    -- still down. Ignore it rather than instantly waking up.
    afk_begin_input_grace()

end


create_command(
    "AFKCamera/trigger_afk",
    "AFK Camera: start/stop AFK now",
    "afk_manual_trigger()",
    "",
    ""
)


-- ============================================================
-- LEAVING AFK BY CHANGING VIEW
-- ============================================================
--
-- The cockpit director works by displacing the pilot's head.
-- X-Plane treats a displaced head as a view the user has panned
-- away from, so the first press of a view key is spent
-- recentring it and only the second actually changes view.
--
-- Watching for the keypress is too late to help: the key
-- sniffer only sets a flag, which the frame loop reads after
-- X-Plane has already dealt with the command, by which point
-- the first press is gone.
--
-- Registering on the view commands themselves with inBefore
-- set fixes it properly. The handler runs BEFORE X-Plane acts,
-- puts the head straight back where the user left it, and
-- returns 1 so the command carries on as normal. X-Plane then
-- sees a centred head and changes view on the first press.
--
-- It also makes view changes end AFK the same way whatever
-- they came from, since a keyboard key, a HOTAS button and a
-- menu click all arrive here as the same command.

local AFK_VIEW_COMMANDS = {
    "sim/view/forward_with_hud",
    "sim/view/forward_with_2d_panel",
    "sim/view/forward_with_nothing",
    "sim/view/forward_with_panel",
    "sim/view/3d_cockpit_cmnd_look",
    "sim/view/default_view",
    "sim/view/chase",
    "sim/view/circle",
    "sim/view/still_spot",
    "sim/view/linear_spot",
    "sim/view/runway",
    "sim/view/tower",
    "sim/view/ridealong",
    "sim/view/track_weapon",
    "sim/view/free_camera",
    "sim/view/quick_look_0",
    "sim/view/quick_look_1",
    "sim/view/quick_look_2",
    "sim/view/quick_look_3",
    "sim/view/quick_look_4",
    "sim/view/quick_look_5",
    "sim/view/quick_look_6",
    "sim/view/quick_look_7",
    "sim/view/quick_look_8",
    "sim/view/quick_look_9"
}

function afk_exit_for_view_command()

    -- Our own sim/view/circle, not the user changing view.
    if afk_view_command_internal then
        return
    end

    if not afk_active then
        return
    end

    afk_active =
        false

    afk_status =
        "ACTIVE"

    current_shot =
        "NONE"

    afk_entry_view_type =
        nil

    idle_time =
        0.0

    last_activity =
        "View changed"

    -- Snap rather than glide. X-Plane is about to act on this
    -- command and has to see the head already centred, so there
    -- is no time for the usual return animation.
    stop_cockpit_camera(true)

    -- The exterior camera is deliberately not released here.
    -- Giving up camera ownership belongs in the frame loop and
    -- in X-Plane's own losing-control callback, which fires as
    -- soon as the view actually changes.

    logMsg(
        "AFK CAMERA: EXITED AFK MODE - VIEW COMMAND"
    )

end


afk_view_command_callback = ffi.cast(
    "XPLMCommandCallback_f",
    function(command, phase, refcon)

        -- Phase 0 is the press. Ignore the hold and the release.
        if phase == 0 then
            afk_exit_for_view_command()
        end

        -- 1 lets the command continue to X-Plane.
        return 1

    end
)


-- Inside a function on purpose. A loop at the top level puts
-- its counter and body locals on the main chunk, which is
-- already at Lua's 200 local limit; one more and the script
-- fails to compile and FlyWithLua quarantines it.
function afk_hook_view_commands()

    for i = 1, #AFK_VIEW_COMMANDS do

        local command_ref =
            XPLM.XPLMFindCommand(
                AFK_VIEW_COMMANDS[i]
            )

        -- Not every command exists in every X-Plane build, and
        -- XPLMFindCommand simply returns null for the ones that
        -- do not. Those are skipped rather than treated as an
        -- error.
        if command_ref ~= nil then

            XPLM.XPLMRegisterCommandHandler(
                command_ref,
                afk_view_command_callback,
                1,
                nil
            )

            afk_view_command_refs[#afk_view_command_refs + 1] =
                command_ref

        end

    end

end

afk_hook_view_commands()

logMsg(
    "AFK CAMERA: VIEW COMMANDS HOOKED: "
    .. tostring(#afk_view_command_refs)
    .. " / "
    .. tostring(#AFK_VIEW_COMMANDS)
)


-- ============================================================
-- MAIN LOOP
-- ============================================================

function afk_director_update()

    -- Watch for an update check finishing. Deliberately ahead
    -- of the enabled test below, so a check started from the
    -- settings window still completes while the camera itself
    -- is switched off.
    afk_update_poll()


    -- Complete plugin disable: release AFK camera ownership,
    -- clear AFK state and do not accumulate idle time.
    if not afk_enabled then

        if afk_active
           or cockpit_camera_controlled
           or cockpit_return_active
           or external_camera_controlled then

            afk_active =
                false

            afk_status =
                "DISABLED"

            current_shot =
                "NONE"

            afk_entry_view_type =
                nil

            external_camera_ownership_lost =
                false

            stop_afk_camera(true)

        end

        idle_time =
            0.0

        return

    end


    poll_mouse_buttons()

    poll_mouse_movement()

    poll_mouse_yoke_input()

    poll_better_mouse_yoke_input()

    poll_joystick_input()


    -- --------------------------------------------------------
    -- VIEW CHANGE / CAMERA OWNERSHIP SAFETY
    -- --------------------------------------------------------
    --
    -- Exterior:
    -- X-Plane tells the camera callback when it takes ownership
    -- back after a manual view change. The callback only records
    -- the event; all Lua state changes happen here.
    if external_camera_ownership_lost then

        external_camera_ownership_lost =
            false

        if afk_active then

            afk_active =
                false

            afk_status =
                "ACTIVE"

            current_shot =
                "NONE"

            idle_time =
                0.0

            afk_entry_view_type =
                nil

            last_activity =
                "View changed"

            logMsg(
                "AFK CAMERA: EXITED AFK MODE - "
                .. "VIEW CHANGED / CAMERA RETURNED TO X-PLANE"
            )

        end

    end


    -- When AFK is not active, capture the current user view so
    -- the correct director is selected when AFK eventually starts.
    if not afk_active then

        update_director_mode()

    elseif director_mode == "COCKPIT"
       and afk_entry_view_type ~= nil
       and afk_view_type ~= afk_entry_view_type then

        -- Cockpit AFK never owns XPLM camera control, so detect
        -- a manual view transition here and restore the original
        -- pilot-head pose before returning to normal flight.
        afk_active =
            false

        afk_status =
            "ACTIVE"

        current_shot =
            "NONE"

        idle_time =
            0.0

        last_activity =
            "View changed"

        afk_entry_view_type =
            nil

        stop_cockpit_camera(true)

        logMsg(
            "AFK CAMERA: EXITED AFK MODE - "
            .. "COCKPIT VIEW CHANGED"
        )

    end


    -- --------------------------------------------------------
    -- Delta time
    -- --------------------------------------------------------

    local current_time =
        os.clock()

    local delta_time =
        current_time
        - last_update_time

    last_update_time =
        current_time


    if delta_time < 0 then
        delta_time = 0
    end


    if delta_time > 1 then
        delta_time = 1
    end


    -- --------------------------------------------------------
    -- Return to pre-AFK cockpit view
    -- --------------------------------------------------------
    --
    -- Must run before the activity handlers below: they return
    -- early on every frame with input, which is exactly when the
    -- return animation is playing.

    cockpit_return_update(
        delta_time
    )


    -- --------------------------------------------------------
    -- Parked or moving
    -- --------------------------------------------------------
    --
    -- Decides which exterior library the next cut draws from.
    -- Runs every frame, not just during AFK, so the hysteresis
    -- has already settled by the time AFK starts.

    afk_update_parked_state(
        delta_time
    )


    -- --------------------------------------------------------
    -- Manual trigger
    -- --------------------------------------------------------
    --
    -- Handled here, before the grace window is evaluated, so
    -- that starting AFK swallows the same frame's input from
    -- the control that started it.

    afk_process_manual_request()


    -- --------------------------------------------------------
    -- Manual trigger grace
    -- --------------------------------------------------------
    --
    -- Runs before the activity chain below. Clearing the flags
    -- here makes every handler fall through, so the director
    -- keeps animating instead of the bound control waking AFK
    -- up the instant it starts it.

    if afk_input_grace_active() then

        afk_clear_input_flags()

    end


    -- --------------------------------------------------------
    -- Better Mouse Yoke
    -- --------------------------------------------------------

    if handle_better_mouse_yoke_activity() then
        return
    end


    -- --------------------------------------------------------
    -- X-Plane mouse joystick
    -- --------------------------------------------------------

    if handle_mouse_yoke_activity() then
        return
    end


    -- --------------------------------------------------------
    -- Physical joystick input
    -- --------------------------------------------------------

    if handle_joystick_activity() then
        return
    end


    -- --------------------------------------------------------
    -- Right mouse button
    -- --------------------------------------------------------

    if handle_right_mouse_activity() then
        return
    end


    -- --------------------------------------------------------
    -- Mouse movement (optional)
    -- --------------------------------------------------------

    if handle_mouse_move_activity() then
        return
    end


    -- --------------------------------------------------------
    -- Mouse input
    -- --------------------------------------------------------

    if mouse_input_detected then

        idle_time = 0.0

        last_activity =
            "Mouse input"


        if afk_active then

            afk_active = false

            afk_status = "ACTIVE"

            current_shot = "NONE"

            afk_entry_view_type = nil


            stop_afk_camera()


            logMsg(
                "AFK CAMERA: "
                .. "EXITED AFK MODE - MOUSE INPUT"
            )

        end


        mouse_input_detected = false


        return

    end


    -- --------------------------------------------------------
    -- Camera movement
    -- --------------------------------------------------------

    if handle_keyboard_activity() then
        return
    end


    -- --------------------------------------------------------
    -- CAMERA OWNERSHIP SAFETY
    -- --------------------------------------------------------
    --
    -- Outside AFK mode, this script must never retain camera
    -- ownership. This catches any path that clears AFK state
    -- without going through the normal release handler.
    if not afk_active
    and (
        cockpit_camera_controlled
        or external_camera_controlled
    ) then

        stop_afk_camera()

    end


    -- --------------------------------------------------------
    -- COCKPIT DIRECTOR
    -- --------------------------------------------------------
    --
    -- This updates pilot-head DataRefs while X-Plane keeps control
    -- of the actual cockpit camera.

    if afk_active
    and director_mode == "COCKPIT" then

        cockpit_director_update(
            delta_time
        )

    end


    -- --------------------------------------------------------
    -- AFK TIMER
    -- --------------------------------------------------------

    if not afk_active then

        if afk_auto_entry then

            idle_time =
                idle_time + delta_time

            if idle_time >= AFK_TIMEOUT then

                enter_afk()

            end

        else

            -- Manual entry: the timer does not run at all.
            idle_time =
                0.0

        end

    end

end


do_every_frame(
    "afk_director_update()"
)


-- ============================================================
-- VIEW DETECTION
-- ============================================================

function get_view_name()

    if afk_view_type == 1026 then

        return "COCKPIT"

    elseif afk_view_type == 1018 then

        return "EXTERNAL CIRCLE"

    elseif afk_view_type == 1028 then

        return "FREE CAM"

    elseif afk_view_type == 1015 then

        return "RUNWAY"

    elseif afk_view_type == 1020 then

        return "STILL SPOT"

    else

        return "UNKNOWN ("
        .. tostring(afk_view_type)
        .. ")"

    end

end


-- ============================================================
-- DEBUG HUD
-- ============================================================

function afk_set_debug_hud_visible(visible)

    afk_debug_hud_visible =
        visible and true or false

    logMsg(
        "AFK CAMERA: DEBUG HUD "
        .. (
            afk_debug_hud_visible
            and "SHOWN"
            or "HIDDEN"
        )
    )

end


function afk_debug_hud_toggle()

    afk_set_debug_hud_visible(
        not afk_debug_hud_visible
    )

end


create_command(
    "AFKCamera/debug_hud_toggle",
    "Show/hide AFK Camera debug HUD",
    "afk_debug_hud_toggle()",
    "",
    ""
)


function afk_debug_display()

    if not afk_debug_hud_visible then
        return
    end

    draw_string(
        30,
        700,
        "AFK CAMERA"
    )


    draw_string(
        30,
        680,
        "Status: "
        .. afk_status
    )


    if afk_auto_entry then

        draw_string(
            30,
            660,
            "Idle: "
            .. string.format(
                "%.1f",
                idle_time
            )
            .. " / "
            .. AFK_TIMEOUT
        )

    else

        draw_string(
            30,
            660,
            "Idle: timer off (manual entry)"
        )

    end


    draw_string(
        30,
        640,
        "Camera: "
        .. camera_status
    )


    draw_string(
        30,
        620,
        "Movement Threshold: "
        .. CAMERA_MOVEMENT_THRESHOLD
        .. " deg"
    )


    draw_string(
        30,
        600,
        "Heading: "
        .. string.format(
            "%.2f",
            afk_view_heading
        )
    )


    draw_string(
        30,
        580,
        "Pitch: "
        .. string.format(
            "%.2f",
            afk_view_pitch
        )
    )


    draw_string(
        30,
        560,
        "Roll: "
        .. string.format(
            "%.2f",
            afk_view_roll
        )
    )


    draw_string(
        30,
        530,
        "LAST ACTIVITY"
    )


    draw_string(
        30,
        510,
        last_activity
    )


    draw_string(
        30,
        485,
        "Entry: "
        .. (
            afk_auto_entry
            and "AUTOMATIC"
            or "MANUAL (bound control)"
        )
        .. (
            afk_input_grace_active()
            and "  [ignoring input]"
            or ""
        )
    )


    draw_string(
        30,
        460,
        "View Type: "
        .. get_view_name()
    )


    draw_string(
        30,
        440,
        "Director: "
        .. director_mode
    )


    draw_string(
        30,
        420,
        "Current Shot: "
        .. current_shot
    )

    if cockpit_return_active then

        draw_string(
            30,
            380,
            "Cockpit: RETURNING TO PRE-AFK VIEW"
        )

    end

    if external_camera_controlled then

        draw_string(
            30,
            380,
            "Cinematic Cut: "
            .. tostring(
                external_shot_index
            )
            .. " / "
            .. tostring(
                #external_current_library
            )
            .. "   Coverage: "
            .. (
                afk_exterior_parked
                and "PARKED (close-up)"
                or "FLIGHT"
            )
        )

    end


    local camera_owner =
        "XPRealistic / X-Plane"

    if cockpit_camera_controlled
    or external_camera_controlled then

        camera_owner =
            "AFK Camera"

    end


    draw_string(
        30,
        400,
        "Camera Owner: "
        .. camera_owner
    )

end


do_every_draw(
    "afk_debug_display()"
)


-- ============================================================
-- KEYBOARD ACTIVITY
-- ============================================================

function handle_keyboard_activity()

    if not keyboard_input_detected then
        return false
    end

    keyboard_input_detected = false

    idle_time = 0.0
    last_activity = "Keyboard input"

    if afk_active then

        afk_active = false
        afk_status = "ACTIVE"
        current_shot = "NONE"

        stop_afk_camera()

        logMsg(
            "AFK CAMERA: EXITED AFK MODE - KEYBOARD INPUT"
        )

    end

    return true

end


-- ============================================================
-- MOUSE INPUT
-- ============================================================

function afk_mouse_click()

    mouse_input_detected = true

end


function afk_mouse_wheel()

    mouse_input_detected = true

end


do_on_mouse_click(
    "afk_mouse_click()"
)


do_on_mouse_wheel(
    "afk_mouse_wheel()"
)


-- ============================================================
-- STARTUP
-- ============================================================

logMsg(
    "===================================="
)

logMsg(
    "AFK CAMERA PHASE 5"
)

logMsg(
    "AFK Camera version: "
    .. afk_version_display(AFK_CAMERA_VERSION)
)

logMsg(
    "AFK timeout: "
    .. AFK_TIMEOUT
    .. " seconds"
)

logMsg(
    "AFK Camera enabled: "
    .. tostring(
        afk_enabled
    )
)

logMsg(
    "Debug HUD visible: "
    .. tostring(
        afk_debug_hud_visible
    )
)

logMsg(
    "AFK entry: "
    .. (
        afk_auto_entry
        and "AUTOMATIC (idle timer)"
        or "MANUAL (bind AFKCamera/trigger_afk)"
    )
)

logMsg(
    "Cockpit head movement: size "
    .. string.format("%.0f", afk_head_size)
    .. " % | speed "
    .. string.format("%.0f", afk_head_speed)
    .. " %"
)

logMsg(
    "Mouse movement wake-up: "
    .. tostring(
        afk_mouse_move_return
    )
)

logMsg(
    "Joystick dead zone: "
    .. string.format(
        "%.1f",
        afk_joystick_deadzone
    )
    .. " %"
)

logMsg(
    "Default settings: Enabled="
    .. tostring(
        DEFAULT_AFK_ENABLED
    )
    .. " | Timeout="
    .. string.format(
        "%.0f",
        DEFAULT_AFK_TIMEOUT
    )
    .. " s"
)

logMsg(
    "Settings file: "
    .. AFK_SETTINGS_FILE
)

logMsg(
    "Camera threshold: "
    .. CAMERA_MOVEMENT_THRESHOLD
    .. " degrees"
)

logMsg(
    "FFI camera control: AFK ONLY"
)

logMsg(
    "Normal flight camera owner: XPRealistic / X-Plane"
)

logMsg(
    "Cockpit AFK method: X-Plane pilot-head DataRef writes"
)

logMsg(
    "AFK camera owner: AFK Camera"
)

logMsg(
    "AFK exterior parked shots: "
    .. tostring(#AFK_EXTERIOR_PARKED_SHOTS)
    .. " close-up / detail"
)

logMsg(
    "AFK exterior flight shots: "
    .. tostring(#AFK_EXTERIOR_FLIGHT_SHOTS)
)

logMsg(
    "===================================="
)