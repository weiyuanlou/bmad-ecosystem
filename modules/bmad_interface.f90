!+
! This file defines the interfaces for the BMAD subroutines
!-

!$Id$
!$Log$
!Revision 1.2  2001/09/27 18:32:13  rwh24
!UNIX compatibility updates
!

#include "CESR_platform.inc"


module bmad_interface

  interface
    subroutine accel_sol_mat_calc (ls, c_m, c_e, gamma_old, gamma_new, b_x,  &
        b_y, coord, mat4, vec_st)
      use bmad_struct
      implicit none
      type (coord_struct) coord
      real ls
      real c_m
      real c_e
      real gamma_old
      real gamma_new
      real b_x
      real b_y
      real mat4(4,4)
      real vec_st(4)
    end subroutine
  end interface

  interface
    subroutine add_superimpose (ring, super_ele, ix_super)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (ele_struct) super_ele
      integer ix_super
    end subroutine
  end interface

  interface
    function attribute_index (ele, name)
      use bmad_struct
      implicit none
      integer attribute_index
      type (ele_struct) ele
      character*(*) name
    end function
  end interface

  interface
    function attribute_name(ele, index)
      use bmad_struct
      implicit none
      character*16 attribute_name
      type (ele_struct) ele
      integer index
    end function
  end interface

  interface
    subroutine b_field_loop (coord, ele, s_pos, b_loop)
      use bmad_struct
      implicit none
      type (coord_struct) coord
      type (ele_struct) ele
      real s_pos
      real b_loop(3)
    end subroutine
  end interface

  interface
    subroutine b_field_mult (ring, coord, first, last, s_pos, b_vector)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (coord_struct) coord
      integer first
      integer last
      real s_pos(n_comp_maxx)
      real b_vector(3)
    end subroutine
  end interface

  interface
    subroutine back_to_under (output, input)
      implicit none
      character*(*) input
      character*(*) output
    end subroutine
  end interface

  interface
    subroutine Beta_Ave(ring, ix_ele, betaxAve, betayAve)
      use bmad_struct
      implicit none
  type (ring_struct)  ring
      real betaxAve
      real betayAve
      integer ix_ele
    end subroutine
  end interface

  interface
    subroutine bmad_parser (in_file, ring)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      character*(*) in_file
    end subroutine
  end interface

  interface
    subroutine bmad_parser2 (in_file, ring, orbit_)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (coord_struct), optional :: orbit_(0:n_ele_maxx)
      character*(*) in_file
    end subroutine
  end interface

  interface
    subroutine bmad_to_cesr (ring, cesr)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (cesr_struct) cesr
    end subroutine
  end interface

  interface
    subroutine bmad_to_db (ring, db)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (db_struct) db
    end subroutine
  end interface

  interface
    subroutine c_to_cbar (ele, cbar_mat)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      real cbar_mat(2,2)
    end subroutine
  end interface

  interface
    subroutine calc_z_tune (ring)
      use bmad_struct
      implicit none
      type (ring_struct) ring
    end subroutine
  end interface

  interface
    subroutine cesr_crossings(i_train, j_car, species, n_trains_tot, n_cars,&
    	cross_positions, n_car_spacing, train_spacing)
			use bmad_struct
			implicit none
      integer, intent(in) :: i_train
      integer, intent(in) :: j_car
      integer, intent(in) :: species
      integer, intent(in) :: n_trains_tot
      integer, intent(in) :: n_cars
      integer, optional, intent(in) :: train_spacing(1:10)
      integer, optional, intent(in) :: n_car_spacing(1:10)
      real, dimension(:), intent(out) :: cross_positions
    end subroutine
  end interface

  interface
    subroutine change_basis (coord, ref_energy, ref_z, to_cart, time_disp)
      use bmad_struct
      implicit none
      type (coord_struct) coord
      real ref_energy
      real ref_z
      real time_disp
      logical to_cart
    end subroutine
  end interface

  interface
    Subroutine check_ele_attribute_set (ring, i_ele, attrib_name, &
                                          ix_attrib, err_flag, err_print_flag)
      use bmad_struct
      implicit none
      type (ring_struct), target :: ring
      integer i_ele
      integer ix_attrib
      character*(*) attrib_name
      logical err_print_flag
      logical err_flag
    end subroutine
  end interface

  interface
    subroutine check_ring_controls (ring, exit_on_error)
      use bmad_struct
      implicit none
      type (ring_struct), target :: ring
      logical exit_on_error
    end subroutine
  end interface

  interface
    subroutine choose_cesr_lattice (lattice, lat_file, current_lat, &
                                                                ring, choice)
      use bmad_struct
      implicit none
      type (ring_struct), optional :: ring
      character(len=*), optional :: choice
      character*(*) lat_file
      character*40 lattice
      character*40 current_lat
    end subroutine
  end interface

  interface
    subroutine chrom_calc (ring, delta_e, chrom_x, chrom_y)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      real delta_e
      real chrom_x
      real chrom_y
    end subroutine
  end interface

  interface
    subroutine closed_orbit_at_start (ring, co, i_dim, iterate)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (coord_struct) co
      integer i_dim
      logical iterate
    end subroutine
  end interface

 interface
   subroutine closed_orbit_from_tracking (ring, closed_orb_, i_dim, &
                                                 eps_rel, eps_abs, init_guess)
     use bmad_struct
     type (ring_struct) ring
     type (coord_struct) closed_orb_(0:n_ele_maxx)
     type (coord_struct), optional :: init_guess
     real eps_rel(:), eps_abs(:)
     integer i_dim
   end subroutine
 end interface

  interface
    subroutine coil_track (start, ele_index, ring, end)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (coord_struct) start
      type (coord_struct) end
      integer ele_index
    end subroutine
  end interface

  interface
    subroutine compress_ring (ring, ok)
      use bmad_struct
      implicit none
      type (ring_struct), target :: ring
      logical ok
    end subroutine
  end interface

  interface
    recursive subroutine control_bookkeeper (ring, ix_ele)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      integer ix_ele
    end subroutine
  end interface

  interface
    subroutine convert_coords (in_type_str, coord_in, ele, out_type_str, coord_out)
      use bmad_struct
      implicit none
      character*(*) in_type_str
      character*(*) out_type_str
      type (coord_struct) coord_in
      type (coord_struct) coord_out
      type (ele_struct) ele
    end subroutine
  end interface

  interface
    subroutine create_group (ring, ix_ele, n_control, control_)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (control_struct) control_(*)
      integer ix_ele
      integer n_control
    end subroutine
  end interface

  interface
    subroutine create_overlay (ring, ix_overlay, ix_value, n_slave, con_)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (control_struct) con_(*)
      integer ix_overlay
      integer n_slave
      integer ix_value
    end subroutine
  end interface

  interface
    subroutine create_vsp_volt_elements (ring, ele_type)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      integer ele_type
    end subroutine
  end interface

  interface
    subroutine db_group_to_bmad (ing_name, ing_num, biggrp_set, ring, db, &
                                                con_, n_con, ok, type_err)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (db_struct) db
      type (control_struct) con_(*)
      integer n_con
      integer ing_num
      integer biggrp_set
      character*12 ing_name
      logical ok, type_err
    end subroutine
  end interface

  interface
    subroutine db_group_to_bmad_group (group_name, group_num, i_biggrp, &
                                           ring, db, ix_ele, ok, type_err)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (db_struct) db
      integer group_num
      integer ix_ele
      integer i_biggrp
      character*12 group_name
      logical ok
      logical type_err
    end subroutine
  end interface

  interface
    subroutine do_mode_flip (ele, ele_flip)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      type (ele_struct) ele_flip
    end subroutine
  end interface

  interface
    subroutine dynamic_aperture (ring, track_input, aperture_)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (aperture_struct) aperture_(*)
      type (track_input_struct) track_input
    end subroutine
  end interface

  interface
    subroutine element_locator (ele_name, ring, ix_ele)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      integer ix_ele
      character*(*) ele_name
    end subroutine
  end interface

  interface
    subroutine emitt_calc (ring, what, mode)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (modes_struct) mode
      integer what
    end subroutine
  end interface

  interface
    real function field_interpolate_3d (position, field_mesh, &
                                                 deltas, position0)
      implicit none
      real, intent(in) :: position(3), deltas(3)
      real, intent(in) :: field_mesh(:,:,:)
      real, intent(in), optional :: position0(3)
    end function
  end interface
 
  interface
    subroutine find_element_ends (ring, ix_ele, ix_start, ix_end)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      integer ix_ele
      integer ix_start
      integer ix_end
    end subroutine
  end interface

  interface
    subroutine fitpoly(coe, x, y, order, samples)
      implicit none
      integer order
      integer samples
      real coe(0:*)
      real x(*)
      real y(*)
    end subroutine
  end interface

  interface
    subroutine get_lattice_list (lat_list, num_lats, directory)
      implicit none
      integer num_lats
      character*(*) directory
      character*40 lat_list(*)
    end subroutine
  end interface

  interface
      function hypergeom(hgcx, arg)
      implicit none
      integer hgcx
      real arg
      real hypergeom
    end function
  end interface

  interface
    subroutine identify_db_node (db_name, db, db_ptr, ok, type_err)
      use bmad_struct
      implicit none
      type (db_struct), target :: db
      type (db_element_struct), pointer :: db_ptr(:)
      character*(*) db_name
      logical ok
      logical type_err
    end subroutine
  end interface

  interface
    subroutine init_ele (ele)
      use bmad_struct
      implicit none
      type (ele_struct) ele
    end subroutine
  end interface

  interface
    subroutine init_LRBBI(ring, oppos_ring, LRBBI_ele, ix_LRBBI, ix_oppos)
      use bmad_struct
      implicit none
      type (ring_struct) ring
			type (ring_struct) oppos_ring
      type (ele_struct) LRBBI_ele
			integer, intent(in) :: ix_LRBBI, ix_oppos
    end subroutine
  end interface

  interface
    subroutine insert_element (ring, insert_ele, insert_index)
      use bmad_struct
      implicit none
      type (ring_struct) ring
			type (ring_struct) oppos_ring
      type (ele_struct) insert_ele
      integer insert_index
    end subroutine
  end interface

  interface
    subroutine insert_LRBBI (ring, oppos_ring, cross_positions, ix_LRBBI)
			use bmad_struct
      type (ring_struct) ring
			type (ring_struct) oppos_ring 
     real, dimension(:), intent(inout) :: cross_positions
      integer, dimension(:), intent(inout) :: ix_LRBBI
    end subroutine
  end interface

  interface
    subroutine k_to_quad_calib(k_theory, energy, cu_theory, k_base,  &
                                                     dk_gev_dcu, cu_per_k_gev)
      implicit none
      real energy
      real k_theory(0:*)
      real k_base(0:120)
      real cu_per_k_gev(0:120)
      real dk_gev_dcu(0:*)
      integer cu_theory(0:*)
    end subroutine
  end interface

  interface
    subroutine LRBBI_crossings (n_bucket, oppos_buckets, cross_positions)
			real, intent(in) :: n_bucket
      real, dimension(:), intent(in) :: oppos_buckets
      real, dimension(:), intent(inout) :: cross_positions
    end subroutine LRBBI_crossings 
  end interface
 
  interface
    subroutine make_g_mats (ele, g_mat, g_inv_mat)
      use bmad_struct       
      implicit none
      type (ele_struct) ele
      real g_mat(4,4)
      real g_inv_mat(4,4)
    end subroutine
  end interface

  interface
    subroutine make_g2_mats (twiss, g2_mat, g2_inv_mat)
      use bmad_struct
      implicit none
      type (twiss_struct) twiss
      real g2_mat(2,2)
      real g2_inv_mat(2,2)
    end subroutine
  end interface

  interface
    subroutine make_hybrid_ring (r_in, use_ele, remove_markers, r_out, ix_out)
      use bmad_struct
      implicit none
      type (ring_struct) r_in
      type (ring_struct) r_out
      integer ix_out(*)
      logical remove_markers
      logical use_ele(*)
    end subroutine
  end interface

  interface
    subroutine make_LRBBI(master_ring, master_ring_oppos, ring, &
    													ix_LRBBI, master_ix_LRBBI)
      use bmad_struct
      implicit none
      type (ring_struct), dimension(:) :: ring
      type (ring_struct) :: master_ring
      type (ring_struct) :: master_ring_oppos
      integer, dimension(:,:) :: ix_LRBBI
      integer, dimension(:,:) :: master_ix_LRBBI
    end subroutine
  end interface
 
  interface
    subroutine make_mat6 (ele, param, c0, c1)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      type (coord_struct), optional :: c0, c1
      type (param_struct) param
    end subroutine
  end interface

  interface
    subroutine custom_make_mat6 (ele, param, c0, c1)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      type (coord_struct), optional :: c0, c1
      type (param_struct) param
    end subroutine
  end interface

  interface
    subroutine custom_radiation_integrals (ring, ir, orb_)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (coord_struct) orb_(0:n_ele_maxx)
      integer ir
    end subroutine
  end interface

  interface
    subroutine make_v_mats (ele, v_mat, v_inv_mat)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      real v_mat(4,4)
      real v_inv_mat(4,4)
    end subroutine
  end interface

  interface
    subroutine mark_LRBBI(master_ring, master_ring_oppos, ring, crossings)
      use bmad_struct
      implicit none
      type (ring_struct), dimension(:) :: ring
      type (ring_struct) :: master_ring
      type (ring_struct) :: master_ring_oppos
      real, dimension(:,:) :: crossings
    end subroutine
  end interface

  interface
    subroutine mat6_dispersion (mat6, e_vec)
      use bmad_struct
      implicit none
      real, intent(inout) :: mat6(6,6)
      real, intent(in) :: e_vec(*)
    end subroutine
  end interface    

  interface
    subroutine mat_inverse (mat, mat_inv)
      implicit none
      real, intent(in)  :: mat(:,:)
      real, intent(out) :: mat_inv(:,:)
    end subroutine
  end interface

  interface
    subroutine mat_symp_check (mat, error)
      implicit none
      real mat(:,:)
      real error
    end subroutine
  end interface

  interface
    subroutine mat_symp_decouple(t0, tol, stat, U, V, Ubar, Vbar, G,  &
                                                 twiss1, twiss2, type_out)
      use bmad_struct
      implicit none
      type (twiss_struct) twiss1, twiss2
      real t0(4,4), U(4,4), V(4,4), tol
      real Ubar(4,4), Vbar(4,4), G(4,4)
      integer stat
      logical type_out
    end subroutine
  end interface

  interface
    subroutine mat_symplectify (mat_in, mat_symp)
      real, intent(in)  :: mat_in(:,:)
      real, intent(out) :: mat_symp(:,:)
    end subroutine
  end interface

  interface
    subroutine mobius_twiss_calc (ele, v_mat)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      real v_mat(4,4)
    end subroutine
  end interface

  interface
    subroutine multipole_ab_to_kt (an, bn, knl, tn)
      use bmad_struct
      implicit none
      real an(0:n_pole_maxx), bn(0:n_pole_maxx)
      real knl(0:n_pole_maxx), tn(0:n_pole_maxx)
    end subroutine
  end interface

  interface
    subroutine multipole_c_init (c, maxx)
      implicit none
      integer maxx
      real c(0:maxx, 0:maxx)
    end subroutine
  end interface

  interface
    subroutine multipole_kt_to_ab (knl, tn, an, bn)
      use bmad_struct
      implicit none
      real an(0:n_pole_maxx), bn(0:n_pole_maxx)
      real knl(0:n_pole_maxx), tn(0:n_pole_maxx)
    end subroutine
  end interface

  interface
    subroutine multipole_ab_scale (ele, particle, a, b)
      use bmad_struct
      type (ele_struct) ele
      integer particle
      real a(0:n_pole_maxx), b(0:n_pole_maxx)
      real value(n_attrib_maxx)
    end subroutine
  end interface

  interface
    subroutine multipole_ab_to_value (a, b, value)
      use bmad_struct
      real a(0:n_pole_maxx)
      real b(0:n_pole_maxx)
      real value(n_attrib_maxx)
    end subroutine
  end interface

  interface  
    subroutine multipole_kick (knl, tilt, n, coord)
      use bmad_struct
      implicit none
      type (coord_struct) coord
      real knl
      real tilt
      integer n
    end subroutine
  end interface

  interface
    subroutine multipole_to_vecs (ele, particle, knl, tilt)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      real knl(0:n_pole_maxx)
      real tilt(0:n_pole_maxx)
      integer particle
    end subroutine
  end interface

  interface
    subroutine name_to_list (ring, ele_names, use_ele)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      logical use_ele(*)
      character*(*) ele_names(*)
    end subroutine
  end interface

  interface
    subroutine new_control (ring, ix_ele)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      integer ix_ele
    end subroutine
  end interface

  interface
    subroutine offset_coords_m (ele, param, coord, set, set_canon, set_multi)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      type (coord_struct) coord
      type (param_struct) param
      logical set, set_canon, set_multi
    end subroutine
  end interface

  interface
    subroutine one_turn_matrix (ring, mat6)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      real mat6(6,6)
    end subroutine
  end interface

  interface
    subroutine one_turn_mat_at_ele (ele, phi_a, phi_b, mat4)
      use bmad_struct
      type (ele_struct) ele
      real phi_a
      real phi_b
      real mat4(4,4)
    end subroutine
  end interface

  interface
    subroutine multi_turn_tracking_analysis (track, i_dim, track0, ele, &
                                                      stable, growth_rate, chi)
      use bmad_struct
      implicit none
      type (coord_struct), intent(in) :: track(:)
      type (coord_struct), intent(out) :: track0
      type (ele_struct), intent(out) :: ele
      real, intent(out) :: growth_rate, chi
      integer, intent(in) :: i_dim
      logical, intent(out) :: stable
    end subroutine
  end interface

  interface
    subroutine multi_turn_tracking_to_mat (track, i_dim, mat1, track0, chi)
      use bmad_struct
      implicit none
      type (coord_struct), intent(in), target :: track(:)
      type (coord_struct), intent(out) :: track0
      real, intent(out) :: mat1(:,:)
      real, intent(out) :: chi
      integer, intent(in) :: i_dim
    end subroutine
  end interface

  interface
    subroutine order_super_lord_slaves (ring, ix_lord)
      use bmad_struct
      implicit none
      type (ring_struct), target :: ring
      integer ix_lord
    end subroutine
  end interface

  interface
    subroutine phase_space_fit (x, xp, twiss, tune, emitt, x_0, xp_0, chi, tol)
      use bmad_struct
      implicit none
      type (twiss_struct) twiss
      real, optional :: tol
      real x(:), xp(:)
      real tune, emitt
      real x_0, xp_0, chi
    end subroutine
  end interface

  interface
    subroutine quad_beta_ave (ring, ix_ele, beta_x_ave, beta_y_ave)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      integer ix_ele
      real beta_x_ave
      real beta_y_ave
    end subroutine
  end interface

  interface
    subroutine quad_calib (lattice, k_theory, k_base,  &
                     len_quad, cu_per_k_gev, quad_rot, dk_gev_dcu, cu_theory)
      use bmad_struct
      implicit none
      character lattice*(*)
      real k_theory(0:*)
      real k_base(0:*)
      real len_quad(0:*)
      real cu_per_k_gev(0:*)
      real dk_gev_dcu(0:*)
      real quad_rot(0:*)
      integer cu_theory(0:*)
    end subroutine
  end interface

  interface
    subroutine radiation_integrals (ring, orb_, mode)
      use bmad_struct
      implicit none
      type (ring_struct), target :: ring
      type (coord_struct), target :: orb_(0:*)
      type (modes_struct) mode
    end subroutine
  end interface

  interface
    subroutine read_butns_file (butns_num, butns, db, ok, type_err)
      use bmad_struct
      implicit none
      type (db_struct) db
      type (butns_struct) butns
      integer butns_num
      logical ok, type_err
    end subroutine
  end interface

  interface
    subroutine read_digested_bmad_file (in_file_name, ring, version)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      integer version
      character*(*) in_file_name
    end subroutine
  end interface

  interface
    function relative_mode_flip (ele1, ele2)
      use bmad_struct
      implicit none
      logical relative_mode_flip
      type (ele_struct) ele1
      type (ele_struct) ele2
    end function
  end interface

  interface
    subroutine ring_ele_ele_attribute (ring, i_ele, attrib_name, &
                             attrib_value, err_flag, make_mat6_flag, orbit_)
      use bmad_struct
      implicit none
      type (ring_struct) :: ring
      type (coord_struct), optional :: orbit_(0:n_ele_maxx)
      real attrib_value
      integer i_ele
      character*(*) attrib_name
      logical make_mat6_flag
      logical err_flag
    end subroutine
  end interface

  interface
    subroutine Ring_Beta_Ave(ring, cesr)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (cesr_struct) cesr
    end subroutine
  end interface

  interface
    subroutine ring_geometry (ring)
      use bmad_struct
      implicit none
      type (ring_struct) ring
    end subroutine
  end interface

  interface
    recursive subroutine ring_make_mat6 (ring, ix_ele, coord_)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (coord_struct), optional :: coord_(0:n_ele_maxx)
      integer ix_ele
    end subroutine
  end interface

  interface
    subroutine ring_set_ele_attribute (ring, i_ele, attrib_name, &
                                attrib_value, err_flag, make_mat6_flag, orbit_)
      use bmad_struct
      implicit none
      type (ring_struct) :: ring
      type (coord_struct), optional :: orbit_(0:n_ele_maxx)
      real attrib_value
      integer i_ele
      character*(*) attrib_name
      logical make_mat6_flag
      logical err_flag
    end subroutine
  end interface

  interface
    subroutine ring_to_quad_calib (ring, cesr, k_theory, k_base,  &
                     len_quad, cu_per_k_gev, quad_rot, dk_gev_dcu, cu_theory)
      use bmad_struct
      implicit none
      type (cesr_struct)  cesr
      type (ring_struct)  ring
      real k_theory(0:*)
      real k_base(0:*)
      real len_quad(0:*)
      real cu_per_k_gev(0:*)
      real dk_gev_dcu(0:*)
      real quad_rot(0:*)
      integer cu_theory(0:*)
    end subroutine
  end interface

  interface
    subroutine s_calc (ring)
      use bmad_struct
      implicit none
      type (ring_struct) ring
    end subroutine
  end interface

  interface
    subroutine set_on (key, ring, on_switch, orb_)
      use bmad_struct
      type (ring_struct) ring
      type (coord_struct), optional :: orb_(0:*)
      integer key
      logical on_switch
    end subroutine
  end interface

  interface
    subroutine set_symmetry (symmetry, ring)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      integer symmetry
    end subroutine
  end interface

  interface
    subroutine set_tune (phi_x_set, phi_y_set, dk1, ring, orb_, ok)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (coord_struct) orb_(0:*)
      real phi_x_set
      real phi_y_set
      real dk1(*)
      logical ok
    end subroutine
  end interface

  interface
    subroutine set_z_tune (ring)
      use bmad_struct
      implicit none
      type (ring_struct), target :: ring
    end subroutine
  end interface

  interface
    subroutine sol_quad_mat_calc (ks, kl, length, order, mat627, orb)
      real ks, kl, length
      integer order
      real mat627(6,27)
      real, optional :: orb(6)
    end subroutine
  end interface

  interface
    subroutine split_ring (ring, s_split, ix_split, split_done)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      real s_split
      integer ix_split
      logical split_done
    end subroutine
  end interface

  interface
    subroutine tilt_coords (tilt_val, coord, set)
      implicit none
      real tilt_val
      real coord(6)
      logical set
    end subroutine
  end interface

  interface
    subroutine track_all (ring, orbit_)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (coord_struct) orbit_(0:*)
    end subroutine
  end interface

  interface
    subroutine track_bend (start, ele, end, is_lost)
      use bmad_struct
      implicit none
      type (coord_struct) start
      type (coord_struct) end
      type (ele_struct) ele
      logical is_lost
    end subroutine
  end interface

  interface
    subroutine track_long (ring, orbit_, ix_start, direction, mats627)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (coord_struct) orbit_(0:*)
      type (mat627_struct) mats627(*)
      integer ix_start
      integer direction
    end subroutine
  end interface
 
  interface
    subroutine track_many (ring, orbit_, ix_start, ix_end, direction)
      use bmad_struct
      implicit none
      type (ring_struct)  ring
      type (coord_struct)  orbit_(0:*)
      integer ix_start
      integer ix_end
      integer direction
    end subroutine
  end interface

  interface
    subroutine track_runge_kutta (start, end, s_start, s_end, &
                 rel_eps, abs_eps, del_s_step, del_s_min, func_type, param)
      use bmad_struct
      implicit none
      type (coord_struct) start, end
      type (param_struct), optional :: param
      real s_start, s_end, rel_eps, abs_eps, del_s_step, del_s_min
      character*(*) func_type
    end subroutine
  end interface

  interface
    subroutine track_wiggler (start, ele, param, end, is_lost)
      use bmad_struct
      implicit none
      type (coord_struct) start
      type (coord_struct) end
      type (param_struct) param
      type (ele_struct) ele
      logical is_lost
    end subroutine
  end interface

  interface
    subroutine transfer_mat_from_tracking (ele, param, orb0, d_orb, error)
      use bmad_struct
      implicit none
      type (ele_struct), intent(inout) :: ele
      type (param_struct), intent(in) :: param
      type (coord_struct), intent(in) :: orb0
      type (coord_struct), intent(in) :: d_orb
      real, intent(out) :: error
    end subroutine
  end interface

  interface
    subroutine transfer_mat_from_twiss (twiss1, twiss2, mat)
      use bmad_struct
      implicit none
      type (twiss_struct) twiss1
      type (twiss_struct) twiss2
      real mat(2,2)
    end subroutine
  end interface

  interface
    subroutine track1 (start, ele, param, end)
      use bmad_struct
      implicit none
      type (coord_struct) start
      type (coord_struct) end
      type (ele_struct) ele
      type (param_struct) param
    end subroutine
  end interface

  interface
    subroutine custom_track1 (start, ele, param, end)
      use bmad_struct
      implicit none
      type (coord_struct) start
      type (coord_struct) end
      type (ele_struct) ele
      type (param_struct) param
    end subroutine
  end interface

  interface
    subroutine twiss_and_track (ring, orb)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (coord_struct) orb(0:*)
    end subroutine
  end interface

  interface
    subroutine twiss_and_track_partial (ele1, ele2, param, del_s, ele3, &
                                                                   start, end)
      use bmad_struct
      implicit none
      type (ele_struct), optional :: ele3
      type (ele_struct) ele1
      type (ele_struct) ele2
      type (coord_struct), optional :: start
      type (coord_struct), optional :: end
      type (param_struct) param
      real del_s
    end subroutine
  end interface

  interface
    subroutine twiss_and_track_body (ele1, ele2, param, del_s, ele3, &
                                                                   start, end)
      use bmad_struct
      implicit none
      type (ele_struct), optional :: ele3
      type (ele_struct) ele1
      type (ele_struct) ele2
      type (coord_struct), optional :: start
      type (coord_struct), optional :: end
      type (param_struct) param
      real del_s
    end subroutine
  end interface

  interface
    subroutine twiss_at_element (ring, ix_ele, start, end, average)
      use bmad_struct
      implicit none
      type (ring_struct), target :: ring
      type (ele_struct), optional :: start
      type (ele_struct), optional :: end
      type (ele_struct), optional :: average
      integer ix_ele
    end subroutine
  end interface

  interface
    subroutine twiss_at_s (ring, s, ele)
      use bmad_struct
      implicit none
      type (ring_struct) :: ring
      type (ele_struct) :: ele
      real s
    end subroutine
  end interface

  interface
    subroutine twiss_at_start (ring)
      use bmad_struct
      implicit none
      type (ring_struct) ring
    end subroutine
  end interface

  interface
    subroutine twiss_from_mat6 (mat6, ele, stable, growth_rate)
      use bmad_struct
      implicit none
      type (ele_struct), intent(out) :: ele
      real, intent(in) :: mat6(6,6)
      real, intent(out) :: growth_rate
      logical, intent(out) :: stable
    end subroutine
  end interface

  interface
    subroutine twiss_from_tracking (ring, closed_orb_, d_orb, error)
      use bmad_struct
      type (ring_struct), intent(inout) :: ring
      type (coord_struct), intent(in) :: closed_orb_(0:n_ele_maxx)
      type (coord_struct), intent(in) :: d_orb
      real, intent(out) :: error
    end subroutine
  end interface

  interface
    subroutine twiss_propagate1 (ele1, ele2)
      use bmad_struct
      implicit none
      type (ele_struct) ele1
      type (ele_struct) ele2
    end subroutine
  end interface

  interface
    subroutine twiss_propagate_all (ring)
      use bmad_struct
      implicit none
      type (ring_struct) ring
    end subroutine
  end interface

  interface
    subroutine type_coord (coord)
      use bmad_struct
      implicit none
      type (coord_struct) coord
    end subroutine
  end interface

  interface
    subroutine type_ele (ele, type_zero_attrib, type_mat6, type_twiss,  &
                                                           type_control, ring)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      type (ring_struct) ring
      integer type_mat6
      logical type_twiss
      logical type_control
      logical type_zero_attrib
    end subroutine
  end interface

  interface
    subroutine type2_ele (ele, type_zero_attrib, type_mat6, type_twiss,  &
                                          type_control, ring, lines, n_lines)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      type (ring_struct) ring
      integer type_mat6, n_lines
      logical type_twiss
      logical type_control
      logical type_zero_attrib
      character*(*) lines(*)
    end subroutine
  end interface

  interface
    subroutine write_digested_bmad_file (digested_name, ring,  &
                                                      n_files, file_names)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      integer n_files
      character*(*) digested_name
      character*(*) file_names(*)
    end subroutine
  end interface

  interface
    subroutine update_hybrid_list (ring, n_in, use_ele)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      logical use_ele(*)
      integer n_in
    end subroutine
  end interface

  interface
    subroutine adjust_control_struct (ring, ix_ele)
      use bmad_struct
      implicit none
      type (ring_struct), target :: ring
      integer ix_ele
    end subroutine
  end interface

  interface
    subroutine long_track (ring, orbit_, ix_start, direction, mats627)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (coord_struct) orbit_(0:*)
      type (mat627_struct) mats627(*)
      integer ix_start
      integer direction
    end subroutine
  end interface

  interface
    subroutine make_mat627 (ele, param, direction, mat627)
      use bmad_struct
      implicit none
      type (ele_struct), target :: ele
      type (param_struct) param
      real mat627(6,27)
      integer direction
    end subroutine
  end interface

  interface
    recursive subroutine ring_make_mat627 (ring, ix_ele, direction, mats627)
      use bmad_struct
      implicit none
      type (ring_struct) ring
      type (mat627_struct) mats627(*)
      integer direction
      integer ix_ele
    end subroutine
  end interface

  interface
    subroutine set_design_linear (ring)
      use bmad_struct
      implicit none
      type (ring_struct) ring
    end subroutine
  end interface

  interface
    subroutine track1_627 (start, ele, param, mat627, end)
      use bmad_struct
      implicit none
      type (coord_struct) start
      type (coord_struct) end
      type (ele_struct) ele
      type (param_struct) param
      real mat627(6,27)
    end subroutine
  end interface

  interface
    subroutine twiss_from_mat2 (mat, det, twiss, stat, tol, type_out)
      use bmad_struct
      implicit none
      type (twiss_struct) twiss
      integer psize
      integer stat
      real mat(:, :)
      real det
      real tol
      logical type_out
    end subroutine
  end interface

  interface
    subroutine twiss_to_1_turn_mat (twiss, phi, mat2)
      use bmad_struct
      type (twiss_struct) twiss
      real phi
      real mat2(2,2)
    end subroutine
  end interface

