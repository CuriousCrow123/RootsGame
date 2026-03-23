class_name BTDecorator
extends BTNode
## Base class for decorator BT nodes that wrap a single child.


func _get_bt_child() -> BTNode:
	for child: Node in get_children():
		if child is BTNode:
			return child as BTNode
	return null
