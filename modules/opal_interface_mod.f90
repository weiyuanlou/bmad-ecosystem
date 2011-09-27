module opal_interface_mod

use bmad_struct
use bmad_interface
use write_lat_file_mod


contains

!------------------------------------------------------------------------------------------------
!------------------------------------------------------------------------------------------------
!------------------------------------------------------------------------------------------------


!------------------------------------------------------------------------
!------------------------------------------------------------------------
!------------------------------------------------------------------------
!+ 
! Subroutine write_opal_lattice_file (opal_file_unit, lat, err)
!
! Subroutine to write an OPAL lattice file using the information in
! a lat_struct. Optionally only part of the lattice can be generated.
!
! Modules needed:
!   ?? use write_lat_file_mod
!
! Input:
!   opal_file_unit -- Integer: unit number to write to
!   lat            -- lat_struct: Holds the lattice information.
!   ix_start       -- Integer, optional: Starting index of lat%ele(i)
!                        used for output.
!   ix_end         -- Integer, optional: Ending index of lat%ele(i)
!                       used for output.
!
! Output:
!   err    -- Logical, optional: Set True if, say a file could not be opened.
!-

subroutine write_opal_lattice_file (opal_file_unit, lat, err, opal_ix_start, opal_ix_end)

implicit none


type (ele_struct), pointer :: ele
type (lat_struct), target :: lat

real(rp), pointer :: val(:)

integer			:: opal_file_unit
integer,  optional :: opal_ix_start, opal_ix_end
character(200)	:: file_name
character(40)	:: r_name = 'write_opal_lattice_file', name
character(2) 	:: continue_char, eol_char, comment_char
character(24)	:: rfmt
character(4000)	:: line
integer			:: iu,  ios, ix_match, ie, ix_start, ix_end, iu_fieldgrid
integer			:: n_names, n
integer 		:: q_sign
character(40), allocatable :: names(:)
integer, allocatable :: an_indexx(:), name_occurrences(:)


real(rp)        :: absmax_Ez
character(40)   :: fieldgrid_output_name
character(200), allocatable :: fieldgrid_names(:)
integer			:: fieldgrid_n_names
integer, allocatable :: fieldgrid_an_indexx(:), fieldgrid_name_occurrences(:)


logical, optional :: err

if (present(err)) err = .true.

