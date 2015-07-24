module re_allocate_mod

use utilities_mod
use sim_utils_struct

!+
! Subroutine re_allocate
!
! Subroutine to reallocate a 1-dim allocatable array.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the original size of the array
! 
! Note: For pointers to an array use the re_associate routine.
! Note: Also see the re_allocate2 routine.
! 
! Note: using exact = False can increase computation speed by
! preventing unneccessary deallocations/reallocations.
!
! This routine is an overloaded name for: 
!   Subroutine re_allocate_string (str, n, exact, init_val)
!   Subroutine re_allocate_integer (inte, n, exact, init_val)
!   Subroutine re_allocate_real (re, n, exact, init_val)
!   Subroutine re_allocate_real_pointer (re_ptr, n, exact)
!   Subroutine re_allocate_complex (cmpl, n, exact, init_val)
!   Subroutine re_allocate_logical (logic, n, exact, init_val)
!
! Modules needed:
!   use re_allocate_mod
!
! Input:
!   str(:)      -- Character(*), allocatable: String array.
!   inte(:)     -- Integer, allocatable: Integer array.
!   re(:)       -- Real(rp), Allocatable: Real array.
!   re_ptr(:)   -- Real_pointer_struct: Real pointer array.
!   cmpl(:)     -- Complex(rp), Allocatable: Complex array.
!   logic(:)    -- Logical, allocatable: Logical array.
!   n           -- Integer: Minimum size needed for 1-dimensional arrays.
!   exact       -- Logical, optional: If present and False then the size of 
!                    the output array is permitted to be larger than n. 
!                    Default is True.
!   init_val    -- optional: If present, init created array space to this value.
!                    If init_val is not present, no init will be done.
!
! Output:
!   str(:)      -- Character(*), allocatable: Allocated array. 
!   inte(:)     -- Integer, allocatable: Allocated array. 
!   re(:)       -- Real(rp), Allocatable: Allocated array. 
!   re_ptr(:)   -- Real_pointer_struct: Real pointer array.
!   cmpl(:)     -- Complex(rp), Allocatable: Allocated Array.
!   logic(:)    -- Logical, allocatable: Allocated array.
!-

interface re_allocate
  module procedure re_allocate_string
  module procedure re_allocate_integer
  module procedure re_allocate_logical
  module procedure re_allocate_real
  module procedure re_allocate_real_pointer
  module procedure re_allocate_complex
end interface

!+
! Subroutine re_allocate2
!
! Subroutine to reallocate a 1-dim allocatable array.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the original size of the array
! 
! Note: For pointers to an array use the re_associate routine.
! Note: Alos see the re_allocate routine.
!
! Note: using exact = False can increase computation speed by
! preventing unneccessary deallocations/reallocations.
!
! This routine is an overloaded name for: 
!   Subroutine re_allocate2_string (str, n_min, n_max, exact, init_val)
!   Subroutine re_allocate2_integer (inte, n_min, n_max, exact, init_val)
!   Subroutine re_allocate2_real (re, n_min, n_max, exact, init_val)
!   Subroutine re_allocate2_real_pointer (re, n_min, n_max, exact)
!   Subroutine re_allocate2_complex (cmpl, n_min, n_max, exact, init_val)
!   Subroutine re_allocate2_logical (logic, n_min, n_max, exact, init_val)
!
! Modules needed:
!   use re_allocate_mod
!
! Input:
!   str(:)      -- Character(*), allocatable: String array.
!   inte(:)     -- Integer, allocatable: Integer array.
!   re(:)       -- Real(rp), Allocatable: Real array.
!   re_ptr(:)   -- Real_pointer_struct: Real pointer array.
!   cmpl(:)     -- Complex(rp), Allocatable: Complex array.
!   logic(:)    -- Logical, allocatable: Logical array.
!   n_min       -- Integer: Desired lower bound.
!   n_max       -- Integer: Desired upper bound.
!   exact       -- Logical, optional: If present and False then the size of 
!                    the output array is permitted to be larger than n. 
!                    Default is True.
!   init_val    -- optional: If present, init created array space to this value.
!                    If init_val is not present, no init will be done.
!
! Output:
!   str(:)      -- Character(*), allocatable: Allocated array. 
!   inte(:)     -- Integer, allocatable: Allocated array. 
!   re(:)       -- Real(rp), Allocatable: Allocated array. 
!   re_ptr(:)   -- Real_pointer_struct: Real pointer array.
!   cmpl(:)     -- Complex(rp), Allocatable: Allocated Array.
!   logic(:)    -- Logical, allocatable: Allocated array.
!-

