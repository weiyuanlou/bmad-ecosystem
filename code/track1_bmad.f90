!+
! Subroutine track1_bmad (start_orb, ele, param, end_orb, err_flag)
!
! Particle tracking through a single element BMAD_standard style.
! This routine is NOT meant for long term tracking since it does not get 
! all the 2nd order terms for the longitudinal motion.
!
! It is assumed that HKICK and VKICK are the kicks in the horizontal
! and vertical kicks irregardless of the value for TILT.
!
! Note: track1_bmad *never* relies on ele%mat6 for tracking excect for 
! hybrid elements.
! 
! Note: end_orb%vec(6) will be set < -1 if the 
! particle fails to make it through an lcavity
!
! Modules Needed:
!   use bmad
!
! Input:
!   start_orb  -- Coord_struct: Starting position
!   ele        -- Ele_struct: Element
!   param      -- lat_param_struct:
!     %particle     -- Particle type
!
! Output:
!   end_orb   -- Coord_struct: End position
!   err_flag  -- Logical, optional: Set true if there is an error. False otherwise.
!-

subroutine track1_bmad (start_orb, ele, param, end_orb, err_flag)

use track1_mod, dummy2 => track1_bmad
use mad_mod, dummy3 => track1_bmad
use lat_geometry_mod, dummy4 => track1_bmad
use ptc_interface_mod, dummy5 => track1_bmad

implicit none

type (coord_struct) :: start_orb, start2_orb
type (coord_struct) :: end_orb, temp_orb
type (ele_struct) :: ele, temp_ele
type (ele_struct), pointer :: ele0
type (lat_param_struct) :: param
type (taylor_struct) taylor(6), taylor2(6)

real(rp) k1, k2, k2l, k3l, length, phase, beta_start
real(rp) beta_end, beta_start_ref, beta_end_ref, hkick, vkick, kick
real(rp) e2, sig_x, sig_y, kx, ky, coef, bbi_const, voltage
real(rp) knl(0:n_pole_maxx), tilt(0:n_pole_maxx)
real(rp) ks, sig_x0, sig_y0, beta, mat6(6,6), mat2(2,2), mat4(4,4)
real(rp) z_slice(100), s_pos, s_pos_old, vec0(6)
real(rp) rel_pc, k_z, pc_start, pc_end, dt_ref, gradient_ref, gradient_max
real(rp) x_pos, y_pos, cos_phi, gradient, e_start, e_end, e_ratio, voltage_max
real(rp) alpha, sin_a, cos_a, f, r11, r12, r21, r22, volt_ref
real(rp) x, y, z, px, py, pz, k, dE0, L, E, pxy2, xp0, xp1, yp0, yp1
real(rp) xp_start, yp_start, dz4_coef(4,4), dz_coef(3)
real(rp) dp_coupler, dp_x_coupler, dp_y_coupler, len_slice, k0l, k1l
real(rp) dcos_phi, dgradient, dpz, w_mat_inv(3,3), w_mat0(3,3)
real(rp) mc2, dpc_start, dE_start, dE_end, dE, dp_dg, dp_dg_ref, g
real(rp) E_start_ref, E_end_ref, pc_start_ref, pc_end_ref

real(rp) p_factor, sin_alpha, cos_alpha, sin_psi, cos_psi, wavelength
real(rp) cos_g, sin_g, cos_tc, sin_tc
real(rp) k_in_norm(3), h_norm(3), k_out_norm(3), e_tot, pc
real(rp) cap_gamma, gamma_0, gamma_h, b_err, dtheta_sin_2theta, b_eff

real(rp) m_in(3,3) , m_out(3,3), y_out(3), x_out(3), k_out(3)
real(rp) test, nn, mm, temp_vec(3), p_vec(3), r_vec(3), charge_dir

complex(rp) f0, fh, f0_g, eta, eta1, f_cmp, xi_0k, xi_hk, e_rel, e_rel2

integer i, n, n_slice, key, ix_fringe

logical, optional :: err_flag
logical err, has_nonzero_pole

character(16) :: r_name = 'track1_bmad'

type (mad_map_struct) map
type (mad_energy_struct) energy

! initially set end_orb = start_orb

if (present(err_flag)) err_flag = .false.

start2_orb = start_orb ! In case start_orb and end_orb share the same memory.

end_orb = start_orb     ! transfer start to end
if (param%particle /= photon$) then
  end_orb%p0c = ele%value(p0c$)
endif
length = ele%value(l$)
rel_pc = 1 + start_orb%vec(6)
charge_dir = param%rel_tracking_charge * ele%orientation

!-----------------------------------------------
! Select
! If element is off looks like a drift. LCavities will still do wakefields.

key = ele%key
if (key == sol_quad$ .and. ele%value(k1$) == 0) key = solenoid$
if (.not. ele%is_on .and. key /= lcavity$) key = drift$  

select case (key)

!-----------------------------------------------
! beambeam
                        
