program slice_test

use bmad
use transfer_map_mod

implicit none

type (lat_struct), target :: lat
type (branch_struct), pointer :: branch
type (coord_struct), allocatable :: ref_orb(:)
type (coord_struct) orb1, orb2a, orb2b, orb2c, orb2d
type (coord_struct) start_orb, end_orb, end_orb2
type (ele_struct) ele1, ele2a, ele2b
type (taylor_struct) t_map(6)

real(rp) s1, s2
real(rp) xmat_c(6,6), vec0_c(6), xmat_d(6,6), vec0_d(6)

integer idum, nargs
logical print_extra
character(100) lat_file

!

lat_file = 'slice_test.bmad'
print_extra = .false.
nargs = cesr_iargc()
if (nargs == 1)then
   call cesr_getarg(1, lat_file)
   print *, 'Using ', trim(lat_file)
   print_extra = .true.
elseif (nargs > 1) then
  print *, 'Only one command line arg permitted.'
  call err_exit
endif

call bmad_parser ('slice_test.bmad', lat)
open (1, file = 'output.now')

! Test on branch 0

branch => lat%branch(0)
call init_coord (start_orb, ele = branch%ele(1), at_downstream_end = .false.)
! Track through split bend
call track1 (start_orb, branch%ele(1), branch%param, end_orb)
call track1 (end_orb, branch%ele(3), branch%param, end_orb)

! Track through unsplit bend
call track1 (start_orb, branch%ele(4), branch%param, end_orb2)

write (1, '(a, 6es18.9)') '"bend:dvec" ABS 1e-14', end_orb2%vec - end_orb%vec
write (1, '(a, es18.9)')  '"bend:dt" ABS 1e-14  ', end_orb2%t - end_orb%t

if (print_extra) then
  call type_ele (branch%ele(1), .false., 0, .false., 0)
  print '(a, 6f16.12)', 'Start: ', start_orb%vec
  print *
  print '(a, 6f16.12)', 'Split: ', end_orb%vec
  print '(a, 6f16.12)', 'Whole: ', end_orb2%vec
  print *
  stop
endif

! Test on branch 1

branch => lat%branch(1)
call reallocate_coord (ref_orb, lat, branch%ix_branch)
ref_orb = lat%beam_start

s1 = 0.5_rp
s2 = 2.5_rp

call track_all (lat, ref_orb, branch%ix_branch)
call lat_make_mat6 (lat, -1, ref_orb, branch%ix_branch)
call twiss_propagate_all (lat, branch%ix_branch)

call twiss_and_track_at_s (lat, s1, ele1, ref_orb, orb1, branch%ix_branch)
call twiss_and_track_at_s (lat, s2, ele2a, ref_orb, orb2a, branch%ix_branch)

orb2c = orb1
call mat6_from_s_to_s (lat, xmat_c, vec0_c, s1, s2, orb2c, branch%ix_branch)

idum = element_at_s (lat, s1, .true., branch%ix_branch, position = orb1)
idum = element_at_s (lat, s2, .true., branch%ix_branch, position = orb2b)
call twiss_and_track_from_s_to_s (branch, orb1, orb2b, ele1, ele2b)

call transfer_map_from_s_to_s (lat, t_map, s1, s2, branch%ix_branch)
call taylor_to_mat6 (t_map, orb1%vec, vec0_d, xmat_d, orb2d%vec)

write (1, *)
write (1, '(a, es22.12)') '"vec(1)" REL  1E-10', orb2a%vec(1)
write (1, '(a, es22.12)') '"vec(2)" REL  1E-10', orb2a%vec(2)
write (1, '(a, es22.12)') '"vec(3)" REL  1E-10', orb2a%vec(3)
write (1, '(a, es22.12)') '"vec(4)" REL  1E-10', orb2a%vec(4)
write (1, '(a, es22.12)') '"vec(5)" REL  1E-10', orb2a%vec(5)
write (1, '(a, es22.12)') '"vec(6)" REL  1E-10', orb2a%vec(6)
write (1, '(a, es22.12)') '"t"      REL  1E-10', orb2a%t
write (1, '(a, es22.12)') '"s"      REL  1E-10', orb2a%s

