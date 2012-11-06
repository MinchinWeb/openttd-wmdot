/* Fibonacci Heap, v.3
 * Part of WmDOT, v.5, r53e [2011-04-09]
 *	Copyright © 2011 by W. Minchin. For more info,
 *		please visit http://openttd-noai-wmdot.googlecode.com/
 */
 
/*	This is based on the NoAI Team's Fibonacci Heap library, v2
 *	The only real change is that I have made Peek and Pop return the highest
 *		rather than the lowest values.
 *	This file remains under the original GNU GPL v2 licence
 */

/* $Id: main.nut 15092 2009-01-15 16:53:18Z truebrain $ */

/**
 * Fibonacci heap.
 *  This heap is heavily optimized for the Insert and Pop functions.
 *  Peek and Pop always return the current lowest value in the list.
 *  Insert is implemented as a lazy insert, as it will simply add the new
 *  node to the root list. Sort is done on every Pop operation.
 */
 
class Fibonacci_Heap_Info {
	function GetVersion()       { return 3; }
	function GetRevision()		{ return "53e"; }
	function GetDate()          { return "2011-04-09"; }
	function GetName()          { return "Fibonacci Heap (Max) (Wm) Library"; }
}

class Fibonacci_Heap {
	_max = null;
	_max_index = 0;
	_max_priority = 0;
	_count = 0;
	_root_list = null;

	/**
	 * Create a new fibonacci heap.
	 * http://en.wikipedia.org/wiki/Fibonacci_heap
	 */
	constructor() {
		_count = 0;
		_max = Node();
		_max.priority = 0xFFFFFFF;
		_max_index = 0;
		_max_priority = 0xFFFFFFF;
		_root_list = [];
	}

	/**
	 * Insert a new entry in the heap.
	 *  The complexity of this operation is O(1).
	 * @param item The item to add to the list.
	 * @param priority The priority this item has.
	 */
	function Insert(item, priority);

	/**
	 * Pop the first entry of the list.
	 *  This is always the item with the lowest priority.
	 *  The complexity of this operation is O(ln n).
	 * @return The item of the entry with the lowest priority.
	 */
	function Pop();

	/**
	 * Peek the first entry of the list.
	 *  This is always the item with the lowest priority.
	 *  The complexity of this operation is O(1).
	 * @return The item of the entry with the lowest priority.
	 */
	function Peek();

	/**
	 * Get the amount of current items in the list.
	 *  The complexity of this operation is O(1).
	 * @return The amount of items currently in the list.
	 */
	function Count();

	/**
	 * Check if an item exists in the list.
	 *  The complexity of this operation is O(n).
	 * @param item The item to check for.
	 * @return True if the item is already in the list.
	 */
	function Exists(item);
};

function Fibonacci_Heap::Insert(item, priority) {
	/* Create a new node instance to add to the heap. */
	local node = Node();
	/* Changing params is faster than using constructor values */
	node.item = item;
	node.priority = priority;

	/* Update the reference to the minimum node if this node has a
	 * smaller priority. */
	if (_max_priority < priority) {
		_max = node;
		_max_index = _root_list.len();
		_max_priority = priority;
	}

	_root_list.append(node);
	_count++;
}

function Fibonacci_Heap::Pop() {

	if (_count == 0) return null;

	/* Bring variables from the class scope to this scope explicitly to
	 * optimize variable lookups by Squirrel. */
	local z = _max;
	local tmp_root_list = _root_list;

	/* If there are any children, bring them all to the root level. */
	tmp_root_list.extend(z.child);

	/* Remove the minimum node from the rootList. */
	tmp_root_list.remove(_max_index);
	local root_cache = {};

	/* Now we decrease the number of nodes on the root level by
	 * merging nodes which have the same degree. The node with
	 * the lowest priority value will become the parent. */
	foreach(x in tmp_root_list) {
		local y;

		/* See if we encountered a node with the same degree already. */
		while (y = root_cache.rawdelete(x.degree)) {
			/* Check the priorities. */
			if (x.priority < y.priority) {
				local tmp = x;
				x = y;
				y = tmp;
			}

			/* Make y a child of x. */
			x.child.append(y);
			x.degree++;
		}

		root_cache[x.degree] <- x;
	}

	/* The root_cache contains all the nodes which will form the
	 *  new rootList. We reset the priority to the maximum number
	 *  for a 32 signed integer to find a new minumum. */
	tmp_root_list.resize(root_cache.len());
	local i = 0;
	local tmp_max_priority = 0xFFFFFFF;

	/* Now we need to find the new minimum among the root nodes. */
	foreach (val in root_cache) {
		if (val.priority > tmp_max_priority) {
			_max = val;
			_max_index = i;
			tmp_max_priority = val.priority;
		}

		tmp_root_list[i++] = val;
	}

	/* Update global variables. */
	_max_priority = tmp_max_priority;

	_count--;
	return z.item;
}

function Fibonacci_Heap::Peek() {
	if (_count == 0) return null;
	return _max.item;
}

function Fibonacci_Heap::Count() {
	return _count;
}

function Fibonacci_Heap::Exists(item) {
	return ExistsIn(_root_list, item);
}

/**
 * Auxilary function to search through the whole heap.
 * @param list The list of nodes to look through.
 * @param item The item to search for.
 * @return True if the item is found, false otherwise.
 */
function Fibonacci_Heap::ExistsIn(list, item) {

	foreach (val in list) {
		if (val.item == item) {
			return true;
		}

		foreach (c in val.child) {
			if (ExistsIn(c, item)) {
				return true;
			}
		}
	}

	/* No luck, item doesn't exists in the tree rooted under list. */
	return false;
}

/**
 * Basic class the fibonacci heap is composed of.
 */
class Fibonacci_Heap.Node {
	degree = null;
	child = null;

	item = null;
	priority = null;

	constructor() {
		child = [];
		degree = 0;
	}
};