interface re_allocate2
  module procedure re_allocate2_string
  module procedure re_allocate2_integer
  module procedure re_allocate2_logical
  module procedure re_allocate2_real
  module procedure re_allocate2_real_pointer
  module procedure re_allocate2_complex
end interface

!+
! Subroutine re_allocate2d
!
! Subroutine to reallocate a 2-dim allocatable array.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the original size of the array
! 
! Note: For pointers to an array use the re_associate routine.
! 
! Note: using exact = False can increase computation speed by
! preventing unneccessary deallocations/reallocations.
!
! This routine is an overloaded name for: 
!   Subroutine re_allocate_string2d (str2, n1, n2, exact, init_val)
!   Subroutine re_allocate_integer2d (inte2, n1, n2, exact, init_val)
!   Subroutine re_allocate_real2d (re2, n1, n2, exact, init_val)
!   Subroutine re_allocate_logical2d (logic2, n1, n2, exact, init_val)
!
! Modules needed:
!   use re_allocate_mod
!
! Input:
!   str2(:,:)   -- Character(*), allocatable: String array.
!   inte2(:,:)  -- Integer, allocatable: Integer array.
!   re2(:,:)    -- Real(rp), Allocatable: Real array.
!   logic2(:,:) -- Logical, allocatable: Logical array.
!   n1, n2      -- Integer: Minimum size needed for 2-dimensional arrays.
!   exact       -- Logical, optional: If present and False then the size of 
!                    the output array is permitted to be larger than n. 
!                    Default is True.
!   init_val    -- optional: If present, init created array space to this value.
!                    If init_val is not present, no init will be done.
!
! Output:
!   str2(:,:)   -- Character(*), allocatable: Allocated array ,
!   inte2(:,:)  -- Integer, allocatable: Allocated array.
!   re2(:,:)    -- Real(rp), Allocatable: Allocated array.
!   logic2(:,:) -- Logical, allocatable: Allocated array. 
!-

interface re_allocate2d
  module procedure re_allocate_string2d
  module procedure re_allocate_integer2d
  module procedure re_allocate_logical2d
  module procedure re_allocate_real2d
end interface

!-----------------------------------------
!+
! Subroutine re_associate
!
! Subroutine to reassociate a 1-dim allocatable array.
! This is modeled after the reassociate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the original size of the array
!
! Note: For allocatable arrays use the re_allocate routine.
! 
! Note: using exact = False can increase computation speed by
! preventing unneccessary deallocations/reallocations.
!
! This routine is an overloaded name for: 
!   Subroutine re_associate_string (str, n, exact, init_val)
!   Subroutine re_associate_integer (inte, n, exact, init_val)
!   Subroutine re_associate_real (re, n, exact, init_val)
!   Subroutine re_associate_logical (logic, n, exact, init_val)
!
! Modules needed:
!   use re_allocate_mod
!
! Input:
!   str(:)   -- Character(*), pointer: String array.
!   inte(:)  -- Integer, pointer: Integer array.
!   re(:)    -- Real(rp), Pointer: Real array.
!   logic(:) -- Logical, pointer: Logical array.
!   n        -- Integer: Minimum size needed.
!   exact    -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than n. 
!                 Default is True.
!   init_val    -- optional: If present, init created array space to this value.
!                    If init_val is not present, no init will be done.
!
! Output:
!   str(:)   -- Character(*), pointer: Associated array with size(str) >= n.
!   inte(:)  -- Integer, pointer: Associated array with size(inte) >= n.
!   re(:)    -- Real(rp), Pointer: Associated array with size(re) >= n.
!   logic(:) -- Logical, pointer: Associated array with size(logic) >= n.
!-

interface re_associate
  module procedure re_associate_string
  module procedure re_associate_integer
  module procedure re_associate_logical
  module procedure re_associate_real
end interface

contains

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate_string (str, n, exact, init_val)
!
! Routine to reallocate an array of strings.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the original size of the array
!
! Input:
!   str(:) -- Character(*), allocatable: String array.
!   n      -- Integer: Size wanted.
!   exact  -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than n. 
!                 Default is True.
!
! Output:
!   str(:) -- Character(*), allocatable: Allocated array with size(str) >= n.
!-

subroutine re_allocate_string (str, n, exact, init_val)

  implicit none

  integer n, n_old, n_save
  character(*), allocatable :: str(:)
  character(len(str)), allocatable :: temp_str(:)
  character(*), optional :: init_val

  logical, optional :: exact

!

  if (allocated(str)) then
    n_old = size(str)
    if (n == n_old) return
    if (.not. logic_option(.true., exact) .and. n < n_old) return
    call move_alloc (str, temp_str)
    allocate (str(n))
    if (present(init_val)) str = init_val
    n_save = min(n, n_old)
    str(1:n_save) = temp_str(1:n_save)
    deallocate (temp_str)  
  else
    allocate (str(n))
    if (present(init_val)) str = init_val
  endif

