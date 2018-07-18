extends Control

"""Touch input control script."""

signal joystick_moved(movement, force)
signal button_pressed(button)

export (bool) var DEBUG_EVENTS = false

const JOYSTICK_DEADZONE = 0.30

onready var joystick = $margin/vbox/hbox/joystick
onready var attack_btn = $margin/vbox/hbox/buttons/attack
onready var special_btn = $margin/vbox/hbox/buttons/special

var is_mouse_over_joystick = false
var is_mouse_over_attack_button = false
var is_mouse_over_special_button = false

var is_mouse_clicked = false

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            is_mouse_clicked = event.pressed

            # Detect buttons
            if event.pressed:
                if is_mouse_over_attack_button:
                    emit_signal("button_pressed", "attack")
                elif is_mouse_over_special_button:
                    emit_signal("button_pressed", "special")

func _ready():
    joystick.connect("mouse_entered", self, "_on_joystick_mouse_entered")
    joystick.connect("mouse_exited", self, "_on_joystick_mouse_exited")
    attack_btn.connect("mouse_entered", self, "_on_attack_button_mouse_entered")
    attack_btn.connect("mouse_exited", self, "_on_attack_button_mouse_exited")
    special_btn.connect("mouse_entered", self, "_on_special_button_mouse_entered")
    special_btn.connect("mouse_exited", self, "_on_special_button_mouse_exited")

    if DEBUG_EVENTS:
        connect("joystick_moved", self, "_on_joystick_moved")
        connect("button_pressed", self, "_on_button_pressed")

func _process_joystick():
    """Process joystick movement."""
    var mouse_position = get_viewport().get_mouse_position()
    var joystick_position = joystick.get_global_position() + joystick.get_size() / 2
    var mouse_joystick_vec = mouse_position - joystick_position
    var force = mouse_joystick_vec / (joystick.get_size() / 2)

    if abs(force.x) < JOYSTICK_DEADZONE:
        pass
    else:
        if force.x < 0:
            emit_signal("joystick_moved", "left", -force.x)
        else:
            emit_signal("joystick_moved", "right", force.x)

    if abs(force.y) < JOYSTICK_DEADZONE:
        pass
    else:
        if force.y < 0:
            emit_signal("joystick_moved", "up", -force.y)
        else:
            emit_signal("joystick_moved", "down", force.y)

func _process(delta):
    if self.is_mouse_over_joystick and self.is_mouse_clicked:
        _process_joystick()

# Events

func _on_joystick_mouse_entered():
    self.is_mouse_over_joystick = true

func _on_joystick_mouse_exited():
    self.is_mouse_over_joystick = false

func _on_attack_button_mouse_entered():
    self.is_mouse_over_attack_button = true

func _on_attack_button_mouse_exited():
    self.is_mouse_over_attack_button = false

func _on_special_button_mouse_entered():
    self.is_mouse_over_special_button = true

func _on_special_button_mouse_exited():
    self.is_mouse_over_special_button = false

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