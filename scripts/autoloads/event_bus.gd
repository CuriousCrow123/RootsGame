extends Node
## Global signal bus for cross-system events. Use sparingly.
## Only for signals with no natural owner in the scene hierarchy.
##
## Add signals here as systems are built. Do not pre-define signals
## that have no producers or consumers yet.
##
## Architectural rule: If a signal can be connected by a shared parent
## in the scene tree, it should NOT be on the EventBus. Only genuinely
## "homeless" signals belong here (e.g., player_died, quest_completed).
##
## Audit (Phase 4 Step 7): All current signals reach their consumers via
## the HUD connect_to_player() pattern or direct autoload references.
## No EventBus signals needed yet. Add signals when a concrete consumer
## emerges that cannot be wired through HUD or parent-child relationships.
