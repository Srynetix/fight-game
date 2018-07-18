extends Control

"""Touch input control script."""

signal joystick_moved(movement, pressed, force)
signal button_pressed(button, pressed)

export (bool) var Disabled = false
export (bool) var DEBUG_EVENTS = false
export (bool) var DEBUG_LIGHTS = false

const JOYSTICK_DEADZONE = 0.30

onready var joystick = $margin/vbox/hbox/joystick
onready var joystick_ball = $margin/vbox/hbox/joystick/container/ball
onready var jump_btn = $margin/vbox/hbox/buttons/jump
onready var attack_btn = $margin/vbox/hbox/buttons/attack
onready var special_btn = $margin/vbox/hbox/buttons/special

onready var debug_ui = $margin/vbox/debughbox

var touch_system = preload("res://scripts/touch_system.gd").new()

var virtual_input_state = _generate_empty_input_state()
var joystick_touch_idx = -1
var jump_touch_idx = -1
var attack_touch_idx = -1
var special_touch_idx = -1

func _lighten_button(button):
    var col = button.modulate
    col.a = 0.95
    button.modulate = col

func _darken_button(button):
    var col = button.modulate
    col.a = 0.25
    button.modulate = col

func _generate_empty_input_state():
    return {
        "left": [false, 0],
        "right": [false, 0],
        "up": [false, 0],
        "down": [false, 0],
        "jump": false,
        "attack": false,
        "special": false
    }

func _reset_movement_state():
    for key in ["left", "right", "up", "down"]:
        self.virtual_input_state[key] = [false, 0]

func _update_debug_ui():
    for key in ["left", "right", "up", "down"]:
        var state_info = self.virtual_input_state[key]
        var state_val = state_info[0]

        if state_val:
            debug_ui.get_node(key).color = Color("#00ff00")
        else:
            debug_ui.get_node(key).color = Color("#ffffff")

    for key in ["jump", "attack", "special"]:
        var state_val = self.virtual_input_state[key]

        if state_val:
            debug_ui.get_node(key).color = Color("#00ff00")
        else:
            debug_ui.get_node(key).color = Color("#ffffff")

func _on_touch_released(idx):
    if idx == joystick_touch_idx:
        joystick_touch_idx = -1
        self._reset_movement_state()
        joystick_ball.rect_position = joystick.get_size() / 2 - joystick_ball.get_size() / 2
        self._darken_button(self.joystick)

    if idx == attack_touch_idx:
        attack_touch_idx = -1
        self.virtual_input_state["attack"] = false
        self._darken_button(self.attack_btn)

    if idx == special_touch_idx:
        special_touch_idx = -1
        self.virtual_input_state["special"] = false
        self._darken_button(self.special_btn)

    if idx == jump_touch_idx:
        jump_touch_idx = -1
        self.virtual_input_state["jump"] = false
        self._darken_button(self.jump_btn)

# Debug

func _on_joystick_moved(movement, force):
    print("Joystick: {movement} ({force})".format({
        "movement": movement,
        "force": force
    }))

func _on_button_pressed(button):
    print("Button: {button}".format({
        "button": button
    }))

# Standard lifecycle

func _ready():
    if DEBUG_EVENTS:
        connect("joystick_moved", self, "_on_joystick_moved")
        connect("button_pressed", self, "_on_button_pressed")

    self.touch_system.connect("touch_released", self, "_on_touch_released")

    debug_ui.visible = DEBUG_LIGHTS

func _input(event):
    self.touch_system.handle_input(event)

    var joystick_rect = joystick.get_global_rect()
    var attack_btn_rect = attack_btn.get_global_rect()
    var special_btn_rect = special_btn.get_global_rect()
    var jump_btn_rect = jump_btn.get_global_rect()

    # Handle touch events
    if event is InputEventScreenTouch:
        var joystick_touch_data = self.touch_system.detect_touch_in_rect(joystick_rect)
        if joystick_touch_data != null:
            joystick_touch_idx = joystick_touch_data.touch_idx

        var attack_touch_data = self.touch_system.detect_touch_in_rect(attack_btn_rect)
        if attack_touch_data != null:
            attack_touch_idx = attack_touch_data.touch_idx
            self.virtual_input_state["attack"] = true
            self._lighten_button(attack_btn)

        var special_touch_data = self.touch_system.detect_touch_in_rect(special_btn_rect)
        if special_touch_data != null:
            special_touch_idx = special_touch_data.touch_idx
            self.virtual_input_state["special"] = true
            self._lighten_button(special_btn)

        var jump_touch_data = self.touch_system.detect_touch_in_rect(jump_btn_rect)
        if jump_touch_data != null:
            jump_touch_idx = jump_touch_data.touch_idx
            self.virtual_input_state["jump"] = true
            self._lighten_button(jump_btn)

    # Handle drag event
    if event is InputEventScreenDrag:
        if joystick_rect.has_point(event.position):
            var joystick_position = joystick.get_global_position() + joystick.get_size() / 2
            var mouse_joystick_vec = event.position - joystick_position
            var force = mouse_joystick_vec / (joystick.get_size() / 2)

            # Move joystick ball
            joystick_ball.rect_position = (joystick.get_size() / 2 - joystick_ball.get_size() / 2) + (force * joystick.get_size() / 2)

            # Reset movement
            self._reset_movement_state()

            if abs(force.x) < JOYSTICK_DEADZONE:
                pass
            else:
                if force.x < 0:
                    self.virtual_input_state["left"] = [true, -force.x]
                else:
                    self.virtual_input_state["right"] = [true, force.x]
                self._lighten_button(joystick)

            if abs(force.y) < JOYSTICK_DEADZONE:
                pass
            else:
                if force.y < 0:
                    self.virtual_input_state["up"] = [true, -force.y]
                else:
                    self.virtual_input_state["down"] = [true, force.y]
                self._lighten_button(joystick)

func _process(delta):
    self._update_debug_ui()

# Public API

func get_virtual_input_state(key):
    """Get virtual input state for one key."""
    var state = self.virtual_input_state[key]
    if typeof(state) == TYPE_ARRAY:
        return state[0]
    else:
        return state