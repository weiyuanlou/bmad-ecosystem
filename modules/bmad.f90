!+
! Module bmad
!
! A "use bmad" statement will define the most common bmad structures needed 
! by a program.
!-

module bmad

use dynamic_aperture_mod
use bookkeeper_mod
use symp_lie_mod
use twiss_and_track_mod
use taylor_mod

implicit none

! This is to suppress the ranlib "has no symbols" message
integer, private :: private_dummy

end module
