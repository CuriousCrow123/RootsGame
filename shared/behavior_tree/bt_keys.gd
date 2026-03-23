class_name BTKeys
extends RefCounted
## StringName constants for blackboard keys. Using constants catches typos at parse time.
## Keys starting with _ are transient (not saved to disk).

const NPC: StringName = &"_npc"
const NAV_AGENT: StringName = &"_nav_agent"
const PLAYER: StringName = &"_player"
const BASE_SPEED: StringName = &"base_speed"
const HOME_POSITION: StringName = &"home_position"
