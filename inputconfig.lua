-- This file configures the input mappings for the game 'Radiant Rewind'
-- This file is read on startup, that means, you have to restart the game for your changes to work.

-- It must conform to the Lua syntax rules.
-- If you messed up the syntax and are stuck, you can delete this file 
-- and it will be re-created on the next startup of the game.

-- You can look up the constants for non-letter keys at https://love2d.org/wiki/KeyConstant
-- Mouse buttons are just numbers: 1 = left, 2 = right, 3 = middle, higher numbers are device specific
-- Joystick configuration is a but more tricky, see https://love2d.org/wiki/love.joystick


-- You can add any number of mouse buttons, keyboard keys and joystick buttons to an action.

keymapping = {
    click = {
        mouseButtons = {1},
        keys = {"space"},
        joystickButtons = {1}
    },
    quit = {
        mouseButtons = {},
        keys = {"escape"},
        joystickButtons = {}
    },       
    fullscreen = {
        mouseButtons = {},
        keys = {"f"},
        joystickButtons = {}
    },      
    mute = {
        mouseButtons = {},
        keys = {"m"},
        joystickButtons = {}
    }, 
    pause = {
        mouseButtons = {},
        keys = {"p"},
        joystickButtons = {9}
    },
    left = {
        mouseButtons = {},
        keys = {"a", "left", "kp4"},
        joystickButtons = {}
    },
    right = {
        mouseButtons = {},
        keys = {"d", "right", "kp6"},
        joystickButtons = {}
    },
    up = {
        mouseButtons = {},
        keys = {"w", "up", "kp8"},
        joystickButtons = {}
    },
    down = {
        mouseButtons = {},
        keys = {"s", "down", "kp2"},
        joystickButtons = {}
    },
    cheat = {
        mouseButtons = {},
        keys = {"n"},
        joystickButtons = {}
    },
    menu = {
        mouseButtons = {},
        keys = {"q"},
        joystickButtons = {}
    },
}

-- Gamepads usually have two axes per analog stick, one of which is the x axis, 
-- and one of which is the y axis. Axis numbers start at 1.
-- If you have multiple gamepads connected at once, each one will work, but they 
-- have the same config, i.e. axis 1 will be both the first axis of one gamepad
-- and the firt axis of the other gamepad.
axismapping = {
    xAxes = {1, 4},
    yAxes = {2, 3}
}