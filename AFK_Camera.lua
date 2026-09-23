-- ============================================================
-- AFK CAMERA
-- Phase 6 - Menu and crash fixes
-- MADE BY DEBARGHYA BASAK
-- ============================================================


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
local DEFAULT_AFK_DEBUG_HUD = true

-- Mouse movement (cursor moving, no button) counts as activity.
--   true  = moving the mouse resets the timer / ends AFK
--   false = only clicks, wheel and the mouse-yoke modes count
local DEFAULT_AFK_MOUSE_MOVE_RETURN = true

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
-- Height of the aircraft-attached visual center that the
-- exterior camera continuously tracks.
local AFK_EXTERNAL_TARGET_HEIGHT = 1.5

-- Aircraft-size adaptive exterior camera.
--
-- X-Plane exposes this value as the aircraft's shadow/viewing-distance
-- size. The cinematic coordinates are authored around the SF50-sized
-- reference used while developing these shots, then scaled for larger
-- or smaller aircraft automatically.
local AFK_EXTERNAL_REFERENCE_SIZE = 10.0

-- Prevent unusual aircraft/add-ons with extreme size values from
-- producing unusably close or distant cinematic cameras.
local AFK_EXTERNAL_MIN_SCALE = 0.70
local AFK_EXTERNAL_MAX_SCALE = 4.00

local AFK_EXTERNAL_SHOT_SPEED = 3.5
-- Base camera speed. Short shots are automatically slowed so every shot lasts >10 seconds.
local AFK_EXTERNAL_MIN_SHOT_DURATION = 11.0

local AFK_EXTERNAL_SHOTS = {
    {
        name = "RIGHT REAR CLOSE",
        start_x = 17.00, start_y = 6.80, start_z = 20.40,
        end_x = 11.05, end_y = 5.61, end_z = 15.04
    },
    {
        name = "LEFT NOSE CLOSE",
        start_x = -17.85, start_y = 6.80, start_z = -3.40,
        end_x = -11.90, end_y = 5.02, end_z = -7.56
    },
    {
        name = "TOP NOSE DIAGONAL",
        start_x = -8.50, start_y = 15.30, start_z = -12.75,
        end_x = 2.21, end_y = 10.54, end_z = -16.32
    },
    {
        name = "LOW SIDE SWEEP",
        start_x = 17.00, start_y = 3.40, start_z = 5.95,
        end_x = -6.20, end_y = 4.00, end_z = 1.79
    },
    {
        name = "LEFT WING CLOSE",
        start_x = -23.80, start_y = 7.65, start_z = 1.70,
        end_x = -14.28, end_y = 7.05, end_z = 5.86
    },
    {
        name = "TAIL DIAGONAL",
        start_x = -9.35, start_y = 6.80, start_z = 24.65,
        end_x = 3.15, end_y = 5.61, end_z = 17.51
    },
    {
        name = "NOSE LOW TO HIGH",
        start_x = 0.00, start_y = 3.40, start_z = -22.95,
        end_x = 0.00, end_y = 10.54, end_z = -18.19
    },
    {
        name = "HIGH RIGHT PASS",
        start_x = 22.95, start_y = 16.15, start_z = 3.40,
        end_x = 15.81, end_y = 11.98, end_z = -4.33
    },
    {
        name = "RIGHT FRONT CLOSE",
        start_x = 19.55, start_y = 5.95, start_z = -8.50,
        end_x = 13.00, end_y = 6.54, end_z = -13.85
    },
    {
        name = "LOW LEFT DIAGONAL",
        start_x = -19.55, start_y = 2.55, start_z = 3.40,
        end_x = -11.22, end_y = 4.93, end_z = -3.14
    },
    {
        name = "OVERHEAD CLOSE",
        start_x = 7.65, start_y = 21.25, start_z = 10.20,
        end_x = -1.87, end_y = 15.30, end_z = -4.67
    },
    {
        name = "LEFT REAR CLOSE",
        start_x = -16.15, start_y = 6.80, start_z = 21.25,
        end_x = -10.20, end_y = 5.02, end_z = 14.71
    }
}

