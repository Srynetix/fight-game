extends RigidBody2D

# Exports
export(int) var PlayerID = 1

# Signals
signal hit(attacker, damage)
signal damage_update(target)

# Imports
var attack_system = preload('res://characters/attack_system.gd').new()
var input_system = preload('res://characters/input_system.gd').new()

# Constants
var MAX_FLOOR_AIRBORNE_TIME = 0.15
var WALK_MAX_VELOCITY = 200.0
var WALK_ACCEL = 800.0
var WALK_DEACCEL = 800.0
var WALK_THRESHOLD = 0.1
var AIR_ACCEL = 800.0
var AIR_DEACCEL = 800.0
var JUMP_VELOCITY = 500.0
var STOP_JUMP_FORCE = 900.0
var MAX_JUMP_COUNT = 3
var ATTACK_TIME = 0.15
var HIT_TIME = 0.25
var FLOOR_DETECTION_THRESHOLD = 0.6

# States
var is_jumping = false
var is_stopping_jump = false
var is_siding_left = false
var is_attacking = false
var is_hit = false

# Values
var animation = 'idle'
var airborne_time = 1e20
var attack_time = ATTACK_TIME
var hit_time = HIT_TIME
var hit_direction = Vector2(1, 1)
var floor_velocity = 0.0
var jump_count = 0

var current_damages = 0
var current_attack_type = ''
var hit_velocity_next_frame = 0

func get_attack_type_from_input():
    if self.input_system.get_key_state("attack"):
        if self.input_system.get_key_state("move_left") or self.input_system.get_key_state("move_right"):
            return 'high'
        else:
            return 'low'

    return ''


func _ready():
    connect("hit", self, "on_hit")

func _process(delta):
    self.input_system.update_system(delta)

func on_hit(attacker):
    if not self.is_hit:
        var attack_data = attack_system.get_data_from_attack(attacker.current_attack_type)
        var attack_hit_direction = (self.position - attacker.position).normalized()

        print('Attacked by {name}, w/ {damage} damages in direction {direction}.'.format({
            'name': attacker.name,
            'damage': attack_data["dmg"],
            'direction': attack_hit_direction
        }))

        self.current_damages += attack_data["dmg"]
        self.is_hit = true
        self.hit_velocity_next_frame = attack_system.calculate_impulse_from_attack(self, attack_data)

        self.hit_direction.x = attack_hit_direction.x

        # Damage update
        emit_signal("damage_update", self)

func detect_floor(state):
    var found_floor = false
    var floor_index = -1

    for x in range(state.get_contact_count()):
        var ci = state.get_contact_local_normal(x)
        if ci.dot(Vector2(0, -1)) > FLOOR_DETECTION_THRESHOLD:
            found_floor = true
            floor_index = x

    return floor_index

func detect_player(state):
    var player_found = null

    for x in range(state.get_contact_count()):
        var obj = state.get_contact_collider_object(x)
        if obj.is_in_group('character'):
            player_found = obj

    return player_found

func _handle_character_input():
    pass

func _integrate_forces(state):
    var lvel = state.get_linear_velocity()
    var step = state.get_step()
    var impulse = Vector2(0, 0)

    # Handle input
    self._handle_character_input()

    var move_left = self.input_system.get_key_state("move_left")
    var move_right = self.input_system.get_key_state("move_right")
    var jump = self.input_system.get_key_state("jump")
    var attack = self.input_system.get_key_state("attack")

    var next_siding_left = self.is_siding_left
    var next_animation = self.animation

    # De-apply last floor velocity
    lvel.x -= self.floor_velocity
    self.floor_velocity = 0.0

    # Detect player
    var player = detect_player(state)
    if player:
        if self.is_attacking and not player.is_hit:
            player.emit_signal('hit', self)

    # Detect floor
    var floor_index = detect_floor(state)
    var found_floor = floor_index != -1

    if found_floor:
        self.airborne_time = 0.0
    else:
        self.airborne_time += step

    var is_on_floor = self.airborne_time < MAX_FLOOR_AIRBORNE_TIME
    if self.is_jumping:
        if lvel.y > 0:
            self.is_jumping = false
        elif not jump:
            self.is_stopping_jump = true

        if self.is_stopping_jump:
            lvel.y += STOP_JUMP_FORCE * step

    if is_on_floor:
        if move_left and not move_right:
            if lvel.x > -WALK_MAX_VELOCITY:
                lvel.x -= WALK_ACCEL * step
        elif move_right and not move_left:
            if lvel.x < WALK_MAX_VELOCITY:
                lvel.x += WALK_ACCEL * step
        else:
            var xv = abs(lvel.x)
            xv -= WALK_DEACCEL * step
            if xv < 0:
                xv = 0
            lvel.x = sign(lvel.x) * xv

        # Check jump
        if not self.is_jumping and jump:
            lvel.y = -JUMP_VELOCITY
            self.is_jumping = true
            self.is_stopping_jump = false
            self.jump_count = 1

        # Siding
        if lvel.x < 0 and move_left:
            next_siding_left = true
        elif lvel.x > 0 and move_right:
            next_siding_left = false

        if not self.is_attacking:
            if self.is_jumping:
                next_animation = 'jump'
            elif abs(lvel.x) < WALK_THRESHOLD:
                next_animation = 'idle'
            else:
                next_animation = 'walk'

    else:
        # In air
        if move_left and not move_right:
            if lvel.x > -WALK_MAX_VELOCITY:
                lvel.x -= AIR_ACCEL * step
        elif move_right and not move_left:
            if lvel.x < WALK_MAX_VELOCITY:
                lvel.x += AIR_ACCEL * step
        else:
            var xv = abs(lvel.x)
            xv -= AIR_DEACCEL * step
            if xv < 0:
                xv = 0
            lvel.x = sign(lvel.x) * xv

        if not self.is_jumping and jump and self.jump_count < MAX_JUMP_COUNT:
            lvel.y = -JUMP_VELOCITY
            self.is_jumping = true
            self.is_stopping_jump = false
            self.jump_count += 1

        # Siding
        if lvel.x < 0 and move_left:
            next_siding_left = true
        elif lvel.x > 0 and move_right:
            next_siding_left = false

    # Attack
    if self.is_attacking:
        self.attack_time -= step
        if self.attack_time <= 0:
            self.attack_time = ATTACK_TIME
            self.is_attacking = false

    # Hit
    if self.is_hit:
        if self.hit_time == HIT_TIME:
            # Apply hit impulse
            impulse = self.hit_velocity_next_frame * self.hit_direction

        self.hit_time -= step
        if self.hit_time <= 0:
            self.hit_time = HIT_TIME
            self.is_hit = false

    # Attacking?
    if not self.is_attacking and attack:
        self.is_attacking = true
        self.current_attack_type = get_attack_type_from_input()
        next_animation = 'attack'

    if next_siding_left != self.is_siding_left:
        if next_siding_left:
            $sprite.scale.x = -abs($sprite.scale.x)
        else:
            $sprite.scale.x = abs($sprite.scale.x)

        self.is_siding_left = next_siding_left

    if found_floor:
        self.floor_velocity = state.get_contact_collider_velocity_at_position(floor_index).x
        lvel.x += self.floor_velocity

    # Animation
    if self.animation != next_animation:
        self.animation = next_animation
        $anim.play(self.animation)

    # Apply final velocity
    lvel += state.get_total_gravity() * step

    # Apply impulse
    lvel += impulse

    state.set_linear_velocity(lvel)