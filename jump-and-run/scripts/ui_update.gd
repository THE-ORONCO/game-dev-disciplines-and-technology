extends Label

func _process(_delta):
	if self.name == "Score":
		text = "Score: " + str(get_parent().get_parent().get_node("Player").score)
	else:
		text = "HP: " + str(get_parent().get_parent().get_node("Player").health)