-- ------------------------------------------------------------
-- RANDOM NO-REPEAT EXTERNAL SHOT BAG
-- ------------------------------------------------------------
--
-- Each cycle contains every one of the 12 shots exactly once,
-- in a randomized order. When the bag is exhausted it is
-- reshuffled. The first shot of the new cycle is also forced
-- to differ from the final shot of the previous cycle.

local external_shot_bag = {}
local external_shot_bag_position = 0
local external_last_shot_index = nil

math.randomseed(os.time())

function shuffle_external_shot_bag()

    external_shot_bag = {}

    for i = 1, #AFK_EXTERNAL_SHOTS do
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

function get_next_external_shot_index()

    if external_shot_bag_position >= #external_shot_bag
       or #external_shot_bag == 0 then

        shuffle_external_shot_bag()
    end

    external_shot_bag_position =
        external_shot_bag_position + 1

    local shot_index =
        external_shot_bag[external_shot_bag_position]

    external_last_shot_index =
        shot_index

    return shot_index
end

local CAMERA_MOVEMENT_THRESHOLD = 0.01


-- ============================================================
-- STATE
-- ============================================================

local idle_time = 0.0

local afk_active = false

local last_heading = nil
local last_pitch = nil
local last_roll = nil

local last_update_time = os.clock()

local camera_status = "INITIALIZING"

local afk_status = "ACTIVE"

local last_activity = "None"

local director_mode = "NONE"

local current_shot = "NONE"

local mouse_input_detected = false


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
    spring_frequency = 0.85,
    spring_damping = 0.72,

    -- Neck pitch muscles are slower than yaw.
    pitch_spring_scale = 0.86,

    -- Counter-movement before a turn, as a fraction of the
    -- turn size. 0 disables it.
    windup = 0.12,

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
    drift_psi = 0.55,
    drift_the = 0.38,
    drift_phi = 0.42,
    drift_pos = 0.0045,

    -- Micro tremor, in degrees.
    tremor = 0.035,

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

for i = 1, 24 do

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

XPLMCommandRef XPLMFindCommand(
    const char *inName
);

void XPLMCommandOnce(
    XPLMCommandRef inCommand
);
]]

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
-- Buttons are treated as activity while physically held.

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

local JOYSTICK_BUTTON_COUNT =
    3200

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

    joystick_initialised =
        true

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

    if axis_detected then

        joystick_input_detected =
            true

        return

    end


    -- --------------------------------------------------------
    -- Joystick buttons
    -- --------------------------------------------------------
    --
    -- Physical joystick buttons are active while held.
    -- No button is generated merely because an assignment exists.

    for i = 0, JOYSTICK_BUTTON_COUNT - 1 do

        local pressed =
            tonumber(
                joystick_button_values[i]
            )

        if pressed ~= nil
        and pressed ~= 0 then

            joystick_input_detected =
                true

            joystick_input_type =
                "Joystick Button"

            return

        end

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

-- Aircraft pose captured at AFK entry.
local cockpit_base_plane_x = 0.0
local cockpit_base_plane_y = 0.0
local cockpit_base_plane_z = 0.0

local cockpit_base_plane_pitch = 0.0
local cockpit_base_plane_roll = 0.0
local cockpit_base_plane_heading = 0.0

-- Camera position relative to the aircraft at AFK entry,
-- expressed in aircraft coordinates.
local cockpit_camera_offset_x = 0.0
local cockpit_camera_offset_y = 0.0
local cockpit_camera_offset_z = 0.0


local cockpit_last_callback_time = os.clock()


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
-- PLAYER ACTIVITY
-- ============================================================

function player_activity(activity)

    idle_time = 0.0

    last_activity = activity


    if afk_active then

        afk_active = false

        afk_status = "ACTIVE"

        current_shot = "NONE"

        afk_entry_view_type = nil


        -- Release camera control ONLY if AFK Camera currently
        -- owns the camera. This hands ownership back to X-Plane,
        -- allowing XPRealistic to resume its camera effects.
        stop_afk_camera()


        logMsg(
            "AFK CAMERA: EXIT - "
            .. activity
        )

    end

end


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


