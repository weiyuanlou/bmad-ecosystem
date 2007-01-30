!+
! Subroutine write_digested_bmad_file (digested_name, lat, n_files, file_names)
!
! Subroutine to write a digested file. The names of the original files used
! to create the LAT structure are also put in the digested file and are used
! by other routines to check if the digested file is out of date.
!
! Modules Needed:
!   use bmad
!
! Input:
!     digested_name -- Character(*): Name for the digested file.
!     lat          -- lat_struct: Input lat structure.
!     n_files       -- Integer, optional: Number of original files
!     file_names(*) -- Character(*), optional: Names of the original 
!                       files used to create the lat structure.
!-

#include "CESR_platform.inc"

subroutine write_digested_bmad_file (digested_name, lat,  &
                                                  n_files, file_names)

  use bmad_struct
  use bmad_interface, except => write_digested_bmad_file
  use equality_mod, only: operator(==)
  use bmad_parser_mod

  implicit none

  type (lat_struct), target, intent(in) :: lat
  type (ele_struct), pointer :: ele
  type (taylor_struct), pointer :: tt(:)
  type (wake_struct), pointer :: wake
  
  integer, intent(in), optional :: n_files
  integer d_unit, i, j, k, n_file
  integer ix_wig, ix_const, ix_r(4), ix_d, ix_m, ix_t(6)
  integer stat_b(12), stat, n_wake
  integer ix_sr_table, ix_sr_mode_long, ix_sr_mode_trans, ix_lr, ierr
  integer :: ix_wake(lat%n_ele_max)

  character(*) digested_name
  character(*), optional :: file_names(:)
  character(200) fname, full_digested_name
  character(32) :: r_name = 'write_digested_bmad_file'

  logical write_wake

  external stat

! Write input file names to the digested file
! The idea is that read_digested_bmad_file can look at these files and see
! if a file has been modified since the digested file has been created.
! Additionally record if one of the random number functions was called.

  n_file = 0
  if (present(n_files)) n_file = n_files

  d_unit = lunget()

  call fullfilename (digested_name, full_digested_name)
  inquire (file = full_digested_name, name = full_digested_name)
  open (unit = d_unit, file = full_digested_name, form = 'unformatted', err = 9000)

! Ran function called?

  if (bp_com%ran_function_was_called) then
    write (d_unit, err = 9010) n_file+2, bmad_inc_version$
    fname = '!RAN FUNCTION WAS CALLED'
    write (d_unit) fname, 0
  else
    write (d_unit, err = 9010) n_file+1, bmad_inc_version$
  endif

! Write digested file name

  stat_b = 0
#ifndef CESR_VMS 
  ierr = stat(full_digested_name, stat_b)
#endif
  fname = '!DIGESTED:' // full_digested_name
  write (d_unit) fname, stat_b(10)  ! stat_b(10) = Modification date
 
! write other file names.

  do j = 1, n_file
    fname = file_names(j)
    stat_b = 0
#ifndef CESR_VMS 
    ierr = stat(fname, stat_b)
#endif
    write (d_unit) fname, stat_b(10)  ! stat_b(10) = Modification date
  enddo

