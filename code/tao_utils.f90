!+
! Module tao_utils
!
! helper subroutines available for communal usage.
!-

module tao_utils

use tao_struct
use tao_interface
use bmad
use output_mod

contains

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_data_check (err)
!
! Routine to do some checking of data.
!-

subroutine tao_data_check (err)

implicit none

type (tao_data_struct), pointer :: datum
integer iu, id
logical err
character(16) :: r_name = 'tao_data_check'

!

err = .false.

do iu = lbound(s%u, 1), ubound(s%u, 1)
  do id = 1, size(s%u(iu)%data)
    datum => s%u(iu)%data(id)
    if (datum%merit_type(1:4) == 'int_' .and. &
            (s%global%opt_with_ref .or. s%global%opt_with_base)) then
      call out_io (s_error$, r_name, &
                        'BAD DATUM INTEGRATION FOR: ' // tao_datum_name(datum))
      err = .true.
    endif
  enddo
enddo

end subroutine tao_data_check

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_pick_universe (name_in, name_out, picked, err, ix_uni)
!
! Subroutine to pick what universe the data name is comming from.
! Examples:
!   "*@..."           -- Choose all universes.
!   "3@..."           -- Choose universe 3. 
!   "[1:30,34]@..."   -- Choose universes 1 through 30 and 34
!   No "@" in name    -- Choose universe s%global%u_view.
!
! Input:
!   name_in    -- Character(*): data name.
!
! Output:
!   name_out   -- Character(*): name_in without any "n@" beginning.
!   picked(:)  -- Logical, allocatable: Array showing picked universes.
!                   The array will be resized if necessary.
!   err        -- Logical: Set True if an error is detected.
!   ix_uni     -- Integer, optional: Set to the picked universe with the highest index.
!-

subroutine tao_pick_universe (name_in, name_out, picked, err, ix_uni)

implicit none

character(*) name_in, name_out
character(20) :: r_name = 'tao_pick_universe'
character(40) uni

integer, optional :: ix_uni
integer i, ix, n, ios, iu, num

logical, allocatable :: picked(:)
logical, allocatable, save :: p(:)
logical err

! Init

call re_allocate(picked, lbound(s%u, 1), ubound(s%u, 1))
call re_allocate(p, -1, ubound(s%u, 1))

err = .false.
picked = .false.
p = .false.
if (present(ix_uni)) ix_uni = -1

! No "@" then simply choose s%global%u_view

ix = index (name_in, '@')
if (ix == 0) then
  picked (s%global%u_view) = .true.
  name_out = name_in
  if (present(ix_uni)) ix_uni = s%global%u_view
  return
endif

! Here whn "@" is found...

uni = name_in(:ix-1)
name_out = name_in(ix+1:)

! Strip off '[' and ']'

if (uni(1:1) == '[' .and. uni(ix-1:ix-1) == ']') uni = uni(2:ix-2)

if (uni == '*') then
  picked = .true.
  if (present(ix_uni)) ix_uni = lbound(s%u, 1)
  return
endif


call location_decode (uni, p, lbound(p, 1), num)
if (num == -1) then
  call out_io (s_error$, r_name, "BAD UNIVERSE NUMBER: " // uni)
  err = .true.
  return
endif

do i = lbound(p, 1), ubound(p, 1)
  if (.not. p(i)) cycle
  iu = tao_universe_number (i)
  if (iu < lbound(s%u, 1) .or. iu > ubound(s%u, 1)) then
    call out_io (s_error$, r_name, "NUMBER DOES NOT CORRESPOND TO A UNIVERSE: " // uni)
    err = .true.
    return
  endif
  picked(iu) = .true.
  if (present(ix_uni)) ix_uni = iu
enddo

end subroutine tao_pick_universe

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_locate_elements (string, ix_universe, ix_ele, ignore_blank) 
!
! Subroutine to find the lattice elements corresponding to the string argument.
!
! Input:
!   string       -- Character(*): String with element name or index locations.
!   ix_universe  -- Integer: Universe to search. 0 => search s%global%u_view.
!   ignore_blank -- Logical, optional: If present and true then do nothing if
!     string is blank. otherwise treated as an error.
!
! Output:
!   ix_ele  -- Integer(:), allocatable: Index array of elements. 
!                         ix_ele(1) = -1 if element not found.
!-

subroutine tao_locate_elements (string, ix_universe, ix_ele, ignore_blank)

implicit none

type (tao_universe_struct), pointer :: u

integer ios, ix, ix_universe, num, i, i_ix_ele
integer, allocatable :: ix_ele(:)

character(*) string
character(40) ele_name
character(20) :: r_name = 'tao_locate_elements'

logical, optional :: ignore_blank
logical, allocatable, save :: here(:)
logical error

! If it is a number translate it:

call str_upcase (ele_name, string)
call string_trim (ele_name, ele_name, ix)

call re_allocate (ix_ele, 1)
ix_ele = -1

if (ix == 0 .and. logic_option(.false., ignore_blank)) return

if (ix == 0) then
  call out_io (s_error$, r_name, 'ELEMENT NAME IS BLANK')
  return
endif

u => tao_pointer_to_universe (ix_universe)
if (.not. associated(u)) return

if (is_integer(ele_name(1:1))) then ! must be an array of numbers
  if (allocated (here)) deallocate(here)
  allocate(here(0:u%model%lat%n_ele_max))
  call location_decode(ele_name, here, 0, num) 
  if (num < 0) then
    call out_io (s_error$, r_name, 'ELEMENT INDEX OUT OF RANGE: ' // ele_name)
    return
  endif
  call re_allocate (ix_ele, num)
  i_ix_ele = 1
  do i = 0, ubound(here,1)
    if (here(i)) then
      ix_ele(i_ix_ele) = i
      i_ix_ele = i_ix_ele + 1
    endif
  enddo
  return
endif

call element_locator (ele_name, u%model%lat, ix_ele(1))

if (ix_ele(1) < 0) call out_io (s_error$, r_name, 'ELEMENT NOT FOUND: ' // string)

end subroutine tao_locate_elements

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_find_plot_region (err, where, region, print_flag)
!
! Routine to find a region using the region name.
!
! Input:
!   where      -- Character(*): Region name.
!   print_flag -- Logical, optional: If present and False then surpress error
!                   messages. Default is True.
!
! Output:
!   err      -- logical: Set True on error. False otherwise.
!   region   -- Tao_plot_region_struct, pointer: Region found.
!-

subroutine tao_find_plot_region (err, where, region, print_flag)

implicit none

type (tao_plot_region_struct), pointer :: region

integer i, ix

character(*) where
character(40) plot_name, graph_name
character(28) :: r_name = 'tao_find_plot_region'

logical, optional :: print_flag
logical err

! Parse where argument

ix = index(where, '.')
if (ix == 0) then
  plot_name = where
else
  plot_name = where(1:ix-1)
endif

! Match plot name to region

err = .false.

call match_word (plot_name, s%plot_region%name, ix, .true.)

if (ix < 1) then
  if (logic_option(.true., print_flag)) call out_io (s_error$, r_name, &
                                    'PLOT LOCATION NOT FOUND: ' // plot_name)
  err = .true.
else
  region => s%plot_region(ix)  
endif

end subroutine

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_find_plots (err, name, where, plot, graph, curve, print_flag, always_allocate)
!
! Routine to find a plot using the region or plot name.
! A region or plot name is something like: name = "top"
! A graph name is something like: name  = "top.x"
! A curve name is something like: name  = "top.x.c1"
! The wild card "*" can be used so name = "top.*.c1" could 
!   return "top.x.c1" and "top.y.c1".
!
! Unless always_allocate = T, The graph(:) array will only be allocated if 
! the graph portion of name is not blank.
!   For example: name = "top" will leave graph(:) unallocated.
! Unless always_allocate = T, The curve(:) array will only be allocated if 
! the curve portion of name is not blank.
!   For example: name = "top.x" will leave curve(:) unallocated.
!
! Input:
!   name       -- Character(*): Name of plot or region.
!   where      -- Character(*): Where to look: 'TEMPLATE', 'REGION', or 'BOTH'
!                   For where = 'BOTH', if something is found in a plot region,
!                   then the templates will not be searched
!   print_flag -- Logical, optional: If present and False then surpress error
!                   messages. Default is True.
!   always_allocate 
!              -- Logical, optional: If present and True then always allocate 
!                   graph(:) and curve(:) arrays except if there is an error. 
!
! Output:
!   err      -- logical: Set True on error. False otherwise.
!   plot(:)  -- Tao_plot_array_struct, allocatable, optional: Array of plots.
!   graph(:) -- Tao_graph_array_struct, allocatable, optional: Array of graphs.
!   curve(:) -- Tao_curve_array_struct, allocatable, optional: Array of curves.
!-

subroutine tao_find_plots (err, name, where, plot, graph, curve, print_flag, always_allocate)

implicit none

type (tao_plot_array_struct), allocatable, optional :: plot(:)
type (tao_graph_array_struct), allocatable, optional :: graph(:)
type (tao_curve_array_struct), allocatable, optional :: curve(:)
type (tao_plot_array_struct), allocatable, save :: p(:)
type (tao_graph_array_struct), allocatable, save :: g(:)
type (tao_curve_array_struct), allocatable, save :: c(:)

integer i, j, k, ix, np, ng, nc

character(*) name, where
character(40) plot_name, graph_name, curve_name
character(28) :: r_name = 'tao_find_plots'

logical, optional :: print_flag, always_allocate
logical err

! Init

if (present(plot)) then
  if (allocated(plot)) deallocate(plot)
endif

if (present(graph)) then
  if (allocated(graph)) deallocate(graph)
endif

if (present(curve)) then
  if (allocated(curve)) deallocate(curve)
endif

if (allocated(p)) deallocate(p)
if (allocated(g)) deallocate(g)
if (allocated(c)) deallocate(c)

! Error check

if (where /= 'REGION' .and. where /= 'BOTH' .and. where /= 'TEMPLATE') then
  if (logic_option(.true., print_flag)) call out_io (s_fatal$, r_name, &
                                             'BAD "WHERE" LOCATION: ' // where)
  call err_exit
endif

! Parse name argument

err = .false.

if (name == "") then
  if (logic_option(.true., print_flag)) &
                call out_io (s_error$, r_name, 'BLANK "WHERE" LOCATION')
  err = .true.
  return
endif

ix = index(name, '.')
if (ix == 0) then
  plot_name = name
  graph_name = ' '
else
  plot_name = name(1:ix-1)
  graph_name = name(ix+1:)
endif

! Match name to region or plot and count how many there are.

np = 0

if (where == 'REGION' .or. where == 'BOTH') then
  do i = 1, size(s%plot_region)
    if (index(s%plot_region(i)%name, trim(plot_name)) == 1 .or. &
        index(s%plot_region(i)%plot%name, trim(plot_name)) == 1 .or. plot_name == '*') np = np + 1
  enddo
endif

if (where == 'TEMPLATE' .or. (where == 'BOTH' .and. np == 0)) then
  do i = 1, size(s%template_plot)
    if (index(s%template_plot(i)%name, trim(plot_name)) == 1 .or. plot_name == '*') np = np + 1
  enddo
endif

! Allocate space

if (np == 0) then
  if (logic_option(.true., print_flag)) call out_io (s_error$, r_name, &
                                             'PLOT NOT FOUND: ' // plot_name)
  err = .true.
  return
endif

allocate (p(np))
if (present(plot)) allocate(plot(np))

! Now that we have counted and allocated the matches set the plot pointers.

np = 0

if (where == 'REGION' .or. where == 'BOTH') then
  do i = 1, size(s%plot_region)
    if (index(s%plot_region(i)%name, trim(plot_name)) == 1 .or. &
        index(s%plot_region(i)%plot%name, trim(plot_name)) == 1 .or. plot_name == '*') then
      np = np + 1
      p(np)%p => s%plot_region(i)%plot
    endif
  enddo
endif

if (where == 'TEMPLATE' .or. (where == 'BOTH' .and. np == 0)) then
  do i = 1, size(s%template_plot)
    if (index(s%template_plot(i)%name, trim(plot_name)) == 1 .or. plot_name == '*') then
      np = np + 1
      p(np)%p => s%template_plot(i)
    endif
  enddo
endif

if (present(plot)) plot = p

! Find the number of graphs and allocate.

ix = index(graph_name, '.')
if (ix == 0) then
  curve_name = ' '
else
  curve_name = graph_name(ix+1:)
  graph_name = graph_name(1:ix-1)
endif

if (logic_option(.false., always_allocate) .and. graph_name == ' ') graph_name = '*'
if (graph_name == ' ') return

ng = 0
do i = 1, np
  do j = 1, size(p(i)%p%graph)
    if (p(i)%p%graph(j)%name == graph_name .or. graph_name == '*') ng = ng + 1
  enddo
enddo

if (ng == 0) then
  if (logic_option(.true., print_flag)) call out_io (s_error$, r_name, &
                  'GRAPH NOT FOUND: ' // trim(plot_name) // '.' // graph_name)
  err = .true.
  return
endif

allocate (g(ng))
if (present(graph)) allocate (graph(ng))

! Now that we have counted and allocated the matches set the graph pointers

ng = 0
do i = 1, np
  do j = 1, size(p(i)%p%graph)
    if (p(i)%p%graph(j)%name == graph_name .or. graph_name == '*') then
      ng = ng + 1
      g(ng)%g => p(i)%p%graph(j)
    endif
  enddo
enddo

if (present(graph)) graph = g

! Find number of curves that match

if (logic_option(.false., always_allocate) .and. curve_name == ' ') curve_name = '*'
if (curve_name == ' ') return

nc = 0
do j = 1, ng
  do k = 1, size(g(j)%g%curve)
    if (g(j)%g%curve(k)%name == curve_name .or. curve_name == '*') nc = nc + 1
  enddo
enddo

if (nc == 0) then
  if (logic_option(.true., print_flag)) call out_io (s_error$, r_name, &
                  'CURVE NOT FOUND: ' // name)
  err = .true.
  return
endif

allocate (c(nc))
if (present(curve)) allocate (curve(nc))

! Now that we have counted and allocated the matches set the curve pointers

nc = 0
do j = 1, ng
  do k = 1, size(g(j)%g%curve)
    if (g(j)%g%curve(k)%name == curve_name .or. curve_name == '*') then
      nc = nc + 1
      c(nc)%c => g(j)%g%curve(k)
    endif
  enddo
enddo

if (present(curve)) curve = c

end subroutine tao_find_plots

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_var_useit_plot_calc (graph, var)
!
! Subroutine to set the variables for plotting.
!
! Input:
!
! Output:
!   var     -- Tao_var_struct:
!     %useit_plot -- True if good for plotting.
!-

subroutine tao_var_useit_plot_calc (graph, var)

implicit none

type (tao_graph_struct) graph
type (tao_var_struct) var(:)

!

var%useit_plot = var%exists .and. var%good_user .and. var%good_plot &
                                                .and. var%good_var

end subroutine tao_var_useit_plot_calc

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_evaluate_element_parameters (err, param_name, values, print_err)
!
! Routine to evaluate a lattice element parameter of the form 
!     <universe>@ele:{<class>}:<ele_name_or_num>[<parameter>]{|<component>}
! or
!     <universe>@ele@middle:{<class>}:<ele_name_or_num>[<parameter>]{|<component>}
! Note: size(values) can be zero without an error
! 
! Input:
!   param_name -- Character(*): parameter name.
!   print_err -- Logical, optional :: Print error message? Default is True.
!
! Output:
!   err       -- Logical: True if there is an error in syntax. False otherwise
!   values(:) -- Real(rp), allocatable: Array of datum valuse.
!-

subroutine tao_evaluate_element_parameters (err, param_name, values, print_err)

implicit none

type (tao_universe_struct), pointer :: u
type (lat_struct), pointer :: lat
type (ele_struct) ele3
type (coord_struct), pointer :: this_orb(:)
type (coord_struct) orb

character(*) param_name
character(60) name, class_ele, parameter, component
character(40) :: r_name = 'tao_evaluate_element_parameters'

real(rp), allocatable :: values(:)
real(rp), pointer :: real_ptr

integer i, j, num, ixe, ix1, ios, n_tot
integer, allocatable, save :: ix_ele(:)

logical err, printit, valid, middle
logical, optional :: print_err
logical, allocatable, save :: this_u(:)

!

call tao_pick_universe (param_name, name, this_u, err)
if (err) return

err = .true.
printit = logic_option (.true., print_err)

if (name(1:4) == 'ele:') then
  name = name(5:)  ! Strip off 'ele:'
  middle = .false.
elseif (name(1:10) == 'ele@middle') then
  name = name(11:)  ! Strip off 'ele@middle:'
  middle = .true.
else
  return
endif

! Get class:name

ix1 = index(name, '[');  if (ix1 == 0) return
class_ele = name(1:ix1-1)
name = name(ix1+1:)
if (class_ele(1:1) == ':') class_ele = class_ele(2:)

! Get parameter

ix1 = index(name, ']');  if (ix1 == 0) return
parameter = name(1:ix1-1)
name = name(ix1+1:)

! Get component

if (name(1:1) == '|') then
  component = name(2:)
elseif (name(1:1) == ' ') then
  component = 'model'
else
  if (printit) call out_io (s_error$, r_name, 'COMPONENT: ' // param_name)
  return
endif

! Evaluate

n_tot = 0
do i = lbound(s%u, 1), ubound(s%u, 1)
  if (.not. this_u(i)) cycle
  u => s%u(i)
  call elements_locator (class_ele, u%model%lat, ix_ele, err)
  if (err) return
  call re_allocate (values, n_tot + size(ix_ele))

  do j = 1, size(ix_ele)
    ixe = ix_ele(j)

    if (parameter == 'index') then
      values(n_tot+j) = ixe
      cycle
    endif

    select case (component)
    case ('model')   
      lat => u%model%lat
      this_orb => u%model%orb
    case ('base')  
      lat => u%base%lat
      this_orb => u%base%orb
    case ('design')
      lat => u%design%lat
      this_orb => u%design%orb
    case default
      call out_io (s_error$, r_name, 'BAD DATUM COMPONENT FOR: ' // param_name)
      return
    end select

    if (middle) then
      call twiss_and_track_partial (lat%ele(ixe-1), lat%ele(ixe), &
                lat%param, lat%ele(ixe)%value(l$)/2, ele3, this_orb(ixe-1), orb)
      if (parameter(1:6) == 'orbit_') then
        call tao_orbit_value (parameter, orb, values(n_tot+j), err)
      else
        call pointer_to_attribute (ele3, parameter, .true., real_ptr, err, printit)
      endif
    else
      if (parameter(1:6) == 'orbit_') then
        call tao_orbit_value (parameter, this_orb(ixe), values(n_tot+j), err)
      else
        call pointer_to_attribute (lat%ele(ixe), parameter, .true., real_ptr, err, printit)
      endif
    endif

    if (err) return
    if (parameter(1:6) /= 'orbit_') values(n_tot+j) = real_ptr
  enddo
  n_tot = n_tot + size(values)
enddo

err = .false.

end subroutine tao_evaluate_element_parameters

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_orbit_value (component, orbit, value, err)
!
! Routine to return the orbit component indicated by component
!
! Input:
!   component -- Character(*): 'orbit_x', 'orbit_px', ... or 'orbit_pz'
!   orbit     -- Coord_struct: orbit.
!
! Output:
!   value -- Real(rp): orbit component.
!   err   -- Logical: Set True if component is not recognized. False otherwise.
!-

subroutine tao_orbit_value (component, orbit, value, err)

implicit none

type (coord_struct) orbit

real(rp) value
character(*) component
logical err

!

err = .true.

select case (component)
case ('orbit_x')
  value = orbit%vec(1)
case ('orbit_px')
  value = orbit%vec(2)
case ('orbit_y')
  value = orbit%vec(3)
case ('orbit_py')
  value = orbit%vec(4)
case ('orbit_z')
  value = orbit%vec(5)
case ('orbit_pz')
  value = orbit%vec(6)
case default
  return
end select

err = .false.

end subroutine tao_orbit_value

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_find_data (err, data_name, d2_ptr, d1_array, d_array, re_array, 
!                       log_array, str_array, int_array, ix_uni, print_err, component)
!
! Routine to set data pointers to the correct data structures. 
!
! The re_array will be used if the component is one of:
!   model, base, design, meas, ref, old, fit, weight
! The l_array will be used if the component is one of:
!   exists, good_meas, good_ref, good_user, good_opt, good_plot
! 
! Example:
!   data_name = '*@orbit.x'
! In this case d2_ptr will be nullifed since the data can refer to
! more than one universe. 
! re_array & l_array will also be nullified since there is no data component specified.
!
! Example:
!   data_name = 'orbit'
! In this case the default universe will be used. The d1_array will have two components
! pointing to orbit.x and orbit.y.
! re_array & l_array will also be nullified since there is no data component specified.
!
! Example:
!   data_name = '2@orbit.x[3,7:9]|meas'
! The measured values for the 3rd, 7th, 8th and 9th elements of orbit.x in universe #2.
! r_arrray will be allocated and l_array will be nullified.
!
! Input:
!   data_name    -- Character(*): The data name type. Eg: "3@orbit.x[2:5,10]|meas"
!   ix_uni       -- Integer, optional: Index of default universe to use.
!                     If ix_uni = 0 then "viewed" universe will be used.
!                     Also, if not present then the "viewed" universe will be used.
!   print_err    -- Logical, optional: Print error message if data is 
!                     not found? Default is True.
!
! Output:
!   err          -- Logical: Err condition
!   d2_ptr       -- Tao_d2_data_struct, pointer, optional: Pointer to the d2 data structure
!                     if there is a unique structure to point to. Null otherwise.
!   d1_array(:)  -- Tao_d1_data_array_struct, allocatable, optional: Pointers to all 
!                     the matching d1_data structures.
!   d_array(:)   -- Tao_data_array_struct, allocatable, optional: Pointers to all 
!                     the matching tao_data_structs.
!   re_array(:)  -- Tao_real_pointer_struct, allocatable, optional: Pointers to real 
!                     component values.
!   log_array(:) -- Tao_logical_array_struct, allocatable, optional: Pointers to
!                     logical component values.
!   str_array(:) -- Tao_string_array_struct, allocatable, optional: Pointers to 
!                     character component values.
!   int_array(:) -- Tao_integer_array_struct, allocatable, optional: pointers to
!                     integer component values
!   component    -- Character(*), optional: Name of the component. E.G: 'good_user'
!                     set to ' ' if no component present.
!-

subroutine tao_find_data (err, data_name, d2_ptr, d1_array, d_array, re_array, &
                           log_array, str_array, int_array, ix_uni, print_err, component)

implicit none

type (tao_d2_data_struct), pointer, optional :: d2_ptr
type (tao_d2_data_struct), pointer :: d2_ptr_loc
type (tao_d1_data_array_struct), allocatable, optional :: d1_array(:)
type (tao_data_array_struct), allocatable, optional    :: d_array(:)
type (tao_real_pointer_struct), allocatable, optional    :: re_array(:)
type (tao_integer_array_struct), allocatable, optional :: int_array(:)
type (tao_logical_array_struct), allocatable, optional :: log_array(:)
type (tao_string_array_struct), allocatable, optional  :: str_array(:)
type (tao_universe_struct), pointer :: u

character(*) :: data_name
character(*), optional :: component
character(20) :: r_name = 'tao_find_data'
character(80) dat_name, component_name
character(16), parameter :: real_components(8) = &
          (/ 'model ', 'base  ', 'design', 'meas  ', 'ref   ', &
             'old   ', 'fit   ', 'weight' /)
character(16), parameter :: logic_components(6) = &
          (/ 'exists   ', 'good_meas', 'good_ref ', 'good_user', 'good_opt ', &
             'good_plot' /)
character(16), parameter :: integer_components(4) = &
          (/ 'ix_ele ', 'ix_ele0', 'ix_d1  ', 'ix_uni ' /)
character(16), parameter :: string_components(1) = (/ 'merit_type' /)

integer, optional :: ix_uni
integer :: data_num, ios
integer i, ix, iu

logical err, component_here, this_err, print_error, error
logical, optional :: print_err
logical, allocatable, save :: picked(:)

! Init

print_error = logic_option(.true., print_err)

nullify (d2_ptr_loc)
if (present(d2_ptr)) nullify(d2_ptr)

if (present(d1_array)) then
  if (allocated (d1_array)) deallocate (d1_array)
endif
if (present(d_array)) then
  if (allocated (d_array)) deallocate (d_array)
endif
if (present(re_array)) then
  if (allocated (re_array)) deallocate (re_array)
endif
if (present(int_array)) then
  if (allocated (int_array)) deallocate (int_array)
endif
if (present(log_array)) then
  if (allocated (log_array)) deallocate (log_array)
endif
if (present(str_array)) then
  if (allocated (str_array)) deallocate (str_array)
endif

err = .true.

if (data_name == '') then
  if (print_error) call out_io (s_error$, r_name, 'DATA NAME IS BLANK')
  return
endif

! Select meas, ref, etc.

ix = index(data_name, '|')
if (ix == 0) then  ! not present
  component_here = .false.
  component_name = ' '
  dat_name = data_name
else
  component_here = .true.
  component_name = data_name(ix+1:)
  dat_name = data_name(:ix-1)
endif
if (present(component)) component = component_name

call string_trim (dat_name, dat_name, ix)

if (component_here) then
  call string_trim (component_name, component_name, ix)
  if (.not. any(component_name == real_components) .and. &
      .not. any(component_name == logic_components) .and. &
      .not. any(component_name == integer_components) .and. &
      .not. any(component_name == string_components)) then
    if (print_error) call out_io (s_error$, r_name, "BAD COMPONENT NAME: " // data_name)
    return            
  endif
endif

! Select universe

call tao_pick_universe (dat_name, dat_name, picked, this_err)
if (this_err) return
if (present(ix_uni)) then
  u => tao_pointer_to_universe (ix_uni)
  if (.not. associated(u)) return
  call find_this_d2 (u, dat_name, this_err)
else
  do i = lbound(s%u, 1), ubound(s%u, 1)
    if (.not. picked(i)) cycle
    u => tao_pointer_to_universe (i)
    call find_this_d2 (u, dat_name, this_err)
    if (this_err) return
  enddo
endif

! error check

if (this_err) then
  if (print_error) call out_io (s_error$, r_name, "Couldn't find data: " // data_name)
  return
endif

if (present(d1_array)) then
  if (.not. allocated (d1_array)) allocate (d1_array(0))
endif
if (present(d_array)) then
  if (.not. allocated (d_array)) allocate (d_array(0))
endif
if (present(re_array)) then
  if (.not. allocated (re_array)) allocate (re_array(0))
endif
if (present(int_array)) then
  if (.not. allocated (int_array)) allocate (int_array(0))
endif
if (present(log_array)) then
  if (.not. allocated (log_array)) allocate (log_array(0))
endif
if (present(str_array)) then
  if (.not. allocated (str_array)) allocate (str_array(0))
endif

err = .false.

!----------------------------------------------------------------------------
contains

subroutine find_this_d2 (uu, name, this_err)

type (tao_universe_struct), target :: uu
integer i, ix
character(*) name
character(80) d1_name, d2_name
logical this_err

! Everything before a period is the d2 name.
! if no period then must be something like name = "orbit" and everything is the d2 name.

this_err = .false.

ix = index(name, '.')
if (ix == 0) then
  ix = index(name, '[')
  if (ix /= 0) then
    d2_name = name(1:ix-1)
    d1_name = name(ix:)
  else
    d2_name = name
    d1_name = '*'
  endif
else
  d2_name = name(1:ix-1)
  d1_name = name(ix+1:)
endif

! loop over matching d2 names

do i = 1, uu%n_d2_data_used
  if (d2_name == '*') then
    call find_this_d1 (uu%d2_data(i), d1_name, .false., this_err)
    if (this_err) return
  elseif (d2_name == uu%d2_data(i)%name) then
    d2_ptr_loc => uu%d2_data(i)
    if (present(d2_ptr)) d2_ptr => uu%d2_data(i)
    call find_this_d1 (uu%d2_data(i), d1_name, .true., this_err)
    exit
  endif
enddo

end subroutine find_this_d2

!----------------------------------------------------------------------------
! contains

subroutine find_this_d1 (d2, name, found_d1, this_err)

type (tao_d2_data_struct), target :: d2
integer i, ix
character(*) name
character(80) d1_name, d_name
logical found_d1, this_err

! Everything before a '[' is the d1 name.

ix = index(name, '[')

if (ix == 0) then
  d1_name = name
  d_name = '*'
else
  d1_name = name(1:ix-1)
  d_name = name(ix+1:)
  ix = index(d_name, ']')
  if (ix == 0) then
    if (print_error) call out_io (s_error$, r_name, "NO MATCHING ']': " // data_name)
    this_err = .true.
    return
  endif
  if (d_name(ix+1:) /= ' ') then
    if (print_error) call out_io (s_error$, r_name, "GARBAGE AFTER ']': " // data_name)
    this_err = .true.
    return
  endif
  d_name = d_name(:ix-1)
endif

do i = 1, size(d2%d1)
  if (size(d2%d1) == 1 .and. d1_name == '') then
    call find_this_data (d2%d1(i), d_name, this_err)
  elseif (d1_name == '*') then
    call find_this_data (d2%d1(i), d_name, this_err)
    if (this_err) return
  elseif (d1_name == d2%d1(i)%name) then
    call find_this_data (d2%d1(i), d_name, this_err)
    exit
  endif
enddo

end subroutine find_this_d1

!----------------------------------------------------------------------------
! contains

subroutine find_this_data (d1, name, this_err)

type (tao_d1_data_struct), target :: d1
type (tao_d1_data_array_struct), allocatable :: d1_temp(:)
type (tao_data_array_struct), allocatable, save :: da(:)
type (tao_real_pointer_struct), allocatable, save :: ra(:)
type (tao_integer_array_struct), allocatable, save :: ia(:)
type (tao_logical_array_struct), allocatable, save :: la(:)
type (tao_string_array_struct), allocatable, save  :: sa(:)

integer i, j, nd, nl, i1, i2, num

character(*) name
character(80) d1_name, d_name

logical this_err
logical, allocatable, save :: list(:)

! d1_array

if (present(d1_array)) then
  if (allocated(d1_array)) then
    nd = size(d1_array)
    if (nd > 0) then
      allocate (d1_temp(nd))
      d1_temp = d1_array
      deallocate(d1_array)
      allocate (d1_array(nd+1))
      d1_array(1:nd) = d1_temp
      deallocate(d1_temp)
    else
      deallocate(d1_array)
      allocate (d1_array(1))
    endif
    d1_array(nd+1)%d1 => d1
  else
    allocate (d1_array(1))
    d1_array(1)%d1 => d1
  endif
endif

!

if (allocated(list)) deallocate(list)
i1 = lbound(d1%d, 1)
i2 = ubound(d1%d, 1)
allocate (list(i1:i2))

if (name == '*') then
  list = .true.

else
  call location_decode (name, list, i1, num)
  if (num <  0) then
    call out_io (s_error$, r_name, "BAD DATA INDEX NUMBER(S): " // name)
    this_err = .true.
    return  
  endif
endif

err = .false.
nl = count(list)

! data array

if (present(d_array)) then

  if (allocated(d_array)) then
    nd = size(d_array)
    allocate (da(nd))
    da = d_array
    deallocate(d_array)
    allocate (d_array(nl+nd))
    j = nd
    d_array(1:nd) = da
    deallocate(da)
  else
    allocate (d_array(nl))
    j = 0
  endif

  do i = i1, i2
    if (list(i)) then
      j = j + 1
      d_array(j)%d => d1%d(i)
    endif
  enddo

endif

! Integer component array

if (present(int_array) .and.  any(component_name == integer_components)) then

  if (allocated(int_array)) then
    nd = size(int_array)
    allocate (ia(nd))
    ia = int_array
    deallocate(int_array)
    allocate (int_array(nl+nd))
    j = nd
    int_array(1:nd) = ia
    deallocate(ia)
  else
    allocate (int_array(nl))
    j = 0
  endif

  do i = i1, i2
    if (list(i)) then
      j = j + 1
      select case (component_name)
      case ('ix_ele')
        int_array(j)%i => d1%d(i)%ix_ele
      case ('ix_ele0')
        int_array(j)%i => d1%d(i)%ix_ele0
      case ('ix_d1')
        int_array(j)%i => d1%d(i)%ix_d1
      case ('ix_uni')
        int_array(j)%i => d1%d(i)%d1%d2%ix_uni
      case default
        call out_io (s_fatal$, r_name, "INTERNAL ERROR: INTEGER DATA")
        call err_exit
      end select
    endif
  enddo

endif

! real component array

if (present(re_array) .and.  any(component_name == real_components)) then

  if (allocated(re_array)) then
    nd = size(re_array)
    allocate (ra(nd))
    ra = re_array
    deallocate(re_array)
    allocate (re_array(nl+nd))
    j = nd
    re_array(1:nd) = ra
    deallocate(ra)
  else
    allocate (re_array(nl))
    j = 0
  endif

  do i = i1, i2
    if (list(i)) then
      j = j + 1
      select case (component_name)
      case ('model')
        re_array(j)%r => d1%d(i)%model_value
        re_array(j)%good_user => d1%d(i)%good_user
        re_array(j)%good_value => d1%d(i)%good_model
      case ('base')
        re_array(j)%r => d1%d(i)%base_value
        re_array(j)%good_user => d1%d(i)%good_user
        re_array(j)%good_value => d1%d(i)%good_model
      case ('design')
        re_array(j)%r => d1%d(i)%design_value
        re_array(j)%good_user => d1%d(i)%good_user
        re_array(j)%good_value => d1%d(i)%good_model
      case ('meas')
        re_array(j)%r => d1%d(i)%meas_value
        re_array(j)%good_user => d1%d(i)%good_user
        re_array(j)%good_value => d1%d(i)%good_meas
      case ('ref')
        re_array(j)%r => d1%d(i)%ref_value
        re_array(j)%good_user => d1%d(i)%good_user
        re_array(j)%good_value => d1%d(i)%good_ref
      case ('old')
        re_array(j)%r => d1%d(i)%old_value
        re_array(j)%good_user => d1%d(i)%good_user
        re_array(j)%good_value => forever_true$
      case ('fit')
        re_array(j)%r => d1%d(i)%fit_value
        re_array(j)%good_user => d1%d(i)%good_user
        re_array(j)%good_value => forever_true$
      case ('weight')
        re_array(j)%r => d1%d(i)%weight
        re_array(j)%good_user => d1%d(i)%good_user
        re_array(j)%good_value => forever_true$
      case default
        call out_io (s_fatal$, r_name, "INTERNAL ERROR: REAL DATA")
        call err_exit
      end select
    endif
  enddo

endif

! logical component array

if (present(log_array) .and. any(component_name == logic_components)) then

  if (allocated(log_array) .and. component_here) then
    nd = size(log_array)
    allocate (la(nd))
    la = log_array
    deallocate(log_array)
    allocate (log_array(nl+nd))
    j = nd
    log_array(1:nd) = la
    deallocate(la)
  else
    allocate (log_array(nl))
    j = 0
  endif

  do i = i1, i2
    if (list(i)) then
      j = j + 1
      select case (component_name)
      case ('exists')
        log_array(j)%l => d1%d(i)%exists
      case ('good_meas')
        log_array(j)%l => d1%d(i)%good_meas
      case ('good_ref')
        log_array(j)%l => d1%d(i)%good_ref
      case ('good_user')
        log_array(j)%l => d1%d(i)%good_user
      case ('good_opt')
        log_array(j)%l => d1%d(i)%good_opt
      case ('good_plot')
        log_array(j)%l => d1%d(i)%good_plot
      case default
        call out_io (s_fatal$, r_name, "INTERNAL ERROR: LOGIC DATA")
        call err_exit
      end select
    endif
  enddo

endif

! string component array

if (present(str_array) .and. any(component_name == string_components)) then

  if (allocated(str_array) .and. component_here) then
    nd = size(str_array)
    allocate (sa(nd))
    sa = str_array
    deallocate(str_array)
    allocate (str_array(nl+nd))
    j = nd
    str_array(1:nd) = sa
    deallocate(sa)
  else
    allocate (str_array(nl))
    j = 0
  endif

  do i = i1, i2
    if (list(i)) then
      j = j + 1
      select case (component_name)
      case ('merit_type')
        str_array(j)%s => d1%d(i)%merit_type
      case default
        call out_io (s_fatal$, r_name, "INTERNAL ERROR: STRING DATA")
        call err_exit
      end select
    endif
  enddo

endif

end subroutine find_this_data

end subroutine tao_find_data

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_find_var (err, var_name, v1_array, v_array, re_array, log_array,  
!                                                    str_array, print_err, component)
!
! Find a v1 variable type, and variable data then point to it.
!
! The re_array will be used if the component is one of:
!   model, base, design, meas, ref, old, step, weight, high_lim, low_lim 
! The log_array will be used if the component is one of:
!   exists, good_var, good_user, good_opt, good_plot
! 
! Example:
!   var_name = 'quad_k1[3]|design'
!
! Input:
!   var_name     -- Character(*): Name of the variable.
!   print_err    -- Logical, optional: Print error message if data is 
!                     not found? Default is True.
!
! Output:
!   err          -- Logical: err condition
!   v1_array(:)  -- Tao_v1_var_array_struct, allocatable, optional: Pointers to 
!                     all the v1_var structures.
!   v_array(:)   -- Tao_var_array_struct, allocatable, optional: Pointers to the 
!                     variable data point.
!   re_array(:)  -- Tao_real_pointer_struct, allocatable, optional: Pointers to real 
!                     component values.
!   log_array(:) -- Tao_logical_array_struct, allocatable, optional: Pointers to
!                     logical component values.
!   str_array(:) -- Tao_string_array_struct, allocatable, optional: Pointers to 
!                     character component values.
!   component    -- Character(*), optional: Name of the component. E.G: 'good_user'
!                   set to ' ' if no component present.
!-

subroutine tao_find_var (err, var_name, v1_array, v_array, re_array, log_array, &
                                                    str_array, print_err, component)

implicit none

type (tao_v1_var_array_struct), allocatable, optional  :: v1_array(:)
type (tao_var_array_struct), allocatable, optional     :: v_array(:)
type (tao_real_pointer_struct), allocatable, optional    :: re_array(:)
type (tao_logical_array_struct), allocatable, optional :: log_array(:)
type (tao_string_array_struct), allocatable, optional  :: str_array(:)

integer i, ix, n_var, ios

character(16), parameter :: real_components(10) = &
          (/ 'model   ', 'base    ', 'design  ', 'meas    ', 'ref     ', &
             'old     ', 'step    ', 'weight  ', 'high_lim', 'low_lim ' /)
character(16), parameter :: logic_components(5) = &
          (/ 'exists   ', 'good_var ', 'good_user', 'good_opt ', 'good_plot' /)
character(16), parameter :: string_components(1) = (/ 'merit_type' /)

character(*) :: var_name
character(*), optional :: component
character(20) :: r_name = 'tao_find_var'
character(80) v1_name, v_name, component_name

logical, optional :: print_err
logical err, component_here, this_err, print_error

! Init

print_error = logic_option(.true., print_err)

if (present(v1_array)) then
  if (allocated (v1_array)) deallocate (v1_array)
endif
if (present(v_array)) then
  if (allocated (v_array)) deallocate (v_array)
endif
if (present(re_array)) then
  if (allocated (re_array)) deallocate (re_array)
endif
if (present(log_array)) then
  if (allocated (log_array)) deallocate (log_array)
endif
if (present(str_array)) then
  if (allocated (str_array)) deallocate (str_array)
endif

err = .true.

! Error if no variables exist

if (s%n_var_used == 0) then
  if (print_error) call out_io (s_error$, r_name, &
                        "NO VARIABLES HAVE BEEN DEFINED IN THE INPUT FILES!")
  return
endif

! Select meas, ref, etc.

ix = index(var_name, '|')
if (ix == 0) then  ! not present
  component_here = .false.
  component_name = ' '   ! garbage
  v1_name = var_name
else
  component_here = .true.
  component_name = var_name(ix+1:)
  v1_name = var_name(:ix-1)
endif
if (present(component)) component = component_name

call string_trim (v1_name, v1_name, ix)
call string_trim (component_name, component_name, ix)

if (component_here) then
  if (.not. any(component_name == real_components) .and. &
      .not. any(component_name == logic_components) .and. &
      .not. any(component_name == string_components)) then
    if (print_error) call out_io (s_error$, r_name, "BAD COMPONENT NAME: " // var_name)
    return            
  endif
endif

! split on '['

ix = index(var_name, '[')
if (ix == 0) then
  v_name = '*'
else
  v_name  = v1_name(ix+1:)
  v1_name = v1_name(1:ix-1)
  ix = index(v_name, ']')
  if (ix == 0) then
    if (print_error) call out_io (s_error$, r_name, "NO MATCHING ']': " // var_name)
    return
  endif
  if (v_name(ix+1:) /= ' ') then
    if (print_error) call out_io (s_error$, r_name, "GARBAGE AFTER ']': " // var_name)
    return
  endif
  v_name = v_name(:ix-1)
endif

call string_trim(v1_name, v1_name, ix)
if (ix == 0) then
  if (print_error) call out_io (s_error$, r_name, 'VARIABLE NAME IS BLANK')
  return
endif

! Point to the correct v1 var type 


if (v1_name == '*') then
  if (present(v1_array)) allocate (v1_array(s%n_v1_var_used))
  do i = 1, s%n_v1_var_used
    if (present(v1_array)) v1_array(i)%v1 => s%v1_var(i)
    call find_this_var (s%v1_var(i), v_name, this_err)
    if (this_err) return
  enddo

else
  do i = 1, s%n_v1_var_used
    if (v1_name == s%v1_var(i)%name) then
      if (present(v1_array)) then
        allocate (v1_array(1))
        v1_array(1)%v1 => s%v1_var(i)
      endif
      call find_this_var (s%v1_var(i), v_name, this_err)
      exit
    endif
  enddo
endif

! error check

if (err) then
  if (print_error) call out_io (s_error$, r_name, "COULDN'T FIND VARIABLE: " // var_name)
  return
endif

if (present(v1_array)) then
  if (.not. allocated (v1_array)) allocate (v1_array(0))
endif
if (present(v_array)) then
  if (.not. allocated (v_array)) allocate (v_array(0))
endif
if (present(re_array)) then
  if (.not. allocated (re_array)) allocate (re_array(0))
endif
if (present(log_array)) then
  if (.not. allocated (log_array)) allocate (log_array(0))
endif
if (present(str_array)) then
  if (.not. allocated (str_array)) allocate (str_array(0))
endif

!----------------------------------------------------------------------------
contains

subroutine find_this_var (v1, name, this_err)

type (tao_v1_var_struct) :: v1
type (tao_var_array_struct), allocatable, save :: va(:)
type (tao_real_pointer_struct), allocatable, save :: ra(:)
type (tao_logical_array_struct), allocatable, save :: la(:)
type (tao_string_array_struct), allocatable, save  :: sa(:)

integer i, j, nd, nl, i1, i2, num

character(*) name
character(40), allocatable, save :: names(:)
character(80) v1_name, v_name

logical this_err
logical, allocatable, save :: list(:)

!

if (allocated(list)) deallocate(list, names)
i1 = lbound(v1%v, 1)
i2 = ubound(v1%v, 1)
allocate (list(i1:i2), names(i1:i2))
this_err = .false.

if (name == '*') then
  list = .true.

else
  do i = i1, i2
    names(i) = v1%v(i)%ele_name
  enddo
  call location_decode (name, list, i1, num, names)
  if (num <  0) then
    call out_io (s_error$, r_name, "BAD VAR INDEX NUMBER(S): " // name)
    this_err = .true.
    return  
  endif
endif

err = .false.
nl = count(list)

! real array

if (present(v_array)) then

  if (allocated(v_array)) then
    nd = size(v_array)
    allocate (va(nd))
    va = v_array
    deallocate(v_array)
    allocate (v_array(nl+nd))
    j = nd
    v_array(1:nd) = va
    deallocate(va)
  else
    allocate (v_array(nl))
    j = 0
  endif

  do i = i1, i2
    if (list(i)) then
      j = j + 1
      v_array(j)%v => v1%v(i)
    endif
  enddo

endif

! real component array

if (present(re_array) .and.  any(component_name == real_components)) then

  if (allocated(re_array)) then
    nd = size(re_array)
    allocate (ra(nd))
    ra = re_array
    deallocate(re_array)
    allocate (re_array(nl+nd))
    j = nd
    re_array(1:nd) = ra
    deallocate(ra)
  else
    allocate (re_array(nl))
    j = 0
  endif

  do i = i1, i2
    if (list(i)) then
      j = j + 1
      select case (component_name)
      case ('model')
        re_array(j)%r => v1%v(i)%model_value
      case ('base')
        re_array(j)%r => v1%v(i)%base_value
      case ('design')
        re_array(j)%r => v1%v(i)%design_value
      case ('meas')
        re_array(j)%r => v1%v(i)%meas_value
      case ('ref')
        re_array(j)%r => v1%v(i)%ref_value
      case ('old')
        re_array(j)%r => v1%v(i)%old_value
      case ('step')
        re_array(j)%r => v1%v(i)%step
      case ('weight')
        re_array(j)%r => v1%v(i)%weight
      case ('high_lim')
        re_array(j)%r => v1%v(i)%high_lim
      case ('low_lim')
        re_array(j)%r => v1%v(i)%low_lim
      case default
        call out_io (s_fatal$, r_name, "INTERNAL ERROR: REAL VAR")
        call err_exit
      end select
    endif
  enddo

endif

! logical component array

if (present(log_array) .and. any(component_name == logic_components)) then

  if (allocated(log_array) .and. component_here) then
    nd = size(log_array)
    allocate (la(nd))
    la = log_array
    deallocate(log_array)
    allocate (log_array(nl+nd))
    j = nd
    log_array(1:nd) = la
    deallocate(la)
  else
    allocate (log_array(nl))
    j = 0
  endif

  do i = i1, i2
    if (list(i)) then
      j = j + 1
      select case (component_name)
      case ('exists')
        log_array(j)%l => v1%v(i)%exists
      case ('good_var')
        log_array(j)%l => v1%v(i)%good_var
      case ('good_user')
        log_array(j)%l => v1%v(i)%good_user
      case ('good_opt')
        log_array(j)%l => v1%v(i)%good_opt
      case ('good_plot')
        log_array(j)%l => v1%v(i)%good_plot
      case default
        call out_io (s_fatal$, r_name, "INTERNAL ERROR: LOGIC VAR")
        call err_exit
      end select
    endif
  enddo

endif

! string component array

if (present(str_array) .and. any(component_name == string_components)) then

  if (allocated(str_array) .and. component_here) then
    nd = size(str_array)
    allocate (sa(nd))
    sa = str_array
    deallocate(str_array)
    allocate (str_array(nl+nd))
    j = nd
    str_array(1:nd) = sa
    deallocate(sa)
  else
    allocate (str_array(nl))
    j = 0
  endif

  do i = i1, i2
    if (list(i)) then
      j = j + 1
      select case (component_name)
      case ('merit_type')
        str_array(j)%s => v1%v(i)%merit_type
      case default
        call out_io (s_fatal$, r_name, "INTERNAL ERROR: STRING VAR")
        call err_exit
      end select
    endif
  enddo

endif

end subroutine find_this_var

end subroutine tao_find_var

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_var_target_calc ()
! 
! Subroutine to calculate the variable target values (the values that they need
! to be set to to do a correction of the orbit, phase, etc.
!
! Input:
!
! Output:
!-

subroutine tao_var_target_calc ()

implicit none

type (tao_var_struct), pointer :: var

integer i, j

!

do j = 1, size(s%var)
  var => s%var(j)
  var%correction_value = var%meas_value + (var%design_value - var%model_value)
enddo

end subroutine tao_var_target_calc

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_set_var_model_value (var, value)
!
! Subroutine to set the value for a model variable and do the necessary bookkeeping.
!
! Input:
!   var   -- Tao_var_struct: Variable to set
!   value -- Real(rp): Value to set to
!-

subroutine tao_set_var_model_value (var, value)

implicit none

type (tao_var_struct), target :: var
type (tao_this_var_struct), pointer :: t

real(rp) value
integer i

!

if (.not. (var%exists .and. var%good_var)) return

! check if hit variable limit
if (s%global%var_limits_on) then
  if (value .lt. var%low_lim) then
    call out_io (s_blank$, ' ', "Hit lower limit of variable: " // tao_var1_name(var))
    value = var%low_lim
  elseif (value .gt. var%high_lim) then
    call out_io (s_blank$, ' ', "Hit upper limit of variable: " // tao_var1_name(var))
    value = var%high_lim
  endif
endif

var%model_value = value
do i = 1, size(var%this)
  t => var%this(i)
  t%model_value = value
  call changed_attribute_bookkeeper (s%u(t%ix_uni)%model%lat, t%ix_ele, t%model_value)
  if (tao_com%common_lattice .and.  t%ix_uni == ix_common_uni$) then
    s%u(:)%universe_recalc = .true.
  else
    s%u(t%ix_uni)%universe_recalc = .true.
  endif
enddo

tao_com%lattice_recalc = .true.

end subroutine tao_set_var_model_value

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! subroutine tao_count_strings (string, pattern, num)
! 
! Subroutine to count the number of a specific pattern in the string
!
! Input:    
!  string    -- character(*): the string to look at
!  pattern   -- character(*): the search pattern
!
! Output:
!  num       -- integer: number of occurances
!-

subroutine tao_count_strings (string, pattern, num)

implicit none

character(*) string, pattern

integer num, len_string, len_pattern, i

num = 0
len_pattern = len(pattern)
len_string  = len(string)

do i = 1, len(string)
  if (i+len_pattern-1 .gt. len_string) return
  if (string(i:i+len_pattern-1) .eq. pattern) num = num + 1
enddo

end subroutine tao_count_strings

!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!----------------------------------------------------------------------------
!+
! Subroutine tao_lat_bookkeeper (u, tao_lat)
!
! This will make sure all bookkeeping is up to date.
!
! Input:
!  u            -- tao_universe_struct
!  lat_name     -- Integer: Which lattice
!
! Output:
!  tao_lat      -- lat_struct
!-

subroutine tao_lat_bookkeeper (u, tao_lat)

implicit none

type (tao_universe_struct), target :: u
type (tao_lattice_struct) :: tao_lat

integer i, j

character(20) :: r_name = "tao_lat_bookkeeper"

! Setup from common if it exists

if (associated(u%common)) then

  ! First put in the common values

  do i = 1, size(s%var)
    do j = 1, size(s%var(i)%this)
      s%var(i)%this(j)%model_value = s%var(i)%common%model_value
      s%var(i)%this(j)%base_value  = s%var(i)%common%base_value
    enddo
  enddo

  ! Then put in the values for this universe

  do i = 1, size(s%var)
    do j = 1, size(s%var(i)%this)
      if (s%var(i)%this(j)%ix_uni /= u%ix_uni) cycle
      s%var(i)%this(j)%model_value = s%var(i)%model_value
      s%var(i)%this(j)%base_value = s%var(i)%base_value
    enddo
  enddo

endif

! Do bookkeeping

call lattice_bookkeeper (tao_lat%lat)

end subroutine tao_lat_bookkeeper

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!+
! Function tao_read_this_index (name, ixc) result (ix)
!
! Returns the integer value in the array <name> at position <ixc>. This is used
! for finding a 6-dimensional index reference so any value at <ixc> greater than
! 6 returns an error.
!
! Input:
!  name     -- Character(*): character array holding the index
!  ixc      -- Integer: location within <name> to evaluate
!
! Output:
!  ix       -- Integer: Index at <name>(<ixc>:<ixc>)
!
! Example:
!      name = r:26
!      ixc  = 3
!
! Gives:
!      ix = 3
!
! Example:
!      name = mat_94
!      ixc  = 7
! Gives:
!      Error: "BAD INDEX CONSTRAINT: mat_94"
!-

function tao_read_this_index (name, ixc) result (ix)

  character(*) name
  integer ix, ixc
  character(20) :: r_name = 'tao_read_this_index'

  ix = index('123456', name(ixc:ixc))
  if (ix == 0) then
    call out_io (s_abort$, r_name, 'BAD INDEX CONSTRAINT: ' // name)
    call err_exit
  endif

end function


!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
! Function tao_var1_name(var) result (var1_name)
!
! Function to return the variable name in the form:
!   var1_name[index]
! For example:
!   quad_k1[23]
!
! Input:
!   var -- Tao_var_struct: Variable
!
! Output:
!   var1_name -- Character(60): Appropriate name.
!-

function tao_var1_name(var) result (var1_name)

implicit none

type (tao_var_struct) var
character(60) var1_name

!

write (var1_name, '(2a, i0, a)') trim(var%v1%name), '[', var%ix_v1, ']'

end function

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
! Function tao_var_attrib_name(var) result (var_attrib_name)
!
! Function to return the variable name in the form:
!   element[attribute]
! For example:
!   Q03W[k1]
!
! Input:
!   var -- Tao_var_struct: Variable
!
! Output:
!   var_attrib_name -- Character(60): Appropriate name.
!-

function tao_var_attrib_name(var) result (var_attrib_name)

implicit none

type (tao_var_struct) var
character(60) var_attrib_name

!

write (var_attrib_name, '(4a)') trim(var%ele_name), '[', trim(var%attrib_name), ']'

end function

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
! Function tao_datum_type_name (datum) result (datum_name)
!
! Function to return the datum type. For example
!   eta.x target   
!
! Input:
!   datum      -- Tao_data_struct: Datum
!
! Output:
!   datum_name -- Character(60): Appropriate name.
!-

function tao_datum_type_name(datum) result (datum_name)

implicit none

type (tao_data_struct) datum
character(200) datum_name
integer ix

! Expressions are too long so shorten the name

datum_name = trim(datum%data_type) // ' <' // trim(datum%merit_type) // '>'
if (datum_name(1:11) == 'expression:') call string_trim (datum_name(12:), datum_name, ix)

end function

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
! Function tao_datum_name (datum, show_universe) result (datum_name)
!
! Function to return the datum name in the form:
!   d2_name.d1_name[index]
! or (if show_universe is True and there is more than one universe):
!   universe@d2_name.d1_name[index]
! For example:
!   2@orbit.x[23]
!   
!
! Input:
!   datum         -- Tao_data_struct: Datum
!   show_universe -- Logical, optional: Show the datum's universe.
!                       Default is True.
!
! Output:
!   datum_name -- Character(60): Appropriate name.
!-

function tao_datum_name(datum, show_universe) result (datum_name)

implicit none

type (tao_data_struct) datum
character(60) datum_name
logical, optional :: show_universe

! If this datum is "isolated". That is, it does not have an associated d1_data 
! structure then just use it's data_type.
! This can happen if the datum is derived from a curve.

if (.not. associated(datum%d1)) then
  datum_name = datum%data_type
  return
endif

! Normal case

datum_name = tao_d2_d1_name (datum%d1, show_universe)
write (datum_name, '(2a, i0, a)') trim(datum_name), '[', datum%ix_d1, ']'

end function

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
! Function tao_d2_d1_name (d1, show_universe) result (d2_d1_name)
!
! Function to return the datum name in the form:
!   d2_name.d1_name
! If there is only one d1_data array associated with the d2_data 
! array then the name is shortened to:
!   d2_name
! Additionally, if show_universe is True and there is more than one universe
! then "universe@" is prepended to the name.
! For example:
!   2@orbit.x
!   
!
! Input:
!   d1            -- Tao_d1_data_struct: Data array.
!   show_universe -- Logical, optional: Show the datum's universe.
!                       Default is True.
!
! Output:
!   d2_d1_name -- Character(60): Appropriate name.
!-

function tao_d2_d1_name(d1, show_universe) result (d2_d1_name)

implicit none

type (tao_d1_data_struct) d1
character(60) d2_d1_name
logical, optional :: show_universe

! If there is only one d1 array associated with the d2_data array then
! drop the d1 name.

if (size(d1%d2%d1) == 1) then
  write (d2_d1_name, '(a)') trim(d1%d2%name)
else
  write (d2_d1_name, '(3a)') trim(d1%d2%name), '.', trim(d1%name)
endif

!

if (size(s%u) > 1 .and. logic_option(.true., show_universe)) &
       write (d2_d1_name, '(i0, 2a)') d1%d2%ix_uni, '@', trim(d2_d1_name)

end function

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
! Function tao_curve_name (curve, use_region) result (curve_name)
!
! Function to return the curve name in the form:
!   plot_name.graph_name.curve_name
! For example:
!   orbit.x.c1
!
! Input:
!   curve      -- Tao_curve_struct: Curve
!   use_region -- Logical: If present and True then use the region 
!                  name instead of the plot name. Region name is
!                  'NULL_REGION' if there is no assocaited region.
!
! Output:
!   curve_name -- Character(60): Appropriate name.
!-

function tao_curve_name(curve, use_region) result (curve_name)

implicit none

type (tao_curve_struct) curve
character(60) curve_name
logical, optional :: use_region

!

curve_name = '.' // trim(curve%g%name) // '.' // trim(curve%name)

if (logic_option(.false., use_region)) then
  if (associated(curve%g%p%r)) then
    curve_name = trim(curve%g%p%r%name) // trim(curve_name)
  else
    curve_name = 'NULL_REGION' // trim(curve_name)
  endif
else
    curve_name = trim(curve%g%p%name) // trim(curve_name)
endif

end function

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!+
! Function tao_universe_number (i_uni) result (i_this_uni)
!
! Fnction to return the universe number.
! i_this_uni = i_uni except when i_uni is -1. 
! In this case i_this_uni = s%global%u_view.
!
! Input:
!   i_uni -- Integer: Nominal universe number.
!
! Output:
!   i_this_uni -- Integer: Universe number. 
!-

function tao_universe_number (i_uni) result (i_this_uni)

implicit none

integer i_uni, i_this_uni

i_this_uni = i_uni
if (i_uni == -1) i_this_uni = s%global%u_view

end function

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!+
! Subroutine tao_parse_command_args (error, cmd_words)
!
! Subroutine to parse the command line arguments.
!
! Input:
!   cmd_words(:) -- Character(*), optional: If present then this is used
!                    in place of the command line.
! Output:
!   error -- Logical: Set True if there is an error. False otherwise.
!-

subroutine tao_parse_command_args (error, cmd_words)

  implicit none

  character(*), optional :: cmd_words(:)
  character(80) arg0
  character(24) :: r_name = 'tao_parse_command_args'

  integer n_arg, i_arg
  logical error, is_set

! Get command line input

  error = .false.

  call tao_hook_parse_command_args(is_set)
  if (is_set) return

  if (present(cmd_words)) then
    n_arg = size(cmd_words)
    if (cmd_words(1) == '') return
  else
    n_arg = cesr_iargc()
    if (n_arg == 0) return
  endif


! since there are arguments reset things to their initial state

  tao_com%init_tao_file  = tao_com%default_init_tao_file
  tao_com%beam_all_file  = ''
  tao_com%beam0_file     = ''
  tao_com%init_lat_file  = ''

! loop over all arguments

  i_arg = 0

  do 

    if (i_arg == n_arg) exit
    call get_next_arg (arg0)

    select case (arg0)
    case ('-init')
      call get_next_arg (tao_com%init_tao_file)

    case ('-beam_all')
      call get_next_arg (tao_com%beam_all_file)

    case ('-beam0')
      call get_next_arg (tao_com%beam0_file)

    case ('-lat')
      call get_next_arg (tao_com%init_lat_file)

    case ('help', '-help')
      call out_io (s_blank$, r_name, (/ &
          'Switches:', &
          '  -init <tao_init_file>', &
          '  -lat <bmad_lattice_file>', &
          '  -beam_all <beam_all_file>', &
          '  -beam0 <beam_init_file>' /) )
      stop

    case ('')
      exit

    case default
      call out_io (s_error$, r_name, 'BAD COMMAND LINE ARGUMENT: ' // arg0)
      call out_io (s_blank$, r_name, (/ &
          'Switches:', &
          '  -init <tao_init_file>', &
          '  -lat <bmad_lattice_file>', &
          '  -beam_all <beam_all_file>', &
          '  -beam0 <beam_init_file>' /) )
      error = .true.
      return
    end select

  enddo

!-----------------------------
contains

subroutine get_next_arg(arg)

  character(*) arg

!

  if (i_arg == n_arg) then
    call out_io (s_error$, r_name, &
                      'MISSING COMMAND LINE ARGUMENT FOR: ' // arg0)
    error = .true.
    return
  endif

  i_arg = i_arg + 1

  if (present(cmd_words)) then
    arg = cmd_words(i_arg)
  else
    call cesr_getarg(i_arg, arg)
  endif

end subroutine get_next_arg

end subroutine tao_parse_command_args


!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!+
! Function tao_pointer_to_universe (ix_uni) result (u)
!
! Routine to set a pointer to a universe.
! If ix_uni is -1 then u(s%global%u_view) will be used.
!
! Input:
!   ix_uni -- Integer: Index to the s%u(:) array
!
! Output:
!   u      -- Tao_universe_struct, pointer: Universe pointer.
!               u will be nullified if ix_uni is out of range.
!               If not present then print a message and exit program.
!-

function tao_pointer_to_universe (ix_uni) result(u)

implicit none

type (tao_universe_struct), pointer :: u
integer ix_uni, ix_u
character(28) :: r_name = 'tao_pointer_to_universe'

!

ix_u = tao_universe_number(ix_uni)

if (ix_u < lbound(s%u, 1) .or. ix_u > ubound(s%u, 1)) then
  call out_io (s_fatal$, r_name, 'UNIVERSE INDEX OUT OF RANGE: \I0\ ', ix_u)
  nullify (u)
  return
endif

u => s%u(ix_u)

end function tao_pointer_to_universe

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!+
! Subroutine tao_ele_ref_to_ele_ref_track (ix_universe, ix_ele_ref, ix_ele_ref_track)
!
! Subroutine to compute ix_ele_ref_track:
!   = ix_ele_ref             if ix_ele_ref <= lat%n_ele_track
!   = ix_slave_at_exit_end   if ix_ele_ref is a super_lord  
!   = -1                     otherwise
!
! Input:
!   ix_universe -- Integer: Universe index.
!   ix_ele_ref  -- Integer: Element index
!
! Output:
!   ix_ele_ref_track -- Integer: Corresponding element in the tracking 
!                         part of the lattice.
!-

subroutine tao_ele_ref_to_ele_ref_track (ix_universe, ix_ele_ref, ix_ele_ref_track)

implicit none

type (lat_struct), pointer :: lat

integer ix_universe, ix_ele_ref, ix_ele_ref_track
integer i_uni, ix_c

!

i_uni = tao_universe_number(ix_universe)
lat => s%u(i_uni)%model%lat

if (ix_ele_ref < 0) then
  ix_ele_ref_track = -1

elseif (ix_ele_ref <= lat%n_ele_track) then
  ix_ele_ref_track = ix_ele_ref

elseif (lat%ele(ix_ele_ref)%lord_status == super_lord$) then
  ix_c = lat%ele(ix_ele_ref)%ix2_slave
  ix_ele_ref_track = lat%control(ix_c)%ix_slave ! element at exit end.

else  ! overlays, multipass_lords, etc.
  ix_ele_ref_track = -1
endif

end subroutine tao_ele_ref_to_ele_ref_track

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!+
! Subroutine tao_ele_locations_given_name (u, name, loc, err, print_err)
!
! Subroutine to find the locations of all elements in lat%ele(:)
! that match name where name is in the form "class:ele_name".
!
! Input:
!   u         -- Universe_struct: Universe with lattice.
!   name      -- Character(*): Name in the form "class:ele_name".
!   print_err -- Logical, optional: If True then print an error message if 
!                 there is a problem. Default is True.
!
! Output:
!   loc(:)  -- Integer, allocatable: indexes of elements whose
!                lat%ele(i)%name corresponds to name. 
!                loc will be allocated  as needed.
!                If there is an error size(loc) = 0.
!   err     -- Logical: Set True if format of name is bad. 
!                Set False otherwise.
!-

subroutine tao_ele_locations_given_name (u, name, loc, err, print_err)

implicit none

type (tao_universe_struct), target :: u
type (lat_struct), pointer :: lat

integer i, n, ix_class

character(*) name
character(40) ele_name

integer, allocatable :: loc(:)
logical, optional :: print_err
logical err

!

call tao_string_to_element_id (name, ix_class, ele_name, err, print_err)
if (err) then
  call re_allocate (loc, 0)
  return
endif

n = 0
lat => u%design%lat
do i = 0, lat%n_ele_max
  if (ix_class /= 0 .and. ix_class /= lat%ele(i)%key) cycle
  if (.not. match_wild(lat%ele(i)%name, ele_name)) cycle
  n = n + 1
  u%ele(n)%ixx = i
enddo

call re_allocate (loc, n)
do i = 1, n
  loc(i) = u%ele(i)%ixx
enddo

end subroutine tao_ele_locations_given_name

!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!+
! Subroutine tao_string_to_element_id (str, ix_class, ele_name, err, print_err)
!
! Routine to split a string in the form str = "xxx:yyy" into an element class
! and an element name. Example: 
!   str = "quad:q*".
! gives
!   ix_class = quadrupole$
!   ele_name = "Q*"
!
! If ":" is not found then ix_class is set to 0 (all classes).
! If str is of the form: "*:yyy" then ix_class is set to 0 (all classes).
! Class abbreviations and lower case names accepted 
! ele_name will be converted to upper case
!
! Input:
!   str       -- Character(*): Character string to parse.
!   print_err -- Logical, optional: If True then print an error message if 
!                 there is a problem. Default is True.
!
! Output:
!   ix_class  -- Integer: Element class. 0 => all classes.
!   ele_name  -- Character(*): Element name.
!   err       -- Set true if there is a problem translating the element class.
!-

subroutine tao_string_to_element_id (str, ix_class, ele_name, err, print_err)

implicit none

integer ix, ix_class

character(*) str, ele_name
character(40) :: r_name = 'tao_string_to_element_id'
character(20) class

logical, optional :: print_err
logical err

!

err = .false.

ix = index(str, ':')

if (ix == 0) then
  ix_class = 0
  ele_name = str
  call str_upcase (ele_name, ele_name)
  return
endif

class = str(:ix-1)
ele_name = str(ix+1:)
call str_upcase (ele_name, ele_name)

if (class == '*') then
  ix_class = 0
  return
endif

ix_class = key_name_to_key_index (class, .true.)
if (ix_class < 1) then
  if (logic_option (.true., print_err)) &
                        call out_io (s_error$, r_name, 'BAD CLASS NAME: ' // class)
  err = .true.
endif

end subroutine tao_string_to_element_id

!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!--------------------------------------------------------------------------

subroutine floor_to_screen_coords (floor, screen)

implicit none

type (floor_position_struct) floor, screen

!

call floor_to_screen (floor%x, floor%y, floor%z, screen%x, screen%y)
screen%theta = pi + floor%theta

end subroutine floor_to_screen_coords

!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!--------------------------------------------------------------------------

subroutine floor_to_screen (x_floor, y_floor, z_floor, x_screen, y_screen)

implicit none

real(rp) x_floor, y_floor, z_floor, x_screen, y_screen

! Mapping from floor coords to screen coords is:
!   Floor   Screen 
!    z   ->  -x
!    x   ->  -y

x_screen = -z_floor
y_screen = -x_floor

end subroutine floor_to_screen

!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!+
! Subroutine tao_split_component (comp_str, comp, err)
!
! Routine to split a component string.
!
! Input:
!   comp_str -- Character(*): Components. EG: 'meas - design'
!
! Output:
!   comp(:) -- Tao_data_var_component_struct, allocatable: Array of individual components.
!   err     -- Logical: Set True if there is an error, False otherwise.
!-

subroutine tao_split_component (comp_str, comp, err)

type (tao_data_var_component_struct), allocatable :: comp(:)

integer i, n, ix

character(*) comp_str
character(60) str
character(40) :: r_name = 'tao_split_component'

logical err

! Count number of components.

err = .true.
call string_trim (comp_str, str, ix)
if (.not. (str(1:1) == '+' .or. str(1:1) == '-')) str = '+' // trim(str)

n = 0
do i = 1, len_trim(str)
  if (str(i:i) == '+' .or. str(i:i) == '-') n = n + 1
enddo

! Allocate space and transfer info.

if (allocated(comp)) then
  if (size(comp) /= n) deallocate (comp)
endif
if (.not. allocated(comp)) allocate (comp(n))

n = 0
do n = 1, size(comp)
  if (str(1:1) == '+') then
    comp(n)%sign = 1
  elseif (str(1:1) == '-') then
    comp(n)%sign = -1
  else
    call out_io (s_error$, r_name, 'BAD COMPONENT LIST: ' // comp_str)
    return
  endif

  call string_trim(str(2:), str, ix)
  comp(n)%name = str(1:ix)
  call string_trim(str(ix+1:), str, ix)

enddo

err = .false.

end subroutine tao_split_component

!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!+
! Subroutine tao_turn_on_rad_int_calc_if_needed_for_plotting ()
! 
! Routine to set u%dynch_rad_int_clac = T if needed for a plot.
!-

subroutine tao_turn_on_rad_int_calc_if_needed_for_plotting ()

type (tao_universe_struct), pointer :: u
type (tao_graph_struct), pointer :: graph
type (tao_curve_struct), pointer :: curve

integer i, j, k
logical do_synch

!

do_synch = .false.
do i = 1, size(s%plot_region)
  if (.not. s%plot_region(i)%visible) cycle
  do j = 1, size(s%plot_region(i)%plot%graph)
    graph => s%plot_region(i)%plot%graph(j)
    do k = 1, size(graph%curve)
      curve => graph%curve(k)
      u => tao_pointer_to_universe(curve%ix_universe)
      
      if ((index(curve%data_type, 'emit.') /= 0) .and. &
                        curve%data_source == 'lattice') do_synch = .true. 
      if (curve%data_type(1:2) == 'i5') do_synch = .true.
    enddo
  enddo
enddo

if (do_synch .and. .not. u%do_synch_rad_int_calc) then
  u%do_synch_rad_int_calc = .true. 
  tao_com%lattice_recalc = .true.
endif

end subroutine tao_turn_on_rad_int_calc_if_needed_for_plotting

end module tao_utils
