extends Node2D

func cleanup():
	print("Removing all mobs")
	# remove all mobs
	for child in $Enemies.get_children():
		child.queue_free()	