end subroutine re_allocate_string

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate_integer (inte, n, exact, init_val)
!
! Routine to reallocate an array of integers.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the original size of the array
!
! Input:
!   inte(:) -- Integer, allocatable: Integer array.
!   n      -- Integer: Size wanted.
!   exact  -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than n. 
!                 Default is True.
!
! Output:
!   inte(:) -- Integer, allocatable: Allocated array with size(inte) >= n.
!-

subroutine re_allocate_integer (inte, n, exact, init_val)

  implicit none

  integer, allocatable :: inte(:), temp_inte(:)

  integer, intent(in) :: n
  integer n_save, n_old
  integer, optional :: init_val

  logical, optional :: exact

!

  if (allocated(inte)) then
    n_old = size(inte)
    if (n == n_old) return
    if (.not. logic_option(.true., exact) .and. n < n_old) return
    call move_alloc (inte, temp_inte)
    allocate (inte(n))
    if (present(init_val)) inte = init_val
    n_save = min(n, n_old)
    inte(1:n_save) = temp_inte(1:n_save)
    deallocate (temp_inte)  
  else
    allocate (inte(n))
    if (present(init_val)) inte = init_val
  endif

end subroutine re_allocate_integer

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate_complex (cmpl, n, exact, init_val)
!
! Routine to reallocate an array of complex numbers.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the original size of the array
!
! Input:
!   cmpl(:)  -- Complex(rp), Allocatable: Complex array.
!   n      -- Integer: Size wanted.
!   exact  -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than n. 
!                 Default is True.
!
! Output:
!   cmpl(:)  -- Complex(rp), Allocatable: Allocated array with size(cmpl) >= n.
!-

subroutine re_allocate_complex (cmpl, n, exact, init_val)

  implicit none

  complex(rp), allocatable :: cmpl(:), temp_cmpl(:)
  complex(rp), optional :: init_val

  integer, intent(in) :: n
  integer n_save, n_old

  logical, optional :: exact

!

  if (allocated(cmpl)) then
    n_old = size(cmpl)
    if (n == n_old) return
    if (.not. logic_option(.true., exact) .and. n < n_old) return
    call move_alloc (cmpl, temp_cmpl)
    allocate (cmpl(n))
    if (present(init_val)) cmpl = init_val
    n_save = min(n, n_old)
    cmpl(1:n_save) = temp_cmpl(1:n_save)
    deallocate (temp_cmpl)  
  else
    allocate (cmpl(n))
    if (present(init_val)) cmpl = init_val
  endif

end subroutine re_allocate_complex

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate_real (re, n, exact, init_val)
!
! Routine to reallocate an array of reals.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the original size of the array
!
! Input:
!   re(:)  -- Real(rp), Allocatable: Real array.
!   n      -- Integer: Size wanted.
!   exact  -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than n. 
!                 Default is True.
!
! Output:
!   re(:)  -- Real(rp), Allocatable: Allocated array with size(re) >= n.
!-

subroutine re_allocate_real (re, n, exact, init_val)

  implicit none

  real(rp), allocatable :: re(:), temp_re(:)
  real(rp), optional :: init_val

  integer, intent(in) :: n
  integer n_save, n_old

  logical, optional :: exact

!

  if (allocated(re)) then
    n_old = size(re)
    if (n == n_old) return
    if (.not. logic_option(.true., exact) .and. n < n_old) return
    call move_alloc (re, temp_re)
    allocate (re(n))
    if (present(init_val)) re = init_val
    n_save = min(n, n_old)
    re(1:n_save) = temp_re(1:n_save)
    deallocate (temp_re)  
  else
    allocate (re(n))
    if (present(init_val)) re = init_val
  endif

end subroutine re_allocate_real

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate_real_pointer (re_ptr, n, exact)
!
! Routine to reallocate an array of real pointers.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The pointers of the array are preserved but data at the end of the
! array will be lost if n is less than the original size of the array
!
! Input:
!   re_ptr(:) -- Real_pointer_struct, Allocatable: Real_pointer array.
!   n         -- Integer: Size wanted.
!   exact     -- Logical, optional: If present and False then the size of 
!                  the output array is permitted to be larger than n. 
!                  Default is True.
!
! Output:
!   re(:)  -- Real_pointer_struct, Allocatable: Allocated array with size(re) >= n.
!-

subroutine re_allocate_real_pointer (re_ptr, n, exact)

  implicit none

  type(real_pointer_struct), allocatable :: re_ptr(:), temp_re(:)

  integer, intent(in) :: n
  integer n_save, n_old, i

  logical, optional :: exact

