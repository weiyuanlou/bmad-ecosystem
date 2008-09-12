#include "CESR_platform.inc"
                                    
!+
! Subroutine tao_de_optimizer (abort)
!
! Subrutine to minimize the merit function by varying variables until
! the "data" as calculated from the model matches the measured data.
! 
! This subroutine is a wrapper for the opti_de optimizer in dcslib.
! 'de' stands for 'differential evolution' see opti_de routine for
! more details.
!
! Output:
!   abort -- Logical: Set True if an user stop signal detected.
!-

subroutine tao_de_optimizer (abort)

use tao_mod
use tao_top10_mod
use tao_var_mod
use opti_mod

implicit none

type (tao_universe_struct), pointer :: u

real(rp), allocatable, save :: var_vec(:), var_step(:)
real(rp) merit_start, merit_end, merit

integer i, n, gen, pop, n_var, population

character(20) :: r_name = 'tao_de_optimizer'
character(80) line

logical abort

! setup

tao_com%opti_init = .true.
tao_com%opti_abort = .false.

! put the variable values into an array for the optimizer

call tao_get_vars (var_vec, var_step = var_step)
var_step = var_step * s%global%de_lm_step_ratio
n_var = size(var_vec)

population = max(5*n_var, 20)
merit_start = tao_merit ()

! run the optimizer

merit = opti_de (var_vec, s%global%n_opti_cycles, population, &
                                                    merit_wrapper, var_step)

! cleanup after the optimizer

call tao_set_vars (var_vec)
merit_end = tao_merit ()

write (line, *) 'Merit start:', merit_start
call out_io (s_blank$, r_name, line)
write (line, *) 'Merit end:', merit_end
call out_io (s_blank$, r_name, line)

call tao_var_write (s%global%var_out_file)
abort = tao_com%opti_abort

end subroutine

!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!+
! Function merit_wrapper (var_vec, end_flag) result (this_merit)
!
! Function called by opti_de to set the variables and return the merit value.
!
! Input:
!   var_vec(:) -- Array of variables.
! 
! Output:
!   end_flag   -- Logical: Set True if we want opti_de to halt.
!   this_merit -- Real(rp): Value of the merit function.
!-

function merit_wrapper (var_vec, end_flag) result (this_merit)

use tao_mod
use input_mod
use tao_var_mod

implicit none

real(rp) var_vec(:)
real(rp) this_merit
real(rp) :: merit_min  = 1e35  ! something large
real(rp) :: merit_min_out = 1e35
real(rp) :: merit_min_type = 1e35
real(rp) merit

integer i, end_flag
integer :: iter = 0
integer, save :: t0(8), t1(8), t_del(8), t_delta

character(80) line, line2, stars
character(20) :: r_name = 'tao_de_optimizer'
character(1) char

! Init

if (tao_com%opti_init) then
  merit_min = 1e35
  merit_min_out = 1e35
  merit_min_type = 1e35
  tao_com%opti_init = .false.
endif

! look for keyboard input to end optimization

end_flag = 0  ! continue

#ifndef CESR_WINCVF
do
  call get_tty_char (char, .false., .false.) 
  if (char == '.') then
    end_flag = 1     ! signal stop
    call out_io (s_blank$, r_name, 'Optimizer stop signal detected.', &
                                                             'Stopping now.')
    tao_com%opti_abort = .true.
    tao_com%optimizer_running = .false.
  endif
  if (char == achar(0)) exit   ! only exit if there is no more input
enddo
#endif

!

stars = '****************************************************'

call tao_set_vars (var_vec)

this_merit = tao_merit ()
merit_min = min(merit_min, this_merit)

if (mod(iter, 1000) == 0) then
  call date_and_time (values = t1)
  t_del = t1 - t0
  t_delta = t_del(7) + 60*(t_del(6) + &
                  60*(t_del(5) + 24*(t_del(3) + 30*t_del(2)))) 
  iter = 0
endif

if (this_merit <= 0.98*merit_min_type .or. t_delta > 10) then
  write (line, *) ' So far the minimum is ', merit_min
  if (bmad_status%status == ok$) then
    call out_io (s_blank$, r_name, stars, line, stars)
  else
    write (line2, *) 'Bmad_status%status is ', status_name(bmad_status%status)
    call out_io (s_blank$, r_name, stars, line, line2, stars)
  endif

  call date_and_time (values = t0)
  t_delta = 0
  merit_min_type = merit_min
endif

if (this_merit < 1e-10) then
  call out_io (s_blank$, r_name, stars, &
                ' MERIT < 1E-10 ==> AT MINIMUM. QUITING HERE.', stars)
  end_flag = 1
endif

if (this_merit <= 0.9*merit_min_out) then
  merit_min_out = this_merit
endif

iter = iter + 1

end function
