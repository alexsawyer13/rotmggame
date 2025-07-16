package game

Handle :: struct {
	id : i64,
	index : i64,
}

PackedArrayWrapper :: struct($T : typeid) {
	item : T,
	removed : bool,
	id : i64,
}

PackedArray :: struct($T : typeid) {
	items : [dynamic]PackedArrayWrapper(T),
	free_list : [dynamic]i64,
	next_id : i64,
	count : i64,
}

make_packed_array :: proc($T : typeid) -> PackedArray(T) {
	p : PackedArray(T)
	p.items = make([dynamic]PackedArrayWrapper(T))
	p.free_list = make([dynamic]i64)
	p.next_id = 0
	p.count = 0
	return p
}

delete_packed_array :: proc(p : ^PackedArray($T)) {
	delete(p.items)
	delete(p.free_list)
	p.next_id = 0
	p.count = 0
}

// Inserts an item to the packed array
// Returns the handle of where it ends up
insert_packed_array :: proc(p : ^PackedArray($T), v : T) -> Handle {
	index : i64

	w : PackedArrayWrapper(T) = {
		item = v,
		removed = false,
		id = p.next_id
	}

	if len(p.free_list) > 0 {
		index = p.free_list[len(p.free_list) - 1]
		pop(&p.free_list)
		p.items[index] = w
	} else {
		index = i64(len(p.items))
		append(&p.items, w)
	}

	p.next_id += 1
	p.count += 1
	return Handle {index = index, id = w.id}
}

// Tries to remove item from packed array
// Returns false if it wasn't found
// True if removed successfully
remove_packed_array :: proc(p : ^PackedArray($T), h : Handle) -> bool {
	if h.index < 0 || h.index >= i64(len(p.items)) {
		return false
		//panic("Trying to delete out of bounds transform component")
	}
	c := &p.items[h.index]
	if c.id != h.id || c.removed {
		return false
		//panic("Trying to delete transform component which is already deleted")
	}
	c.removed = true
	append(&p.free_list, h.index)
	p.count -= 1
	return true
}

// Tries to get item from packed array
// If it doesn't exist, return nil
get_packed_array :: #force_inline proc(p : PackedArray($T), h : Handle) -> ^T {
	if h.index < 0 || h.id < 0 do return nil
	if h.index >= i64(len(p.items)) do return nil
	v := &p.items[h.index]
	if v.id != h.id || v.removed do return nil
	return &v.item
}
