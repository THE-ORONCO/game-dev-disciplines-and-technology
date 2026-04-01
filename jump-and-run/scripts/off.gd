extends Area2D

func _on_body_entered(body):
	print("Off, player must die")
	if body.name == "Player":
		body.hit(10) # player must die painfully