case (beambeam$)

  if (ele%value(charge$) == 0 .or. param%n_part == 0) return

  sig_x0 = ele%value(sig_x$)
  sig_y0 = ele%value(sig_y$)
  if (sig_x0 == 0 .or. sig_y0 == 0) return

  call offset_particle (ele, end_orb, param, set$)

  n_slice = max(1, nint(ele%value(n_slice$)))
  call bbi_slice_calc (n_slice, ele%value(sig_z$), z_slice)
  s_pos = 0    ! end at the ip
  do i = 1, n_slice
    s_pos_old = s_pos
    s_pos = (end_orb%vec(5) + z_slice(i)) / 2
    end_orb%vec(1) = end_orb%vec(1) + end_orb%vec(2) * (s_pos - s_pos_old)
    end_orb%vec(3) = end_orb%vec(3) + end_orb%vec(4) * (s_pos - s_pos_old)
    if (ele%a%beta == 0) then
      sig_x = sig_x0
      sig_y = sig_y0
    else
      beta = ele%a%beta - 2 * ele%a%alpha * s_pos + ele%a%gamma * s_pos**2
      sig_x = sig_x0 * sqrt(beta / ele%a%beta)
      beta = ele%b%beta - 2 * ele%b%alpha * s_pos + ele%b%gamma * s_pos**2
      sig_y = sig_y0 * sqrt(beta / ele%b%beta)
    endif

    call bbi_kick (end_orb%vec(1)/sig_x, end_orb%vec(3)/sig_y, sig_y/sig_x,  &
                                                                kx, ky)
    bbi_const = -param%n_part * ele%value(charge$) * classical_radius_factor /  &
                    (2 * pi * ele%value(p0c$) * (sig_x + sig_y))
    coef = ele%value(bbi_const$) / (n_slice * rel_pc)
    end_orb%vec(2) = end_orb%vec(2) + kx * coef
    end_orb%vec(4) = end_orb%vec(4) + ky * coef
  enddo
  end_orb%vec(1) = end_orb%vec(1) - end_orb%vec(2) * s_pos
  end_orb%vec(3) = end_orb%vec(3) - end_orb%vec(4) * s_pos

  call offset_particle (ele, end_orb, param, unset$)  

!-----------------------------------------------
! bend_sol_quad
! This is modeled using kick-drift-kick where 
!   kick  == thin bend & quad kick
!   drift == thick solenoid

case (bend_sol_quad$)

  call offset_particle (ele, end_orb, param, set$)

  n_slice = max(1, nint(length / ele%value(ds_step$)))
  len_slice = length / n_slice
  ks  = charge_dir * ele%value(ks$) / rel_pc 
  k0l = charge_dir * ele%value(g$) * len_slice
  k1l = charge_dir * ele%value(k1$) * len_slice

  call solenoid_mat_calc (ks, length, mat4)

  do i = 1, n_slice

    ! Kick

    end_orb%vec(2) = end_orb%vec(2)
    end_orb%vec(4) = end_orb%vec(4)

    ! Solendoid "drift"

    xp_start = end_orb%vec(2) + ks * end_orb%vec(3) / 2
    yp_start = end_orb%vec(4) - ks * end_orb%vec(1) / 2
    end_orb%vec(5) = end_orb%vec(5) - len_slice * (xp_start**2 + yp_start**2 ) / 2
    end_orb%vec(1:4) = matmul (mat4, end_orb%vec(1:4))
  enddo

  call offset_particle (ele, end_orb, param, unset$)
  call track1_low_energy_z_correction (end_orb, ele, param)
  call time_and_s_calc ()

!-----------------------------------------------
! collimator

case (rcollimator$, ecollimator$, monitor$, instrument$, pipe$) 

  call offset_particle (ele, end_orb, param, set$, .false., set_tilt = .false., set_hvkicks = .false.)
  n_slice = max(1, nint(length / ele%value(ds_step$)))
  end_orb%vec(2) = end_orb%vec(2) + ele%value(hkick$) / (2 * n_slice)
  end_orb%vec(4) = end_orb%vec(4) + ele%value(vkick$) / (2 * n_slice)
  do i = 1, n_slice
    call track_a_drift (end_orb, ele, length/n_slice)
    if(i == n_slice) then
      end_orb%vec(2) = end_orb%vec(2) + ele%value(hkick$) * charge_dir / (2 * n_slice)
      end_orb%vec(4) = end_orb%vec(4) + ele%value(vkick$) * charge_dir / (2 * n_slice)
    else
      end_orb%vec(2) = end_orb%vec(2) + ele%value(hkick$) * charge_dir / n_slice
      end_orb%vec(4) = end_orb%vec(4) + ele%value(vkick$) * charge_dir / n_slice
    end if
  end do
  call offset_particle (ele, end_orb, param, unset$, .false., set_tilt = .false., set_hvkicks = .false.)

!-----------------------------------------------
! drift
 
case (drift$) 

  call offset_particle (ele, end_orb, param, set$, .false.)
  call track_a_drift (end_orb, ele, length)
  call offset_particle (ele, end_orb, param, unset$, .false.)