-- How far the pilot looks to the left
local COCKPIT_LEFT_ANGLE = 25.0

-- How long each movement takes
local COCKPIT_MOVE_TIME = 2.5

-- How long to stay looking left
local COCKPIT_HOLD_TIME = 1.5

-- How long to stay centered
local COCKPIT_CENTER_HOLD = 2.0

local COCKPIT_RIGHT_ANGLE = 25.0

local COCKPIT_DOWN_ANGLE = 12.0

local COCKPIT_PANEL_LEFT = 15.0
local COCKPIT_PANEL_DOWN = 8.0

local COCKPIT_PANEL_RIGHT = 15.0

local cockpit_last_random_choice = 0

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


local function cockpit_wrap_heading(value)

    while value > 180.0 do
        value = value - 360.0
    end

    while value < -180.0 do
        value = value + 360.0
    end

    return value

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


local function cockpit_world_to_aircraft(
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


    -- Inverse heading
    local x_heading =
        x * math.cos(psi)
        + z * math.sin(psi)

    local y_heading =
        y

    local z_heading =
        z * math.cos(psi)
        - x * math.sin(psi)


    -- Inverse pitch
    local x_pitch =
        x_heading

    local y_pitch =
        y_heading * math.cos(theta)
        + z_heading * math.sin(theta)

    local z_pitch =
        z_heading * math.cos(theta)
        - y_heading * math.sin(theta)


    -- Inverse roll
    local x_aircraft =
        x_pitch * math.cos(phi)
        - y_pitch * math.sin(phi)

    local y_aircraft =
        y_pitch * math.cos(phi)
        + x_pitch * math.sin(phi)

    local z_aircraft =
        z_pitch


    return
        x_aircraft,
        y_aircraft,
        z_aircraft

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
        return cockpit_random_range(1.6, 4.5)

    elseif roll < 0.88 then

        -- Ordinary look.
        return cockpit_random_range(4.5, 12.0)

    end

    -- Occasional long stare out of the window.
    return cockpit_random_range(12.0, 28.0)

end


function cockpit_random_center_hold()

    return cockpit_random_range(1.2, 4.0)

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

    local move_time =
        0.55
        + distance * 0.022

    -- Nobody moves at exactly the same speed twice.
    move_time =
        move_time
        * cockpit_random_range(0.88, 1.15)

    if move_time < 0.45 then
        move_time = 0.45
    end

    if move_time > 2.4 then
        move_time = 2.4
    end

    return move_time

end


-- Every look carries a little movement on the other axis too.
-- Purely horizontal or purely vertical head turns look wrong.
function cockpit_start_random_shot()

    local choice

    repeat
        choice = math.random(1, 5)
    until choice ~= cockpit_last_random_choice

    cockpit_last_random_choice = choice


    if choice == 1 then

        -- LOOK LEFT

        cockpit_set_shot(
            "LOOK LEFT",

            cockpit_base_head_psi
            - cockpit_random_range(20.0, 30.0),

            cockpit_base_head_the
            + cockpit_random_range(-3.5, 2.0),

            nil
        )


    elseif choice == 2 then

        -- LOOK RIGHT

        cockpit_set_shot(
            "LOOK RIGHT",

            cockpit_base_head_psi
            + cockpit_random_range(20.0, 30.0),

            cockpit_base_head_the
            + cockpit_random_range(-3.5, 2.0),

            nil
        )


    elseif choice == 3 then

        -- LOOK DOWN

        cockpit_set_shot(
            "LOOK DOWN",

            cockpit_base_head_psi
            + cockpit_random_range(-4.0, 4.0),

            cockpit_base_head_the
            - cockpit_random_range(8.0, 14.0),

            nil
        )


    elseif choice == 4 then

        -- LEFT INSTRUMENT PANEL

        cockpit_set_shot(
            "LOOK PANEL LEFT",

            cockpit_base_head_psi
            - cockpit_random_range(11.0, 19.0),

            cockpit_base_head_the
            - cockpit_random_range(5.5, 10.5),

            nil
        )


    else

        -- RIGHT INSTRUMENT PANEL

        cockpit_set_shot(
            "LOOK PANEL RIGHT",

            cockpit_base_head_psi
            + cockpit_random_range(11.0, 19.0),

            cockpit_base_head_the
            - cockpit_random_range(5.5, 10.5),

            nil
        )

    end

end


function cockpit_return_to_center()

    cockpit_set_shot(
        "CENTER HOLD",
        cockpit_base_head_psi,
        cockpit_base_head_the,
        cockpit_random_center_hold()
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

        if cockpit_shot == "CENTER" then

            -- Initial center hold finished.
            -- Pick a random direction.

            cockpit_start_random_shot()


        elseif cockpit_shot == "LOOK LEFT" then

            -- LEFT -> HOLD LEFT

            cockpit_set_shot(
                "HOLD LEFT",
                cockpit_target_heading,
                cockpit_target_pitch,
                cockpit_random_hold()
            )


        elseif cockpit_shot == "HOLD LEFT" then

            -- LEFT -> CENTER

            cockpit_set_shot(
                "RETURN CENTER LEFT",
                cockpit_base_head_psi,
                cockpit_base_head_the,
                nil
            )


        elseif cockpit_shot == "LOOK RIGHT" then

            -- RIGHT -> HOLD RIGHT

            cockpit_set_shot(
                "HOLD RIGHT",
                cockpit_target_heading,
                cockpit_target_pitch,
                cockpit_random_hold()
            )


        elseif cockpit_shot == "HOLD RIGHT" then

            -- RIGHT -> CENTER

            cockpit_set_shot(
                "RETURN CENTER RIGHT",
                cockpit_base_head_psi,
                cockpit_base_head_the,
                nil
            )


        elseif cockpit_shot == "LOOK DOWN" then

            -- DOWN -> HOLD

            cockpit_set_shot(
                "HOLD DOWN",
                cockpit_target_heading,
                cockpit_target_pitch,
                cockpit_random_hold()
            )


        elseif cockpit_shot == "HOLD DOWN" then

            -- DOWN -> CENTER

            cockpit_set_shot(
                "RETURN CENTER DOWN",
                cockpit_base_head_psi,
                cockpit_base_head_the,
                nil
            )


        elseif cockpit_shot == "LOOK PANEL LEFT" then

            -- PANEL LEFT -> HOLD

            cockpit_set_shot(
                "HOLD PANEL LEFT",
                cockpit_target_heading,
                cockpit_target_pitch,
                cockpit_random_hold()
            )


        elseif cockpit_shot == "HOLD PANEL LEFT" then

            -- PANEL LEFT -> CENTER

            cockpit_set_shot(
                "RETURN CENTER PANEL LEFT",
                cockpit_base_head_psi,
                cockpit_base_head_the,
                nil
            )


        elseif cockpit_shot == "LOOK PANEL RIGHT" then

            -- PANEL RIGHT -> HOLD

            cockpit_set_shot(
                "HOLD PANEL RIGHT",
                cockpit_target_heading,
                cockpit_target_pitch,
                cockpit_random_hold()
            )


        elseif cockpit_shot == "HOLD PANEL RIGHT" then

            -- PANEL RIGHT -> CENTER

            cockpit_set_shot(
                "RETURN CENTER PANEL RIGHT",
                cockpit_base_head_psi,
                cockpit_base_head_the,
                nil
            )


        elseif cockpit_shot == "RETURN CENTER LEFT"
            or cockpit_shot == "RETURN CENTER RIGHT"
            or cockpit_shot == "RETURN CENTER DOWN"
            or cockpit_shot == "RETURN CENTER PANEL LEFT"
            or cockpit_shot == "RETURN CENTER PANEL RIGHT" then

            -- After every movement, pause in center.

            cockpit_return_to_center()


        elseif cockpit_shot == "CENTER HOLD" then

            -- Center pause finished.
            -- Pick another random shot.

            cockpit_start_random_shot()

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

        local omega_psi =
            2.0
            * math.pi
            * COCKPIT_HEAD.spring_frequency

        local omega_the =
            omega_psi
            * COCKPIT_HEAD.pitch_spring_scale


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

            local life =
                cockpit_smoothstep(
                    cockpit_life_blend
                )


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

function external_prepare_shot(index)

    local shot =
        AFK_EXTERNAL_SHOTS[index]

    external_shot_index =
        index

    external_shot_phase =
        "MOVE"

    external_shot_time =
        0.0


    -- HARD CUT / TELEPORT:
    -- Each shot has its own independent starting position.
    -- The camera jumps there immediately.

    external_current_x =
        shot.start_x

    external_current_y =
        shot.start_y

    external_current_z =
        shot.start_z

    external_start_x =
        shot.start_x

    external_start_y =
        shot.start_y

    external_start_z =
        shot.start_z

    external_target_x =
        shot.end_x

    external_target_y =
        shot.end_y

    external_target_z =
        shot.end_z

    -- --------------------------------------------------------
    -- AIRCRAFT-SIZE SCALING
    -- --------------------------------------------------------
    --
    -- The authored shot is multiplied around the aircraft CG.
    -- X/Z control lateral/longitudinal distance; Y controls
    -- camera height. Scaling all three keeps the composition
    -- proportional for small jets, airliners and larger aircraft.

    external_aircraft_scale =
        get_external_aircraft_scale()

    external_current_x =
        external_current_x
        * external_aircraft_scale

    external_current_y =
        external_current_y
        * external_aircraft_scale

    external_current_z =
        external_current_z
        * external_aircraft_scale

    external_start_x =
        external_start_x
        * external_aircraft_scale

    external_start_y =
        external_start_y
        * external_aircraft_scale

    external_start_z =
        external_start_z
        * external_aircraft_scale

    external_target_x =
        external_target_x
        * external_aircraft_scale

    external_target_y =
        external_target_y
        * external_aircraft_scale

    external_target_z =
        external_target_z
        * external_aircraft_scale


    -- Exact 3D path length -> base duration from the camera speed.
    -- A minimum duration is then enforced so every cinematic shot
    -- lasts more than 10 seconds.

    local dx =
        external_target_x
        - external_start_x

    local dy =
        external_target_y
        - external_start_y

    local dz =
        external_target_z
        - external_start_z

    external_shot_distance =
        math.sqrt(
            dx * dx
            + dy * dy
            + dz * dz
        )

    if external_shot_distance < 0.01 then
        external_shot_distance =
            0.01
    end

    external_shot_duration =
        external_shot_distance
        / AFK_EXTERNAL_SHOT_SPEED

    if external_shot_duration <= AFK_EXTERNAL_MIN_SHOT_DURATION then
        external_shot_duration =
            AFK_EXTERNAL_MIN_SHOT_DURATION
    end

    current_shot =
        shot.name

    logMsg(
        "AFK CAMERA: CUT TO EXTERNAL SHOT "
        .. tostring(index)
        .. "/"
        .. tostring(#AFK_EXTERNAL_SHOTS)
        .. " | "
        .. shot.name
        .. " | "
        .. tostring(AFK_EXTERNAL_SHOT_SPEED)
        .. " M/S BASE | MIN "
        .. tostring(AFK_EXTERNAL_MIN_SHOT_DURATION)
        .. " S / SLOW CLOSE"
        .. " | SIZE SCALE "
        .. string.format("%.2f", external_aircraft_scale)
    )

end


function external_advance_shot()

    -- Select the next shot from the randomized no-repeat bag.
    local next_index =
        get_next_external_shot_index()

    external_prepare_shot(
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
        -- CONSTANT-SPEED MOVE
        -- ----------------------------------------------------
        --
        -- Linear progress gives one constant physical velocity.
        -- There is no easing and no hold phase.

        external_shot_time =
            external_shot_time
            + delta_time

        local progress =
            external_shot_time
            / external_shot_duration


        if progress >= 1.0 then

            external_current_x =
                external_target_x

            external_current_y =
                external_target_y

            external_current_z =
                external_target_z

            -- Immediately prepare the next cut.
            external_advance_shot()

        else

            external_current_x =
                external_start_x
                + (
                    external_target_x
                    - external_start_x
                )
                * progress

            external_current_y =
                external_start_y
                + (
                    external_target_y
                    - external_start_y
                )
                * progress

            external_current_z =
                external_start_z
                + (
                    external_target_z
                    - external_start_z
                )
                * progress

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
        -- Aim at aircraft visual center
        -- ----------------------------------------------------
        --
        -- The target point is attached to the aircraft itself.
        -- This is important while the aircraft pitches or banks:
        -- the camera continues to look at the same physical point
        -- on the airplane instead of a fixed world-relative point.
        --
        -- Reuse the proven aircraft-to-world transform already used
        -- by the cockpit camera.

        local target_offset_x,
              target_offset_y,
              target_offset_z =
            cockpit_aircraft_to_world(
                0.0,
                AFK_EXTERNAL_TARGET_HEIGHT
                * external_aircraft_scale,
                0.0,
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
            horizontal_distance =
                0.1
        end

        out_camera.heading =
            math.deg(
                math.atan2(
                    to_target_x,
                    -to_target_z
                )
            )

        out_camera.pitch =
            math.deg(
                math.atan2(
                    to_target_y,
                    horizontal_distance
                )
            )

        out_camera.roll =
            0.0

        out_camera.zoom =
            AFK_EXTERNAL_ZOOM

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

    XPLM.XPLMCommandOnce(
        external_circle_command
    )

    external_camera_ownership_lost =
        false

    external_last_callback_time =
        os.clock()

    external_camera_controlled =
        true

    -- First shot is also selected from the randomized no-repeat bag.
    external_prepare_shot(
        get_next_external_shot_index()
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
-- TEST COMMAND
-- ============================================================

function afk_test_command()

    player_activity(
        "Test Command"
    )

end


create_command(
    "AFKDirector/test_activity",
    "AFK Camera Test Activity",
    "afk_test_command()",
    "",
    ""
)


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
            460,
            500,
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


function afk_settings_on_build(wnd, x, y)

    imgui.TextUnformatted(
        "AFK Camera"
    )

    imgui.TextUnformatted(
        "Automatic cinematic camera after inactivity."
    )

    imgui.Separator()


    -- --------------------------------------------------------
    -- ENABLE / DISABLE
    -- --------------------------------------------------------

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


    imgui.TextUnformatted("")


    -- --------------------------------------------------------
    -- AFK TIMER
    -- --------------------------------------------------------

    imgui.TextUnformatted(
        "AFK Timer"
    )

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


    imgui.TextUnformatted(
        "Current timer: "
        .. string.format(
            "%.0f",
            AFK_TIMEOUT
        )
        .. " seconds"
    )


    imgui.TextUnformatted("")


    -- --------------------------------------------------------
    -- WAKE-UP INPUTS
    -- --------------------------------------------------------

    imgui.TextUnformatted(
        "Wake-up inputs"
    )

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
            clamp_afk_joystick_deadzone(
                new_deadzone
            )

    end

    imgui.TextUnformatted(
        "Axis changes below the dead zone are ignored."
    )

    -- Live jitter readout: leave the stick alone and set the
    -- dead zone a little above the number shown here.
    imgui.TextUnformatted(
        "Largest axis change right now: "
        .. string.format(
            "%.2f",
            joystick_last_max_difference
            * 100.0
        )
        .. " %"
    )


    imgui.TextUnformatted("")


    -- --------------------------------------------------------
    -- DEBUG HUD
    -- --------------------------------------------------------

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


    imgui.Separator()


    -- --------------------------------------------------------
    -- CURRENT STATE
    -- --------------------------------------------------------

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
    )

    imgui.TextUnformatted(
        "Last activity: "
        .. tostring(
            last_activity
        )
    )


    imgui.TextUnformatted("")


    -- --------------------------------------------------------
    -- SAVE
    -- --------------------------------------------------------

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
-- MAIN LOOP
-- ============================================================

function afk_director_update()

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

        idle_time =
            idle_time + delta_time


        if idle_time >= AFK_TIMEOUT then

            enter_afk()

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
                #AFK_EXTERNAL_SHOTS
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
    "AFK exterior mode: Constant-speed cinematic cut shots"
)

logMsg(
    "===================================="
)