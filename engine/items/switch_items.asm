SwitchItemsInBag:
	ld a, [wSwitchItem]
	and a
	jr z, .init
	ld b, a
	ld a, [wScrollingMenuCursorPosition]
	inc a
	cp b
	jr z, .trivial
	ld a, [wScrollingMenuCursorPosition]
	call ItemSwitch_GetNthItem
	ld a, [hl]
	cp -1
	ret z
	ld hl, wSwitchItem
	dec [hl]
	call .try_combining_stacks
	jmp c, .combine_stacks
	ld a, [wScrollingMenuCursorPosition]
	ld c, a
	ld a, [wSwitchItem]
	cp c
	jr c, .above
	jr .below

.init:
	ld a, [wScrollingMenuCursorPosition]
	inc a
	ld [wSwitchItem], a
	ret

.trivial:
	xor a
	ld [wSwitchItem], a
	ret

.below:
	ld a, [wSwitchItem]
	call ItemSwitch_CopyItemToBuffer
	ld a, [wScrollingMenuCursorPosition]
	ld d, a
	ld a, [wSwitchItem]
	ld e, a
	call ItemSwitch_GetItemOffset
	push bc
	ld a, [wSwitchItem]
	call ItemSwitch_GetNthItem
	dec hl
	push hl
	call ItemSwitch_GetItemFormatSize
	add hl, bc
	ld d, h
	ld e, l
	pop hl
	pop bc
	call ItemSwitch_BackwardsCopyBytes
	ld a, [wScrollingMenuCursorPosition]
	call ItemSwitch_CopyBufferToItem
	xor a
	ld [wSwitchItem], a
	ret

.above:
	ld a, [wSwitchItem]
	call ItemSwitch_CopyItemToBuffer
	ld a, [wScrollingMenuCursorPosition]
	ld d, a
	ld a, [wSwitchItem]
	ld e, a
	call ItemSwitch_GetItemOffset
	push bc
	ld a, [wSwitchItem]
	call ItemSwitch_GetNthItem
	ld d, h
	ld e, l
	call ItemSwitch_GetItemFormatSize
	add hl, bc
	pop bc
	rst CopyBytes
	ld a, [wScrollingMenuCursorPosition]
	call ItemSwitch_CopyBufferToItem
	xor a
	ld [wSwitchItem], a
	ret

.try_combining_stacks:
	ld a, [wSwitchItem]
	call ItemSwitch_GetNthItem
	ld d, h
	ld e, l
	ld a, [wScrollingMenuCursorPosition]
	call ItemSwitch_GetNthItem
	ld a, [wMenuData_ScrollingMenuItemFormat]
	cp SCROLLINGMENU_ITEMS_16BIT_QUANTITY
	jr z, .try_combining_stacks_handle_16_bit
	ld a, [de]
	cp [hl]
	jr nz, .no_combine
.check_stack_combine
	ld a, [wScrollingMenuCursorPosition]
	call ItemSwitch_GetItemQuantity
	cp MAX_ITEM_STACK
	jr z, .no_combine
	ld a, [wSwitchItem]
	call ItemSwitch_GetItemQuantity
	cp MAX_ITEM_STACK
	jr nz, .combine
.no_combine
	and a
	ret
.combine
	scf
	ret

.try_combining_stacks_handle_16_bit
	ld a, [de]
	cp [hl]
	jr nz, .no_combine
	inc de
	inc hl
	ld a, [de]
	cp [hl]
	jr nz, .no_combine
	jr .check_stack_combine

.combine_stacks:
	ld a, [wSwitchItem]
	call ItemSwitch_GetItemQuantityPointer
	push hl
	ld a, [wScrollingMenuCursorPosition]
	call ItemSwitch_GetItemQuantityPointer
	ld a, [hl]
	pop hl
	add [hl]
	cp MAX_ITEM_STACK + 1
	jr c, .merge_stacks
	sub MAX_ITEM_STACK
	push af
	ld a, [wScrollingMenuCursorPosition]
	call ItemSwitch_GetItemQuantityPointer
	ld [hl], MAX_ITEM_STACK
	ld a, [wSwitchItem]
	call ItemSwitch_GetItemQuantityPointer
	pop af
	ld [hl], a
	xor a
	ld [wSwitchItem], a
	ret

