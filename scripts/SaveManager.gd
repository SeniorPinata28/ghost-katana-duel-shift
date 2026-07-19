extends Node

const SAVE_PATH := "user://ghost_katana_save.cfg"

var level_1_complete := false
var unlocked_techniques: Array[String] = ["blade"]

func load_game() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	level_1_complete = bool(config.get_value("progress", "level_1_complete", false))
	var stored: Array = config.get_value("progress", "unlocked_techniques", ["blade"])
	unlocked_techniques.clear()
	for item in stored:
		unlocked_techniques.append(str(item))

func mark_level_1_complete() -> void:
	level_1_complete = true
	unlock_technique("breaker")
	save_game()

func unlock_technique(technique: String) -> void:
	if not unlocked_techniques.has(technique):
		unlocked_techniques.append(technique)

func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "level_1_complete", level_1_complete)
	config.set_value("progress", "unlocked_techniques", unlocked_techniques)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_error("Could not save progress. Error code: %s" % error)
