!+  
! Subroutine convert_coords (in_type_str, coord_in, ele,
!                                                out_type_str, coord_out)
!
! Subroutine to convert between lab frame, normal mode, normalized normal
! mode, and action-angle coordinates.
!
! Modules Needed:
!   use bmad_struct
!   use bmad_interface
!
! Input:
!   in_type_str  -- Character*(*): type of the input coords.
!   coord_in -- Coord_struct: Input coordinates.
!   ele      -- Ele_struct: Provides the Twiss parameters.
!
! Output:
!   out_type_str  -- Character*(*): type of the output coords.
!   coord_out -- Coord_struct: Output coordinates.
!
! in_type_str and out_type_str can be:
!   'LAB'                {x, x', y, y', z, z'}
!   'MODE'               {a, a', b, b', z, z'}
!   'NORMALIZED'         {a_bar, a'_bar, b_bar, b'_bar, z_bar, z'_bar}
!   'ACTION-ANGLE'       {j_a, phi_a, j_b, phi_b, j_z,  phi_z}
!
!
! x_vec = V_mat * (a_vec + eta_vec * z')
!
! a_bar  =  sqrt(2*j_a) * cos(phi_a)
! a'_bar = -sqrt(2*j_a) * sin(phi_a)
!
! Note:
!
! 1) If ELE%Z%BETA = 0 then ELE%Z%BETA is set to 1.
!
! 2) phases are in radians
!-

!$Id$
!$Log$
!Revision 1.2  2001/09/27 18:31:50  rwh24
!UNIX compatibility updates
!

#include "CESR_platform.inc"


subroutine convert_coords (in_type_str, coord_in, ele, out_type_str, coord_out)

  use bmad_struct
  use bmad_interface

  implicit none

  character*(*) in_type_str, out_type_str
  type (coord_struct) coord_in, coord_out
  type (ele_struct) ele

  integer in_type, out_type

  real mat(4,4), mat_inv(4,4), mat2(2,2), mat2_inv(2,2), eta_vec(4)

  integer :: lab$ = 1, mode$ = 2, normalized$ = 3, action_angle$ = 4
  character*16 type_names(5) / 'LAB', 'MODE', 'NORMALIZED', &
                    'ACTION-ANGLE', ' ' /

!---------------------------------------
! match character strings to type list

  call match_word (in_type_str, type_names, in_type)

  if (in_type <= 0) then
    if (bmad_status%type_out) type *, &
                'ERROR IN CONVERT_COORDS: UNKNOWN IN_TYPE_STR: ', in_type_str
    if (bmad_status%exit_on_error) call err_exit
    bmad_status%ok = .false.
    return
  endif

  call match_word (out_type_str, type_names, out_type)

  if (out_type <= 0) then
    if (bmad_status%type_out) type *, &
               'ERROR IN CONVERT_COORDS: UNKNOWN OUT_TYPE_STR: ', out_type_str
    if (bmad_status%exit_on_error) call err_exit
    bmad_status%ok = .false.
    return
  endif

! out = in then nothing to do

  coord_out = coord_in
  if (ele%z%beta == 0) ele%z%beta = 1

  if (in_type == out_type) return

!---------------------------------------
! from lab to action_angle

  if (out_type > in_type) then

! lab to normal mode

    if (in_type == lab$) then
      call make_v_mats (ele, mat, mat_inv)
      coord_out%vec(1:4) = matmul (mat_inv, coord_out%vec(1:4))
      eta_vec = (/ ele%x%eta, ele%x%etap, ele%y%eta, ele%y%etap /)
      coord_out%vec(1:4) = coord_out%vec(1:4) - eta_vec * coord_out%vec(6)
      if (out_type == mode$) return
      in_type = mode$
    endif

! normal mode to normalized normal mode

    if (in_type == mode$) then
      call make_g_mats (ele, mat, mat_inv)
      coord_out%vec(1:4) = matmul (mat, coord_out%vec(1:4))
      call make_g2_mats (ele%z, mat2, mat2_inv)
      coord_out%vec(5:6) = matmul (mat2, coord_out%vec(5:6))
      if (out_type == normalized$) return
    endif

! normalized normal mode to action angle

    call to_action (coord_out%vec(1:2))
    call to_action (coord_out%vec(3:4))
    call to_action (coord_out%vec(5:6))

    return

  endif

!---------------------------------------
! from action_angle to lab

! action_angle to normalized

  if (in_type == action_angle$) then
    call from_action (coord_out%vec(1:2))
    call from_action (coord_out%vec(3:4))
    call from_action (coord_out%vec(5:6))
    if (out_type == normalized$) return
    in_type = normalized$
  endif

! normalized to normal mode

  if (in_type == normalized$) then
    call make_g_mats (ele, mat, mat_inv)
    coord_out%vec(1:4) = matmul (mat_inv, coord_out%vec(1:4))
    call make_g2_mats (ele%z, mat2, mat2_inv)
    coord_out%vec(5:6) = matmul (mat2_inv, coord_out%vec(5:6))
    if (out_type == mode$) return
  endif

! normal mode to lab

  eta_vec = (/ ele%x%eta, ele%x%etap, ele%y%eta, ele%y%etap /)
  coord_out%vec(1:4) = coord_out%vec(1:4) + eta_vec * coord_out%vec(6)
  call make_v_mats (ele, mat, mat_inv)
  coord_out%vec(1:4) = matmul (mat, coord_out%vec(1:4))

  return

!---------------------------------------
contains

subroutine to_action (coord)
    implicit none
    real coord(2), j, phi
    j = (coord(1)**2 + coord(2)**2) / 2
    if (j == 0) then
      phi = 0
    else
      phi = atan2 (-coord(2), coord(1))
    endif
    coord = (/ j, phi /)
  end subroutine

subroutine from_action (coord)
    implicit none
    real coord(2), x, xp
    x  =  sqrt(2*coord(1)) * cos(coord(2))
    xp = -sqrt(2*coord(1)) * sin(coord(2))
    coord = (/ x, xp /)
  end subroutine

end subroutine

