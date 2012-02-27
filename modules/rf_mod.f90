module rf_mod

use runge_kutta_mod

real(rp), pointer, private :: field_scale, dphi0_ref
type (lat_param_struct), pointer, private :: param_com
type (ele_struct), pointer, private :: ele_com

integer, private, save :: n_loop ! Used for debugging.
logical, private, save :: is_lost

contains

!--------------------------------------------------------------------------------------------
!--------------------------------------------------------------------------------------------
!--------------------------------------------------------------------------------------------
!+
! Subroutine rf_auto_scale_phase_and_amp(ele, param, err_flag)
!
! Routine to set the reference phase and amplitude of the accelerating field if
! this field is defined. This routine works on lcavity, rfcavity and e_gun elements
!
! All calculations are done with a particle with the energy of the reference particle and 
! with z = 0.
!
! First: With the phase set for maximum acceleration, set the field_scale for the
! correct change in energy:
!     dE = ele%value(gradient$) * ele%value(l$) for lcavity elements.
!        = ele%value(voltage$)                  for rfcavity elements.
!
! Second:
! If the element is an lcavity then the RF phase is set for maximum acceleration.
! If the element is an rfcavity then the RF phase is set for zero acceleration and
! dE/dz will be negative (particles with z > 0 will be deaccelerated).
!
! Note: If |dE| is too small, this routine cannot scale and will do nothing.
!
! Note: For an rfcavity if ele%lat%rf_auto_scale_phase = F and lat%rf_auto_scale_amp = T then
! the first step is done above but then the phase is reset to the original phase in step 2.
!
! Modules needed
!   use rf_mod
!
! Input:
!   ele   -- ele_struct: RF element. Either lcavity or rfcavity.
!     %value(gradient$) -- Accelerating gradient to match to if an lcavity.
!     %value(voltage$)  -- Accelerating voltage to match to if an rfcavity.
!     %lat%rf_auto_scale_phase ! Scale phase? Default is True if ele%lat is not associated.
!     %lat%rf_auto_scale_amp   ! Scale amp?   Default is True if ele%lat is not associated.
!   param -- lat_param_struct: lattice parameters
!
! Output:
!   ele      -- ele_struct: element with phase and amplitude adjusted.
!   err_flag -- Logical, Set true if there is an error. False otherwise.
!-

subroutine rf_auto_scale_phase_and_amp(ele, param, err_flag)

use super_recipes_mod
use nr, only: zbrent

implicit none

type (ele_struct), target :: ele
type (lat_param_struct), target :: param

integer, parameter :: n_sample = 16

real(rp) pz, phi, pz_max, phi_max, e_tot, scale_correct, dE_peak_wanted, dE_cut, E_tol
real(rp) dphi, e_tot_start, pz_plus, pz_minus, b, c, phi_tol, scale_tol, phi_max_old
real(rp) value_saved(n_attrib_maxx), dphi0_ref_original, pz_arr(0:n_sample-1), pz_max1, pz_max2
real(rp) dE_max1, dE_max2

integer i, j, tracking_method_saved, num_times_lost, i_max1, i_max2

logical step_up_seen, err_flag, scale_phase, scale_amp, adjust_phase, adjust_amp

character(28), parameter :: r_name = 'rf_auto_scale_phase_and_amp'

! Check if auto scale is needed.
! Adjust_phase is used to determine if the phase can be adjusted when scaling the amplitude.

if (.not. ele%is_on) return

err_flag = .false.

scale_phase = .true.
scale_amp   = .true.
if (associated (ele%lat)) then
  scale_phase = ele%lat%rf_auto_scale_phase
  scale_amp   = ele%lat%rf_auto_scale_amp
  if (.not. scale_phase .and. .not. scale_amp) return
endif

adjust_phase = (scale_phase .or. ele%key == rfcavity$)
adjust_amp   = scale_amp

if (ele%key == e_gun$) then
  scale_phase = .false.
  adjust_phase = .false.
endif

! Init.
! Note: dphi0_ref is set in neg_pz_calc

if (ele%tracking_method == bmad_standard$ .or. ele%tracking_method == mad$) return

nullify(field_scale)

select case (ele%field_calc)
case (bmad_standard$) 
  field_scale => ele%value(field_scale$)
  dphi0_ref => ele%value(dphi0_ref$)

case (grid$, map$, custom$)
  do i = 1, size(ele%em_field%mode)
    if (ele%em_field%mode(i)%harmonic == 1 .and. ele%em_field%mode(i)%m == 0) then
      field_scale => ele%em_field%mode(i)%field_scale
      dphi0_ref => ele%em_field%mode(i)%dphi0_ref
      exit
    endif
  enddo
end select

dphi0_ref_original = dphi0_ref

