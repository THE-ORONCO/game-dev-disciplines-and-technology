class_name PongPlayer
extends Node3D

@export var rotation_speed = 3.0
@export var ball:Ball
@onready var ai_controller := %AI
@onready var sensor: RayCastSensor3D = %sensor

var needs_reset = false

func _ready():
	ai_controller.init(self)

func game_over():
	needs_reset = true
	ai_controller.done = true
	ai_controller.needs_reset = true

func _physics_process(delta):
	if needs_reset:
		ball.reset()
		needs_reset = false
		return
	
	var movement : float
	if ai_controller.heuristic == "human":
		movement = Input.get_axis("rotate_anticlockwise", "rotate_clockwise")
	else:
		movement = ai_controller.move_action
	rotate_y(movement*delta*rotation_speed)


func _on_area_3d_body_entered(body):
	ai_controller.reward += 1.0
