!+
! Subroutine track1_taylor (start, ele, param, end)
!
! Subroutine to track through an element using the elements taylor series.
!
! Moudules needed:
!   use bmad
!
! Input:
!   start      -- Coord_struct: Starting coords.
!   ele        -- Ele_struct: Element to track through.
!   param      -- lat_param_struct: Beam parameters.
!     %enegy     -- Energy in GeV
!     %particle  -- Particle type [positron$, or electron$]
!
! Output:
!   end        -- Coord_struct: Ending coords.
!-

subroutine track1_taylor (start, ele, param, end)

  use ptc_interface_mod, except => track1_taylor

  implicit none

  type (coord_struct) :: start
  type (coord_struct) :: end
  type (lat_param_struct) :: param
  type (ele_struct) :: ele

!

  if (.not. associated(ele%taylor(1)%term)) then
    if (bmad_status%type_out) then
      print *, 'WARNING FROM TRACK1_TAYLOR: TAYLOR SERIES NOT PRESENT FOR: ', &
                                                                      ele%name
      print *, '        I WILL MAKE A TAYLOR SERIES AROUND THE GIVEN ORBIT...'
    endif
    call ele_to_taylor(ele, param, start)
  endif

! If the Taylor map does not have the offsets included then do the appropriate
! tracking.

  if (ele%map_with_offsets) then  ! simple case
    call track_taylor (start%vec, ele%taylor, end%vec)

  else
    end = start
    call offset_particle (ele, param, end, set$, &
                          set_canonical = .false., set_multipoles = .false.)
    call track_taylor (end%vec, ele%taylor, end%vec)
    call offset_particle (ele, param, end, unset$, &
                          set_canonical = .false., set_multipoles = .false.)
  endif

end subroutine