if (.not. associated(field_scale)) then
  call out_io (s_fatal$, r_name, 'CANNOT DETERMINE WHAT TO SCALE. NO FIELD MODE WITH HARMONIC = 1, M = 0', &
                                 'FOR ELEMENT: ' // ele%name)
  if (bmad_status%exit_on_error) call err_exit ! exit on error.
  return
endif

! Compute Energy gain at peak (zero phase)

ele_com => ele
param_com => param

select case (ele%key)
case (rfcavity$)
  dE_peak_wanted = ele%value(voltage$)
  e_tot_start = ele%value(e_tot$)
case (lcavity$)
  dE_peak_wanted = ele%value(gradient$) * ele%value(l$)
  e_tot_start = ele%value(e_tot_start$)
case default
  call out_io (s_fatal$, r_name, 'CONFUSED ELEMENT TYPE!')
  if (bmad_status%exit_on_error) call err_exit ! exit on error.
  return
end select

! Auto scale amplitude when dE_peak_wanted is zero or very small is not possible.
! Therefore if dE_peak_wanted is less than dE_cut then do nothing.

if (adjust_amp) then
  dE_cut = 10 ! eV
  if (abs(dE_peak_wanted) < dE_cut) return
endif

if (field_scale == 0) then
  ! Cannot autophase if not allowed to make the field_scale non-zero.
  if (.not. adjust_amp) then
    call out_io (s_fatal$, &
            r_name, 'CANNOT AUTO PHASE IF NOT ALLOWED TO MAKE THE FIELD_SCALE NON-ZERO FOR: ' // ele%name)
    if (bmad_status%exit_on_error) call err_exit ! exit on error.
    return 
  endif
  field_scale = 1  ! Initial guess.
endif

! Set error fields to zero

value_saved = ele%value
ele%value(phi0$) = 0
ele%value(dphi0$) = 0
ele%value(phi0_err$) = 0
if (ele%key == lcavity$) ele%value(gradient_err$) = 0

tracking_method_saved = ele%tracking_method
if (ele%tracking_method == bmad_standard$) ele%tracking_method = runge_kutta$

phi_max = dphi0_ref   ! Init guess
if (ele%key == rfcavity$) phi_max = ele%value(dphi0_max$)

phi_max_old = 100 ! Number far from unity

! scale_correct is the correction factor applied to field_scale on each iteration:
!  field_scale(new) = field_scale(old) * scale_correct
! scale_tol is the tolerance for scale_correct.
! scale_tol = E_tol / dE_peak_wanted corresponds to a tolerance in dE_peak_wanted of E_tol. 

E_tol = 0.1 ! eV
scale_tol = max(1d-7, E_tol / dE_peak_wanted) ! tolerance for scale_correct
phi_tol = 1d-5

! See if %dphi0_ref and %field_scale are already set correctly.
! If so we can quit.

pz_max   = -neg_pz_calc(phi_max)

if (.not. is_lost) then
  if (adjust_phase) then
    pz_plus  = -neg_pz_calc(phi_max + 2 * phi_tol)
    pz_minus = -neg_pz_calc(phi_max - 2 * phi_tol)
  else
    pz_plus  = -100  ! So that (pz_max > pz_plus) test is True.
    pz_minus = -100
  endif

  if (adjust_amp) then
    scale_correct = dE_peak_wanted / dE_particle(pz_max) 
  else
    scale_correct = 1
  endif

  if (pz_max > pz_plus .and. pz_max > pz_minus .and. abs(scale_correct - 1) < 2 * scale_tol) then
    call cleanup_this()
    dphi0_ref = dphi0_ref_original
    return
  endif
endif

! OK so the input %dphi0_ref and %field_scale are not set correctly...
! First choose a starting phi_max by finding an approximate phase for max acceleration.
! We start by testing 4 phases 90 deg apart.
! pz_max1 gives the maximal acceleration of the 4. pz_max2 gives the second largest.

pz_arr(0) = pz_max
dphi = 1.0_rp / n_sample

do i = 1, n_sample - 1
  pz_arr(i) = -neg_pz_calc(phi_max + i*dphi)
enddo

i_max1 = maxloc(pz_arr, 1) - 1
pz_max1 = pz_arr(i_max1)
dE_max1 = dE_particle(pz_max1)

pz_arr(i_max1) = -1  ! To find next max
i_max2 = maxloc(pz_arr, 1) - 1
pz_max2 = pz_arr(i_max2)
dE_max2 = dE_particle(pz_max2)

if (dE_max1 < 0) then
  call out_io (s_error$, r_name, 'CANNOT FIND ACCELERATING PHASE REGION FOR: ' // ele%name)
  err_flag = .true.
  return
endif

! If dE_max1 is large compared to dE_max2 then just use the dE_max1 phase. 
! Otherwise take half way between dE_max1 and dE_max2 phases.

if (dE_max2 < dE_max1/2) then  ! Just use dE_max1 point
  phi_max = phi_max + dphi * i_max1
  pz_max = pz_max1
! wrap around case when i_max1 = 0 and i_max2 = n_sample-1 or vice versa.
elseif (abs(i_max1 - i_max2) == n_sample - 1) then   
  phi_max = phi_max - dphi / 2.0
  pz_max = -neg_pz_calc(phi_max)
else
  phi_max = phi_max + dphi * (i_max1 + i_max2) / 2.0
  pz_max = -neg_pz_calc(phi_max)
endif

! Now adjust %field_scale for the correct acceleration at the phase for maximum acceleration. 

n_loop = 0  ! For debug purposes.
num_times_lost = 0
dphi = 0.05

main_loop: do

  ! Find approximately the phase for maximum acceleration.
  ! First go in +phi direction until pz decreases.

  if (adjust_phase) then
    step_up_seen = .false.

    do i = 1, 100
      phi = phi_max + dphi
      pz = -neg_pz_calc(phi)

      if (is_lost) then
        do j = -19, 20
          print *, j, phi_max+j/40.0, -neg_pz_calc(phi_max + j / 40.0)
        enddo
        call out_io (s_error$, r_name, 'CANNOT STABLY TRACK PARTICLE!')
        err_flag = .true.
        return
      endif

      if (pz < pz_max) then
        pz_plus = pz
        exit
      endif

      pz_minus = pz_max
      pz_max = pz
      phi_max = phi
      step_up_seen = .true.
    enddo

    ! If needed: Now go in -phi direction until pz decreases

    if (.not. step_up_seen) then
      do
        phi = phi_max - dphi
        pz = -neg_pz_calc(phi)
        if (pz < pz_max) then
          pz_minus = pz
          exit
        endif
        pz_plus = pz_max
        pz_max = pz
        phi_max = phi
      enddo
    endif

    ! Quadradic interpolation to get the maximum phase.
    ! Formula: pz = a + b*dt + c*dt^2 where dt = (phi-phi_max) / dphi

    b = (pz_plus - pz_minus) / 2
    c = pz_plus - pz_max - b

    phi_max = phi_max - b * dphi / (2 * c)
    pz_max = -neg_pz_calc(phi_max)

  endif

  ! Now scale %field_scale
  ! scale_correct = dE(design) / dE (from tracking)
  ! Can overshoot so if scale_correct is too large then scale back by a factor of 10

  if (adjust_amp) then
    scale_correct = dE_peak_wanted / dE_particle(pz_max)
    if (scale_correct > 1000) scale_correct = max(1000.0_rp, scale_correct / 10)
    field_scale = field_scale * scale_correct
  else
    scale_correct = 1
  endif

  if (abs(scale_correct - 1) < scale_tol .and. abs(phi_max-phi_max_old) < phi_tol) exit
  phi_max_old = phi_max

  dphi = 0.05
  if (abs(scale_correct - 1) < 0.1) dphi = max(phi_tol, 0.1*sqrt(2*abs(scale_correct - 1))/twopi)

  if (adjust_phase) then
    pz_max = -neg_pz_calc(phi_max)
  endif

enddo main_loop

! For an rfcavity now find the zero crossing with negative slope which is
! about 90deg away from max acceleration.

if (ele%key == rfcavity$) then
  value_saved(dphi0_max$) = dphi0_ref  ! Save for use with OPAL
  if (scale_phase) then
    dphi = 0.1
    phi_max = phi_max - dphi
    do
      phi = phi_max - dphi
      pz = -neg_pz_calc(phi)
      if (pz < 0) exit
      phi_max = phi
    enddo
    dphi0_ref = modulo2 (zbrent(neg_pz_calc, phi_max-dphi, phi_max, 1d-9), 0.5_rp)
  else
    dphi0_ref = dphi0_ref_original
  endif
endif

! Cleanup

call cleanup_this()

!------------------------------------
contains

subroutine cleanup_this ()

select case (ele%field_calc)
case (bmad_standard$) 
  if (associated(field_scale, ele%value(field_scale$))) then
    value_saved(field_scale$) = field_scale 
    value_saved(dphi0_ref$) = dphi0_ref
  endif
end select

ele%value = value_saved
ele%tracking_method = tracking_method_saved

end subroutine cleanup_this

!------------------------------------
! contains
! Function returns the energy gain of a particle given final pz

function dE_particle(pz) result (de)

real(rp) pz, e_tot, de

call convert_pc_to ((1 + pz) * ele%value(p0c$), param%particle, e_tot = e_tot)
de = e_tot - e_tot_start

end function dE_particle

end subroutine rf_auto_scale_phase_and_amp

!----------------------------------------------------------------
!----------------------------------------------------------------
!----------------------------------------------------------------

function neg_pz_calc (phi) result (neg_pz)

implicit none

type (coord_struct) start_orb, end_orb
real(rp), intent(in) :: phi
real(rp) neg_pz

! brent finds minima so need to flip the final energy

dphi0_ref = phi
call init_coord (start_orb, ele = ele_com, particle = param_com%particle)
call track1 (start_orb, ele_com, param_com, end_orb)

neg_pz = -end_orb%vec(6)
if (param_com%lost) neg_pz = 1

is_lost = param_com%lost

n_loop = n_loop + 1

end function

end module