! Write the lat structure to the digested file. We do this in pieces
! since the whole structure is too big to write in 1 statement.

  write (d_unit) &
          lat%name, lat%lattice, lat%input_file_name, lat%title, &
          lat%a, lat%b, lat%z, lat%param, lat%version, lat%n_ele_track, &
          lat%n_ele_track, lat%n_ele_max, &
          lat%n_control_max, lat%n_ic_max, lat%input_taylor_order
  
  n_wake = 0  ! number of wakes written to the digested file.

  do i = 0, lat%n_ele_max
  
    ele => lat%ele(i)
    tt => ele%taylor
    
    ix_wig = 0; ix_d = 0; ix_m = 0; ix_t = 0; ix_const = 0; ix_r = 0
    ix_sr_table = 0; ix_sr_mode_long = 0; ix_sr_mode_trans = 0; ix_lr = 0

    if (associated(ele%wig_term)) ix_wig = size(ele%wig_term)
    if (associated(ele%const))    ix_const = size(ele%const)
    if (associated(ele%r))        ix_r = (/ lbound(ele%r), ubound(ele%r) /)
    if (associated(ele%descrip))  ix_d = 1
    if (associated(ele%a_pole))        ix_m = 1
    if (associated(tt(1)%term))   ix_t = (/ (size(tt(j)%term), j = 1, 6) /)

    ! Since some large lattices with a large number of wakes can take a lot of time writing 
    ! the wake info we only write a wake when needed.
    ! The idea is that ix_lr serves as a pointer to a previously written wake.

    write_wake = .true.
    if (associated(ele%wake)) then
      do j = 1, n_wake
        if (.not. lat%ele(ix_wake(j))%wake == ele%wake) cycle
        write_wake = .false.
        ix_lr = -ix_wake(j)        
      enddo

      if (write_wake) then
        if (associated(ele%wake%sr_table))       ix_sr_table       = size(ele%wake%sr_table)
        if (associated(ele%wake%sr_mode_long))  ix_sr_mode_long  = size(ele%wake%sr_mode_long)
        if (associated(ele%wake%sr_mode_trans)) ix_sr_mode_trans = size(ele%wake%sr_mode_trans)
        if (associated(ele%wake%lr))        ix_lr        = size(ele%wake%lr)
        n_wake = n_wake + 1
        ix_wake(n_wake) = i
      endif
    endif

    ! Now write the element info

    write (d_unit) ix_wig, ix_const, ix_r, ix_d, ix_m, ix_t, &
            ix_sr_table, ix_sr_mode_long, ix_sr_mode_trans, ix_lr, &
            ele%name, ele%type, ele%alias, ele%attribute_name, ele%a, &
            ele%b, ele%z, ele%value, ele%gen0, ele%vec0, ele%mat6, &
            ele%c_mat, ele%gamma_c, ele%s, ele%key, ele%floor, &
            ele%is_on, ele%sub_key, ele%control_type, ele%ix_value, &
            ele%n_slave, ele%ix1_slave, ele%ix2_slave, ele%n_lord, &
            ele%ic1_lord, ele%ic2_lord, ele%ix_pointer, ele%ixx, &
            ele%ix_ele, ele%mat6_calc_method, ele%tracking_method, &
            ele%num_steps, ele%integrator_order, ele%ptc_kind, &
            ele%taylor_order, ele%symplectify, ele%mode_flip, &
            ele%multipoles_on, ele%map_with_offsets, ele%Field_master, &
            ele%logic, ele%internal_logic, ele%field_calc, ele%aperture_at, &
            ele%coupler_at, ele%on_an_i_beam, ele%csr_calc_on

    do j = 1, ix_wig
      write (d_unit) ele%wig_term(j)
    enddo

    if (associated(ele%const))    write (d_unit) ele%const
    if (associated(ele%r))        write (d_unit) ele%r
    if (associated(ele%descrip))  write (d_unit) ele%descrip
    if (associated(ele%a_pole))        write (d_unit) ele%a_pole, ele%b_pole
    
    do j = 1, 6
      if (ix_t(j) == 0) cycle
      write (d_unit) tt(j)%ref
      do k = 1, ix_t(j)
        write (d_unit) tt(j)%term(k)
      enddo
    enddo

    if (associated(ele%wake) .and. write_wake) then
      write (d_unit) ele%wake%sr_file
      write (d_unit) ele%wake%sr_table
      write (d_unit) ele%wake%sr_mode_long
      write (d_unit) ele%wake%sr_mode_trans
      write (d_unit) ele%wake%lr_file
      write (d_unit) ele%wake%lr
      write (d_unit) ele%wake%z_sr_mode_max
    endif

  enddo

! write the control info, etc

  do i = 1, lat%n_control_max
    write (d_unit) lat%control(i)
  enddo

  do i = 1, lat%n_ic_max
    write (d_unit) lat%ic(i)
  enddo

  write (d_unit) lat%beam_start

  close (d_unit)

  return

! Errors

9000  print *
  print *, 'WRITE_DIGESTED_BMAD_FILE: NOTE: CANNOT OPEN FILE FOR OUTPUT:'
  print *, '    ', trim(digested_name)
  print *, '     [This does not affect program operation]'
  return

9010  print *
  print *, 'WRITE_DIGESTED_BMAD_FILE: NOTE: CANNOT WRITE TO FILE FOR OUTPUT:'
  print *, '    ', trim(digested_name)
  print *, '     [This does not affect program operation]'
  close (d_unit)
  return

end subroutine
