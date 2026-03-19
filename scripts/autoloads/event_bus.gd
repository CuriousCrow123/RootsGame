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
