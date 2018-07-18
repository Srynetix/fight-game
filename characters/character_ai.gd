extends "res://characters/character.gd"

export (bool) var Disable = false

onready var attack_timer = $attack_timer
onready var idle_timer = $idle_timer

var PLAYER_LENGTH_THRESHOLD = 40
var IDLE_DELAY = 1          # secs
var ACTIVE_DELAY = 2        # secs
var ATTACK_DELAY = 0.35     # secs

var attack_at_next_turn = false
var is_idle = false

func _ready():
    """Ready."""
    attack_timer.wait_time = ATTACK_DELAY
    attack_timer.connect("timeout", self, "_on_attack_timer_timeout")

    idle_timer.wait_time = ACTIVE_DELAY
    idle_timer.connect("timeout", self, "_on_idle_timer_timeout")

    idle_timer.start()

func _detect_players():
    """Detect other players."""
    var output_characters = []
    var characters = get_tree().get_nodes_in_group("character")
    for c in characters:
        if c != self:
            output_characters.append(c)

    return output_characters

func _on_attack_timer_timeout():
    """On attack timer timeout."""
    if not self.is_hit and not self.is_idle:
        self.attack_at_next_turn = true

func _on_idle_timer_timeout():
    """On idle timer timeout."""
    if self.is_idle:
        idle_timer.wait_time = ACTIVE_DELAY
    else:
        idle_timer.wait_time = IDLE_DELAY

    self.is_idle = !self.is_idle
    idle_timer.start()

func _handle_character_input():
    """Handle character input."""

    # Reset inputs
    self.input_system.reset_input_state()

    # Idle
    if self.is_idle:
        return

    if Disable:
        return

    # Attacking
    if attack_timer.time_left > 0:
        return

    var players = self._detect_players()
    var first = players[0]

    var p_vec = first.position - position
    var p_direction = p_vec.normalized()
    var p_length = p_vec.length()

    if p_direction.y < -0.5:
        if not self.is_jumping:
            self.input_system.enable_key_state("jump")

    if abs(p_length) > PLAYER_LENGTH_THRESHOLD:
        if p_direction.x > 0:
            self.input_system.enable_key_state("right")
        else:
            self.input_system.enable_key_state("left")
    else:
        attack_timer.start()

    if self.attack_at_next_turn:
        self.input_system.enable_key_state("attack")
        self.attack_at_next_turn = false
