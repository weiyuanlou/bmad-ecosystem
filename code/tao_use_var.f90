!+
! subroutine tao_use_var (s, action, var_class, locations)
!
! Veto, restore or use specified datums. range syntax: 1:34 46 58:78
!
! Input:
!   s		  -- tao_super_universe_struct
!   var_class     -- charatcer(*): the selected variable class
!   locations     -- character(*): the index location expression
!
! Output:
!   s		  -- tao_super_universe_struct
!-

subroutine tao_use_var (s, action, var_class, locations)

use tao_mod

implicit none

type (tao_super_universe_struct) :: s
character(*)                     :: action
character(*)                     :: var_class
character(*)                     :: locations

type (tao_v1_var_struct), pointer :: v1_ptr

logical, allocatable :: action_logic(:) !which elements do we take action on?

integer which, i, n1, n2, k
integer err_num

character(12) :: r_name = "tao_use_var"
character(200) line

logical do_all_universes
logical err

! decipher action

call match_word (action, name$%use_veto_restore, which)

! Apply to all universes? 
! With parallel vars yes.


if (s%global%parallel_vars) then
  do k = 1, size(s%u)
    call use_var (s%u(k))
  enddo
else
  call use_var (s%u(s%global%u_view))
endif

!------------------------------------------------------------------
contains

subroutine use_var (u)

type (tao_universe_struct) u

! find data class and sub_class

  call tao_find_var (err, u, var_class, v1_ptr)
  if (err) return

! find locations

  err_num = 0
  n1 = lbound(v1_ptr%v, 1)
  n2 = ubound(v1_ptr%v, 1)
  allocate(action_logic(n1:n2))
  call location_decode (locations, action_logic, n1, err_num) 
  if (err_num .eq. -1) return

! set d%good_user based on action and action_logic

select case (which)
case (use$)
  v1_ptr%v(:)%good_user = action_logic
case (veto$)
  where (action_logic) v1_ptr%v(:)%good_user = .not. action_logic
case (restore$)
  where (action_logic) v1_ptr%v(:)%good_user = action_logic
case default
  call out_io (s_error$, r_name, &
                    "Internal error picking name$%use_veto_restore")
  err = .true.
end select


! optimizer bookkeeping and print out changes

  call tao_set_var_useit_opt(s)
  call tao_var_show_use (v1_ptr)

  deallocate(action_logic)

end subroutine

end subroutine tao_use_var