write (1, *)

write (1, '(a, es22.12)') '"Db:vec(1)" ABS  1e-14', orb2b%vec(1) - orb2a%vec(1)
write (1, '(a, es22.12)') '"Db:vec(2)" ABS  1e-14', orb2b%vec(2) - orb2a%vec(2)
write (1, '(a, es22.12)') '"Db:vec(3)" ABS  1e-14', orb2b%vec(3) - orb2a%vec(3)
write (1, '(a, es22.12)') '"Db:vec(4)" ABS  1e-14', orb2b%vec(4) - orb2a%vec(4)
write (1, '(a, es22.12)') '"Db:vec(5)" ABS  1e-14', orb2b%vec(5) - orb2a%vec(5)
write (1, '(a, es22.12)') '"Db:vec(6)" ABS  1e-14', orb2b%vec(6) - orb2a%vec(6)
write (1, '(a, es22.12)') '"Db:t"      ABS  1e-14', orb2b%t - orb2a%t
write (1, '(a, es22.12)') '"Db:s"      ABS  1e-14', orb2b%s - orb2a%s

write (1, *)

write (1, '(a, es22.12)') '"Dc:vec(1)" ABS  1e-14', orb2c%vec(1) - orb2a%vec(1)
write (1, '(a, es22.12)') '"Dc:vec(2)" ABS  1e-14', orb2c%vec(2) - orb2a%vec(2)
write (1, '(a, es22.12)') '"Dc:vec(3)" ABS  1e-14', orb2c%vec(3) - orb2a%vec(3)
write (1, '(a, es22.12)') '"Dc:vec(4)" ABS  1e-14', orb2c%vec(4) - orb2a%vec(4)
write (1, '(a, es22.12)') '"Dc:vec(5)" ABS  1e-14', orb2c%vec(5) - orb2a%vec(5)
write (1, '(a, es22.12)') '"Dc:vec(6)" ABS  1e-14', orb2c%vec(6) - orb2a%vec(6)
write (1, '(a, es22.12)') '"Dc:t"      ABS  1e-14', orb2c%t - orb2a%t
write (1, '(a, es22.12)') '"Dc:s"      ABS  1e-14', orb2c%s - orb2a%s

write (1, *)

write (1, '(a, es22.12)') '"Dd:vec(1)" ABS  1e-14', orb2d%vec(1) - orb2a%vec(1)
write (1, '(a, es22.12)') '"Dd:vec(2)" ABS  1e-14', orb2d%vec(2) - orb2a%vec(2)
write (1, '(a, es22.12)') '"Dd:vec(3)" ABS  1e-14', orb2d%vec(3) - orb2a%vec(3)
write (1, '(a, es22.12)') '"Dd:vec(4)" ABS  1e-14', orb2d%vec(4) - orb2a%vec(4)
write (1, '(a, es22.12)') '"Dd:vec(5)" ABS  1e-14', orb2d%vec(5) - orb2a%vec(5)
write (1, '(a, es22.12)') '"Dd:vec(6)" ABS  1e-14', orb2d%vec(6) - orb2a%vec(6)

write (1, *)

write (1, '(a, es22.12)') '"a%beta " REL  1E-10', ele2a%a%beta
write (1, '(a, es22.12)') '"b%beta " REL  1E-10', ele2b%b%beta
write (1, '(a, es22.12)') '"a%alpha" REL  1E-10', ele2a%a%alpha
write (1, '(a, es22.12)') '"b%alpha" REL  1E-10', ele2b%b%alpha
write (1, '(a, es22.12)') '"a%eta  " REL  1E-10', ele2a%a%eta
write (1, '(a, es22.12)') '"b%eta  " REL  1E-10', ele2b%b%eta

write (1, *)

