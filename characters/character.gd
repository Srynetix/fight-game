extends RigidBody2D

# Exports
export(int) var PlayerID = 1

# Signals
signal hit(attacker, damage)

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
var ATTACK_TIME = 0.25
var HIT_TIME = 0.25
var HIT_VELOCITY = Vector2(500, -100)
var FLOOR_DETECTION_THRESHOLD = 0.6

# Inputs
var is_input_left_pressed = false
var is_input_right_pressed = false
var is_input_jump_just_pressed = false
var is_input_attack_just_pressed = false

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
var hit_direction = Vector2(0, 0)
var floor_velocity = 0.0
var jump_count = 0

func _ready():
    connect("hit", self, "on_hit")

func on_hit(attacker, damage):
    if not self.is_hit:
        self.hit_direction = (self.position - attacker.position).normalized()

        print('Attacked by {name}, w/ {damage} damages in direction {direction}.'.format({
            'name': attacker.name,
            'damage': damage,
            'direction': self.hit_direction
        }))

        self.is_hit = true

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

func handle_input():
    """Do not handle input in base class."""

func _integrate_forces(state):
    var lvel = state.get_linear_velocity()
    var step = state.get_step()
    var impulse = Vector2(0, 0)

    self.handle_input()
    var move_left = self.is_input_left_pressed
    var move_right = self.is_input_right_pressed
    var jump = self.is_input_jump_just_pressed
    var attack = self.is_input_attack_just_pressed

    var next_siding_left = self.is_siding_left
    var next_animation = self.animation

    # De-apply last floor velocity
    lvel.x -= self.floor_velocity
    self.floor_velocity = 0.0

    # Detect player
    var player = detect_player(state)
    if player:
        if self.is_attacking and not player.is_hit:
            player.emit_signal('hit', self, 10)

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
            impulse = HIT_VELOCITY * self.hit_direction

        self.hit_time -= step
        if self.hit_time <= 0:
            self.hit_time = HIT_TIME
            self.is_hit = false

    # Attacking?
    if not self.is_attacking and attack:
        self.is_attacking = true
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
    # state.integrate_forces()