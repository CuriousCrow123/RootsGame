class_name BTComposite
extends BTNode
## Base class for composite BT nodes that have multiple children (Selector, Sequence).

var _running_child_index: int = -1


func _get_bt_children() -> Array[BTNode]:
	var children: Array[BTNode] = []
	for child: Node in get_children():
		if child is BTNode:
			children.append(child as BTNode)
	return children