.merge_stacks:
	push af
	ld a, [wScrollingMenuCursorPosition]
	call ItemSwitch_GetItemQuantityPointer
	pop af
	ld [hl], a
	ld hl, wMenuData_ItemsPointerAddr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wSwitchItem]
	cp [hl]
	jr nz, .not_combining_last_item
	dec [hl]
	ld a, [wSwitchItem]
	call ItemSwitch_GetNthItem
	ld [hl], -1 ; end
	xor a
	ld [wSwitchItem], a
	ret

.not_combining_last_item:
	dec [hl]
	call ItemSwitch_GetItemFormatSize
	push bc
	ld a, [wSwitchItem]
	call ItemSwitch_GetNthItem
	pop bc
	push hl
	add hl, bc
	pop de
.copy_loop
	ld a, [hli]
	ld [de], a
	inc de
	cp -1 ; end?
	jr nz, .copy_loop
	xor a
	ld [wSwitchItem], a
	ret

ItemSwitch_CopyItemToBuffer:
	call ItemSwitch_GetNthItem
	ld de, wSwitchItemBuffer
	call ItemSwitch_GetItemFormatSize
	jmp CopyBytes

ItemSwitch_CopyBufferToItem:
	call ItemSwitch_GetNthItem
	ld d, h
	ld e, l
	ld hl, wSwitchItemBuffer
	call ItemSwitch_GetItemFormatSize
	jmp CopyBytes

ItemSwitch_GetNthItem:
	push af
	call ItemSwitch_GetItemFormatSize
	ld hl, wMenuData_ItemsPointerAddr
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	pop af
	jmp AddNTimes

ItemSwitch_GetItemOffset:
	push hl
	call ItemSwitch_GetItemFormatSize
	ld a, d
	sub e
	jr nc, .dont_negate
	dec a
	cpl
.dont_negate
	ld hl, 0
	rst AddNTimes
	ld b, h
	ld c, l
	pop hl
	ret

ItemSwitch_GetItemFormatSize:
	push hl
	ld a, [wMenuData_ScrollingMenuItemFormat]
	ld c, a
	ld b, 0
	ld hl, .item_format_sizes
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld b, [hl]
	ld c, a
	pop hl
	ret

.item_format_sizes:
; entries correspond to SCROLLINGMENU_ITEMS_* constants
	dw 0 ; unused
	dw 1 ; SCROLLINGMENU_ITEMS_NORMAL
	dw 2 ; SCROLLINGMENU_ITEMS_QUANTITY
	dw 3 ; SCROLLINGMENU_ITEMS_16BIT_QUANTITY

ItemSwitch_GetItemQuantity:
	push af
	call ItemSwitch_GetItemFormatSize
	ld a, c
	cp 1
	jr z, .no_quantity
	cp 3
	jr z, .item_16bit
	pop af
	call ItemSwitch_GetNthItem
	inc hl
	ld a, [hl]
	ret

.no_quantity
	pop af
	ld a, 1
	ret

.item_16bit
	pop af
	call ItemSwitch_GetNthItem
	inc hl
	inc hl
	ld a, [hl]
	ret

ItemSwitch_GetItemQuantityPointer:
	push af
	call ItemSwitch_GetItemFormatSize
	ld a, c
	cp 3
	jr z, .item_16bit
	pop af
	call ItemSwitch_GetNthItem
	inc hl
	ret

.item_16bit
	pop af
	call ItemSwitch_GetNthItem
	inc hl
	inc hl
	ret

ItemSwitch_BackwardsCopyBytes:
.loop
	ld a, [hld]
	ld [de], a
	dec de
	dec bc
	ld a, b
	or c
	jr nz, .loop
	ret