!-----------------------------------------------
! elseparator

case (elseparator$)
   
  call offset_particle (ele, end_orb, param, set$, .false., set_hvkicks = .false.) 
  call transfer_ele(ele, temp_ele, .true.)
  call zero_ele_offsets(temp_ele)
  temp_ele%value(hkick$) = temp_ele%value(hkick$) * param%rel_tracking_charge / (1. + end_orb%vec(6))
  temp_ele%value(vkick$) = temp_ele%value(vkick$) * param%rel_tracking_charge / (1. + end_orb%vec(6))
  if (param%particle < 0) then
    temp_ele%value(hkick$) = -temp_ele%value(hkick$)
    temp_ele%value(vkick$) = -temp_ele%value(vkick$)
  endif

  call make_mad_map (temp_ele, param, energy, map)
  end_orb%vec(6) = 0
  end_orb%vec(2) = end_orb%vec(2) / (1 + start2_orb%vec(6))
  end_orb%vec(4) = end_orb%vec(4) / (1 + start2_orb%vec(6))
  call mad_track1 (end_orb, map, end_orb)
  end_orb%vec(2) = end_orb%vec(2) * (1 + start2_orb%vec(6))
  end_orb%vec(4) = end_orb%vec(4) * (1 + start2_orb%vec(6))
   
  call offset_particle (ele, end_orb, param, unset$, .false., set_hvkicks = .false.)
  call end_z_calc
  end_orb%vec(6) = start2_orb%vec(6)
  call track1_low_energy_z_correction (end_orb, ele, param)
  call time_and_s_calc ()

!-----------------------------------------------
! kicker
 
case (kicker$, hkicker$, vkicker$) 

  hkick = charge_dir * ele%value(hkick$) 
  vkick = charge_dir * ele%value(vkick$) 
  kick  = charge_dir * ele%value(kick$) 

  call offset_particle (ele, end_orb, param, set$, .false., set_hvkicks = .false.)
  n_slice = max(1, nint(length / ele%value(ds_step$)))
  if (ele%key == hkicker$) then
     end_orb%vec(2) = end_orb%vec(2) + kick / (2 * n_slice)
  elseif (ele%key == vkicker$) then
     end_orb%vec(4) = end_orb%vec(4) + kick / (2 * n_slice)
  else
     end_orb%vec(2) = end_orb%vec(2) + hkick / (2 * n_slice)
     end_orb%vec(4) = end_orb%vec(4) + vkick / (2 * n_slice)
  endif
  do i = 1, n_slice
     call track_a_drift (end_orb, ele, length/n_slice)
     if (i == n_slice) then
        if (ele%key == hkicker$) then
           end_orb%vec(2) = end_orb%vec(2) + kick / (2 * n_slice)
        elseif (ele%key == vkicker$) then
           end_orb%vec(4) = end_orb%vec(4) + kick / (2 * n_slice)
        else
           end_orb%vec(2) = end_orb%vec(2) + hkick / (2 * n_slice)
           end_orb%vec(4) = end_orb%vec(4) + vkick / (2 * n_slice)
        endif
     else 
        if (ele%key == hkicker$) then
           end_orb%vec(2) = end_orb%vec(2) + kick / n_slice
        elseif (ele%key == vkicker$) then
           end_orb%vec(4) = end_orb%vec(4) + kick / n_slice
        else
           end_orb%vec(2) = end_orb%vec(2) + hkick / n_slice
           end_orb%vec(4) = end_orb%vec(4) + vkick / n_slice
        endif
     endif
  end do
  call offset_particle (ele, end_orb, param, unset$, .false., set_hvkicks = .false.)

  if (ele%key == kicker$) then
    end_orb%vec(1) = end_orb%vec(1) + ele%value(h_displace$)
    end_orb%vec(3) = end_orb%vec(3) + ele%value(v_displace$)
  endif
   
!-----------------------------------------------
! LCavity: Linac rf cavity
! Ultra-relativistic formalism from:
!       J. Rosenzweig and L. Serafini
!       Phys Rev E, Vol. 49, p. 1599, (1994)
! with b_0 = b_-1 = 1. The extra factors of beta are included to make the 
! transverse determinant equal to (beta_i*gamma_i)/(beta_f*gamma_f) which it should
! be at low energies.

