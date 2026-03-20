class_name QuestTracker
extends Node
## Tracks active quests and their current step. Dialogue files drive all
## condition logic — this class only manages state transitions.
## Full implementation in Phase 2 (Step 4). Stub exists so PlayerController compiles.

signal quest_started(quest_id: String)
signal quest_step_completed(quest_id: String, step_id: String)
signal quest_completed(quest_id: String)
