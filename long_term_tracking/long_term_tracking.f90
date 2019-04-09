program long_term_tracking

use long_term_tracking_mod

implicit none

type (ltt_params_struct) lttp
type (lat_struct), target :: lat
type (beam_init_struct) beam_init
type (ptc_map_with_rad_struct) map_with_rad
type (coord_struct), allocatable :: closed_orb(:)

real(rp) time

!

call ltt_init_params(lttp, lat, beam_init)
call ltt_init_tracking (lttp, lat, closed_orb, map_with_rad)
call ltt_print_inital_info (lttp, map_with_rad)

call run_timer ('START')

select case (lttp%simulation_mode)
case ('CHECK');  call ltt_run_check_mode(lttp, lat, map_with_rad, beam_init, closed_orb)  ! A single turn tracking check
case ('SINGLE'); call ltt_run_single_mode(lttp, lat, beam_init, closed_orb, map_with_rad) ! Single particle tracking
case ('BUNCH');  call ltt_run_bunch_mode(lttp, lat, beam_init, closed_orb, map_with_rad)  ! Beam tracking
case ('STAT');   call ltt_run_stat_mode(lttp, lat, closed_orb)                            ! Lattice statistics (radiation integrals, etc.).
case default
  print *, 'BAD SIMULATION_MODE: ' // lttp%simulation_mode
end select

call run_timer ('READ', time)
print '(a, f8.2)', 'Tracking time (min)', time/60

end program


