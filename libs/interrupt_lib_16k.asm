

setInterruptTo:
;de interrupt pointer
		ld hl, interruptcallfunction
		inc hl
		ld (hl), e
		inc hl
		ld (hl), d		
		
; Setup the 128 entry vector table
		di

		ld            hl, VectorTable
		ld            de, IM2Routine
		ld            b, 129

		; Setup the I register (the high byte of the table)
		ld            a, h
		ld            i, a

		; Loop to set all 128 entries in the table
		_Setup:
		ld            (hl), e
		inc           hl
		ld            (hl), d
		inc           hl
		djnz          _Setup

		; Setup IM2 mode
		im            2
		ei
		ret


      			
		ORG           $7C7C
IM2Routine:   
		push af             ; preserve registers.
		push bc
		push hl
		push de
		push ix
interruptcallfunction:
		call #0000          ;	:replaced as SetInterruptTo		
		pop ix              ; restore registers.
		pop de
		pop hl
		pop bc
		pop af
		ei                  ; always re-enable interrupts before returning.
		reti                ; done.		
		

; Make sure this is on a 256 byte boundary
              ORG           $7d00
VectorTable:
              defs          258




      
