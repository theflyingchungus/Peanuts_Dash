extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $Jump
@onready var dash_sound: AudioStreamPlayer2D = $Dash


const SPEED = 400.0

# Stops the player upon entering/exiting a level
var movement_locked = false

# Dash settings
@export var dash_duration = 0.15
@export var dash_max_speed = 900.0
@export var dash_speed_curve: Curve  # assign in Inspector - shapes speed over dash duration
@export var dash_cooldown_duration = 0.3  # prevents spamming ground dashes back-to-back
@export var post_dash_float_duration = 0.1
@export var dash_jump_boost_multiplier = 1.5
@export var coyote_time_duration = 0.1  # seconds of grace after leaving a platform
@export var jump_buffer_duration = 0.1   # how early a jump press is still remembered

var jump_velocity = -800.0
var dash_timer = 0.0
var is_dashing = false
var dash_direction: Vector2 = Vector2.RIGHT
var post_dash_float_timer = 0.0
var dash_cooldown_timer = 0.0
var coyote_timer = 0.0
var jump_buffer_timer = 0.0

# Dash gating
var has_jumped = false
var has_dashed = false

# Post-dash tuning
@export var end_dash_speed_multiplier = 0.75  # how much velocity carries into normal movement

# Hit-stop tuning
@export var hitstop_frames = 3  # how many physics frames to freeze

var hitstop_timer = 0
var is_frozen = false

# After-image tuning
@export var afterimage_scene: PackedScene  # assign a small scene below
@export var afterimage_spawn_interval = 0.02

var afterimage_timer = 0.0

func _physics_process(delta: float) -> void:
	if is_frozen:
		hitstop_timer -= 1
		if hitstop_timer <= 0:
			is_frozen = false
		return  # skip all movement/dash logic while frozen
		
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		
	if is_on_floor() and not is_dashing:
		has_jumped = false
		has_dashed = false
		coyote_timer = coyote_time_duration	# refresh grace window while grounded
	else:
		coyote_timer -= delta				#counts down once airborne

	# Record a jump press into the buffer whenever it happens
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = jump_buffer_duration
	else:
		jump_buffer_timer -= delta
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- Handle dash movement (overrides normal physics while active) ---
	if is_dashing:
		# Allow jump to cancel the dash early, keeping dash momentum
		if Input.is_action_just_pressed("ui_accept") and has_jumped == false:
			_end_dash_with_jump()
			jump_sound.play()
		else:
			_process_dash(delta)
		move_and_slide()
		return # skip normal movement/gravity this frame
	
	if post_dash_float_timer > 0:
		post_dash_float_timer -= delta
		# skip gravity entirely during float window
	elif not is_on_floor():
		velocity += get_gravity() * delta
	
	# Add walking animation.
	if velocity.x > 1 or velocity.x < -1:
		animated_sprite_2d.animation = "walk"
	else:
		animated_sprite_2d.animation = "idle"

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if not movement_locked:
		# Handle walking
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
		# Handle jumping
		if jump_buffer_timer > 0 and coyote_timer > 0:
			velocity.y = jump_velocity
			has_jumped = true
			coyote_timer = 0
			jump_buffer_timer = 0   # consume the buffer so it can't fire twice
			jump_sound.play()
		
		# Dash input: allowed on ground (with cooldown) OR once per jump in the air
		var can_ground_dash = is_on_floor() and dash_cooldown_timer <= 0
		var can_air_dash = not is_on_floor() and has_jumped and not has_dashed
		
		# Handle dashing
		if Input.is_action_just_pressed("dash") and (can_ground_dash or can_air_dash):
			start_dash()

	else:
		velocity.x = 0
	
	if direction != 0:
		dash_direction.x = sign(direction)
	
	move_and_slide()
	
	if direction == 1.0:
		animated_sprite_2d.flip_h = false
	elif direction == -1.0:
		animated_sprite_2d.flip_h = true
		
func lock_movement():
	movement_locked = true

func unlock_movement():
	movement_locked = false
	
func start_dash():
	is_dashing = true
	has_dashed = true
	dash_timer = 0.0
	is_frozen = true
	hitstop_timer = hitstop_frames
	
	var input_dir = Vector2(
	Input.get_axis("ui_left", "ui_right"),
	Input.get_axis("ui_up", "ui_down")  # only if you have up/down actions mapped
	)
	if input_dir.length() > 0:
		dash_direction = input_dir.normalized()
	else:
		dash_direction = Vector2(dash_direction.x, 0)  # horizontal-only fallback
	dash_cooldown_timer = dash_cooldown_duration  # applies whether ground or air dash
	dash_sound.play()

func _process_dash(delta):
	dash_timer += delta
	var t = clamp(dash_timer / dash_duration, 0.0, 1.0)

	var speed_multiplier = 1.0
	if dash_speed_curve:
		speed_multiplier = dash_speed_curve.sample(t)
	else:
		# fallback shaping if no curve assigned: fast start, ease out
		speed_multiplier = 1.0 - pow(t, 3)

	velocity = dash_direction * dash_max_speed * speed_multiplier

	# Spawn afterimages at intervals
	afterimage_timer -= delta
	if afterimage_timer <= 0:
		spawn_afterimage()
		afterimage_timer = afterimage_spawn_interval

	if dash_timer >= dash_duration:
		is_dashing = false
		# carry momentum into normal movement instead of hard stopping
		velocity = dash_direction * dash_max_speed * end_dash_speed_multiplier
		post_dash_float_timer = post_dash_float_duration # Brief no gravity after dash

func _end_dash_with_jump():
	is_dashing = false
	velocity.y = jump_velocity
	velocity.x *= dash_jump_boost_multiplier
	# velocity.x is intentionally left untouched — carries the dash's horizontal speed forward
	has_jumped = true
	post_dash_float_timer = post_dash_float_duration  # optional: reuse the float window for a floatier arc

func spawn_afterimage():
	var ghost = Sprite2D.new()
	ghost.texture = $AnimatedSprite2D.sprite_frames.get_frame_texture($AnimatedSprite2D.animation, $AnimatedSprite2D.frame)  # copy your player's current sprite frame
	ghost.scale = $AnimatedSprite2D.scale * scale  # combine sprite scale + player node scale
	ghost.flip_h = $AnimatedSprite2D.flip_h
	ghost.modulate = Color(1, 1, 1, 0.5)  # semi-transparent
	get_parent().add_child(ghost)
	ghost.global_position = global_position
	ghost.global_rotation = global_rotation

	var tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.3)  # fade out over 0.3s
	tween.tween_callback(ghost.queue_free)
