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

type photon_init_spline_struct
  type (spline_struct), allocatable :: energy_prob(:)
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
!   splines   -- photon_init_spline_struct: Spline structure
!-

subroutine photon_read_spline (spline_dir, splines)

implicit none

type (photon_init_spline_struct) splines
type (spline_struct), allocatable, target :: prob_spline(:), pl_spline(:), pc_spline(:), pl45_spline(:)

character(*) spline_dir
character(len(spline_dir)+1) s_dir
character(20) source_type, basename

real(rp) dE_spline_max, dP_spline_max

integer i, j, n, ix, num_rows_energy, num_rows_angle, iu, n_rows

namelist / master_params / source_type, dE_spline_max, dP_spline_max, num_rows_energy, &
            num_rows_angle
namelist / params / n_rows
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

read (iu, nml = params)
allocate (prob_spline(n_rows))
read(iu, nml = spline)
close (iu)

call move_alloc (prob_spline, splines%energy_prob)

end subroutine photon_read_spline


end module
