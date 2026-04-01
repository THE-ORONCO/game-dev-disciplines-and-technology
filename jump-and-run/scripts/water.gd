extends Area2D

func _on_body_entered(body):
	if body.name == "Player":
		body.in_water = true
		body.velocity.y = 0

func _on_body_exited(body):
	if body.name == "Player":
		body.in_water = false
