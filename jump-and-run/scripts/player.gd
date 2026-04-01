extends CharacterBody2D

const SPEED = 200
const JUMP_VELOCITY = 400
const PUSH_FORCE = 20
const WATER_GRAVITY = 0.3
const WATER_RUN = 0.5

enum State {IDLE, RUN, JUMP, FALL, DEAD}
var state  = null

var enable_double_jump = false
var double_jump = false
var in_water = false

var is_enemy_free = true

var health = 10
var score = 0

@export var print_state_transitions = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var anim : AnimatedSprite2D = get_node("AnimatedSprite2D");
@onready var timer : Timer = get_node("InvincibilityTimer")
@onready var hitbox_area : Area2D = get_node("Hitbox")

func _ready():
	print("ready")
	set_floor_snap_length(2) # "snap" to the floor when going slopes down (default: 1)
	reset_game()

func _process(delta):
	if Global.enable_camera and not $Camera2D.enabled:
		# enable the player-camera
		$Camera2D.enabled = true

func get_jump_action() -> bool:
	return Input.is_action_just_pressed("ui_accept")

func get_direction():
	var direction = Input.get_axis("ui_left", "ui_right")

	if direction < 0:
		anim.flip_h = true;
	elif direction > 0:
		anim.flip_h = false;

	return direction

func reset_game():
	health = 10
	enable_double_jump = false
	# cleanup the current level
	get_parent().get_node("CurrentLevel").get_child(0).cleanup()
	# start randomly at one of the starting positions
	var n = randi_range(0,get_parent().get_node("CurrentLevel").get_child(0).get_node("StartPositions").get_child_count() - 1)
	global_position = get_parent().get_node("CurrentLevel").get_child(0).get_node("StartPositions").get_child(n).global_position
	timer.stop()
	hitbox_area.set_collision_mask_value(3, true)
	is_enemy_free = true
	state = State.IDLE

func _physics_process(delta):
	if health <= 0 and state != State.DEAD:
		velocity.x = 0
		velocity.y = 0
		anim.play("hurt")
		state = State.DEAD
	else:
		if not timer.is_stopped():
			# we were hit
			anim.set_visible(randi_range(0,1))
		else:
			anim.set_visible(true)

	var state_last = state

	if state == State.DEAD:
		if not anim.is_playing():
			reset_game()
	elif state == State.IDLE:
		velocity.x = 0
		# transitions possible: RUN, FALL, JUMP
		if not is_on_floor():
			state = State.FALL
		elif get_jump_action():
			state = State.JUMP
		elif get_direction() != 0:
			state = State.RUN
		else:
			anim.play("idle")
	elif state == State.RUN:
		# transitions possible: IDLE, FALL, JUMP
		if not is_on_floor():
			state = State.FALL
		elif get_jump_action():
			state = State.JUMP
		else:
			var direction = get_direction()
			if direction != 0:
				anim.play("run")
				if in_water:
					velocity.x = direction * SPEED * WATER_RUN
				else:
					velocity.x = direction * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				if velocity.x == 0:
					state = State.IDLE
	elif state == State.JUMP:
		# transitions possible: FALL
		anim.play("jump")
		velocity.y = -JUMP_VELOCITY
		state = State.FALL
		# no need to check for x direction; happens in "FALL"
	elif state == State.FALL:
		# transitions possible: IDLE
		if double_jump and get_jump_action():
			state = State.JUMP
			double_jump = false
		else:
			if is_on_floor():
				velocity.y = 0
				state = State.IDLE
				if enable_double_jump:
					double_jump = true
			else:
				if velocity.y > 0:
					anim.play("fall")

				# Add the gravity.
				if in_water and velocity.y > 0:
					# falling inside water
					velocity.y += gravity * WATER_GRAVITY * delta
				else:
					# falling outside water or jumping (inside or outside water)
					velocity.y += gravity * delta
				
				var direction = get_direction()
				if direction != 0:
					if in_water:
						velocity.x = direction * SPEED * WATER_RUN
					else:
						velocity.x = direction * SPEED
				else:
					velocity.x = move_toward(velocity.x, 0, SPEED)

	if print_state_transitions:
		if state_last != state:
			print("My state:", state)
			state_last = state
	
	move_and_slide()
	
	# check for the box
	for id in get_slide_collision_count():
		var c = get_slide_collision(id)
		var collider = c.get_collider()
		if collider.is_in_group("box"):
			# print("collided with a box")
			collider.apply_central_impulse(-c.get_normal() * PUSH_FORCE)
	
func _on_invincibility_timer_timeout():
	hitbox_area.set_collision_mask_value(3, true) # can hit enemies again

func hit(damage):
	if timer.is_stopped() and health > 0: # player is not already hit
		score -= damage
		health -= damage
		if health > 0:
			# still alive
			hitbox_area.set_collision_mask_value(3, false) # cannot hit enemies
			timer.start()
		# the case for health <= 0 is detected in physics_process (see above)

func can_hit():
	# player is not already hit, alive and not shadowed by an enemy
	return timer.is_stopped() and health > 0 and is_enemy_free

func _on_hitbox_body_entered(body):
	if body.is_in_group("enemy"):
		print("Player is hitting the enemy")
		if can_hit():
			velocity.y = -JUMP_VELOCITY * 0.8 # bounce back a little
			body.hit()