!

  if (allocated(re_ptr)) then
    n_old = size(re_ptr)
    if (n == n_old) return
    if (.not. logic_option(.true., exact) .and. n < n_old) return
    call move_alloc(re_ptr, temp_re)
    allocate (re_ptr(n))
    n_save = min(n, n_old)
    forall (i = 1:n_save) re_ptr(i)%r => temp_re(i)%r
    deallocate (temp_re)
    do i = n_save+1, n
      re_ptr(i)%r => null()
    enddo
  else
    allocate (re_ptr(n))
    forall (i = 1:n) re_ptr(i)%r => null()
  endif

end subroutine re_allocate_real_pointer

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate_logical (logic, n, exact, init_val)
!
! Routine to reallocate a string array.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the size of the array
!
! Input:
!   logic(:) -- Logical, allocatable: Logical array.
!   n      -- Logical: Size wanted.
!   exact  -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than n. 
!                 Default is True.
!
! Output:
!   logic(:) -- Logical, allocatable: Allocated array with size(logic) >= n.
!-

subroutine re_allocate_logical (logic, n, exact, init_val)

  implicit none

  logical, allocatable :: logic(:), temp_logic(:)

  integer, intent(in) :: n
  integer n_save, n_old

  logical, optional :: exact
  logical, optional :: init_val

!

  if (allocated(logic)) then
    n_old = size(logic)
    if (n == n_old) return
    if (.not. logic_option(.true., exact) .and. n < n_old) return
    call move_alloc(logic, temp_logic)
    allocate (logic(n))
    if (present(init_val)) logic = init_val
    n_save = min(n, n_old)
    logic(1:n_save) = temp_logic(1:n_save)
    deallocate (temp_logic)  
  else
    allocate (logic(n))
    if (present(init_val)) logic = init_val
  endif

end subroutine re_allocate_logical

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate2_string (str, n1, n2, exact, init_val)
!
! Routine to reallocate an array of strings.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if [n1, n2] is less than the original size of the array
!
! Input:
!   str(:) -- Character(*), allocatable: String array.
!   n1     -- Integer: Desired lower bound.
!   n2     -- Integer: Desired upper bound.
!   exact  -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than [n1, n2]. 
!                 Default is True.
!
! Output:
!   str(:) -- Character(*), allocatable: Allocated array with 
!               bounds spanning at least [n1, n2]
!-

subroutine re_allocate2_string (str, n1, n2, exact, init_val)

  implicit none

  integer n1, n2, n1_old, n2_old, n1_save, n2_save
  character(*), allocatable :: str(:)
  character(len(str)), allocatable :: temp_str(:)
  character(*), optional :: init_val

  logical, optional :: exact

!

  if (allocated(str)) then
    n1_old = lbound(str, 1); n2_old = ubound(str, 1)
    if (n1 == n1_old .and. n2 == n2_old) return
    if (.not. logic_option(.true., exact) .and. n1_old <= n1 .and. n2 <= n2_old) return
    call move_alloc(str, temp_str)
    allocate (str(n1:n2))
    if (present(init_val)) str = init_val
    n1_save = max(n1, n1_old); n2_save = min(n2, n2_old)
    str(n1_save:n2_save) = temp_str(n1_save:n2_save)
    deallocate (temp_str)  
  else
    allocate (str(n1:n2))
    if (present(init_val)) str = init_val
  endif

end subroutine re_allocate2_string

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate2_integer (inte, n1, n2, exact, init_val)
!
! Routine to reallocate an array of integers.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if [n1, n2] is less than the original size of the array
!
! Input:
!   inte(:) -- Integer, allocatable: Integer array.
!   n1     -- Integer: Desired lower bound.
!   n2     -- Integer: Desired upper bound.
!   exact   -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than [n1, n2]. 
!                 Default is True.
!
! Output:
!   inte(:) -- Integer, allocatable: Allocated array with 
!                bounds spanning at least [n1, n2]
!-

subroutine re_allocate2_integer (inte, n1, n2, exact, init_val)

  implicit none

  integer, allocatable :: inte(:), temp_inte(:)

  integer, intent(in) :: n1, n2
  integer n1_save, n2_save, n1_old, n2_old
  integer, optional :: init_val

  logical, optional :: exact

!

  if (allocated(inte)) then
    n1_old = lbound(inte, 1); n2_old = ubound(inte, 1)
    if (n1 == n1_old .and. n2 == n2_old) return
    if (.not. logic_option(.true., exact) .and. n1_old <= n1 .and. n2 <= n2_old) return
    call move_alloc(inte, temp_inte)
    allocate (inte(n1:n2))
    if (present(init_val)) inte = init_val
    n1_save = max(n1, n1_old); n2_save = min(n2, n2_old)
    inte(n1_save:n2_save) = temp_inte(n1_save:n2_save)
    deallocate (temp_inte)  
  else
    allocate (inte(n1:n2))
    if (present(init_val)) inte = init_val
  endif

