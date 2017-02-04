!+
! Program to convert a Bmad file to an XSIF file and a MAD file
!
! Usage:
!   bmad_to_mad_sad_and_xsif {-nobpm} {-noaperture} {-force} {-xsif} {-mad8} {-madx} {-sad} <bmad_file_name>
!
! The MAD and XSIF files will be created in the current directory.
!
! The bmad_file_name will have a '.bmad' appended to the name if there
! is no '.' in the original name.
!
! The output file name will be the bmad_file_name with the '.bmad' suffix
! (or whatever suffix is there) replaced by:
!       '.xsif'       for XSIF files
!       '.mad8'       for MAD8 files
!       '.madx'       for MAD-X files
!       '.sad'        for SAD files.
!
! Lattices with and without bpm markers can be generated by using the "-nobpm" option. 
! This is useful for cesr lattices where bpms within a quad will produce drifts with negative lengths.
! 
! If the "-force" option is used to force translation even when no reference orbit and twiss parameters
! can be computed.
!-

program bmad_to_mad_sad_and_xsif

use bmad
use write_lat_file_mod

implicit none

type (lat_struct) lat
type (coord_struct), allocatable :: orbit(:)

integer i, n_arg, ix, status
logical is_rel, nobpm, aperture, force
character(120) file_name, out_name, dir, arg
character(16) bpm_ans, out_type

character(*), parameter :: r_name = 'bmad_to_mad_sad_and_xsif'

!

n_arg = cesr_iargc()
nobpm = .false.
file_name = ''
out_type = 'all'
aperture = .true.
force = .false.

do i = 1, n_arg
  call cesr_getarg (i, arg)
  select case (arg)
  case ('-force')
    force = .true.
  case ('-nobpm')
    nobpm = .true.
  case ('-noaperture')
    aperture = .false.
  case ('-xsif', '-mad8', '-madx', '-sad')
    out_type = arg
  case default
    if (arg(1:1) == '-') then
      print *, 'Bad switch: ', trim(arg)
      file_name = ''
      exit
    else
      file_name = arg
    endif
  end select
enddo

if (file_name == '') then
  print '(a)', 'Usage: bmad_to_mad_sad_and_xsif {-nobpm} {-noaperture} {-xsif} {-mad8} {-madx} {-sad} <bmad_file_name>'
  stop
endif

! Get the lattice

call file_suffixer (file_name, file_name, 'bmad', .false.)
call bmad_parser (file_name, lat)
call twiss_and_track (lat, orbit, status, use_beam_start = .true.)
if (status /= ok$ .and. .not. force) then
  call out_io (s_error$, r_name, 'PROBLEM TRACKING. NO OUTPUT GENERATED!', &
                                 'USE THE "-force" OPTION TO FORCE TRANSLATION.')
  stop
endif

ix = splitfilename (file_name, dir, file_name, is_rel)

! Lattices with bpm markers

out_name = file_name
if (nobpm) then
  ix = index(out_name, '.')
  out_name = out_name(1:ix-1) // '_with_bpm'
endif

if (out_type == 'all' .or. out_type == '-xsif') then
  call file_suffixer (out_name, out_name, 'xsif', .true.)
  call write_lattice_in_foreign_format ('XSIF', out_name, lat, orbit, include_apertures = aperture)
endif

if (out_type == 'all' .or. out_type == '-mad8') then
  call file_suffixer (out_name, out_name, 'mad8', .true.)
  call write_lattice_in_foreign_format ('MAD-8', out_name, lat, orbit, include_apertures = aperture)
endif

if (out_type == 'all' .or. out_type == '-madx') then
  call file_suffixer (out_name, out_name, 'madx', .true.)
  call write_lattice_in_foreign_format ('MAD-X', out_name, lat, orbit, include_apertures = aperture)
endif

if (out_type == 'all' .or. out_type == '-sad') then
  call file_suffixer (out_name, out_name, 'sad', .true.)
  call write_lattice_in_foreign_format ('SAD', out_name, lat, orbit, include_apertures = aperture)
endif

! Lattices without bpm markers.
! Also combine drifts to either side of a detector.

if (.not. nobpm) stop

do i = 1, lat%n_ele_track
  if (lat%ele(i)%name(1:4) == 'DET_') then
    lat%ele(i)%key = -1 ! Mark for deletion
    if (lat%ele(i-1)%key == drift$ .and. lat%ele(i+1)%key == drift$) then
      lat%ele(i-1)%value(l$) = lat%ele(i-1)%value(l$) + lat%ele(i+1)%value(l$)
      lat%ele(i+1)%key = -1
    endif
  endif
enddo

call remove_eles_from_lat(lat)

out_name = file_name

if (out_type == 'all' .or. out_type == '-xsif') then
  call file_suffixer (out_name, out_name, 'xsif', .true.)
  call write_lattice_in_foreign_format ('XSIF', out_name, lat, orbit, include_apertures = aperture)
endif

if (out_type == 'all' .or. out_type == '-mad8') then
  call file_suffixer (out_name, out_name, 'mad8', .true.)
  call write_lattice_in_foreign_format ('MAD-8', out_name, lat, orbit, include_apertures = aperture)
endif

if (out_type == 'all' .or. out_type == '-madx') then
  call file_suffixer (out_name, out_name, 'madx', .true.)
  call write_lattice_in_foreign_format ('MAD-X', out_name, lat, orbit, include_apertures = aperture)
endif

if (out_type == 'all' .or. out_type == '-sad') then
  call file_suffixer (out_name, out_name, 'sad', .true.)
  call write_lattice_in_foreign_format ('SAD', out_name, lat, orbit, include_apertures = aperture)
endif

end program