case (lcavity$)

  if (length == 0) return

  if (ele%value(E_tot_start$) == 0) then
    if (present(err_flag)) err_flag = .true.
    call out_io (s_fatal$, r_name, 'E_TOT_START IS 0 FOR A LCAVITY!' // ele%name)
    if (global_com%exit_on_error) call err_exit
    return
  endif

  E_start_ref  = ele%value(E_tot_start$)
  E_end_ref    = ele%value(E_tot$)
  gradient_ref = (E_end_ref - E_start_ref) / length
  pc_start_ref = ele%value(p0c_start$)
  pc_end_ref   = ele%value(p0c$)
  beta_start_ref = pc_start_ref / E_start_ref
  beta_end_ref   = pc_end_ref / E_end_ref

  pc_start = pc_start_ref * rel_pc
  call convert_pc_to (pc_start, param%particle, E_tot = E_start, beta = beta_start)

  ! The RF phase is defined with respect to the time at the beginning of the element.
  ! So if dealing with a slave element and absolute time tracking then need to correct.

  phase = twopi * (ele%value(phi0_err$) + ele%value(dphi0_ref$) + &
             ele%value(phi0$) + ele%value(dphi0$) + &
             particle_time (end_orb, ele) * ele%value(rf_frequency$))
  if (absolute_time_tracking(ele)) phase = phase - &
                            twopi * slave_time_offset(ele) * ele%value(rf_frequency$) 

  gradient_max = (ele%value(gradient$) + ele%value(gradient_err$)) * ele%value(field_scale$)

  if (.not. ele%is_on) then
    gradient_max = 0
  endif

  cos_phi = cos(phase)
  gradient = gradient_max * cos_phi + gradient_shift_sr_wake(ele, param)

  ! If the cavity is off and the reference energy does not change then
  ! the tracking is simple.

  if (gradient == 0 .and. gradient_ref == 0) then
    if (ele%is_on) call offset_particle (ele, end_orb, param, set$, .false.)
    call track_a_drift (end_orb, ele, length)
    if (ele%is_on) call offset_particle (ele, end_orb, param, unset$, .false.)
    ! 1/gamma^2 low E correction
    end_orb%vec(5) = end_orb%vec(5) + length * end_orb%vec(6) * (1 - 3 * end_orb%vec(6) / 2) * (mass_of(param%particle) / ele%value(e_tot$))**2
    return
  endif

  E_end = E_start + gradient * length
  if (E_end <= mass_of(param%particle)) then
    end_orb%state = lost_z_aperture$
    end_orb%vec(6) = -1.01  ! Something less than -1
    return
  endif

  call convert_total_energy_to (E_end, param%particle, pc = pc_end, beta = beta_end)
  E_ratio = E_end / E_start
  end_orb%beta = beta_end

  call offset_particle (ele, end_orb, param, set$)

  ! entrance kick

  k1 = -gradient / (2 * pc_start)
  end_orb%vec(2) = end_orb%vec(2) + k1 * end_orb%vec(1)
  end_orb%vec(4) = end_orb%vec(4) + k1 * end_orb%vec(3)

  ! coupler kick

  if (ele%value(coupler_strength$) /= 0) call coupler_kick_entrance()

  if (gradient == 0) then
    r11 = 1
    r12 = length
    r21 = 0
    r22 = 1

  else
    voltage_max = gradient_max * length
    if (abs(voltage_max * cos_phi) < 1e-5 * pc_start) then
      f = voltage_max / pc_start
      alpha = f * (1 + f * cos_phi / 2)  / (2 * sqrt_2)
    else
      alpha = log(E_ratio) / (2 * sqrt_2 * cos_phi)
    endif
    cos_a = cos(alpha)
    sin_a = sin(alpha)
    f = gradient / (2 * sqrt_2 * cos_phi)
    r11 =  cos_a
    r12 =  sin_a * beta_start * E_start / f
    r21 = -sin_a * f / (E_end * beta_end)
    r22 =  cos_a * beta_start * E_start / (E_end * beta_end)
  endif

  x_pos = end_orb%vec(1)
  y_pos = end_orb%vec(3)

  end_orb%vec(1) = r11 * x_pos + r12 * end_orb%vec(2)
  end_orb%vec(2) = r21 * x_pos + r22 * end_orb%vec(2)
  end_orb%vec(3) = r11 * y_pos + r12 * end_orb%vec(4)
  end_orb%vec(4) = r21 * y_pos + r22 * end_orb%vec(4)

  ! coupler kick

  if (ele%value(coupler_strength$) /= 0) call coupler_kick_entrance()

  ! exit kick

  k2 = gradient / (2 * pc_end) 
  end_orb%vec(2) = end_orb%vec(2) + k2 * end_orb%vec(1)
  end_orb%vec(4) = end_orb%vec(4) + k2 * end_orb%vec(3)

  ! Final momentum and z calc

  mc2 = mass_of(param%particle)

  end_orb%vec(6) = (pc_end - pc_end_ref) / pc_end_ref 

  call offset_particle (ele, end_orb, param, unset$)

  dp_dg = (pc_end - pc_start) / gradient
  end_orb%vec(5) = end_orb%vec(5) * (beta_end / beta_start) - beta_end * (dp_dg - c_light * ele%value(delta_ref_time$))

  ! Correction of z for finite transverse velocity assumes a uniform change in slope.

  xp0 = start2_orb%vec(2) / rel_pc
  xp1 = end_orb%vec(2) / (1 + end_orb%vec(6))
  yp0 = start2_orb%vec(4) / rel_pc
  yp1 = end_orb%vec(4) / (1 + end_orb%vec(6))

  end_orb%vec(5) = end_orb%vec(5) - (length / 6) * (xp0**2 + xp1**2 + xp0*xp1 + yp0**2 + yp1**2 + yp0*yp1)

  ! Time & s calc

  f = gradient * length * mc2**2 / (pc_start**2 * E_start)

  if (abs(f) < 1d-6) then
    end_orb%t = start2_orb%t + length * (E_start / pc_start) * (1 - f/2) / c_light
  else
    end_orb%t = start2_orb%t + (pc_end - pc_start) / (gradient * c_light)
  endif

  end_orb%s = ele%s

!-----------------------------------------------
! marker, etc.

case (marker$, branch$, photon_branch$, floor_shift$, fiducial$)

  return

!-----------------------------------------------
! match

case (match$)

  if (ele%value(match_end_orbit$) /= 0) then
    ele%value(x0$)  = start2_orb%vec(1)
    ele%value(px0$) = start2_orb%vec(2)
    ele%value(y0$)  = start2_orb%vec(3)
    ele%value(py0$) = start2_orb%vec(4)
    ele%value(z0$)  = start2_orb%vec(5)
    ele%value(pz0$) = start2_orb%vec(6)
    end_orb%vec = [ ele%value(x1$), ele%value(px1$), &
                ele%value(y1$), ele%value(py1$), &
                ele%value(z1$), ele%value(pz1$) ]
    return
  endif

  call match_ele_to_mat6 (ele, vec0, mat6, err)
  if (err) then
    ! Since there are cases where this error may be raised many 
    ! times, do not print an error message.
    if (present(err_flag)) err_flag = .true.
    end_orb%state = lost$
    return
  endif

  end_orb%vec = matmul (mat6, end_orb%vec) + vec0

  call time_and_s_calc ()

!-----------------------------------------------
! multipole, ab_multipole

case (multipole$, ab_multipole$) 

  call offset_particle (ele, end_orb, param, set$, set_canonical = .false., set_multipoles = .false.)

  call multipole_ele_to_kt(ele, param, .false., has_nonzero_pole, knl, tilt)
  call multipole_kicks (knl, tilt, end_orb, .true.)

  call offset_particle (ele, end_orb, param, unset$, set_canonical = .false., set_multipoles = .false.)

!-----------------------------------------------
! octupole
! The octupole is modeled using kick-drift.

case (octupole$)

  n_slice = max(1, nint(length / ele%value(ds_step$)))

  k3l = charge_dir * ele%value(k3$) * length / n_slice

  call offset_particle (ele, end_orb, param, set$, set_canonical = .false.)

  end_orb%vec(2) = end_orb%vec(2) + k3l *  (3*end_orb%vec(1)*end_orb%vec(3)**2 - end_orb%vec(1)**3) / 12
  end_orb%vec(4) = end_orb%vec(4) + k3l *  (3*end_orb%vec(3)*end_orb%vec(1)**2 - end_orb%vec(3)**3) / 12

  do i = 1, n_slice

    call track_a_drift (end_orb, ele, length / n_slice)

    if (i == n_slice) then
      end_orb%vec(2) = end_orb%vec(2) + k3l *  (3*end_orb%vec(1)*end_orb%vec(3)**2 - end_orb%vec(1)**3) / 12
      end_orb%vec(4) = end_orb%vec(4) + k3l *  (3*end_orb%vec(3)*end_orb%vec(1)**2 - end_orb%vec(3)**3) / 12
    else
      end_orb%vec(2) = end_orb%vec(2) + k3l *  (3*end_orb%vec(1)*end_orb%vec(3)**2 - end_orb%vec(1)**3) / 6
      end_orb%vec(4) = end_orb%vec(4) + k3l *  (3*end_orb%vec(3)*end_orb%vec(1)**2 - end_orb%vec(3)**3) / 6
    endif

  enddo

  call offset_particle (ele, end_orb, param, unset$, set_canonical = .false.)

!-----------------------------------------------
! patch

case (patch$)

  end_orb%vec(1) = end_orb%vec(1) - ele%value(x_offset$)
  end_orb%vec(3) = end_orb%vec(3) - ele%value(y_offset$)
  r_vec = [end_orb%vec(1), end_orb%vec(3), -ele%value(z_offset$)]
  
  rel_pc = 1 + end_orb%vec(6)
  p_vec = [end_orb%vec(2)/rel_pc, end_orb%vec(2)/rel_pc, 0.0_rp]
  p_vec(3) = sqrt(1 - p_vec(1)**2 - p_vec(2)**2)
  if (end_orb%p0c < 0) p_vec(3) = -p_vec(3)

  if (ele%value(x_pitch$) /= 0 .or. ele%value(y_pitch$) /= 0 .or. ele%value(tilt$) /= 0) then
    call floor_angles_to_w_mat (ele%value(x_pitch$), ele%value(y_pitch$), ele%value(tilt$), w_mat_inv = w_mat_inv)
    p_vec = matmul(w_mat_inv, p_vec)
    r_vec = matmul(w_mat_inv, r_vec)
    end_orb%vec(2) = p_vec(1)
    end_orb%vec(4) = p_vec(2)
    end_orb%p0c = sign(end_orb%p0c, p_vec(3))
  endif

  end_orb%vec(1) = r_vec(1) - r_vec(3) * p_vec(1) / p_vec(3)
  end_orb%vec(3) = r_vec(2) - r_vec(3) * p_vec(2) / p_vec(3)

  end_orb%vec(5) = end_orb%vec(5) + r_vec(3) / p_vec(3) + &
                    end_orb%beta * (ele%value(z_offset$) + c_light * ele%value(t_offset$))
  end_orb%vec(6) = (end_orb%vec(6) * ele%value(p0c_start$) + (ele%value(p0c_start$) - ele%value(p0c$))) / ele%value(p0c$) 

!-----------------------------------------------
! quadrupole

case (quadrupole$)

  call offset_particle (ele, end_orb, param, set$)

  k1 = charge_dir * ele%value(k1$) / rel_pc

  ! Entrance edge

  ix_fringe = nint(ele%value(fringe_type$))
  if (ix_fringe == full_straight$ .or. ix_fringe == full_bend$) then
    x = end_orb%vec(1); px = end_orb%vec(2); y = end_orb%vec(3); py = end_orb%vec(4)
    end_orb%vec(1) = x  + k1 * (x**3/12 + x*y**2/4)
    end_orb%vec(2) = px + k1 * (x*y*py/2 - px*(x**2 + y**2)/4)
    end_orb%vec(3) = y  - k1 * (y**3/12 + y*x**2/4)
    end_orb%vec(4) = py - k1 * (y*x*px/2 - py*(y**2 + x**2)/4)
  endif

  ! Body

  call quad_mat2_calc (-k1, length, mat2, dz_coef)
  end_orb%vec(5) = end_orb%vec(5) + dz_coef(1) * end_orb%vec(1)**2 + &
                            dz_coef(2) * end_orb%vec(1) * end_orb%vec(2) + &
                            dz_coef(3) * end_orb%vec(2)**2 

  end_orb%vec(1:2) = matmul(mat2, end_orb%vec(1:2))

  call quad_mat2_calc (k1, length, mat2, dz_coef)
  end_orb%vec(5) = end_orb%vec(5) + dz_coef(1) * end_orb%vec(3)**2 + &
                            dz_coef(2) * end_orb%vec(3) * end_orb%vec(4) + &
                            dz_coef(3) * end_orb%vec(4)**2 

  end_orb%vec(3:4) = matmul(mat2, end_orb%vec(3:4))

  ! Exit edge

  if (ix_fringe == full_straight$ .or. ix_fringe == full_bend$) then
    x = end_orb%vec(1); px = end_orb%vec(2); y = end_orb%vec(3); py = end_orb%vec(4)
    end_orb%vec(1) = x  - k1 * (x**3/12 + x*y**2/4)
    end_orb%vec(2) = px - k1 * (x*y*py/2 - px*(x**2 + y**2)/4)
    end_orb%vec(3) = y  + k1 * (y**3/12 + y*x**2/4)
    end_orb%vec(4) = py + k1 * (y*x*px/2 - py*(y**2 + x**2)/4)
  endif

  call offset_particle (ele, end_orb, param, unset$)  

  call track1_low_energy_z_correction (end_orb, ele, param)
  call time_and_s_calc ()

!-----------------------------------------------
! rfcavity

case (rfcavity$)

  call offset_particle (ele, end_orb, param, set$, set_canonical = .false.)

  ! coupler kick

  if (ele%value(coupler_strength$) /= 0) call coupler_kick_entrance()

  !

  x = end_orb%vec(1)
  y = end_orb%vec(3)
  z = end_orb%vec(5)

  px = end_orb%vec(2)
  py = end_orb%vec(4)
  pz = end_orb%vec(6)

  voltage = ele%value(voltage$) * ele%value(field_scale$) 

  if (voltage /= 0 .and. ele%value(RF_frequency$) == 0) then
     if (present(err_flag)) err_flag = .true.
     call out_io (s_fatal$, r_name, &
                 '"RF_FREQUENCY" ATTRIBUTE NOT SET FOR RF: ' // ele%name, &
                 'YOU NEED TO SET THIS OR THE "HARMON" ATTRIBUTE.')
     if (global_com%exit_on_error) call err_exit
     return
  endif

  ! The RF phase is defined with respect to the time at the beginning of the element.
  ! So if dealing with a slave element and absolute time tracking then need to correct.

  phase = twopi * (ele%value(phi0$) + ele%value(dphi0$) - ele%value(dphi0_ref$) - &
               particle_time (end_orb, ele) * ele%value(rf_frequency$))
  if (absolute_time_tracking(ele)) phase = phase + &
                            twopi * slave_time_offset(ele) * ele%value(rf_frequency$) 

  k = twopi * ele%value(rf_frequency$) * voltage * cos(phase) / (ele%value(p0c$) * c_light)

  dE0 =  voltage * sin(phase) / ele%value(E_tot$)
  L = ele%value(l$)
  E = 1 + pz
  E2 = E**2
  pxy2 = px**2 + py**2

  !

  end_orb%vec(1) = x + px*L * (1/E - dE0/2 + pxy2*L/12 + pz*dE0 + dE0**2/3) 
  end_orb%vec(3) = y + py*L * (1/E - dE0/2 + pxy2*L/12 + pz*dE0 + dE0**2/3)
  end_orb%vec(5) = z + pxy2*L * (-1/(2*E2) + dE0/2)
  end_orb%vec(6) = pz + dE0 + k*pxy2*L * (-1/(4*E2) + dE0/6) 

  ! coupler kick

  if (ele%value(coupler_strength$) /= 0) call coupler_kick_entrance()

  call offset_particle (ele, end_orb, param, unset$, set_canonical = .false.)

  call track1_low_energy_z_correction (end_orb, ele, param)
  call time_and_s_calc ()

!-----------------------------------------------
! sbend

case (sbend$)

  call track_a_bend (start_orb, ele, param, end_orb)
  call time_and_s_calc ()

!-----------------------------------------------
! sextupole
! The sextupole is modeled using kick-drift.

case (sextupole$)

  n_slice = max(1, nint(length / ele%value(ds_step$)))

  k2l = charge_dir * ele%value(k2$) * length / n_slice

  call offset_particle (ele, end_orb, param, set$, set_canonical = .false.)

  end_orb%vec(2) = end_orb%vec(2) + k2l * (end_orb%vec(3)**2 - end_orb%vec(1)**2)/4
  end_orb%vec(4) = end_orb%vec(4) + k2l * end_orb%vec(1) * end_orb%vec(3) / 2

  do i = 1, n_slice
    call track_a_drift (end_orb, ele, length/n_slice)
    if (i == n_slice) then
      end_orb%vec(2) = end_orb%vec(2) + k2l * (end_orb%vec(3)**2 - end_orb%vec(1)**2)/4
      end_orb%vec(4) = end_orb%vec(4) + k2l * end_orb%vec(1) * end_orb%vec(3) / 2
    else
      end_orb%vec(2) = end_orb%vec(2) + k2l * (end_orb%vec(3)**2 - end_orb%vec(1)**2)/2
      end_orb%vec(4) = end_orb%vec(4) + k2l * end_orb%vec(1) * end_orb%vec(3)
    endif
  enddo

  call offset_particle (ele, end_orb, param, unset$, set_canonical = .false.)

!-----------------------------------------------
! solenoid
! Notice that ks is independent of the ele orientation

case (solenoid$)

  call offset_particle (ele, end_orb, param, set$)

  ks = param%rel_tracking_charge * ele%value(ks$) / rel_pc

  xp_start = end_orb%vec(2) + ks * end_orb%vec(3) / 2
  yp_start = end_orb%vec(4) - ks * end_orb%vec(1) / 2
  end_orb%vec(5) = end_orb%vec(5) - length * (xp_start**2 + yp_start**2 ) / 2

  call solenoid_mat_calc (ks, length, mat4)
  end_orb%vec(1:4) = matmul (mat4, end_orb%vec(1:4))

  call offset_particle (ele, end_orb, param, unset$)
  call track1_low_energy_z_correction (end_orb, ele, param)
  call time_and_s_calc ()

!-----------------------------------------------
! sol_quad

case (sol_quad$)

  call offset_particle (ele, end_orb, param, set$)

  ks = param%rel_tracking_charge * ele%value(ks$) / rel_pc
  k1 = charge_dir * ele%value(k1$) / rel_pc
  vec0 = 0
  call sol_quad_mat6_calc (ks, k1, length, mat6, vec0, dz4_coef)
  end_orb%vec(5) = end_orb%vec(5) + sum(end_orb%vec(1:4) * matmul(dz4_coef, end_orb%vec(1:4)))   
  end_orb%vec(1:4) = matmul (mat6(1:4,1:4), end_orb%vec(1:4))

  call offset_particle (ele, end_orb, param, unset$)
  call track1_low_energy_z_correction (end_orb, ele, param)
  call time_and_s_calc ()

!-----------------------------------------------
! Taylor

case (taylor$)

  if (ele%orientation == 1) then
    call track1_taylor (start_orb, ele, param, end_orb)

  else
    call taylor_inverse (ele%taylor, taylor)
    taylor2 = ele%taylor
    ele%taylor = taylor
    call track1_taylor (start_orb, ele, param, end_orb)
    ele%taylor = taylor2
    call kill_taylor(taylor)
  endif

  call time_and_s_calc ()

!-----------------------------------------------
! wiggler:
! Only periodic type wigglers are handled here.
! In the horizontal plane the tracking looks like a drift.
! The tracking in the vertical plane is:
!   1) 1/2 the octupole kick at the entrance face.
!   2) Track as a quadrupole through the body
!   3) 1/2 the octupole kick at the exit face.

