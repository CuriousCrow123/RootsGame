class_name BTTalkToPlayer
extends BTLeaf
## Signals the NPC to start dialogue. Returns RUNNING until the BT is resumed
## after dialogue completes. No await inside the BT node.
##
## Flow: BTTalkToPlayer returns RUNNING → BehaviorTreeRunner stays on this node.
## Meanwhile, npc_controller.interact() runs the dialogue (with await) and calls
## _bt_runner.resume() when done. On resume, the runner re-evaluates from root,
## so this node is never ticked again for the same interaction.


func _tick(_delta: float, _blackboard: Dictionary) -> Status:
	# If we're being ticked, the BT is active, which means either:
	# (a) We just entered — need to signal NPC to start dialogue.
	# (b) We were resumed after dialogue ended — should not happen because
	#     resume() resets the tree to evaluate from root.
	# In practice this node stays RUNNING until interrupt() is called.
	return Status.RUNNING
