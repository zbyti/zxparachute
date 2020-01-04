
				
include "libs/screen_macros.asm"
include "libs/key_macros.asm"

				org 	0x4000

counter:		defw	0		; global loop counter (useless?)
				defw	0

frame_counter:	defw	0		; global frame counter every 50s
				defw	0

playing			defb	0		; game running 0 = menu, 1 = playing

time_50s:		defb 	0		; time structure
time_second:	defb 	0
time_minute:	defb 	0
time_hour:		defb 	0

score:			defw	0
lives:			defb	0
boatpos:		defb	0
game:			defb 	0

left_debounce:	defb	0
right_debounce:	defb	0

last_heli:		defb	0

shark_walk_pos:		defb	0
shark_walk_delay:	defb	0
shark_walk_counter:	defb	0


step:			defb	0
step_counter:	defb	0
step_speed:		defb	0	

second_update:	defb 0
man_overboard_position:	defb 0	; -1
man_overboard_entry:	defb 0

max_parachutes:	defb	0

				defb	0
				defb	0


parachute_step_index:	defb	0

gamea_highcore	defw 0
gameb_highcore	defw 0

				org 0x4000
fons:
incbin 	"parachute_screen.scr"	

				org 0x5ccb
main:				
				ld sp, 0x8000

				im 1
				
				xor a				; posem el marge negre
				out	(#fe), a ;					
				ld ($5C48), a	

				ld hl, screen_start		; clear vars
				ld de, screen_start+1
				ld bc, 31
				xor a
				ld (hl), a				
				ldir

				call swap_logo
				call waitnokey
				call waitkey
				call waitnokey
				call swap_logo
																
				call showallandhideforfun
				call hideAll
				call update_screen
				
												
				ld a, 8
				ld (step_speed), a
				
				call update_clock
				
				ld de, rpsinterrupt
				call setInterruptTo
				
				call start_game
				
		main_loop:
				
				
				ld hl, counter
				call inc32counter				
							
				ld a, (step)
				or a
				jr z, main_no_step
					xor a
					ld (step), a
					; every step
					
					call check_parachute_saved
					call heli_blades	
					call shark_move
					call clock_keys
					call move_parachutes
									
			main_no_step:	
			

				ld a, (second_update)
				or a
				jr z, main_no_second
					xor a
					ld (second_update), a
					; every second
					
					call start_shark_if_need					
					call update_clock
				
				main_no_second:		
				
				call update_clock_dots			

				call update_screen							
				
				call parachute_keys				

				ld b, KEYSEG_QWERT
				ld d, KEY_Q
				call checkkey
				call nz, add_parachute

				ld b, KEYSEG_ZXCV
				ld d, KEY_Z
				call checkkey
				ld c, i_manwater_1 - 1 ; just for test
				call nz, man_lost

				ld b, KEYSEG_ZXCV
				ld d, KEY_C
				call checkkey
				jp	nz, main
				
				ld b, KEYSEG_ZXCV
				ld d, KEY_X
				call checkkey
				jp	z, main_loop
				
		end_main_return:
				rst 0			; reset on exit

				
swap_logo: 
				ld hl, attributes_start
				ld de, logo
				ld bc, attributes_size
				
				call swap_memory
				
				ret

; hl starting pos, b len
; move bytes
; modifies de, hl, a, b
scroll_bytes:
				ld d,h
				ld e,l
			scroll_bytes_loop:
				dec de
				ld a,(de)
				ld (hl), a	
				dec hl			
				djnz scroll_bytes_loop
				ld (hl), 0
				ret

get_free_parachute:
				
				ld a, 0
				ret

get_random_position:

				ret
				
check_position_used:

				ret

add_parachute:
				ld a, 1 
				ld (i_parachute_1_1), a
				ld (i_parachute_2_1), a
				ld (i_parachute_3_1), a
				
				ret

parachute_saved:
				ld a,(score)
				inc a
				ld (score), a
				ret

check_parachute_saved:
				
				ld a,( i_boat_left )
				or a
				jr z, check_parachute_saved_middle
					ld bc, 15 			; replace by beep
					call delay50s

					ld a,( i_parachute_1_7 )
					or a
					ret z
					xor a
					ld (i_parachute_1_7), a
					jr parachute_saved

			check_parachute_saved_middle:
				ld a,( i_boat_middle)
				or a
				jr z, check_parachute_saved_right
					ld bc, 15 ; replace by beep
					call delay50s

					ld a,( i_parachute_2_6 )
					or a
					ret z
					xor a
					ld (i_parachute_2_6), a
					jr parachute_saved
				
			check_parachute_saved_right:
					ld bc, 15 ; replace by beep
					call delay50s

					ld a,( i_parachute_3_5 )
					or a
					ret z
					xor a
					ld (i_parachute_3_5), a
					jr parachute_saved
				
do_parachute_fall:

				ret

can_parachute_hang_on_palm:

				ret

is_parachute_hang_on_palm:
				ret
				



move_parachutes:
				ld a, (parachute_step_index)
				inc a
				cp %11
				jr nz, moveparachutes_cont
					xor a
			moveparachutes_cont:
				ld (parachute_step_index), a				
				or a
				jr nz, move_parachutes_row2				
					ld a, (i_parachute_1_7)
					or a
					jr z, move_parachutes_row1_cont
						xor a
						ld (i_parachute_1_7), a
						ld c, i_manwater_3 - 1 
						call man_lost
				move_parachutes_row1_cont:
					ld hl, i_parachute_1_7
					ld b, 6			
					call scroll_bytes
					jr move_parachutes_end



			move_parachutes_row2:
				cp 1
				jr nz, move_parachutes_row3
					ld a, (i_parachute_2_6)
					or a
					jr z, move_parachutes_row2_cont
						xor a
						ld (i_parachute_2_6), a
						ld c, i_manwater_2 - 1 
						call man_lost
				move_parachutes_row2_cont:
					ld hl, i_parachute_2_6
					ld b, 5				
					call scroll_bytes
					jr move_parachutes_end



			move_parachutes_row3:
				ld a, (i_parachute_3_5)
				or a
				jr z, move_parachutes_row3_cont
					xor a
					ld (i_parachute_3_5), a
					ld c, i_manwater_1 - 1 
					call man_lost

			move_parachutes_row3_cont:
				ld hl, i_parachute_3_5
				ld b, 4				
				call scroll_bytes	

			move_parachutes_end:

				ret

show_lives:
				ld a, (lives)
				or a
				ret z
				
				ld a, 1
				ld (i_miss), a
				
				ld a,(lives)
				ld b,a
			
			show_lives_loop:	
				push bc
					ld a, i_live_3+1	; i_screen is align 256 so low byte of the pointer is also the index
					sub b
					call showImage
				pop bc
				djnz show_lives_loop
							
				
				ret

start_live:
				xor a
				ld (shark_walk_pos), a	
				call show_lives
					
				ret
				
start_game:
				call hideAll

				ld a, 1												
				ld (i_monkey), a
				ld (i_heli), a
				ld (i_heli_blade_front), a				
				ld (i_heli_blade_back), a
				ld (i_am), a
				ld (i_digit_1), a
				ld (i_digit_2), a
				ld (i_digit_3), a
				ld (i_digit_4), a
				ld (i_gamea), a
				ld (i_boat_middle), a

				;ld a, 1
				ld (boatpos), a
				
				ld hl,0
				ld (score), hl
				ld (frame_counter), hl
				ld (frame_counter+2), hl
				ld (counter), hl
				ld (counter+2), hl
				
				ld a, 0
				ld (lives), a
				
				ld a, 1
				ld (max_parachutes), a
				
				ld a,1
				ld (playing), a
				
				call start_live
				ret		
				

		
man_lost:				
				call man_overboard
			
				ld a,(lives)
				cp 3
				jr z, man_lost_last
					inc a
					ld (lives), a
			man_lost_last:	
			
				call start_live
				ret
				
;modifies a
hide_sharks:
			xor a
			ld (i_shark_1), a
			ld (i_shark_2), a
			ld (i_shark_3), a
			ld (i_shark_4), a
			ld (i_shark_5), a
			ret
				

; delays 50s of seconds
; bc=delay time
; 50 = 1s, 3000 = 1m
delay50s:		ld	hl, (frame_counter)
				add hl, bc
				ld d, h
				ld e, l
				
		delay50s_loop:
				;halt		; at least 1 frame = 1/50s
				push hl				
				push de
				call parachute_keys				
				call update_screen
				pop de
				pop hl
				
				ld	hl, (frame_counter)
				;and a
				sbc hl, de
				jp m, delay50s_loop

				ret


man_overboard_beep:
				ld a, (man_overboard_entry)
				or a
				jr z, man_overboard_beep_regular
					ld bc, 15 * 3
					call delay50s				
					xor a
					ld (man_overboard_entry), a
					ret
					
			man_overboard_beep_regular:	
				ld bc, 15
				call delay50s
				
				ret

; c = start position	
man_overboard:
				call hide_sharks
				ld a, c
				ld (man_overboard_position), a
				ld a, 1
				ld (man_overboard_entry), a
		
		man_overboard_loop:	
				; Mostrem  tauró
				ld a, (man_overboard_position)
				cp i_manwater_1 - 1
				call nz, showImage
				; Mostrem paracaigudista				
				inc a
				call showImage
				
				call update_screen
				call man_overboard_beep

				ld a, (man_overboard_position)			; extra delay last pos
				cp i_shark_5 - 1
				jr nz, man_overboard_nofinal
					ld bc, 15*3
					call delay50s
				
				
			man_overboard_nofinal:
								
				; Amaguem tauró
				ld a, (man_overboard_position)
				cp i_manwater_1 - 1
				call nz, hideImage
				; Amaguem paracaigudista				
				inc a
				call hideImage								
				inc a
				ld (man_overboard_position), a
				cp i_manwater_6 + 1
				jr nz, man_overboard_loop
				

				ret

				

; called every second
start_shark_if_need:

				ld a, (shark_walk_counter)
				inc a
				ld (shark_walk_counter), a
				cp 10
				
				ret nz
				
				xor a
				ld (shark_walk_counter), a
				ld a, i_shark_1				; low byte pointer is index images aligned to 256 
				ld (shark_walk_pos), a
				call showImage
				xor a
				ld (shark_walk_delay), a

				ret
	
shark_move:
				ld a,(shark_walk_pos)			; is shark moving
				or a			
				ret z							; return if not
				
				ld a, (shark_walk_delay)		; move once every 4 steps
				inc a
				ld (shark_walk_delay), a
				cp 4
				ret nz							; return if not				
				xor a
				ld (shark_walk_delay), a		; reset move delay counter
				
				ld a,(shark_walk_pos)
				call hideImage
				inc a
				inc a
				cp i_shark_5+2				; low byte pointer is index images aligned to 256 
				jr nz, shark_move_next
					xor a
					ld (shark_walk_pos), a
					ret
					
			shark_move_next:
					ld (shark_walk_pos), a
					call showImage
									
			ret

heli_blades:
				ld a, (last_heli)
				inc a
				;and %11
				ld (last_heli), a
				
				ld b, a
				
				rra
				and 1
				ld (i_heli_blade_back), a
				
				ld a, b
				dec  a
				rra
				and 1
				ld (i_heli_blade_front), a								
				
				ret


moveright:
			ld a, (boatpos)
			cp 2
			ret z		; we are max right just return
			inc a
			
			jr boat_repos
				
moveleft:
			
			ld a, (boatpos)
			or a
			ret z		; we are max left just return
			dec a		
		
		boat_repos:	
		
			ld (boatpos), a
			ld b, a
				xor a
				ld (i_boat_left),a
				ld (i_boat_right),a
				ld (i_boat_middle),a
			ld a,b 
			
			ld hl, i_boat_left
			add l
			ld l, a 
			ld a, 1
			ld (hl), a			
			
			ret
			

			
			

showallandhideforfun:
	
				call hideAll
				call update_screen
				halt
				nop
				
			
				ld a, 1
		slowshowAll_loop:
				push af
				call showImage
				call update_screen
				halt
				nop				
				
				pop af
				inc a
				cp number_of_images
				jr nz, slowshowAll_loop
				
				ret
				



rpsinterrupt:
			
				ld hl, frame_counter
				call inc32counter
				call update_time_int
			
			
		step_counter_interrupt:
				ld a, (step_speed)
				ld b, a
				ld a, (step_counter)				
				
				cp b
				jr nz, step_counter_nostep
					ld a, 1
					ld (step), a				
					xor a
					ld (step_counter), a
					jr step_counter_segueix
		step_counter_nostep:
				inc a
				ld (step_counter), a
				
		step_counter_segueix:
			
				ret
	
			
update_time_int:	

				ld hl, time_50s
				ld a, (time_second)
				ld b, a
				call update_time
				
				ld a, (time_second)
				cp b
				ret z
				ld a, 1
				ld (second_update), a

				ret				

include "parachute_lcd.asm"
include "parachute_keys.asm"
include "parachute_misc.asm"
include "parachute_screen.asm"
include "parachute_logo.asm"
include "parachute_screen_lib.asm"
include "parachute_digits.asm"
include "parachute_math.asm"
include "parachute_clock.asm"


include 'libs/interrupt_lib_16k.asm' ; always include last line or before org	

run main