case (wiggler$)

  if (ele%sub_key == map_type$) then
    if (present(err_flag)) err_flag = .true.
    call out_io (s_fatal$, r_name, &
            'MAP_TYPE WIGGLER: ' // ele%name, &
            'HAS TRACKING_METHOD = BMAD_STANDARD.', &
            'THIS IS NOT A POSSIBLE OPTION FOR THE TRACKING_METHOD.')
    if (global_com%exit_on_error) call err_exit
    return
  endif

  call offset_particle (ele, end_orb, param, set$)

  if (ele%value(l_pole$) == 0) then
    k_z = 0
  else
    k_z = pi / ele%value(l_pole$)
  endif
  k1 = -charge_dir * 0.5 * (c_light * ele%value(b_max$) / (ele%value(p0c$) * rel_pc))**2

  ! 1/2 of the octupole octupole kick at the entrance face.

  end_orb%vec(4) = end_orb%vec(4) + k1 * length * k_z**2 * end_orb%vec(3)**3 / 3

  ! Quadrupole body

  call quad_mat2_calc (k1, length, mat2)
  end_orb%vec(1) = end_orb%vec(1) + length * end_orb%vec(2)
  end_orb%vec(3:4) = matmul (mat2, end_orb%vec(3:4))

  ! 1/2 of the octupole octupole kick at the exit face.

  end_orb%vec(4) = end_orb%vec(4) + k1 * length * k_z**2 * end_orb%vec(3)**3 / 3
  call offset_particle (ele, end_orb, param, unset$)
  end_orb%vec(5) = start2_orb%vec(5) + length * (end_orb%beta * ele%value(e_tot$) / ele%value(p0c$) - &
                   1/sqrt(1 - (end_orb%vec(2) / rel_pc)**2 - (end_orb%vec(4) / rel_pc)**2)) &
                   - 0.5*k1*length / k_z**2 * (1 - rel_pc**2)
  call track1_low_energy_z_correction (end_orb, ele, param)

  end_orb%t = start2_orb%t + (ele%value(l$) - 0.5*k1*length / k_z**2 * rel_pc**2) / (end_orb%beta * c_light)
  end_orb%s = ele%s

