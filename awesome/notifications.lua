local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local naughty = require("naughty")

local helpers = require("helpers")

-- Icon size
-- naughty.config.defaults['icon_size'] = beautiful.notification_icon_size

-- Timeouts
naughty.config.defaults.timeout = 5
naughty.config.presets.low.timeout = 2
naughty.config.presets.critical.timeout = 12

-- -- Apply theme variables
naughty.config.padding = beautiful.notification_padding
naughty.config.spacing = beautiful.notification_spacing
naughty.config.defaults.margin = beautiful.notification_margin
naughty.config.defaults.border_width = beautiful.notification_border_width

naughty.config.presets.normal = {
    font = "IBM Plex 10",
    fg = beautiful.notification_fg,
    -- bg           = beautiful.notification_bg,
    border_width = beautiful.notification_border_width,
    margin = beautiful.notification_margin,
    position = beautiful.notification_position
}

naughty.config.presets.low = {
    font = beautiful.notification_font,
    fg = beautiful.notification_fg,
    -- bg           = beautiful.notification_bg,
    border_width = beautiful.notification_border_width,
    margin = beautiful.notification_margin,
    position = beautiful.notification_position
}

naughty.config.presets.ok = naughty.config.presets.low
naughty.config.presets.info = naughty.config.presets.low
naughty.config.presets.warn = naughty.config.presets.normal

naughty.config.presets.critical = {
    font = beautiful.notification_font,
    fg = beautiful.notification_crit_fg,
    -- bg           = beautiful.notification_crit_bg,
    border_width = beautiful.notification_border_width,
    margin = beautiful.notification_margin,
    position = beautiful.notification_position
}

-- For antialiasing
-- The real background color is set in the widget_template
local notification_bg = beautiful.notification_bg
beautiful.notification_bg = "#00000000"

-- Template
-- ===================================================================
naughty.connect_signal(
    "request::display",
    function(n)
        local custom_notification_icon =
            wibox.widget {
            font = "icomoon 14",
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox
        }

        -- Default symbol and color
        local symbol = ""
        local color = beautiful.xforeground

        -- Try to detect the notification source and change the symbol and/or color ccordingly
        if n.title == "Telegram" then
            symbol = ""
        elseif n.title == "Volume" then
            symbol = ""
            n.title = ""
        elseif n.title == "Screenshot" then
            symbol = ""
        elseif n.title == "Captured" then
            -- n.title = ""
            symbol = ""
        elseif n.title == "Performance mode" then
            symbol = ""
        elseif n.title == "Night mode" then
            symbol = ""
        elseif n.title:match("Connection") then
            symbol = ""
        elseif n.title == "Battery status" then
            -- symbol = ""
            symbol = ""
        elseif n.title == "Charger status" then
            symbol = ""
            n.title = ""
        elseif n.title:match("YouTube") then
            -- symbol = ""
            -- symbol = ""
            symbol = ""
        end

        naughty.layout.box {
            notification = n,
            type = "splash",
            -- For antialiasing: The real shape is set in widget_template
            shape = gears.shape.rectangle,
            border_width = beautiful.notification_border_width,
            border_color = beautiful.notification_border_color,
            widget_template = {
                {
                    {
                        {
                            {
                                {
                                    {
                                        markup = helpers.colorize_text(symbol, color),
                                        widget = custom_notification_icon
                                    },
                                    margins = beautiful.notification_margin,
                                    widget = wibox.container.margin
                                },
                                naughty.widget.message,
                                {
                                    naughty.list.actions,
                                    margins = beautiful.notification_margin,
                                    widget = wibox.container.margin
                                },
                                layout = wibox.layout.fixed.horizontal
                            },
                            bg = "#00000000",
                            id = "background_role",
                            widget = naughty.container.background
                        },
                        strategy = "min",
                        width = dpi(100),
                        widget = wibox.container.constraint
                    },
                    strategy = "max",
                    width = beautiful.notification_max_width or dpi(500),
                    widget = wibox.container.constraint
                },
                -- Anti-aliasing container
                bg = notification_bg,
                -- This will be the anti-aliased shape of the notification
                shape = helpers.rrect(beautiful.notification_border_radius),
                margins = beautiful.notification_margin,
                widget = wibox.container.background
            }
        }
    end
)

-- naughty.disconnect_signal("request::display", naughty.default_notification_handler)

-- Battery notifications
-- ===================================================================

-- Helper variables
local charger_plugged = true
local battery_full_already_notified = true
local battery_low_already_notified = false
local battery_critical_already_notified = false

local last_notification
local function send_notification(title, text, icon, timeout)
    local args = {
        title = title,
        text = text,
        icon = icon,
        timeout = timeout
    }
    if last_notification and not last_notification.is_expired then
        last_notification.title = args.title
        last_notification.text = args.text
        last_notification.icon = args.icon
    else
        last_notification = naughty.notification(args)
    end

    last_notification = notification
end

-- Full / Low / Critical notifications
awesome.connect_signal(
    "evil::battery",
    function(battery)
        local text
        local icon
        local timeout

        if battery then
            if not charger_plugged then
                icon = icons.battery
                if battery < 6 and not battery_critical_already_notified then
                    battery_critical_already_notified = true
                    text = helpers.colorize_text("CRITICAL", beautiful.xcolor9)
                    timeout = 0
                elseif battery < 16 and not battery_low_already_notified then
                    battery_low_already_notified = true
                    text = helpers.colorize_text("Low", beautiful.xcolor11)
                    timeout = 6
                end
            else
                icon = icons.battery_charging
                if battery > 99 and not battery_full_already_notified then
                    battery_full_already_notified = true
                    text = helpers.colorize_text("Full", beautiful.xcolor10)
                    timeout = 6
                end
            end

            -- If text has been initialized, then we need to send a
            -- notification
            if text then
                send_notification("Battery status", text, icon, timeout)
            end
        end
    end
)

-- Charger notifications
local charger_first_time = true
awesome.connect_signal(
    "evil::charger",
    function(plugged)
        charger_plugged = plugged
        local text
        local icon
        -- TODO if charger is plugged and battery is full, then set
        -- battery_full_already_notified to true
        if plugged then
            battery_critical_already_notified = false
            battery_low_already_notified = false
            text = "Plugged"
            icon = icons.battery_charging
        else
            battery_full_already_notified = false
            text = "Unplugged"
            icon = icons.battery
        end

        -- Do not send a notification the first time (when AwesomeWM (re)starts)
        if charger_first_time then
            charger_first_time = false
        else
            send_notification("Charger status", text, icon, 3)
        end
    end
)
