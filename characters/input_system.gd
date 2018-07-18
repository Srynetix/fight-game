extends Node

"""Input system."""

class BufferSorter:
    # Buffer sorter
    static func sort(a, b):
        # Sort using dt (idx 2)
        return a[2] < b[2]

# Buffer update signal.
# Receive last buffer.
signal buffer_update(buffer)

# Max size for each buffer
const INPUT_BUFFER_MAX_SIZE = 10

var move_buffer = []
var attack_buffer = []
var combo_buffer = []
var current_delta = 0
var player_id = -1
var virtual_input = null

var MOVE_ACTIONS = ["left", "right", "down", "jump", "up"]
var ATTACK_ACTIONS = ["attack", "special"]
var COMBO_ACTIONS = {
    "left_a": ["left", "attack"],
    "right_a": ["right", "attack"],
    "up_a": ["up", "attack"],
    "down_a": ["down", "attack"],
    "left_special": ["left", "special"],
    "right_special": ["right", "special"],
    "up_special": ["up", "special"],
    "down_special": ["down", "special"]
}

var INPUT_MAP = {
    "left": {
        "key": "left",
        "just": false
    },
    "right": {
        "key": "right",
        "just": false
    },
    "up": {
        "key": "up",
        "just": false,
    },
    "down": {
        "key": "down",
        "just": false,
    },
    "jump": {
        "key": "jump",
        "just": true
    },
    "attack": {
        "key": "attack",
        "just": true
    },
    "special": {
        "key": "special",
        "just": true
    }
}

var DISPLAY_MAP = {
    "left": "←",
    "right": "→",
    "up": "↑",
    "down": "↓",
    "jump": "j",
    "attack": "a",
    "left_a": "a←",
    "left_a_smash": "a←*",
    "right_a": "a→",
    "right_a_smash": "a→*",
    "up_a": "↑a",
    "up_a_smash": "↑a*",
    "down_a": "↓a",
    "down_a_smash": "↓a*",
    "special": "b",
    "left_special": "←b",
    "right_special": "→b",
    "up_special": "↑b",
    "down_special": "↓b"
}

var input_state = _generate_empty_input_state()

func _init(player_id):
    self.player_id = player_id

func _format_buffers():
    """
    Format buffers to later use.
    """
    var formatted = ""
    var buf_result = []

    for key_info in move_buffer:
        buf_result.append(key_info)
    for key_info in attack_buffer:
        buf_result.append(key_info)
    for key_info in combo_buffer:
        buf_result.append(key_info)

    # Sort by dt
    buf_result.sort_custom(BufferSorter, "sort")

    for key_info in buf_result:
        var key = key_info[0]
        var st = key_info[1]
        if not st:
            continue

        if key in DISPLAY_MAP:
            formatted += DISPLAY_MAP[key]
        else:
            formatted += "?"

        formatted += " "

    return formatted


func _detect_smash_combo(move, attack, diff):
    """
    Detect smash combo.
    """
    if move[1] == false or attack[1] == false:
        return ""

    for key in COMBO_ACTIONS:
        var checks = COMBO_ACTIONS[key]
        if checks[0] == move[0] and checks[1] == attack[0]:
            if attack[0] == "attack" and diff < 0.1:
                return key + "_smash"
            return key

    return ""

func _get_last_pressed(buffer):
    var state_idx = {}
    var idx = 0
    for key_info in buffer:
        if key_info[1]:
            state_idx[key_info[0]] = idx
        else:
            state_idx[key_info[0]] = -1
        idx += 1

    var fkidx = -1
    for key in state_idx:
        var kidx = state_idx[key]
        if kidx != -1:
            fkidx = kidx

    # Return last pressed
    if fkidx != -1:
        return buffer[fkidx]

    # Return last
    return buffer[len(buffer) - 1]

func _detect_combos():
    """
    Analyze buffers to detect combos.
    """
    var move_buf_len = len(move_buffer)
    if move_buf_len == 0:
        return

    var attack_buf_len = len(attack_buffer)
    if attack_buf_len == 0:
        return

    var move = _get_last_pressed(move_buffer)
    var attack = _get_last_pressed(attack_buffer)
    var diff = abs(move[2] - attack[2])

    var combo = _detect_smash_combo(move, attack, diff)
    if combo != '':
        print("COMBO " + combo)
        _insert_combo(combo)
        attack_buffer.pop_back()

func _insert_combo(combo):
    """Insert combo into combo buffer."""
    var buf_len = len(combo_buffer)
    if buf_len >= INPUT_BUFFER_MAX_SIZE / 3:
        combo_buffer.pop_front()
    combo_buffer.push_back([combo, true, current_delta])


func _get_buffer_from_key(key):
    """Get correct buffer depending on key type."""
    if key in MOVE_ACTIONS:
        return move_buffer
    else:
        return attack_buffer

func _update_buffer(key, state):
    """Update correct buffer with key and state."""
    var buffer = _get_buffer_from_key(key)
    var buf_len = len(buffer)
    if buf_len > 0:
        var head = buffer.back()
        if key == head[0] and state == head[1]:
            # Ignore key if same key and same state
            return

    if buf_len >= INPUT_BUFFER_MAX_SIZE / 3:
        buffer.pop_front()
    buffer.push_back([key, state, current_delta])

    # Detect combos and signal
    _detect_combos()
    emit_signal("buffer_update", _format_buffers())


func _get_player_input_action(name):
    """Get player input action."""
    return "p{id}_{name}".format({'id': self.player_id, 'name': name})


func _generate_empty_input_state():
    """Generate empty input state."""
    var state = {}
    for key in INPUT_MAP:
        state[key] = false

    return state

func _set_key_state(key, state):
    """Set key state."""
    if state != self.input_state[key]:
        _update_buffer(key, state)

    self.input_state[key] = state

func _handle_player_key(input_key):
    """Handle player key."""
    var key_info = INPUT_MAP[input_key]
    var key_name = self._get_player_input_action(key_info["key"])

    if self.virtual_input:
        self._set_key_state(input_key, virtual_input.get_virtual_input_state(input_key))
    else:
        if key_info["just"]:
            self._set_key_state(input_key, Input.is_action_just_pressed(key_name))
        else:
            self._set_key_state(input_key, Input.is_action_pressed(key_name))

# Public API

func handle_virtual_joystick(movement, force):
    """Handle virtual joystick."""
    if movement == "left":
        self._set_key_state("left", true)
    elif movement == "right":
        self._set_key_state("right", true)

func handle_virtual_button(button):
    """Handle virtual button."""
    if button == "attack":
        self._set_key_state("attack", true)
    elif button == "special":
        self._set_key_state("special", true)

func enable_key_state(key):
    """Enable key state."""
    self._set_key_state(key, true)

func disable_key_state(key):
    """Disable key state."""
    self._set_key_state(key, false)

func get_key_state(key):
    """Get key state."""
    return self.input_state[key]
#    return false

func reset_input_state():
    """Reset input state."""
    self.input_state = _generate_empty_input_state()

func handle_player_keys():
    """Handle player keys."""
    for key in INPUT_MAP:
        self._handle_player_key(key)

func update_system(delta):
    """Update input system."""
    # Delta update
    self.current_delta += delta

func set_virtual_input(virtual_input):
    """Set current virtual input."""
    self.virtual_input = virtual_input