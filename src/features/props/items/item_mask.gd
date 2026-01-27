extends GameItem


func selected() -> void:
	if actor is PlayerCharacter:
		actor.masked = true


func unselected() -> void:
	if actor is PlayerCharacter:
		actor.masked = false


func sold() -> void:
	if actor is PlayerCharacter:
		actor.masked = false


func dropped() -> void:
	super()
	if actor is PlayerCharacter:
		actor.masked = false
