-- This file has been consolidated and simplified from ML4W into the Hyprland configuration directory.
--  _   _                  _                 _
-- | | | |_   _ _ __  _ __| | __ _ _ __   __| |
-- | |_| | | | | '_ \| '__| |/ _` | '_ \ / _` |
-- |  _  | |_| | |_) | |  | | (_| | | | | (_| |
-- |_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_|
--        |___/|_|
--
-- Simplified Hyprland Configuration (Stow-ready)
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Monitors
-- -----------------------------------------------------
-- eDP-1 is managed dynamically below (docked/undocked handling), not declared statically here.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "1",
})

-- -----------------------------------------------------

-- -----------------------------------------------------
-- Environment Variables
-- -----------------------------------------------------
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("GDK_SCALE", "1")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Amber")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("XAUTHORITY", "$HOME/.Xauthority")

-- -----------------------------------------------------
-- Colors
-- -----------------------------------------------------
local colors = dofile(os.getenv("HOME") .. "/.local/share/matugen/hyprland-colors.lua")
local color8 = colors.on_primary_fixed
local color11 = colors.on_surface

-- -----------------------------------------------------
-- Autostart
-- -----------------------------------------------------

-- Workspace Assignments

-- -----------------------------------------------------
-- Input
-- -----------------------------------------------------

hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("md3_accel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.38, 0.04 }, { 1, 0.07 } } })
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 3,
    bezier = "md3_decel",
    style = "popin 60%",
})
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 3,
    bezier = "md3_decel",
    style = "popin 60%",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3,
    bezier = "md3_accel",
    style = "popin 60%",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 10,
    bezier = "default",
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 3,
    bezier = "md3_decel",
})
hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 3,
    bezier = "menu_decel",
    style = "slide",
})
hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 1.6,
    bezier = "menu_accel",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 7,
    bezier = "menu_decel",
    style = "slide",
})

hl.window_rule({
    match = {
        title = "^(pavucontrol)$",
    },
    float = true,
})

hl.window_rule({
    match = {
        title = "^(blueman-manager)$",
    },
    float = true,
})

hl.window_rule({
    match = {
        title = "^(nm-connection-editor)$",
    },
    float = true,
})

hl.window_rule({
    match = {
        title = "^(qalculate-gtk)$",
    },
    float = true,
})

hl.window_rule({
    match = {
        title = "^(Picture-in-Picture)$",
    },
    float = true,
    pin = true,
    move = "69.5% 4%",
})

hl.window_rule({
    match = {
        class = "(.*waypaper.*)",
    },
    float = true,
    size = "900 700",
    center = true,
})

hl.window_rule({
    match = {
        class = ".*",
    },
    focus_on_activate = true,
})

hl.window_rule({
    match = {
        class = "^(zoom)$",
    },
    no_anim = true,
    no_shadow = true,
    float = true,
})

hl.window_rule({
    match = {
        title = "^(zoom)$",
    },
    float = true,
})

hl.window_rule({
    match = {
        title = "^(as_toolbar)$",
    },
    float = true,
})

