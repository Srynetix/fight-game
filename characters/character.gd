extends RigidBody2D

# Constants
var MAX_FLOOR_AIRBORNE_TIME = 0.15
var WALK_MAX_VELOCITY = 200.0
var WALK_ACCEL = 800.0
var WALK_DEACCEL = 800.0
var AIR_ACCEL = 800.0
var AIR_DEACCEL = 800.0
var JUMP_VELOCITY = 500.0
var STOP_JUMP_FORCE = 900.0
var MAX_JUMP_COUNT = 2

# States
var is_jumping = false
var is_stopping_jump = false
var is_siding_left = false

# Values
var animation = 'idle'
var airborne_time = 1e20
var floor_velocity = 0.0
var jump_count = 0

func detect_floor(state):
    var found_floor = false
    var floor_index = -1

    for x in range(state.get_contact_count()):
        var ci = state.get_contact_local_normal(x)
        if ci.dot(Vector2(0, -1)) > 0.6:
            found_floor = true
            floor_index = x

    return floor_index

func _integrate_forces(state):
    var lvel = state.get_linear_velocity()
    var step = state.get_step()

    var move_left = Input.is_action_pressed('ui_left')
    var move_right = Input.is_action_pressed('ui_right')
    var jump = Input.is_action_just_pressed('ui_accept')

    var next_siding_left = is_siding_left
    var next_animation = animation

    # De-apply last floor velocity
    lvel.x -= floor_velocity
    floor_velocity = 0.0

    # Detect floor
    var floor_index = detect_floor(state)
    var found_floor = floor_index != -1

    if found_floor:
        airborne_time = 0.0
    else:
        airborne_time += step

    var is_on_floor = airborne_time < MAX_FLOOR_AIRBORNE_TIME
    if is_jumping:
        if lvel.y > 0:
            is_jumping = false
        elif not jump:
            is_stopping_jump = true

        if is_stopping_jump:
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
        if not is_jumping and jump:
            lvel.y = -JUMP_VELOCITY
            is_jumping = true
            is_stopping_jump = false
            jump_count = 1

        # Siding
        if lvel.x < 0 and move_left:
            next_siding_left = true
        elif lvel.x > 0 and move_right:
            next_siding_left = false

        if is_jumping:
            pass
        elif abs(lvel.x) < 0.1:
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

        if not is_jumping and jump and jump_count < MAX_JUMP_COUNT:
            lvel.y = -JUMP_VELOCITY
            is_jumping = true
            is_stopping_jump = false
            jump_count += 1

        # Siding
        if lvel.x < 0 and move_left:
            next_siding_left = true
        elif lvel.x > 0 and move_right:
            next_siding_left = false

    if next_siding_left != is_siding_left:
        if next_siding_left:
            $sprite.scale.x = -abs($sprite.scale.x)
        else:
            $sprite.scale.x = abs($sprite.scale.x)

        is_siding_left = next_siding_left

    if found_floor:
        floor_velocity = state.get_contact_collider_velocity_at_position(floor_index).x
        lvel.x += floor_velocity

    # Animation
    if animation != next_animation:
        animation = next_animation
        $anim.play(animation)

    # Apply final velocity
    lvel += state.get_total_gravity() * step
    state.set_linear_velocity(lvel)