end subroutine re_allocate2_integer

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate2_complex (cmpl, n1, n2, exact, init_val)
!
! Routine to reallocate an array of complex numbers.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if [n1, n2] is less than the original size of the array
!
! Input:
!   cmpl(:)  -- Complex(rp), Allocatable: Complex array.
!   n1     -- Integer: Desired lower bound.
!   n2     -- Integer: Desired upper bound.
!   exact  -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than [n1, n2]. 
!                 Default is True.
!
! Output:
!   cmpl(:)  -- Complex(rp), Allocatable: Allocated array with 
!                bounds spanning at least [n1, n2]
!-

subroutine re_allocate2_complex (cmpl, n1, n2, exact, init_val)

  implicit none

  complex(rp), allocatable :: cmpl(:), temp_cmpl(:)
  complex(rp), optional :: init_val

  integer, intent(in) :: n1, n2
  integer n1_save, n2_save, n1_old, n2_old

  logical, optional :: exact

!

  if (allocated(cmpl)) then
    n1_old = lbound(cmpl, 1); n2_old = ubound(cmpl, 1)
    if (n1 == n1_old .and. n2 == n2_old) return
    if (.not. logic_option(.true., exact) .and. n1_old <= n1 .and. n2 <= n2_old) return
    call move_alloc(cmpl, temp_cmpl)
    allocate (cmpl(n1:n2))
    if (present(init_val)) cmpl = init_val
    n1_save = max(n1, n1_old); n2_save = min(n2, n2_old)
    cmpl(n1_save:n2_save) = temp_cmpl(n1_save:n2_save)
    deallocate (temp_cmpl)  
  else
    allocate (cmpl(n1:n2))
    if (present(init_val)) cmpl = init_val
  endif

end subroutine re_allocate2_complex

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate2_real (re, n1, n2, exact, init_val)
!
! Routine to reallocate an array of reals.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if [n1, n2] is less than the original size of the array
!
! Input:
!   re(:)  -- Real(rp), Allocatable: Real array.
!   n1     -- Integer: Desired lower bound.
!   n2     -- Integer: Desired upper bound.
!   exact  -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than [n1, n2]. 
!                 Default is True.
!
! Output:
!   re(:)  -- Real(rp), Allocatable: Allocated array with 
!                bounds spanning at least [n1, n2]
!-

subroutine re_allocate2_real (re, n1, n2, exact, init_val)

  implicit none

  real(rp), allocatable :: re(:), temp_re(:)
  real(rp), optional :: init_val

  integer, intent(in) :: n1, n2
  integer n1_save, n2_save, n1_old, n2_old

  logical, optional :: exact

!

  if (allocated(re)) then
    n1_old = lbound(re, 1); n2_old = ubound(re, 1)
    if (n1 == n1_old .and. n2 == n2_old) return
    if (.not. logic_option(.true., exact) .and. n1_old <= n1 .and. n2 <= n2_old) return
    call move_alloc(re, temp_re)
    allocate (re(n1:n2))
    if (present(init_val)) re = init_val
    n1_save = max(n1, n1_old); n2_save = min(n2, n2_old)
    re(n1_save:n2_save) = temp_re(n1_save:n2_save)
    deallocate (temp_re)  
  else
    allocate (re(n1:n2))
    if (present(init_val)) re = init_val
  endif

end subroutine re_allocate2_real

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate2_real_pointer (re_ptr, n1, n2, exact)
!
! Routine to reallocate an array of reals.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if [n1, n2] is less than the original size of the array
!
! Input:
!   re_ptr(:) -- Real_pointer_struct, allocatable: Real array.
!   n1     -- Integer: Desired lower bound.
!   n2     -- Integer: Desired upper bound.
!   exact  -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than [n1, n2]. 
!                 Default is True.
!
! Output:
!   re_ptr(:)  -- Real_pointer_struct, allocatable: Allocated array with 
!                  bounds spanning at least [n1, n2]
!-

subroutine re_allocate2_real_pointer (re_ptr, n1, n2, exact)

  implicit none

  type(real_pointer_struct), allocatable :: re_ptr(:), temp_re_ptr(:)

  integer, intent(in) :: n1, n2
  integer n1_save, n2_save, n1_old, n2_old, i

  logical, optional :: exact

