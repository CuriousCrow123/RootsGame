extends GutTest
## Unit tests for QuestTracker node.

var _tracker: QuestTracker
var _quest_data: QuestData


func before_each() -> void:
	_tracker = QuestTracker.new()
	add_child_autofree(_tracker)
	_quest_data = _create_test_quest()


func test_initial_state_is_inactive() -> void:
	assert_eq(
		_tracker.get_quest_state("fetch_amulet"),
		QuestTracker.QuestState.INACTIVE,
		"Unstarted quest should be INACTIVE",
	)


func test_is_quest_active_false_before_start() -> void:
	assert_false(
		_tracker.is_quest_active("fetch_amulet"),
		"Quest should not be active before starting",
	)


func test_start_quest() -> void:
	_tracker.start_quest(_quest_data)
	assert_true(
		_tracker.is_quest_active("fetch_amulet"),
		"Quest should be ACTIVE after starting",
	)


func test_start_quest_emits_signal() -> void:
	watch_signals(_tracker)
	_tracker.start_quest(_quest_data)
	assert_signal_emitted_with_parameters(_tracker, "quest_started", ["fetch_amulet"])


func test_start_quest_ignores_duplicate() -> void:
	_tracker.start_quest(_quest_data)
	watch_signals(_tracker)
	_tracker.start_quest(_quest_data)
	assert_signal_not_emitted(_tracker, "quest_started")


func test_advance_quest() -> void:
	_tracker.start_quest(_quest_data)
	_tracker.advance_quest("fetch_amulet")
	assert_true(
		_tracker.is_quest_active("fetch_amulet"),
		"Quest should still be ACTIVE after advancing to second step",
	)
	assert_eq(
		_tracker.get_current_step_description("fetch_amulet"),
		"Return the amulet to Nathan",
	)


func test_advance_quest_emits_step_completed() -> void:
	_tracker.start_quest(_quest_data)
	watch_signals(_tracker)
	_tracker.advance_quest("fetch_amulet")
	assert_signal_emitted_with_parameters(
		_tracker, "quest_step_completed", ["fetch_amulet", "get_amulet"]
	)


func test_quest_completes_on_final_advance() -> void:
	_tracker.start_quest(_quest_data)
	_tracker.advance_quest("fetch_amulet")  # get_amulet → return_amulet
	_tracker.advance_quest("fetch_amulet")  # return_amulet → complete
	assert_true(
		_tracker.is_quest_complete("fetch_amulet"),
		"Quest should be COMPLETE after final advance",
	)


func test_quest_completed_signal() -> void:
	_tracker.start_quest(_quest_data)
	_tracker.advance_quest("fetch_amulet")
	watch_signals(_tracker)
	_tracker.advance_quest("fetch_amulet")
	assert_signal_emitted_with_parameters(_tracker, "quest_completed", ["fetch_amulet"])


func test_advance_nonexistent_quest_does_nothing() -> void:
	watch_signals(_tracker)
	_tracker.advance_quest("nonexistent")
	assert_signal_not_emitted(_tracker, "quest_step_completed")
	assert_signal_not_emitted(_tracker, "quest_completed")


func test_get_current_step_description() -> void:
	_tracker.start_quest(_quest_data)
	assert_eq(
		_tracker.get_current_step_description("fetch_amulet"),
		"Find the amulet in the chest",
	)


func test_get_current_step_description_empty_for_unknown() -> void:
	assert_eq(
		_tracker.get_current_step_description("nonexistent"),
		"",
	)


func test_save_load_roundtrip() -> void:
	_tracker.start_quest(_quest_data)
	_tracker.advance_quest("fetch_amulet")
	var save_data: Dictionary = _tracker.get_save_data()

	# Create fresh tracker with same quest data and load
	var new_tracker: QuestTracker = QuestTracker.new()
	add_child_autofree(new_tracker)
	new_tracker.start_quest(_quest_data)
	new_tracker.load_save_data(save_data)

	assert_true(
		new_tracker.is_quest_active("fetch_amulet"),
		"Loaded tracker should have active quest",
	)
	assert_eq(
		new_tracker.get_current_step_description("fetch_amulet"),
		"Return the amulet to Nathan",
		"Loaded tracker should be on second step",
	)


func test_save_key() -> void:
	assert_eq(_tracker.get_save_key(), "quest_tracker")


# -- Helpers --


func _create_test_quest() -> QuestData:
	var step1: QuestStepData = QuestStepData.new()
	step1.step_id = "get_amulet"
	step1.description = "Find the amulet in the chest"
	step1.next_step_id = "return_amulet"

	var step2: QuestStepData = QuestStepData.new()
	step2.step_id = "return_amulet"
	step2.description = "Return the amulet to Nathan"
	step2.next_step_id = ""

	var quest: QuestData = QuestData.new()
	quest.quest_id = "fetch_amulet"
	quest.display_name = "The Old Amulet"
	quest.description = "Retrieve the old amulet for Nathan."
	quest.steps = [step1, step2]
	return quest
