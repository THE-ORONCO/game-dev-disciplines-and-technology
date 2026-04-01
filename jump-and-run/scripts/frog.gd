extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var anim : AnimatedSprite2D = get_node("AnimatedSprite2D")
var player = null
var chase = false
var dying = false
const SPEED = 50

func _physics_process(delta):
	if dying:
		if not anim.is_playing():
			self.queue_free()
	else:
		velocity.y += gravity * delta;
		if chase:
			anim.play("jump")

			# player is still shadowed by frog
			if not player.is_enemy_free:
				player.hit(3)
				
			var direction = (player.position - self.position).normalized()
			if direction.x > 0:
				anim.flip_h = true
			elif direction.x < 0:
				anim.flip_h = false
			velocity.x = direction.x * SPEED
		else:
			anim.play("idle")
			velocity.x = 0
		move_and_slide();

func _on_player_detection_body_entered(body):
	if body.name == "Player":
		player = body
		chase = true

func _on_player_detection_body_exited(body):
	if body.name == "Player":
		chase = false

func hit():
	player.score += 1
	dying = true
	anim.play("death")

func _on_hitbox_body_entered(body):
	if body.name == "Player":
		print("Frog is hitting the player")
		body.is_enemy_free = false
		body.hit(3)

func _on_hitbox_body_exited(body):
	if body.name == "Player":
		body.is_enemy_free = true
