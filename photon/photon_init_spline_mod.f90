!+
! Module photon_init_spline_mod
!
! Module for initializing phtons given the appropriate splines fits
! to the photon probability distributions.
!-

module photon_init_spline_mod

use bmad_struct
use bmad_interface
use spline_mod

type photon_init_h_angle_spline_struct
  type (spline_struct), allocatable :: prob(:), pl(:), pc(:), pl45(:)
end type

type photon_init_v_angle_spline_struct
  type (spline_struct), allocatable :: prob(:), pl(:), pc(:), pl45(:)
  type (photon_init_h_angle_spline_struct), allocatable :: h_angle(:)
end type

type photon_init_splines_struct
  character(16) type
  type (spline_struct), allocatable :: energy_prob(:)
  type (photon_init_v_angle_spline_struct), allocatable :: v_angle(:)
end type

contains

!----------------------------------------------------------------------------------------
!----------------------------------------------------------------------------------------
!----------------------------------------------------------------------------------------
!+
! Subroutine photon_read_spline (spline_dir, splines)
!
! Routine to initialize a photon using a set of spline fits.
!
! Input:
!   spline_dir -- character(*): Root directory for the spline fits.
!
! Output:
!   splines   -- photon_init_splines_struct: Spline structure
!-

subroutine photon_read_spline (spline_dir, splines)

implicit none

type (photon_init_splines_struct) splines
type (spline_struct), allocatable, target :: prob_spline(:), pl_spline(:), pc_spline(:), pl45_spline(:)

character(*) spline_dir
character(len(spline_dir)+1) s_dir
character(20) source_type, basename
character(200) v_angle_spline_file

real(rp) dE_spline_max, dP_spline_max

integer i, j, n, ix, num_rows_energy, num_rows_v_angle, iu, n_rows

namelist / master_params / source_type, dE_spline_max, dP_spline_max, num_rows_energy, &
            num_rows_v_angle
namelist / energy_params / n_rows
namelist / v_angle_params / n_rows
namelist / spline / prob_spline, pl_spline, pc_spline, pl45_spline

! Add '/' suffix if needed

s_dir = spline_dir
n = len_trim(spline_dir)
if (spline_dir(n:n) /= '/') s_dir = trim(s_dir) // '/'

! Read general parameters

iu = lunget()
open (iu, file = trim(s_dir) // 'spline.params')
read (iu, nml = master_params)
close(iu)

! Read energy spline

iu = lunget()
open (iu, file = trim(s_dir) // 'spline/energy.spline')

read (iu, nml = energy_params)
allocate (prob_spline(n_rows))
read(iu, nml = spline)
close (iu)

call move_alloc (prob_spline, splines%energy_prob)

! Read vertical angle splines

allocate (splines%v_angle(num_rows_energy))

do i = 1, num_rows_energy
  write (v_angle_spline_file, '(2a, i0, a)') trim(s_dir), 'spline/v_angle', i, '.spline'
  open (iu, file = v_angle_spline_file)

  read (iu, nml = v_angle_params)
  allocate (prob_spline(n_rows), pl_spline(n_rows), pc_spline(n_rows), pl45_spline(n_rows))
  read(iu, nml = spline)
  close (iu)

  call move_alloc (prob_spline, splines%v_angle(i)%prob)
  call move_alloc (pl_spline, splines%v_angle(i)%pl)
  call move_alloc (pc_spline, splines%v_angle(i)%pc)
  call move_alloc (pl45_spline, splines%v_angle(i)%pl45)
enddo

end subroutine photon_read_spline


end module