local mainMod = "SUPER"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("kitty -e yazi"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("pkill rofi || rofi -show drun -replace -i"))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("hyprctl activewindow | grep pid | tr -d 'pid:' | xargs kill"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + T", hl.dsp.window.resize({ x = 1200, y = 540 }))
hl.bind(mainMod .. " + T", hl.dsp.window.move({ x = 360, y = 100 }))
hl.bind(mainMod .. " + BACKSLASH", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + Tab", hl.dsp.group.next())

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("~/.local/bin/custom/bt-connect-speaker.sh"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("~/.local/bin/uv run ~/.local/bin/custom/rofi/code_project.py"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.local/bin/uv run --script ~/.local/bin/custom/rofi/screenshot_area.py swappy"))
hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("~/.local/bin/uv run --script ~/.local/bin/custom/rofi/screenshot_area.py copy"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("~/.local/bin/uv run --script ~/.local/bin/custom/rofi/screenshot_text.py"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("~/.local/bin/uv run --script ~/.local/bin/custom/rofi/screenshot_full.py"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("~/.local/bin/uv run --script ~/.local/bin/custom/rofi/specific_code_project.py ~/code/ember-data-processing"))
hl.bind(mainMod .. " + PERIOD", hl.dsp.exec_cmd("~/.local/bin/uv run --script ~/.local/bin/custom/rofi/emoji_picker.py"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("~/.local/bin/uv run --script ~/.local/bin/custom/rofi/power.py"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("~/.local/bin/custom/rofi/port_opener.sh"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("sh -c \"xdg-open \\\"$(wl-paste)\\\"\""))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("~/.local/bin/custom/group.sh"))
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/.local/bin/custom/cliphist.sh"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/waybar/launch.sh"))
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd("~/.config/waybar/toggle.sh"))
hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("~/.local/bin/uv run --script ~/.local/bin/custom/rofi/wallpaper.py local"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("~/.local/bin/uv run --script ~/.local/bin/custom/rofi/wallpaper.py select"))
hl.bind(mainMod .. " + CTRL + T", hl.dsp.exec_cmd("~/.local/bin/uv run --script ~/.local/bin/custom/rofi/waybar_theme.py"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("pkill hypridle && notify-send -a \"System\" -i \"caffeine-on\" \"Caffeine Mode\" \"Hypridle paused. System will stay awake.\" || (hypridle & notify-send -a \"System\" -i \"caffeine-off\" \"Normal Mode\" \"Hypridle started. Idle timers enabled.\")"))

hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

hl.bind(mainMod .. " + CTRL + Tab", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CTRL + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -q s +10%"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q s 10%-"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ 0 && pactl set-sink-volume @DEFAULT_SINK@ +5%"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ 0 && pactl set-sink-volume @DEFAULT_SINK@ -5%"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("~/.local/bin/custom/mic-lock.sh toggle"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.layer_rule({
    match = { namespace = "selection" },
    blur = false,
})

hl.layer_rule({
    match = { namespace = "slurp" },
    blur = false,
})

hl.window_rule({
    match = {
        class = "(dotfiles-floating)",
    },
    float = true,
    size = "1000 700",
    center = true,
})

hl.config({
    input = {
        kb_layout = "gb",
        numlock_by_default = true,
        follow_mouse = 1,
        mouse_refocus = false,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            scroll_factor = 1.0,
        },
    },
    -- -----------------------------------------------------
    -- General
    -- -----------------------------------------------------
    general = {
        gaps_in = 10,
        gaps_out = 14,
        border_size = 3,
        col = {
            active_border = color11,
            inactive_border = color8,
        },
        layout = "dwindle",
        resize_on_border = true,
    },
    -- -----------------------------------------------------
    -- Decoration
    -- -----------------------------------------------------
    decoration = {
        rounding = 10,
        active_opacity = 1.0,
        inactive_opacity = 0.9,
        fullscreen_opacity = 1.0,
        -- blur {
        --     enabled = true
        --     size = 6
        --     passes = 2
        --     new_optimizations = on
        --     ignore_opacity = true
        --     xray = true
        -- }
        shadow = {
            enabled = true,
            range = 30,
            render_power = 3,
            color = 0x66000000,
        },
    },
    -- -----------------------------------------------------
    -- Animations
    -- -----------------------------------------------------
    animations = {
        enabled = true,
    },
    -- -----------------------------------------------------
    -- Layouts
    -- -----------------------------------------------------
    dwindle = {
        preserve_split = true,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        initial_workspace_tracking = 1,
    },
    binds = {
        workspace_back_and_forth = false,
        allow_workspace_cycles = true,
    },
    -- -----------------------------------------------------
    -- Window Rules
    -- -----------------------------------------------------
    -- Zoom: Disable animations, shadows and floating for toolbars
    -- -----------------------------------------------------
    -- Keybindings
    -- -----------------------------------------------------
    -- Core Applications
    -- Window Management
    -- Vim Motions (Focus)
    -- Resizing
    -- Custom Script Bindings (from dotfiles/scripts)
    -- Actions from ML4W
    -- Workspaces
    -- Next/Previous Workspace
    -- Fn keys
    -- Mouse Bindings
    -- Layer Rules
    -- General floating
})

-- -----------------------------------------------------
-- Docked / undocked monitor handling
-- -----------------------------------------------------
-- Replaces the old hypr_monitor_auto.py + kanshi setup: when the DP-2 dock
-- monitor is present, disable the laptop screen; otherwise use it normally.
local function monitor_name(mon)
    if type(mon) == "table" then
        return mon.name
    end
    return mon
end

local function apply_docked()
    hl.exec_cmd("hyprctl keyword monitor DP-2,3440x1440@100,0x0,1")
    hl.exec_cmd("hyprctl keyword monitor eDP-1,disable")
end

local function apply_undocked()
    hl.exec_cmd("hyprctl keyword monitor eDP-1,preferred,auto,1")
end

local function is_docked()
    for _, mon in pairs(hl.get_monitors()) do
        if monitor_name(mon) == "DP-2" then
            return true
        end
    end
    return false
end

hl.on("monitor.added", function(mon)
    if monitor_name(mon) == "DP-2" then
        apply_docked()
    end
end)

hl.on("monitor.removed", function(mon)
    if monitor_name(mon) == "DP-2" then
        apply_undocked()
    end
end)

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=hyprland XCURSOR_THEME XCURSOR_SIZE")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Amber'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 36")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("swaync")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("~/.config/waybar/launch.sh")
    hl.exec_cmd("~/.local/bin/uv run --script ~/.local/bin/custom/rofi/wallpaper.py fetch")
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Amber 36")
    hl.exec_cmd("~/.local/bin/uv run --script ~/.local/bin/custom/rofi/specific_code_project.py ~/code/ember-data-processing", { workspace = "1 silent" })
    hl.exec_cmd("google-chrome-stable", { workspace = "2 silent" })
    hl.exec_cmd("slack", { workspace = "3 silent" })
    hl.exec_cmd("pear-desktop", { workspace = "7 silent" })
    hl.exec_cmd("zen-browser", { workspace = "9 silent" })

    if is_docked() then
        apply_docked()
    else
        apply_undocked()
    end
end)