!

  if (allocated(re_ptr)) then
    n1_old = lbound(re_ptr, 1); n2_old = ubound(re_ptr, 1)
    if (n1 == n1_old .and. n2 == n2_old) return
    if (.not. logic_option(.true., exact) .and. n1_old <= n1 .and. n2 <= n2_old) return
    call move_alloc(re_ptr, temp_re_ptr)
    allocate (re_ptr(n1:n2))
    n1_save = max(n1, n1_old); n2_save = min(n2, n2_old)
    re_ptr(n1_save:n2_save) = temp_re_ptr(n1_save:n2_save)
    deallocate (temp_re_ptr)  
    do i = n1, n2
      if (i >= n1_old .and. i <= n2_old) cycle
      re_ptr(i)%r => null()
    enddo

  else
    allocate (re_ptr(n1:n2))
    forall (i = n1:n2) re_ptr(i)%r => null()
  endif

end subroutine re_allocate2_real_pointer

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate2_logical (logic, n1, n2, exact, init_val)
!
! Routine to reallocate a logical array.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if [n1, n2] is less than the size of the array
!
! Input:
!   logic(:) -- Logical, allocatable: Logical array.
!   n1     -- Integer: Desired lower bound.
!   n2     -- Integer: Desired upper bound.
!   exact    -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than [n1, n2]. 
!                 Default is True.
!
! Output:
!   logic(:) -- Logical, allocatable: Allocated array with 
!                 bounds spanning at least [n1, n2]
!-

subroutine re_allocate2_logical (logic, n1, n2, exact, init_val)

  implicit none

  logical, allocatable :: logic(:), temp_logic(:)
  logical, optional :: init_val

  integer, intent(in) :: n1, n2
  integer n1_save, n2_save, n1_old, n2_old

  logical, optional :: exact

!

  if (allocated(logic)) then
    n1_old = lbound(logic, 1); n2_old = ubound(logic, 1)
    if (n1 == n1_old .and. n2 == n2_old) return
    if (.not. logic_option(.true., exact) .and. n1_old <= n1 .and. n2 <= n2_old) return
    call move_alloc(logic, temp_logic)
    allocate (logic(n1:n2))
    if (present(init_val)) logic = init_val
    n1_save = max(n1, n1_old); n2_save = min(n2, n2_old)
    logic(n1_save:n2_save) = temp_logic(n1_save:n2_save)
    deallocate (temp_logic)  
  else
    allocate (logic(n1:n2))
    if (present(init_val)) logic = init_val
  endif

end subroutine  re_allocate2_logical

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate_string2d (str2, n1, n2, exact, init_val)
!
! Routine to reallocate an array of strings.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if [n1, n2] is less than the original size of the array
!
! Input:
!   str2(:,:) -- Character(*), allocatable: String array.
!   n1, n2    -- Integer: Size wanted.
!   exact     -- Logical, optional: If present and False then the size of 
!                  the output array is permitted to be larger than [n1, n2]. 
!                  Default is True.
!
! Output:
!   str2(:,:) -- Character(*), allocatable: Allocated array with 
!                  bounds spanning at least [n1, n2]
!-

subroutine re_allocate_string2d (str2, n1, n2, exact, init_val)

  implicit none

  integer n1, n2, n1_old, n2_old, n1_save, n2_save
  character(*), allocatable :: str2(:,:)
  character(len(str2)), allocatable :: temp_str2(:,:)
  character(*), optional :: init_val

  logical, optional :: exact

!

  if (allocated(str2)) then
    n1_old = ubound(str2, 1); n2_old = ubound(str2, 2)
    if (n1 == n1_old .and. n2 == n2_old) return
    if (.not. logic_option(.true., exact) .and. n1_old <= n1 .and. n2_old <= n2) return
    call move_alloc(str2, temp_str2)
    allocate (str2(n1,n2))
    if (present(init_val)) str2 = init_val
    n1_save = min(n1, n1_old); n2_save = min(n2, n2_old)
    str2(1:n1_save,1:n2_save) = temp_str2(1:n1_save,1:n2_save)
    deallocate (temp_str2)  
  else
    allocate (str2(n1,n2))
    if (present(init_val)) str2 = init_val
  endif

end subroutine re_allocate_string2d

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate_integer2d (inte2, n1, n2, exact, init_val)
!
! Routine to reallocate an array of integers.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if [n1, n2] is less than the original size of the array
!
! Input:
!   inte2(:,:) -- Integer, allocatable: Integer array.
!   n1, n2     -- Integer: Size wanted.
!   exact      -- Logical, optional: If present and False then the size of 
!                   the output array is permitted to be larger than [n1, n2]. 
!                   Default is True.
!
! Output:
!   inte2(:,:) -- Integer, allocatable: Allocated array with 
!                   bounds spanning at least [n1, n2]
!-