!If unit number is zero, make a new file
if (opal_file_unit == 0 ) then
	! Open the file
	iu = lunget()	
	call file_suffixer (lat%input_file_name, file_name, 'opal', .true.)
	open (iu, file = file_name, iostat = ios)
	if (ios /= 0) then
	  	call out_io (s_error$, r_name, 'CANNOT OPEN FILE: ' // trim(file_name))
  		return
  	endif
else
	iu = opal_file_unit
endif


!OPAL formatting characters
comment_char = '//'
continue_char = ''
eol_char = ';'


!Elements to write
!Get optional start index
if (present(opal_ix_start) ) then 
	ix_start = opal_ix_start
else
	ix_start = 1
end if
!Get optional end index
if (present(opal_ix_end) ) then 
	ix_end = opal_ix_end
else
	ix_end = lat%n_ele_track
end if

!Check order
if (ix_start > ix_end) then
  call out_io (s_error$, r_name, 'Bad index range')
  return
endif

!Initialize unique name list
n = ix_end - ix_start + 1
allocate ( names(n), an_indexx(n), name_occurrences(n) )
name_occurrences = 0
n_names = 0

!Initialize fieldgrid filename list
n = ix_end - ix_start + 1
allocate ( fieldgrid_names(n), fieldgrid_an_indexx(n), fieldgrid_name_occurrences(n) )
fieldgrid_name_occurrences = 0
fieldgrid_n_names = 0


!-------------------------------------------
! Write info to the output file...
! lat lattice name

write (iu, '(2a)') comment_char, ' Generated by: write_opal_lattice_file'
write (iu, '(3a)') comment_char, ' Bmad Lattice File: ', trim(lat%input_file_name)
write (iu, '(3a)') comment_char, ' Bmad Lattice Name: ', trim(lat%lattice)
write (iu, *)

!Helper variables
!sign of particle charge
q_sign = sign(1,  charge_of(lat%param%particle) ) 

!Loop over all elements
ele_loop: do ie = ix_start, ix_end
	ele => lat%ele(ie)
	!point to value array for convenience
	val => ele%value
	
	
	!Make unique names	
    call find_indexx (ele%name, names, an_indexx, n_names, ix_match)
    if (ix_match > 0) then
    	name_occurrences(ix_match) = name_occurrences(ix_match) + 1
    	!Replace ele%name with a unique name
    	write(ele%name, '(2a,i0)') trim(ele%name), '_', name_occurrences(ix_match) 
    	!Be careful with this internal write statement
    	!This only works because ele%name is first in the write list
	end if
    !add name to list  
    call find_indexx (ele%name, names, an_indexx, n_names, ix_match, add_to_list = .true.)
    n_names = n_names + 1

	!Format for numbers
	rfmt = 'es13.5'


	!----------------------------------------------------------
	!----------------------------------------------------------
	!Element attributes
	select case (ele%key)

	!----------------------------------------------------------
	!Marker -----------------------------------
	!----------------------------------------------------------
    case (marker$)
        write (line, '(a)' ) trim(ele%name) // ': marker'
      !Write ELEMEDGE
      call value_to_line (line, ele%s - val(L$), 'elemedge', rfmt, 'R', .false.)

	!----------------------------------------------------------
	!Drift -----------------------------------   
	!----------------------------------------------------------
     case (drift$, instrument$)
        write (line, '(a, ' // rfmt //')' ) trim(ele%name) // ': drift, l =', val(l$)
      !Write ELEMEDGE
      call value_to_line (line, ele%s - val(L$), 'elemedge', rfmt, 'R', .false.)

	!----------------------------------------------------------
	!Sbend -----------------------------------       
	!----------------------------------------------------------
     case (sbend$)
        write (line, '(a, '//rfmt//')') trim(ele%name) // ': sbend, l =', val(l$)
        call value_to_line (line, val(b_field$), 'k0', rfmt, 'R')
        call value_to_line (line, val(e_tot$), 'designenergy', rfmt, 'R')
        call value_to_line (line, val(e1$), 'E1', rfmt, 'R')
        call value_to_line (line, val(e2$), 'E2', rfmt, 'R')
		call value_to_line (line, ele%s - val(L$), 'elemedge', rfmt, 'R', .false.)
		!TODO: Field map must be specified!
		
		
	!----------------------------------------------------------
	!Quadrupole -----------------------------------   
	!----------------------------------------------------------
     case (quadrupole$)
        write (line, '(a, es13.5)') trim(ele%name) // ': quadrupole, l =', val(l$)
        !Note that OPAL-T has k1 = dBy/dx, and that bmad needs a -1 sign for electrons
        call value_to_line (line, q_sign*val(b1_gradient$), 'k1', rfmt, 'R')
		call value_to_line (line, ele%s - val(L$), 'elemedge', rfmt, 'R', .false.)
		
	!----------------------------------------------------------
	!Lcavity -----------------------------------
	!----------------------------------------------------------
    case (lcavity$)
      !Check that there is a map or grid associated to make a decent field grid for OPAL
	  if (.not. associated(ele%rf%field)  )then
	    call out_io (s_error$, r_name, 'No rf_field_struct for: ' // key_name(ele%key), &
                                     '----')
        call err_exit
      endif
	  if (.not. associated(ele%rf%field%mode(1)%grid)  )then
	    call out_io (s_error$, r_name, 'No grid for: ' // key_name(ele%key), &
                                     '----')
        call err_exit
      endif
      
      write (line, '(a, es13.5)') trim(ele%name) // ': rfcavity, type = "STANDING", l =', val(l$)

      !Check field map file. If file has not been written, create a new file. 
      call find_indexx (ele%rf%field%mode(1)%grid%file, fieldgrid_names, fieldgrid_an_indexx, fieldgrid_n_names, ix_match)
      !Check for match with existing grid
      if (ix_match > 0) then
        !File exists. 
          fieldgrid_name_occurrences(ix_match) = fieldgrid_name_occurrences(ix_match) + 1
          fieldgrid_output_name = ''
          write(fieldgrid_output_name, '(a, i0, a)') 'fieldgrid_', ix_match, '.t7'
          !Get maximum field for "VOLT =" by calling write_opal_field_grid_file with 0 file unit number
          call write_opal_field_grid_file (0, ele, lat%param, absmax_Ez)
      else
        !File does not exist.
        
        !Add name to list  
        call find_indexx (ele%rf%field%mode(1)%grid%file, fieldgrid_names, fieldgrid_an_indexx, fieldgrid_n_names, ix_match, add_to_list = .true.)
        fieldgrid_n_names = fieldgrid_n_names + 1
        
        ! Write new fieldgrid file
        fieldgrid_output_name = ''
        write(fieldgrid_output_name, '(a, i0, a)') 'fieldgrid_', fieldgrid_n_names, '.t7'
	    iu_fieldgrid = lunget()
	    open (iu_fieldgrid, file = fieldgrid_output_name, iostat = ios)
	    	    call write_opal_field_grid_file (iu_fieldgrid, ele, lat%param, absmax_Ez)
	    close(iu_fieldgrid)
	  end if
	  !Add FMAPFN to line
      write (line, '(4a)') trim(line),  ', fmapfn = "', trim(fieldgrid_output_name), '"'
      
      !Write field scaling in MV/m
      call value_to_line (line, 1e-6*absmax_ez, 'volt', rfmt, 'R')
      
      !Write frequency in MHz
      call value_to_line (line, 1e-6*ele%rf%field%mode(1)%freq, 'freq', rfmt, 'R')
      
      !Write ELEMEDGE
      call value_to_line (line, ele%s - val(L$), 'elemedge', rfmt, 'R', .false.)
      

	!----------------------------------------------------------
	!Default -----------------------------------
	!----------------------------------------------------------
     case default
        call out_io (s_error$, r_name, 'UNKNOWN ELEMENT TYPE: ' // key_name(ele%key), &
             'CONVERTING TO DRIFT')
        write (line, '(a, es13.5)') trim(ele%name) // ': drift, l =', val(l$)
        !Write ELEMEDGE
        call value_to_line (line, ele%s - val(L$), 'elemedge', rfmt, 'R', .false.)
	end select
	
	!type (general attribute)
	if (ele%type /= '') write (line, '(4a)') trim(line), ', type = "', trim(ele%type), '"'
	
	!end line
	write (line, '(2a)') trim(line), trim(eol_char)

	!call write_opal_field_map()

	!----------------------------------------------------------
	!----------------------------------------------------------


	!Finally write out line
	call write_lat_line (line, iu, .true.)  
enddo ele_loop


!Write lattice line
write (iu, *)
line = 'lattice: line = ('

lat_loop: do ie = ix_start, ix_end
	 call write_line_element (line, iu, lat%ele(ie), lat)
enddo lat_loop		
!write closing parenthesis
line = line(:len_trim(line)-1) // ')' // eol_char
call write_lat_line (line, iu, .true.)



!Cleanup
deallocate (names, an_indexx, name_occurrences)

if (present(err)) err = .false.

end subroutine write_opal_lattice_file



!------------------------------------------------------------------------
!------------------------------------------------------------------------
!------------------------------------------------------------------------
!+ 
! Subroutine write_opal_field_grid_file (opal_file_unit, ele, param, maxfield, err)
!
! Subroutine to write an OPAL lattice file using the information in
! a lat_struct. Optionally only part of the lattice can be generated.
!
!
! Input:
!   opal_file_unit -- Integer: unit number to write to, if > 0
!                        if < 0, nothing is written, and only maxfield is returned
!   ele            -- ele_struct: element to make map
!   param          -- lat_param_struct: Contains lattice information
!
! Output:          
!   maxfield       -- Real(rp): absolute maximum found for element field scaling
!   err            -- Logical, optional: Set True if, say a file could not be opened.
!-



subroutine write_opal_field_grid_file (opal_file_unit, ele, param, maxfield, err)

implicit none


integer			:: opal_file_unit
integer         :: dimensions
type (ele_struct) :: ele
type (lat_param_struct) :: param
real(rp)        :: maxfield
logical, optional :: err

character(40)	:: r_name = 'write_opal_field_grid_file'
character(10)   ::  rfmt 


type (coord_struct) :: orb
type(em_field_struct) :: field_re, field_im
type (em_field_point_struct), allocatable :: pt(:,:,:)
type (em_field_point_struct) :: ref_field
real(rp) :: x_step, z_step, x_min, x_max, z_min, z_max
real(rp) :: freq, x, z, phase_ref
complex ::  phasor_rotation

integer :: nx, nz, iz, ix

real(rp) :: Ex_factor, Ez_factor, By_factor

logical loc_ref_frame

!
if (present(err)) err = .true.


loc_ref_frame = .true. 

!Format for numbers
  rfmt = 'es13.5'
  
select case (ele%key)

  case (lcavity$) 
                                         
    freq = ele%rf%field%mode(1)%freq

    !TODO: pass these parameters in somehow
    x_step = 0.001_rp
    z_step = 0.001_rp

    x_min = 0.0_rp
    x_max = 0.02_rp

    z_min = 0.0_rp
    z_max = ele%value(L$)

    nx = ceiling(x_max/x_step)  
    nz = ceiling(z_max/z_step)

  !Example
  !2DDynamic XZ
  !0.	100.955	743   #zmin(cm),  zmax(cm).   nz - 1
  !1300.              #freq (MHz)
  !-0.10158700000000001	4.793651666666666	11    # rmin(cm),  rmax(cm),   nr-1
  !
  !-547.601	-9.64135	0	-20287.798905810083   ! Ez(t0), Er(t0), dummy->0.0, -10^6 / mu_0 * B_phi (t + 1/4 1/f) 

  !Allocate temporary pt array
  allocate ( pt(0:nx, 0:nz, 1:1) )
  !Write data points
  
  !initialize maximum found field
  maxfield = 0
  
  do ix = 0, nx
    do iz = 0, nz
      x = x_step * ix
      z = z_step * iz 
      orb%vec(1) = x
      orb%vec(3) = 0.0_rp
      
      !Calculate field at \omegat*t=0 and \omega*t = \pi/2 to get real and imaginary parts
      call em_field_calc (ele, param, z, 0.0_rp,        orb, loc_ref_frame, field_re)
      call em_field_calc (ele, param, z, 0.25/freq , orb, loc_ref_frame, field_im)

      pt(ix, iz, 1)%E(:) = cmplx(field_re%E(:), field_im%E(:))
      pt(ix, iz, 1)%B(:) = cmplx(field_re%B(:), field_im%B(:))
      
      !Update ref_field if larger Ez is found
      !TODO: Opal may use Ex as well for scaling. Check this. 
      if(abs(pt(ix, iz, 1)%E(3)) > maxfield) then
         ref_field = pt(ix, iz, 1)
         maxfield = abs(ref_field%E(3))
      end if 
    end do
  end do
  
  ! Write to file
  if (opal_file_unit > 0 )  then

    !Write header
    write (opal_file_unit, '(3a)') ' 2DDynamic XZ', '  # Created from ele: ', trim(ele%name)
    write (opal_file_unit, '(2'//rfmt//', i8, a)') 100*z_min, 100*nz*z_step, nz, '  # z_min (cm), z_max (cm), n_z_points -1'
    write (opal_file_unit, '('//rfmt//', a)') 1e-6 * freq, '  # frequency (MHz)'
    write (opal_file_unit, '(2'//rfmt//', i8, a)') 100*x_min, 100*nx*x_step, nx, '  # x_min (cm), x_max (cm), n_x_points -1'

    !Scaling for T7 format
    Ex_factor = (1/maxfield)
    Ez_factor = (1/maxfield)
   By_factor = -(1/maxfield)*1e6_rp / ( fourpi * 1e-7)

  
    !Calculate complex rotation number to rotate Ez onto the real axis
    phase_ref = atan2( aimag(ref_field%E(3) ), real(ref_field%E(3) ) )
    phasor_rotation = cmplx(cos(phase_ref), -sin(phase_ref))
  
    do ix = 0, nx
      do iz = 0, nz
      
        write (opal_file_unit, '(4'//rfmt//')') Ez_factor * real ( pt(ix, iz, 1)%E(3) * phasor_rotation ), &
                                                Ex_factor * real ( pt(ix, iz, 1)%E(1) * phasor_rotation ), &
                                                0.0_rp, &
                                                By_factor * aimag (  pt(ix, iz, 1)%B(2)*phasor_rotation )
      enddo
    enddo
  
  end if
   
   
   deallocate(pt)
   
  case default
  call out_io (s_error$, r_name, 'MISSING OPAL FIELD GRID CODE FOR: ' // key_name(ele%key), &
             '----')
  call err_exit
  
  
  
end select 



end subroutine write_opal_field_grid_file

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine convert_particle_coordinates_t_to_s (particle, p0c, mc2, tref)
!
! Subroutine to convert particle coordinates from t-based to s-based system. 
!
! Modules needed:
!   use bmad
!
! Input:
!   particle   -- coord_struct: input particle
!   p0c        -- real: Reference momentum. The sign indicates direction of p_s. 
!   mc2        -- real: particle rest mass in eV
!   tref       -- real: reference time for z coordinate
! Output:
!    particle   -- coord_struct: output particle 
!-

subroutine convert_particle_coordinates_t_to_s (particle, p0c, mc2, tref)

!use bmad_struct

implicit none

type (coord_struct), intent(inout), target ::particle
real(rp), intent(in) :: p0c
real(rp), intent(in) :: mc2
real(rp), intent(in) :: tref

real(rp) :: pctot

real(rp), pointer :: vec(:)
vec => particle%vec

      !Convert t to s
      pctot = sqrt (vec(2)**2 + vec(4)**2 + vec(6)**2)
      !vec(1) = vec(1)   !this is unchanged
      vec(2) = vec(2)/abs(p0c)
      !vec(3) = vec(3)   !this is unchanged
      vec(4) = vec(4)/abs(p0c)
      vec(5) = -c_light * (pctot/sqrt(pctot**2 +mc2**2)) *  (particle%t - tref) !z \equiv -c \beta(s)  (t(s) -t_0(s)) 
      vec(6) = pctot/abs(p0c) - 1.0_rp

end subroutine convert_particle_coordinates_t_to_s

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!+
! Subroutine convert_particle_coordinates_s_to_t (particle, p0c)
!
! Subroutine to convert particle coordinates from s-based to t-based system. 
!     The sign of p0c indicates the direction of p_s
!
! Modules needed:
!   use bmad
!
! Input:
!   particle   -- coord_struct: input particle
!   p0c        -- real: Reference momentum. The sign indicates direction of p_s 
! Output:
!    particle   -- coord_struct: output particle 
!-

subroutine convert_particle_coordinates_s_to_t (particle, p0c)

!use bmad_struct

implicit none

type (coord_struct), intent(inout), target :: particle
real(rp), intent(in) :: p0c
real(rp), pointer :: vec(:)

vec => particle%vec

      !Convert s to t
      vec(6) = p0c * sqrt( ((1+vec(6)))**2 - vec(2)**2 -vec(4)**2 )
      !vec(1) = vec(1) !this is unchanged
      vec(2) = vec(2)*abs(p0c)
      !vec(3) = vec(3) !this is unchanged
      vec(4) = vec(4)*abs(p0c)
      vec(5) = particle%s
      

end subroutine convert_particle_coordinates_s_to_t


end module
