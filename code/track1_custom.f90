!+
! Subroutine track1_custom (start, ele, param, end)
!
! Dummy routine for custom tracking. 
! If called, this routine will generate an error message and quit.
! This routine needs to be replaced for a custom calculation.
!
! Modules Needed:
!   use bmad
!
! Input:
!   start  -- Coord_struct: Starting position.
!   ele    -- Ele_struct: Element.
!   param  -- lat_param_struct: Lattice parameters.
!
! Output:
!   end   -- Coord_struct: End position.
!   param -- lat_param_struct: Lattice parameters.
!     %lost -- Logical. Set to true if a particle is lost.
!-

#include "CESR_platform.inc"

subroutine track1_custom (start, ele, param, end)

  use bmad_interface, except => track1_custom

  implicit none

  type (coord_struct) :: start
  type (coord_struct) :: end
  type (ele_struct) :: ele
  type (lat_param_struct) :: param

!

  print *, 'ERROR: DUMMY TRACK1_CUSTOM CALLED FOR: ', ele%name
  print *, '       EITHER CUSTOM TRACKING_METHOD WAS CALLED BY MISTAKE,'
  print *, '       OR THE CORRECT ROUTINE WAS NOT LINKED IN!'
  call err_exit

  end%vec = 0  ! so compiler will not complain

end subroutine