subroutine re_allocate_integer2d (inte2, n1, n2, exact, init_val)

  implicit none

  integer, allocatable :: inte2(:,:), temp_inte2(:,:)
  integer, optional :: init_val

  integer, intent(in) :: n1, n2
  integer n1_save, n2_save, n1_old, n2_old

  logical, optional :: exact

!

  if (allocated(inte2)) then
    n1_old = ubound(inte2, 1); n2_old = ubound(inte2, 2)
    if (n1 == n1_old .and. n2 == n2_old) return
    if (.not. logic_option(.true., exact) .and. n1_old <= n1 .and. n2_old <= n2) return
    call move_alloc(inte2, temp_inte2)
    allocate (inte2(n1,n2))
    if (present(init_val)) inte2 = init_val
    n1_save = min(n1, n1_old); n2_save = min(n2, n2_old)
    inte2(1:n1_save,1:n2_save) = temp_inte2(1:n1_save,1:n2_save)
    deallocate (temp_inte2)  
  else
    allocate (inte2(n1,n2))
    if (present(init_val)) inte2 = init_val
  endif

end subroutine re_allocate_integer2d

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate_real2d (re2, n1, n2, exact, init_val)
!
! Routine to reallocate an array of reals.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if [n1, n2] is less than the original size of the array
!
! Input:
!   re2(:,:) -- Real(rp), Allocatable: Real array.
!   n1, n2   -- Integer: Size wanted.
!   exact    -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than [n1, n2]. 
!                 Default is True.
!
! Output:
!   re2(:,:) -- Real(rp), Allocatable: Allocated array with 
!                 bounds spanning at least [n1, n2]
!-

subroutine re_allocate_real2d (re2, n1, n2, exact, init_val)

  implicit none

  real(rp), allocatable :: re2(:,:), temp_re2(:,:)
  real(rp), optional :: init_val

  integer, intent(in) :: n1, n2
  integer n1_save, n2_save, n1_old, n2_old

  logical, optional :: exact

!

  if (allocated(re2)) then
    n1_old = ubound(re2, 1); n2_old = ubound(re2, 2)
    if (n1 == n1_old .and. n2 == n2_old) return
    if (.not. logic_option(.true., exact) .and. n1_old <= n1 .and. n2_old <= n2) return
    n1_save = min(n1, n1_old); n2_save = min(n2, n2_old)
    allocate (temp_re2(n1_save,n2_save))
    temp_re2 = re2(1:n1_save,1:n2_save)
    deallocate (re2)
    allocate (re2(n1,n2))
    if (present(init_val)) re2 = init_val
    re2(1:n1_save,1:n2_save) = temp_re2
    deallocate (temp_re2)  
  else
    allocate (re2(n1,n2))
    if (present(init_val)) re2 = init_val
  endif

end subroutine re_allocate_real2d

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_allocate_logical2d (logic2, n1, n2, exact, init_val)
!
! Routine to reallocate a logical array.
! This is modeled after the reallocate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if [n1, n2] is less than the size of the array
!
! Input:
!   logic2(:,:) -- Logical, allocatable: Logical array.
!   n1, n2      -- Integer: Size wanted.
!   exact       -- Logical, optional: If present and False then the size of 
!                    the output array is permitted to be larger than [n1, n2]. 
!                    Default is True.
!
! Output:
!   logic2(:,:) -- Logical, allocatable: Allocated array with 
!                    bounds spanning at least [n1, n2]
!-

subroutine re_allocate_logical2d (logic2, n1, n2, exact, init_val)

  implicit none

  logical, allocatable :: logic2(:,:), temp_logic2(:,:)
  logical, optional :: init_val

  integer, intent(in) :: n1, n2
  integer n1_save, n2_save, n1_old, n2_old

  logical, optional :: exact

!

  if (allocated(logic2)) then
    n1_old = ubound(logic2, 1); n2_old = ubound(logic2, 2)
    if (n1 == n1_old .and. n2 == n2_old) return
    if (.not. logic_option(.true., exact) .and. n1_old <= n1 .and. n2_old <= n2) return
    call move_alloc(logic2, temp_logic2)
    allocate (logic2(n1,n2))
    if (present(init_val)) logic2 = init_val
    n1_save = min(n1, n1_old); n2_save = min(n2, n2_old)
    logic2(1:n1_save,1:n2_save) = temp_logic2(1:n1_save,1:n2_save)
    deallocate (temp_logic2)  
  else
    allocate (logic2(n1,n2))
    if (present(init_val)) logic2 = init_val
  endif

