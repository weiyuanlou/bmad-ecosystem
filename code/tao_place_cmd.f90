!+
! Subroutine tao_place_cmd (s, where, who)
!
! Subroutine to determine the placement of a plot in the plot window.
! The appropriate s%tamplate_plot(i) determined by the who argument is
! transfered to the appropriate s%plot_page%plot(j) determined by the where
! argument.
!
! Input:
!   s     -- Tao_super_universe_struct:
!    %template_plot(i) -- template matched to who.
!   where -- Character(*): Region where the plot goes. Eg: 'top'.
!   who   -- Character(*): Type of plot. Eg: 'orbit'.
!
! Output
!   s     -- Tao_super_universe_struct:
!    %plot_page%plot(j) -- Plot matched to where.
!-

subroutine tao_place_cmd (s, where, who)

use tao_mod

implicit none

type (tao_super_universe_struct), target :: s
type (tao_plot_struct), pointer :: plot
type (tao_plot_struct), pointer :: template

integer i
logical err

character(*) who, where
character(20) :: r_name = 'tao_place_cmd'

! Find the region where the plot is to be placed.
! The plot pointer will point to the plot associated with the region.

call tao_find_plot (err, s%plot_page%plot, 'BY_REGION', where, plot)
if (err) return

! If who = 'non' then no plot is wanted here so just turn off
! plotting in the region

if (who == 'none') then
  plot%visible = .false.
  return
endif

! Find the template for the type of plot.

call tao_find_plot (err, s%template_plot, 'BY_TYPE', who, template)
if (err) return

! transfer the plotting information from the template to the plot 
! representing the region

call tao_plot_struct_transfer (template, plot, .true.)
plot%visible = .true.

end subroutine
