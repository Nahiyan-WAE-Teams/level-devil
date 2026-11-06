extends RefCounted
class_name LevelCatalog

const WORLDS := [
	{
		"name": "THE EASY WAY",
		"subtitle": "A LITTLE WALK IN THE PARK",
		"accent": Color("#e5a13a"),
		"levels": [
			{"name": "A FRIENDLY START", "hint": "THE FLOOR LOOKS PERFECTLY SAFE.", "platforms": [Rect2(0, 430, 370, 110), Rect2(430, 430, 530, 110)], "traps": [{"type": "spikes", "rect": Rect2(535, 390, 54, 80)}]},
			{"name": "TRUST ISSUES", "hint": "SOME FLOORS HAVE A SHORT MEMORY.", "platforms": [Rect2(0, 430, 300, 110), Rect2(360, 430, 250, 110), Rect2(670, 430, 290, 110)], "traps": [{"type": "collapse", "rect": Rect2(430, 400, 74, 60)}]},
			{"name": "LOOK UP", "hint": "THE CEILING IS PAYING ATTENTION.", "platforms": [Rect2(0, 430, 420, 110), Rect2(480, 430, 480, 110)], "traps": [{"type": "falling", "rect": Rect2(580, 330, 70, 100)}]},
			{"name": "POINTY BUSINESS", "hint": "THAT EMPTY SPACE ISN'T EMPTY.", "platforms": [Rect2(0, 430, 250, 110), Rect2(310, 430, 250, 110), Rect2(620, 430, 340, 110)], "traps": [{"type": "spikes", "rect": Rect2(385, 390, 64, 80)}, {"type": "collapse", "rect": Rect2(690, 400, 70, 60)}]},
			{"name": "THE LAST DOOR", "hint": "YOU REALLY THOUGHT IT WAS OVER?", "platforms": [Rect2(0, 430, 320, 110), Rect2(380, 430, 210, 110), Rect2(650, 430, 310, 110)], "traps": [{"type": "falling", "rect": Rect2(710, 320, 76, 110)}, {"type": "spikes", "rect": Rect2(500, 390, 58, 80)}]},
			{"name": "ONE STEP TOO FAR", "hint": "THE SAFE PATCH IS A LITTLE SMALLER.", "platforms": [Rect2(0, 430, 250, 110), Rect2(320, 430, 250, 110), Rect2(640, 430, 320, 110)], "traps": [{"type": "spikes", "rect": Rect2(390, 390, 60, 80)}]},
			{"name": "THE FLOOR PLAN", "hint": "SOME TILES ARE ONLY VISITING.", "platforms": [Rect2(0, 430, 270, 110), Rect2(340, 430, 220, 110), Rect2(630, 430, 330, 110)], "traps": [{"type": "collapse", "rect": Rect2(380, 400, 70, 60)}, {"type": "falling", "rect": Rect2(720, 320, 70, 110)}]},
			{"name": "A MOVING PROBLEM", "hint": "WAIT. JUMP. REGRET.", "platforms": [Rect2(0, 430, 240, 110), Rect2(620, 430, 340, 110)], "moving_platforms": [{"rect": Rect2(365, 360, 110, 24), "distance": 95.0, "speed": 1.25}], "traps": [{"type": "saw", "rect": Rect2(540, 375, 44, 44)}]},
			{"name": "DOOR NUMBER TWO", "hint": "THE FIRST EXIT IS A VERY GOOD LIAR.", "platforms": [Rect2(0, 430, 960, 110)], "traps": [{"type": "fake_exit", "rect": Rect2(830, 350, 70, 80)}, {"type": "spikes", "rect": Rect2(520, 390, 60, 80)}]},
			{"name": "THE EASY WAY OUT", "hint": "YOU HAVE LEARNED NOTHING. PERFECT.", "platforms": [Rect2(0, 430, 250, 110), Rect2(310, 430, 250, 110), Rect2(620, 430, 340, 110)], "moving_platforms": [{"rect": Rect2(250, 365, 65, 22), "distance": 25.0, "speed": 1.8}], "traps": [{"type": "collapse", "rect": Rect2(350, 400, 65, 60)}, {"type": "reverse", "rect": Rect2(650, 385, 70, 90)}, {"type": "falling", "rect": Rect2(790, 315, 70, 115)}]}
		]
	},
	{
		"name": "BAD INTENTIONS",
		"subtitle": "THE RULES ARE NOW OPTIONAL",
		"accent": Color("#d95d55"),
		"levels": [
			{"name": "MIND YOUR STEP", "hint": "THE SAW HAS A SCHEDULE.", "platforms": [Rect2(0, 430, 310, 110), Rect2(390, 430, 570, 110)], "traps": [{"type": "saw", "rect": Rect2(480, 380, 44, 44)}]},
			{"name": "BACKWARDS DAY", "hint": "LEFT IS THE NEW RIGHT.", "platforms": [Rect2(0, 430, 960, 110)], "traps": [{"type": "reverse", "rect": Rect2(390, 385, 80, 90)}]},
			{"name": "CEILING WALKER", "hint": "GRAVITY IS HAVING A DAY OFF.", "platforms": [Rect2(0, 430, 260, 110), Rect2(330, 430, 630, 110)], "traps": [{"type": "gravity", "rect": Rect2(440, 385, 90, 90)}]},
			{"name": "MOVING TARGET", "hint": "WAIT FOR THE FLOOR TO COME TO YOU.", "platforms": [Rect2(0, 430, 250, 110), Rect2(660, 430, 300, 110)], "moving_platforms": [{"rect": Rect2(390, 365, 110, 24), "distance": 95.0, "speed": 1.5}], "traps": [{"type": "fake_exit", "rect": Rect2(850, 350, 70, 80)}]},
			{"name": "DEVIL'S DUE", "hint": "EVERY TRICK YOU LEARNED. AT ONCE.", "platforms": [Rect2(0, 430, 230, 110), Rect2(320, 430, 220, 110), Rect2(650, 430, 310, 110)], "moving_platforms": [{"rect": Rect2(245, 365, 75, 22), "distance": 30.0, "speed": 2.0}], "traps": [{"type": "saw", "rect": Rect2(390, 375, 42, 42)}, {"type": "reverse", "rect": Rect2(480, 385, 70, 90)}, {"type": "falling", "rect": Rect2(730, 315, 72, 115)}]},
			{"name": "NO HANDRAILS", "hint": "THE SAW KNOWS YOUR ROUTE.", "platforms": [Rect2(0, 430, 260, 110), Rect2(340, 430, 250, 110), Rect2(670, 430, 290, 110)], "traps": [{"type": "saw", "rect": Rect2(395, 375, 44, 44)}, {"type": "spikes", "rect": Rect2(500, 390, 60, 80)}]},
			{"name": "OPPOSITE DAY", "hint": "THE CONTROLS HAVE THEIR OWN OPINION.", "platforms": [Rect2(0, 430, 960, 110)], "traps": [{"type": "reverse", "rect": Rect2(280, 385, 80, 90)}, {"type": "reverse", "rect": Rect2(650, 385, 80, 90)}]},
			{"name": "UP IS DOWN", "hint": "THE CEILING IS NOT A SAFE PLACE EITHER.", "platforms": [Rect2(0, 430, 250, 110), Rect2(320, 430, 270, 110), Rect2(660, 430, 300, 110)], "traps": [{"type": "gravity", "rect": Rect2(350, 385, 90, 90)}, {"type": "falling", "rect": Rect2(710, 310, 72, 115)}]},
			{"name": "EXIT INTERVIEW", "hint": "ONE DOOR IS REAL. ONE IS NOT.", "platforms": [Rect2(0, 430, 960, 110)], "traps": [{"type": "fake_exit", "rect": Rect2(690, 350, 70, 80)}, {"type": "saw", "rect": Rect2(460, 375, 44, 44)}, {"type": "spikes", "rect": Rect2(810, 390, 58, 80)}]},
			{"name": "THE DEVIL'S HOUSE", "hint": "EVERY LESSON. ONE LAST TIME.", "platforms": [Rect2(0, 430, 220, 110), Rect2(290, 430, 220, 110), Rect2(590, 430, 370, 110)], "moving_platforms": [{"rect": Rect2(220, 360, 75, 22), "distance": 25.0, "speed": 2.1}, {"rect": Rect2(510, 350, 80, 22), "distance": 25.0, "speed": 1.7}], "traps": [{"type": "saw", "rect": Rect2(350, 375, 42, 42)}, {"type": "reverse", "rect": Rect2(420, 385, 72, 90)}, {"type": "falling", "rect": Rect2(680, 310, 72, 115)}, {"type": "collapse", "rect": Rect2(760, 400, 70, 60)}]}
		]
	}
]

static func world_count() -> int:
	return WORLDS.size()

static func level_count(world_index: int) -> int:
	if world_index < 0 or world_index >= WORLDS.size():
		return 0
	return (WORLDS[world_index]["levels"] as Array).size()

static func get_world(world_index: int) -> Dictionary:
	if world_index < 0 or world_index >= WORLDS.size():
		return {}
	return WORLDS[world_index]

static func get_level(world_index: int, level_index: int) -> Dictionary:
	if level_index < 0 or level_index >= level_count(world_index):
		return {}
	return WORLDS[world_index]["levels"][level_index]

static func global_level_index(world_index: int, level_index: int) -> int:
	if world_index < 0 or world_index >= WORLDS.size() or level_index < 0 or level_index >= level_count(world_index):
		return -1
	var result := level_index
	for index in range(world_index):
		result += level_count(index)
	return result

static func is_level_unlocked(world_index: int, level_index: int, highest_completed: int) -> bool:
	var global_index := global_level_index(world_index, level_index)
	return global_index >= 0 and global_index <= highest_completed + 1
