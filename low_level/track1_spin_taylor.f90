!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!+
! subroutine track1_spin_taylor (start_orb, ele, param, end_orb)
!
! Particle spin tracking through a single element with a spin map.
!
! Input :
!   start_orb  -- Coord_struct: Starting coords.
!   ele        -- Ele_struct: Element to track through.
!   param      -- lat_param_struct: Beam parameters.
!   end_orb    -- Coord_struct: Ending coords.
!
! Output:
!   end_orb     -- Coord_struct:
!     %spin(3)   -- Ending spin
!-

subroutine track1_spin_taylor (start_orb, ele, param, end_orb)

use taylor_mod, dummy => track1_spin_taylor

implicit none

type (coord_struct) :: start_orb, end_orb
type (ele_struct) ele
type (lat_param_struct) param

real(rp) quat(4), norm
character(*), parameter :: r_name = 'track1_spin_taylor'

!

if (.not. associated(ele%spin_taylor(0)%term)) then
  call out_io (s_error$, r_name, 'NO SPIN TAYLOR MAP ASSOCIATED WITH ELEMENT: ' // ele%name)
  if (global_com%exit_on_error) call err_exit
  end_orb%spin = start_orb%spin
endif

quat = track_taylor (start_orb%vec, ele%spin_taylor, ele%taylor%ref)
norm = norm2(quat)
if (abs(norm - 1) > 0.5) then
  call out_io (s_warn$, r_name, 'Norm of quaternion computed from the spin taylor map of element: ' // ele%name, &
                                'is far from 1.0')
endif

end_orb%spin = rotate_vec_given_quat(quat/norm, start_orb%spin)

end subroutine track1_spin_taylor


