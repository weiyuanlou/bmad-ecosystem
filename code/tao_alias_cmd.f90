!+
! Subroutine tao_alias_cmd (s, alias, string)
!
! Routine define an alias command.
! 
! Input:
!   alias  -- Name of the tao command file.
!   string(9) -- Command file arguments.
!
! Output:
!   
!-

subroutine tao_alias_cmd (s, alias, string)

use tao_mod
use tao_common

implicit none

type (tao_super_universe_struct) s

character(*) alias
character(*) string
character(20) :: r_name = 'tao_alias_cmd'

integer i

! Check to see if alias already defined. If so just overwrite it.

do i = 1, tao_com%n_alias
  if (tao_com%alias(i)%name == alias) then
    tao_com%alias(i)%string = string
    return
  endif
enddo

if (tao_com%n_alias >= size(tao_com%alias)) then
  call out_io (s_error$, r_name, 'NUMBER OF ALIASES TOO LARGE!')
  return
endif

tao_com%n_alias = tao_com%n_alias + 1
tao_com%alias(tao_com%n_alias)%name = alias
tao_com%alias(tao_com%n_alias)%string = string

end subroutine 