end subroutine re_allocate_logical2d

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_associate_string (str, n, exact, init_val)
!
! Routine to reassociate an array of strings.
! This is modeled after the reassociate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the original size of the array
!
! Input:
!   str(:) -- Character(*), pointer: String array.
!   n      -- Integer: Size wanted.
!   exact  -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than n. 
!                 Default is True.
!
! Output:
!   str(:) -- Character(*), pointer: Allocated array with size(str) >= n.
!-

subroutine re_associate_string (str, n, exact, init_val)

  implicit none

  character(*), pointer :: str(:)
  character(len(str)), pointer :: temp_str(:)
  character(*), optional :: init_val

  integer n, n_old, n_save

  logical, optional :: exact

!

  if (associated(str)) then
    n_old = size(str)
    if (n == n_old) return
    if (.not. logic_option(.true., exact) .and. n < n_old) return
    n_save = min(n, n_old)
    temp_str => str
    allocate (str(n))
    if (present(init_val)) str = init_val
    str(1:n_save) = temp_str
    deallocate (temp_str)  
  else
    allocate (str(n))
    if (present(init_val)) str = init_val
  endif

end subroutine re_associate_string

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_associate_integer (inte, n, exact, init_val)
!
! Routine to reassociate an array of integers.
! This is modeled after the reassociate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the original size of the array
!
! Input:
!   inte(:) -- Integer, pointer: Integer array.
!   n       -- Integer: Size wanted.
!   exact   -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than n. 
!                 Default is True.
!
! Output:
!   inte(:) -- Integer, pointer: Allocated array with size(inte) >= n.
!-

subroutine re_associate_integer (inte, n, exact, init_val)

  implicit none

  integer, pointer :: inte(:), temp_inte(:)

  integer, intent(in) :: n
  integer n_save, n_old
  integer, optional :: init_val

  logical, optional :: exact

!

  if (associated(inte)) then
    n_old = size(inte)
    if (n == n_old) return
    if (.not. logic_option(.true., exact) .and. n < n_old) return
    n_save = min(n, n_old)
    temp_inte => inte
    allocate (inte(n))
    if (present(init_val)) inte = init_val
    inte(1:n_save) = temp_inte
    deallocate (temp_inte)  
  else
    allocate (inte(n))
    if (present(init_val)) inte = init_val
  endif

end subroutine re_associate_integer

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_associate_real (re, n, exact, init_val)
!
! Routine to reassociate an array of reals.
! This is modeled after the reassociate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the original size of the array
!
! Input:
!   re(:)  -- Real(rp), Pointer: Real array.
!   n      -- Integer: Size wanted.
!   exact  -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than n. 
!                 Default is True.
!
! Output:
!   re(:)  -- Real(rp), Pointer: Allocated array with size(re) >= n.
!-

subroutine re_associate_real (re, n, exact, init_val)

  implicit none

  real(rp), pointer :: re(:), temp_re(:)
  real(rp), optional :: init_val

  integer, intent(in) :: n
  integer n_save, n_old

  logical, optional :: exact

!

  if (associated(re)) then
    n_old = size(re)
    if (n == n_old) return
    if (.not. logic_option(.true., exact) .and. n < n_old) return
    n_save = min(n, n_old)
    temp_re => re
    allocate (re(n))
    if (present(init_val)) re = init_val
    re(1:n_save) = temp_re
    deallocate (temp_re)  
  else
    allocate (re(n))
    if (present(init_val)) re = init_val
  endif


end subroutine re_associate_real

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine re_associate_logical (logic, n, exact, init_val)
!
! Routine to reassociate a string array.
! This is modeled after the reassociate functions in Numerical Recipes.
! Note: The data of the array is preserved but data at the end of the
! array will be lost if n is less than the size of the array
!
! Input:
!   logic(:) -- Logical, pointer: Logical array.
!   n        -- Logical: Size wanted.
!   exact    -- Logical, optional: If present and False then the size of 
!                 the output array is permitted to be larger than n. 
!                 Default is True.
!
! Output:
!   logic(:) -- Logical, pointer: Allocated array with size(logic) >= n.
!-

subroutine re_associate_logical (logic, n, exact, init_val)

  implicit none

  logical, pointer :: logic(:), temp_logic(:)

  integer, intent(in) :: n
  integer n_save, n_old

  logical, optional :: exact
  logical, optional :: init_val

!

  if (associated(logic)) then
    n_old = size(logic)
    if (n == n_old) return
    if (.not. logic_option(.true., exact) .and. n < n_old) return
    n_save = min(n, n_old)
    temp_logic => logic
    allocate (logic(n))
    if (present(init_val)) logic = init_val
    logic(1:n_save) = temp_logic
    deallocate (temp_logic)  
  else
    allocate (logic(n))
    if (present(init_val)) logic = init_val
  endif


end subroutine re_associate_logical

end module