! for make_mat6...

  interface
    subroutine mat6_multipole (ele, param, c00, factor, mat6, unit_matrix)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      type (param_struct) param
      type (coord_struct) c00
      real mat6(6,6)
      real factor
      logical unit_matrix
    end subroutine
  end interface

  interface
    subroutine quad_mat_calc (k1, length, mat)
      implicit none
      real length
      real mat(2,2)
      real k1
    end subroutine
  end interface

  interface
    subroutine sol_quad_mat6_calc (ks, k1, s_len, m, orb)
      use bmad_struct
      implicit none
      real ks
      real k1
      real s_len
      real m(6,6)
      real orb(6)
    end subroutine
  end interface

  interface
    subroutine mat4_multipole (ele, knl, tilt, n, c0, kick_mat)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      type (coord_struct) c0
      real knl
      real tilt
      real kick_mat(4,4)
      integer n
    end subroutine
  end interface

  interface
    function mexp (x, m)
      real x
      real mexp
      integer m
    end function
  end interface

  interface
    subroutine bbi_kick_matrix (ele, orb, s_pos, mat6)
      use bmad_struct
      implicit none
      type (ele_struct) ele
      type (coord_struct) orb
      real s_pos
      real mat6(6,6)
    end subroutine
  end interface

  interface
    subroutine bbi_slice_calc (n_slice, sig_z, z_slice)
      implicit none
      integer n_slice
      real sig_z
      real z_slice(*)
    end subroutine
  end interface

  interface
    subroutine tilt_mat6 (mat6, tilt)
      use bmad_struct
      implicit none
      real tilt
      real mat6(6,6)
    end subroutine
  end interface

  interface
    subroutine solenoid_mat_calc (ks, length, mat4)
      implicit none
      real ks
      real length
      real mat4(4,4)
    end subroutine
  end interface

end module