write (1, '(a, es22.12)') '"D:a%beta"  ABS  1e-14', ele2b%a%beta - ele2a%a%beta
write (1, '(a, es22.12)') '"D:b%beta"  ABS  1e-14', ele2b%b%beta - ele2b%b%beta
write (1, '(a, es22.12)') '"D:a%alpha" ABS  1e-14', ele2b%a%alpha - ele2b%a%alpha
write (1, '(a, es22.12)') '"D:b%alpha" ABS  1e-14', ele2b%b%alpha - ele2b%b%alpha
write (1, '(a, es22.12)') '"D:a%eta"   ABS  1e-14', ele2b%a%eta - ele2b%a%eta
write (1, '(a, es22.12)') '"D:b%eta"   ABS  1e-14', ele2b%b%eta - ele2b%b%eta

write (1, *)

write (1, '(a, 6f17.12)') '"xmat_c(1,:)" ABS  1e-10', xmat_c(1,:)
write (1, '(a, 6f17.12)') '"xmat_c(2,:)" ABS  1e-10', xmat_c(2,:)
write (1, '(a, 6f17.12)') '"xmat_c(3,:)" ABS  1e-10', xmat_c(3,:)
write (1, '(a, 6f17.12)') '"xmat_c(4,:)" ABS  1e-10', xmat_c(4,:)
write (1, '(a, 6f17.12)') '"xmat_c(5,:)" ABS  1e-10', xmat_c(5,:)
write (1, '(a, 6f17.12)') '"xmat_c(6,:)" ABS  1e-10', xmat_c(6,:)
write (1, '(a, 6f17.12)') '"vec0_c(:)"   ABS  1e-10', vec0_c

write (1, *)

write (1, '(a, 6f17.12)') '"Db:xmat_c(1,:)" ABS  1e-10', xmat_c(1,:) - ele2b%mat6(1,:)
write (1, '(a, 6f17.12)') '"Db:xmat_c(2,:)" ABS  1e-10', xmat_c(2,:) - ele2b%mat6(2,:)
write (1, '(a, 6f17.12)') '"Db:xmat_c(3,:)" ABS  1e-10', xmat_c(3,:) - ele2b%mat6(3,:)
write (1, '(a, 6f17.12)') '"Db:xmat_c(4,:)" ABS  1e-10', xmat_c(4,:) - ele2b%mat6(4,:)
write (1, '(a, 6f17.12)') '"Db:xmat_c(5,:)" ABS  1e-10', xmat_c(5,:) - ele2b%mat6(5,:)
write (1, '(a, 6f17.12)') '"Db:xmat_c(6,:)" ABS  1e-10', xmat_c(6,:) - ele2b%mat6(6,:)
write (1, '(a, 6f17.12)') '"Db:vec0_c(:)"   ABS  1e-10', vec0_c - ele2b%vec0

write (1, *)

write (1, '(a, 6f17.12)') '"Dd:xmat_c(1,:)" ABS  1e-10', xmat_c(1,:) - xmat_d(1,:)
write (1, '(a, 6f17.12)') '"Dd:xmat_c(2,:)" ABS  1e-10', xmat_c(2,:) - xmat_d(2,:)
write (1, '(a, 6f17.12)') '"Dd:xmat_c(3,:)" ABS  1e-10', xmat_c(3,:) - xmat_d(3,:)
write (1, '(a, 6f17.12)') '"Dd:xmat_c(4,:)" ABS  1e-10', xmat_c(4,:) - xmat_d(4,:)
write (1, '(a, 6f17.12)') '"Dd:xmat_c(5,:)" ABS  1e-10', xmat_c(5,:) - xmat_d(5,:)
write (1, '(a, 6f17.12)') '"Dd:xmat_c(6,:)" ABS  1e-10', xmat_c(6,:) - xmat_d(6,:)
write (1, '(a, 6f17.12)') '"Dd:vec0_c(:)"   ABS  1e-10', vec0_c - vec0_d

close (1)


end program 
