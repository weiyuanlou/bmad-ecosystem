!+
! Subroutine make_mat6 (ele, param, start, end, end_in)
!
! Subroutine to make the 6x6 1st order transfer matrix for an element 
! along with the 0th order transfer vector.
!
! Modules needed:
!   use bmad
!
! Input:
!   ele    -- Ele_struct: Element holding the transfer matrix.
!   param  -- Param_struct: Lattice global parameters.
!   start  -- Coord_struct, optional: Coordinates at the beginning of element. 
!               If not present then default is start = 0.
!   end    -- Coord_struct, optional: Coordinates at the end of element.
!               end is an input only if end_in is set to True.
!   end_in -- Logical, optional: If present and True then the end coords
!               will be taken as input. not output as normal.
!
!
! Output:
!   ele    -- Ele_struct: Element
!     %mat6  -- Real(rp): 1st order 6x6 transfer matrix.
!     %vec0  -- Real(rp): 0th order transfer vector.
!   end    -- Coord_struct, optional: Coordinates at the end of element.
!               end is an output if end_in is not set to True.
!   param  -- Param_struct:
!     %lost  -- Since make_mat6 may do tracking %lost may be set to True if
!                 tracking was unsuccessful. %lost set to False otherwise.
!-

#include "CESR_platform.inc"

subroutine make_mat6 (ele, param, start, end, end_in)

  use bmad_struct
  use bmad_interface, except => make_mat6
  use symp_lie_mod, only: symp_lie_bmad
  use bookkeeper_mod, only: attribute_bookkeeper
  use mad_mod, only: make_mat6_mad
  use em_field_mod, only: track_com

  implicit none

  type (ele_struct), target :: ele
  type (coord_struct), optional :: start, end
  type (param_struct)  param
  type (coord_struct) a_start, a_end

  integer mat6_calc_method

  logical, optional :: end_in
  logical end_input

!--------------------------------------------------------
! init

  param%lost = .false.
  call attribute_bookkeeper (ele, param)

  mat6_calc_method = ele%mat6_calc_method
  if (.not. ele%is_on) mat6_calc_method = bmad_standard$

!

  end_input = .false.
  if (present(end_in)) end_input = end_in

  if (end_input .and. .not. present(end)) then
    print *, 'ERROR IN MAKE_MAT6: CONFUSED END_IN WITHOUT AN END!'
    call err_exit
  endif

  if (present(start)) then
    a_start = start
  else
    a_start%vec = 0
  endif

  if (end_input) a_end = end

  select case (mat6_calc_method)

  case (taylor$)
    call make_mat6_taylor (ele, param, a_start)
    if (.not. end_input) call track_taylor (a_start%vec, ele%taylor, a_end%vec)

  case (custom$) 
    call make_mat6_custom (ele, param, a_start, a_end)

  case (bmad_standard$)
    call make_mat6_bmad (ele, param, a_start, a_end, end_in)

  case (symp_lie_ptc$)
    call make_mat6_symp_lie_ptc (ele, param, a_start)
    if (.not. end_input) call track_taylor (a_start%vec, ele%taylor, a_end%vec)

  case (symp_lie_bmad$)
    call symp_lie_bmad (ele, param, a_start, a_end, .true., track_com)

  case (tracking$)
    call make_mat6_tracking (ele, param, a_start, a_end)

  case (mad$)
    call make_mat6_mad (ele, param, a_start, a_end)

  case (none$)
    return

  case default
    print *, 'ERROR IN MAKE_MAT6: UNKNOWN MAT6_CALC_METHOD: ', &
                                    calc_method_name(ele%mat6_calc_method)
    call err_exit
  end select

! symplectify if wanted

  if (ele%symplectify) call mat_symplectify (ele%mat6, ele%mat6)

! Make the 0th order transfer vector

  ele%vec0 = a_end%vec - matmul(ele%mat6, a_start%vec)
  if (present(end) .and. .not. end_input) end = a_end

end subroutine