!-----------------------------------------------
! unknown

case default

  if (present(err_flag)) err_flag = .true.
  call out_io (s_fatal$, r_name, &
          'BMAD_STANDARD TRACKING_METHOD NOT IMPLMENTED FOR: ' // key_name(ele%key), &
          'FOR ELEMENT: ' // ele%name)
  if (global_com%exit_on_error) call err_exit
  return

end select

!------------------------------------------
contains

subroutine time_and_s_calc ()

end_orb%t = start2_orb%t + (ele%value(l$) + start2_orb%vec(5) - end_orb%vec(5)) / (end_orb%beta * c_light)
end_orb%s = ele%s

end subroutine time_and_s_calc

!--------------------------------------------------------------
! contains

! Rough calculation for change in longitudinal position using:
!      dz = -L * (<x'^2> + <y'^2>)/ 2 
! where <...> means average.
! The formula below assumes a linear change in velocity between 
! the beginning and the end:

subroutine end_z_calc ()

implicit none

end_orb%vec(5) = start2_orb%vec(5) - (length / rel_pc**2) * &
      (start2_orb%vec(2)**2 + end_orb%vec(2)**2 + start2_orb%vec(2) * end_orb%vec(2) + &
       start2_orb%vec(4)**2 + end_orb%vec(4)**2 + start2_orb%vec(4) * end_orb%vec(4)) / 6

end subroutine end_z_calc

!--------------------------------------------------------------
! contains

subroutine coupler_kick_entrance ()

implicit none

dp_coupler = (ele%value(gradient$) * ele%value(gradient_err$)) * ele%value(field_scale$) * &
      ele%value(coupler_strength$) * cos(phase + twopi * ele%value(coupler_phase$))
dp_x_coupler = dp_coupler * cos (twopi * ele%value(coupler_angle$))
dp_y_coupler = dp_coupler * sin (twopi * ele%value(coupler_angle$))

if (nint(ele%value(coupler_at$)) == both_ends$) then
  dp_x_coupler = dp_x_coupler / 2
  dp_y_coupler = dp_y_coupler / 2
endif

if (nint(ele%value(coupler_at$)) == upstream_end$ .or. &
    nint(ele%value(coupler_at$)) == both_ends$) then
  end_orb%vec(2) = end_orb%vec(2) + dp_x_coupler / pc_start
  end_orb%vec(4) = end_orb%vec(4) + dp_y_coupler / pc_start
endif

end subroutine coupler_kick_entrance

!--------------------------------------------------------------
! contains

subroutine coupler_kick_exit ()

implicit none

if (nint(ele%value(coupler_at$)) == downstream_end$ .or. &
    nint(ele%value(coupler_at$)) == both_ends$) then
  end_orb%vec(2) = end_orb%vec(2) + dp_x_coupler / pc_end
  end_orb%vec(4) = end_orb%vec(4) + dp_y_coupler / pc_end
endif

end subroutine coupler_kick_exit

end subroutine track1_bmad
