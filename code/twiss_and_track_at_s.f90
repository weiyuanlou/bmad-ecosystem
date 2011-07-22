!+
! Subroutine twiss_and_track_at_s (lat, s, ele, orb, orb_at_s, ix_branch, err)
! 
! Subroutine to return the twiss parameters and particle orbit at a 
! given longitudinal position. See also twiss_and_track_partial.
!
! Note: When calculating the Twiss parameters, this routine assumes 
! that the lattice elements already contain the Twiss parameters calculated
! for the ends of the elements. 
!
! See also:
!   twiss_and_track_from_s_to_s
!   twiss_and_track_intra_ele
!
! Modules Needed:
!   use bmad
!
! Input:
!   lat       -- lat_struct: Lattice.
!   s         -- Real(rp): Longitudinal position. If s is negative the
!                  the position is taken to be lat%param%total_length - s.
!   orb(0:)   -- Coord_struct, optional: Orbit through the Lattice.
!   ix_branch -- Integer, optional: Branch index, Default is 0 (main lattice).
!
! Output:
!   ele      -- Ele_struct, optional: Element structure holding the Twiss parameters.
!                  if orb is not given then the Twiss parameters are calculated
!                  with respect to the zero orbit.
!   orb_at_s -- Coord_struct, optional: Particle position at the position s.
!             If orb_at_s is present then this routine assumes that orb is
!             present.
!   err      -- Logical, optional: Set True if there is a problem in the 
!                 calculation, False otherwise.
!-

subroutine twiss_and_track_at_s (lat, s, ele, orb, orb_at_s, ix_branch, err)

use bmad_struct
use bmad_interface, except_dummy => twiss_and_track_at_s
use lat_geometry_mod

implicit none

type (lat_struct), target :: lat
type (ele_struct), optional :: ele
type (coord_struct), optional :: orb(0:)
type (coord_struct), optional :: orb_at_s
type (branch_struct), pointer :: branch

real(rp) s, s_use

integer, optional :: ix_branch
integer i, i_branch

logical err_flag
logical, optional :: err

character(20), parameter :: r_name = 'twiss_and_track_at_s'

! If close enough to edge of element just use element info.

i_branch = integer_option(0, ix_branch)
branch => lat%branch(i_branch)

call ele_at_s (lat, s, i, ix_branch, err_flag, s_use)
if (err_flag) then
  if (present(err)) err = .true. 
  return
endif

if (abs(s_use - branch%ele(i)%s) < bmad_com%significant_longitudinal_length) then
  if (present(ele)) ele = branch%ele(i)
  if (present(orb_at_s)) orb_at_s = orb(i)
  if (present(err)) err = .false.
  return
endif

! Normal case where we need to partially track through an element.

if (present(orb)) then
  call twiss_and_track_partial (branch%ele(i-1), branch%ele(i), &
               branch%param, s_use-branch%ele(i-1)%s, ele, orb(i-1), orb_at_s, err = err)
else
  call twiss_and_track_partial (branch%ele(i-1), branch%ele(i), &
               lat%param, s_use-branch%ele(i-1)%s, ele, err = err)
endif

call ele_geometry (branch%ele(i-1)%floor, ele, ele%floor)

end subroutine
