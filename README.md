# AFK Camera

> **A cinematic AFK camera system for X-Plane 12.**

AFK Camera automatically turns an unattended aircraft into a cinematic scene. After a configurable period of inactivity, it can direct the **cockpit pilot head** or run a sequence of **external cinematic camera shots**, then return control when the pilot interacts again.

[**Download AFK CAMERA ZIP (v1.0)**](https://github.com/Debarghya-Basak/AFK-Cam/archive/refs/tags/v1.0.zip)

Built for **X-Plane 12 + FlyWithLua NG+**.

---

## What it does

### Cinematic AFK mode

When the pilot stops interacting with the aircraft, AFK Camera enters AFK mode after the configured timeout.

The camera behavior depends on the current X-Plane view:

- **Cockpit:** the normal X-Plane cockpit camera remains in charge while AFK Camera animates the pilot head.
- **External views:** AFK Camera takes control and plays cinematic aircraft shots.
- **Unsupported views:** the plugin can enter AFK state without taking camera control.

Normal flying is kept separate from AFK mode, so the normal flight camera remains with **X-Plane / XPRealistic**.

### Cockpit pilot-head director

The cockpit director creates subtle, human-like attention movements:

- Look left
- Look right
- Look down
- Look toward the left instrument panel
- Look toward the right instrument panel
- Smooth transitions back to center
- Randomized holds and movement durations

The cockpit system uses X-Plane pilot-head DataRefs rather than taking over the XPLM camera.

### External cinematic camera

The external director currently contains **12 authored cinematic shots** with:

- Randomized order
- No immediate shot repetition
- Slow camera movement
- Minimum shot duration of 11 seconds
- Continuous aircraft-centered framing
- Aircraft-size adaptive camera distances
- Automatic camera handoff when the user changes view

The same shot library can therefore be used across aircraft with very different physical sizes.

### Input detection

AFK Camera watches for real pilot interaction and exits AFK mode when activity is detected.

Supported input layers include:

- Keyboard input
- Mouse clicks
- Mouse wheel
- Mouse movement
- X-Plane mouse-yoke input
- Better Mouse Yoke input
- Physical joystick axis movement
- Physical joystick buttons
- Right-mouse camera dragging

Joystick input has an adjustable dead zone so small hardware jitter does not constantly wake the camera.

---

## Settings UI

Open the settings window from:

**X-Plane -> Plugins -> FlyWithLua -> FlyWithLua Macros -> AFK Camera: Open Settings**

The UI currently provides:

| Setting                 | Range / Behavior                                |
| ----------------------- | ----------------------------------------------- |
| Enable AFK Camera       | Enable / disable                                |
| AFK Timer               | 3 to 300 seconds                                |
| Mouse movement ends AFK | On / off                                        |
| Joystick dead zone      | 0.1% to 25%                                     |
| Show Debug HUD          | On / off                                        |
| Save Settings           | Writes settings to disk                         |
| Restore Defaults        | Restores the configured defaults and saves them |

### Default values

The current script ships with:

```text
AFK Camera: Enabled
AFK Timer: 30 seconds
Debug HUD: Enabled
Mouse movement ends AFK: Enabled
Joystick dead zone: 1.0%
```

The developer defaults are kept in one place near the top of the Lua file:

```lua
local DEFAULT_AFK_ENABLED = true
local DEFAULT_AFK_TIMEOUT = 30.0
local DEFAULT_AFK_DEBUG_HUD = true
local DEFAULT_AFK_MOUSE_MOVE_RETURN = true
local DEFAULT_AFK_JOYSTICK_DEADZONE = 1.0
```

Change those values when you want to define what **Restore Defaults** should use.

---

## Settings persistence

AFK Camera saves user settings to:

```text
AFKCamera_settings.ini
```

The file is stored beside the Lua script.

Example:

```ini
enabled=1
timeout=30
debug_hud=1
mouse_move=1
joystick_deadzone=1.0
```

You do **not** need to edit this file manually. The settings UI is the recommended way to configure AFK Camera.

---

## Requirements

### Required

- **X-Plane 12**
- **FlyWithLua NG+** with floating-window / ImGui support
- **Windows**

The current script was developed around **FlyWithLua NG+ 2.8.16**.

FlyWithLua:

- https://forums.x-plane.org/files/file/82888-flywithlua-ng-next-generation-plus-edition-for-x-plane-12-win-lin-mac/

### Optional

**Better Mouse Yoke**

AFK Camera can detect Better Mouse Yoke activity so mouse-yoke control can wake the simulator from AFK mode.

AFK Camera does **not** enable or disable Better Mouse Yoke itself.

Better Mouse Yoke project:

- https://forums.x-plane.org/files/file/100265-bettermouseyoke-xplane12-win-mac-lin/

---

## Installation

### 1. Install FlyWithLua

Install FlyWithLua into your X-Plane 12 `Resources/plugins` directory.

The final structure should look approximately like:

```text
X-Plane 12/
└── Resources/
    └── plugins/
        └── FlyWithLua/
            ├── Scripts/
            └── ...
```

FlyWithLua's scripts are loaded from its `Scripts` folder.

### 2. Install AFK Camera

Copy:

```text
AFK CAMERA.lua
```

directly into:

```text
X-Plane 12/Resources/plugins/FlyWithLua/Scripts/
```

Do not place the Lua file inside another subfolder.

### 3. Start X-Plane

Launch X-Plane 12 and load an aircraft.

For the first installation, a full X-Plane restart is recommended.

### 4. Open AFK Camera Settings

In X-Plane:

```text
Plugins
  -> FlyWithLua
      -> FlyWithLua Macros
          -> AFK Camera: Open Settings
```

Configure the timeout and other options, then press **Save Settings**.

### 5. Confirm the settings file

After saving, you should see:

```text
AFKCamera_settings.ini
```

beside `AFK CAMERA.lua`.

---

## Quick start

A typical first test:

1. Set **AFK Timer** to 10-30 seconds.
2. Keep **Enable AFK Camera** enabled.
3. Choose your preferred mouse/joystick wake-up settings.
4. Take off or sit on the ramp.
5. Stop touching the controls.
6. Wait for the AFK timer.
7. AFK Camera will select the director for the current view.
8. Interact with the simulator to exit AFK.

The debug HUD can show the current status, idle time, active shot, and camera ownership while testing.

---

## How the camera works

### Cockpit

Cockpit AFK does not take XPLM camera ownership.

Instead, AFK Camera writes to X-Plane's pilot-head view data, allowing the normal cockpit camera and other camera effects to remain active.

This is especially useful when using camera-effect software such as XPRealistic.

### External

For external cinematic mode, AFK Camera temporarily takes XPLM camera control and uses the authored shot path.

The external camera:

- Tracks the aircraft
- Computes a look-at orientation
- Scales shot geometry using the aircraft size value exposed by X-Plane
- Keeps each shot slow and cinematic
- Returns control when the user exits AFK or changes view

---

## View routing

AFK Camera recognizes these X-Plane view types:

| View            | AFK behavior                     |
| --------------- | -------------------------------- |
| Cockpit         | Cockpit pilot-head director      |
| External Circle | External cinematic camera        |
| Free Cam        | External cinematic camera        |
| Runway          | External cinematic camera        |
| Still Spot      | External cinematic camera        |
| Other / unknown | AFK state without camera control |

---

## Commands

AFK Camera registers the following user-facing command:

```text
AFKCamera/settings_toggle
```

This opens or closes the settings window and can be assigned to a keyboard or joystick button.

A debug HUD command is also available:

```text
AFKDirector/debug_hud_toggle
```

For normal users, the **Settings UI** is the easiest way to configure the plugin.

---

## Debug HUD

The optional HUD can display:

- AFK status
- Idle time
- Camera status
- Current view
- Current shot
- Camera owner
- Cinematic shot progress
- Cockpit return state

For hardware debugging, the settings window also shows the largest joystick axis change currently detected. This makes it easier to select a dead zone just above your controller's idle jitter.

---

## Reloading and updating

FlyWithLua supports reloading Lua scripts from:

```text
Plugins
  -> FlyWithLua
      -> Reload all Lua script files
```

AFK Camera includes cleanup for its native callback and camera state during FlyWithLua shutdown/reload.

When updating the script:

1. Close X-Plane or make sure the script is no longer active.
2. Replace `AFK CAMERA.lua`.
3. Keep `AFKCamera_settings.ini` if you want to preserve your saved settings.
4. Start X-Plane again.

---

## Troubleshooting

### The AFK Camera menu item is not visible

Check that:

- FlyWithLua is installed correctly.
- `AFK CAMERA.lua` is directly inside `FlyWithLua/Scripts`.
- The script has a `.lua` extension.
- FlyWithLua successfully loaded the script.
- Your FlyWithLua build supports floating windows / ImGui.

Check FlyWithLua's log if the script fails to load.

### The settings window does not open

The current script requires FlyWithLua floating-window / ImGui support.

If the script reports that floating windows are unsupported, update to a compatible FlyWithLua NG+ build.

### The aircraft enters AFK but the cockpit does not move

Make sure you are actually in an X-Plane cockpit view. External, runway, free-camera, and still-spot views use the external cinematic director.

### The AFK timer wakes up from tiny joystick movement

Increase:

```text
Joystick dead zone
```

Start around 1-2% and increase it gradually if your hardware still reports idle jitter.

### Better Mouse Yoke movement does not wake AFK

Make sure Better Mouse Yoke itself is active and moving the aircraft controls. AFK Camera detects its yoke output; it does not toggle the Better Mouse Yoke plugin.

---

## Recommended repository layout

```text
AFK-Camera/
├── AFK CAMERA.lua
├── README.md
└── docs/
    └── AFK_Camera_Installation_Manual.pdf
```

`AFKCamera_settings.ini` is normally generated automatically after the user saves settings.

---

## Credits

**AFK Camera**

Created by **Debarghya Basak**

Built for the X-Plane 12 community with FlyWithLua.

Third-party projects used / supported by the setup:

- FlyWithLua - https://forums.x-plane.org/files/file/82888-flywithlua-ng-next-generation-plus-edition-for-x-plane-12-win-lin-mac/
- Better Mouse Yoke - https://forums.x-plane.org/files/file/100265-bettermouseyoke-xplane12-win-mac-lin/

---

## Status

AFK Camera is actively structured as a FlyWithLua script rather than an X-Plane plugin binary.

The current project includes:

- Cinematic AFK detection
- Cockpit pilot-head animation
- External cinematic shot director
- Aircraft-size adaptive framing
- Randomized no-repeat cinematic shots
- Better Mouse Yoke activity detection
- Joystick dead-zone handling
- Persistent settings
- FlyWithLua settings UI
- Restore Defaults
- Debug HUD
- Reload/shutdown cleanup
