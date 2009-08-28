!+
! Subroutine s_calc (lat)
!
! Subroutine to calculate the longitudinal distance S for the elements
! in a lattice.
!
! Modules Needed:
!   use bmad
!
! Input:
!   lat -- lat_struct:
!
! Output:
!   lat -- lat_struct:
!-

subroutine s_calc (lat)

use bmad_struct
use bmad_interface, except_dummy => s_calc
use lat_ele_loc_mod

implicit none

type (lat_struct), target :: lat
type (ele_struct), pointer :: ele
type (branch_struct), pointer :: line

integer i, j, n, ix2
real*8 ss

! Just go through all the elements and add up the lengths.

ss = lat%ele(0)%s

do n = 1, lat%n_ele_track
  ss = lat%ele(n-1)%s + lat%ele(n)%value(l$)
  lat%ele(n)%s = ss
enddo

lat%param%total_length = ss - lat%ele(0)%s

! Now fill in the s positions of the super_lords and zero everyone else.
! Exception: A null_ele lord element is the result of a superposition on a multipass section.
! We need to preserve the s value of this element.

do n = lat%n_ele_track+1, lat%n_ele_max
  if (lat%ele(n)%key == null_ele$) cycle
  if (lat%ele(n)%lord_status == super_lord$) then
    ix2 = lat%control(lat%ele(n)%ix2_slave)%ix_slave
    lat%ele(n)%s = lat%ele(ix2)%s
  else
    lat%ele(n)%s = 0
  endif
enddo

! Now do the bookkeeping for any branches...

do i = 1, ubound(lat%branch, 1)
  line => lat%branch(i)
  line%ele(0)%s = 0
  if (line%ix_from_branch /= 0) then
    ele => pointer_to_ele (lat, line%ix_from_ele, line%ix_from_branch)
    line%ele(0)%s = ele%s
  endif
  do n = 1, line%n_ele_track
    ss = line%ele(n-1)%s + line%ele(n)%value(l$)
    line%ele(n)%s = ss
  enddo
enddo

end subroutine
