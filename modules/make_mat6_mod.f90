#include "CESR_platform.inc"

module make_mat6_mod

  use dcslib_struct
  use dcslib_interface
  use physical_constants

contains

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!+
! Subroutine QUAD_MAT_CALC (K1, LENGTH, MAT)
!
! Subroutine to initialize the transfer matrix for a quad
!-

subroutine quad_mat_calc (k1, length, mat)

  implicit none

  real(rdef) length, mat(2,2), cx, sx
  real(rdef) k1, sqrt_k, arg, arg2

!

  sqrt_k = sqrt(abs(k1))
  arg = sqrt_k * length

  if (arg < 1e-3) then
    arg2 = k1 * length**2
    cx = 1 - arg2 / 2
    sx = (1 - arg2 / 6) * length
  elseif (k1 < 0) then       ! focus
    cx = cos(arg)
    sx = sin(arg) / sqrt_k
  else                           ! defocus
    cx = cosh(arg)
    sx = sinh(arg) / sqrt_k
  endif

  mat(1,1) = cx
  mat(1,2) = sx
  mat(2,1) = k1 * sx
  mat(2,2) = cx

end subroutine

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!+
! Subroutine SOL_QUAD_MAT6_CALC (KS, K1, LENGTH, MAT6, ORB)
!
! Subroutine to calculate the transfer matrix for a combination 
! solenoid/quadrupole element.
!
! Modules Needed:
!   use bmad
!
! Input:
!   ks      [Real]       Solenoid strength
!   k1      [Real]       Quadrupole strength
!   length  [Real]       Sol_quad length
!   orb(6)  [Real]       Orbit at beginning of the sol_quad.
!
! Output
!   mat6(6,6) [Real]  Transfer matrix across the sol_quad
!-

subroutine sol_quad_mat6_calc (ks, k1, s_len, m, orb)

  implicit none

  real(rdef) ks, k1, s_len
  real(rdef) m(6,6)
  real(rdef) orb(6)

  integer i, j
  integer order

  real(rdef) ks2, s, c, snh, csh
  real(rdef) darg1, alpha, alpha2, beta, beta2, f, q, r, a, b
  real(rdef) df, dalpha2, dalpha, dbeta2, dbeta, darg
  real(rdef) dC, dCsh, dS, dSnh, dq, dr, da, db
  real(rdef) ks3, fp, fm, dfm, dfp, df_f, ug
  real(rdef) s1, s2, snh1, snh2, dsnh1, dsnh2, ds1, ds2
  real(rdef) coef1, coef2, dcoef1, dcoef2, ks4

  real(rdef) t5(4,4), t6(4,4)

! Calc
          
  ks2 = ks**2
  ks3 = ks2 * ks 
  ks4 = ks2*ks2
  f = sqrt(ks4 + 4*k1**2)
  ug = 1 / (4*f)
  alpha2 = (f + ks2) / 2; alpha = sqrt(alpha2)
  beta2  = (f - ks2) / 2; beta  = sqrt(beta2)
  S = sin(alpha*s_len)                              
  C = cos(alpha*s_len)
  Snh = sinh(beta*s_len)
  Csh = cosh(beta*s_len)
  q = f + 2*k1 - ks2
  r = f - 2*k1 + ks2
  a = f + 2*k1 + ks2
  b = f - 2*k1 - ks2
  fp = f + 2*k1
  fm = f - 2*k1

  S1 = S * alpha
  S2 = S / alpha

  Snh1 = Snh * beta

  if (abs(beta) < 1e-10) then
    Snh2 = s_len
  else
    Snh2 = Snh / beta
  endif

  coef1 = ks2*r + 4*k1*a
  coef2 = ks2*q + 4*k1*b

  call mat_unit(m, 6, 6)
               
  m(1,1) = 2*ug * (fp*C + fm*Csh)
  m(1,2) = (2*ug/k1) * (q*S1 - r*Snh1)
  m(1,3) = (ks*ug/k1) * (-b*S1 + a*Snh1)
  m(1,4) = 4*ug*ks * (-C + Csh)

  m(2,1) = -(ug/2) * (coef1*S2 + coef2*Snh2)
  m(2,2) = m(1,1)             
  m(2,3) = ug*ks3 * (C - Csh)
  m(2,4) = ug*ks * (a*S2 + b*Snh2)

  m(3,1) = -m(2,4)
  m(3,2) = -m(1,4)
  m(3,3) = 2*ug * (fm*C + fp*Csh)  
  m(3,4) = 2*ug * (r*S2 + q*Snh2)

  m(4,1) = -m(2,3)     
  m(4,2) = -m(1,3)
  m(4,3) = (ug/(2*k1)) * (-coef2*S1 + coef1*Snh1)
  m(4,4) = m(3,3)

!

  if (all(orb(1:4) == 0)) return

  df      = -2 * (ks4 + 2*k1**2) / f
  dalpha2 = df/2 - ks2
  dalpha  = (df/2 - ks2)/(2*alpha)
  dbeta2  = ks2 + df/2
  if (beta < 1e-4) then
    dbeta   = -abs(k1**3/(ks3*ks2))
  else
    dbeta   = (ks2 + df/2)/(2*beta)
  endif
  darg    = s_len*dalpha
  darg1   = s_len*dbeta         
  dC      = -darg*S
  dCsh    = darg1*Snh
  dS      = darg*C
  dSnh    = darg1*Csh
  dq      = -2*k1 + 2*ks2 + df
  dr      =  2*k1 - 2*ks2 + df
  da      = -2*k1 - 2*ks2 + df
  db      =  2*k1 + 2*ks2 + df
  dfp = df - 2*k1
  dfm = df + 2*k1
  df_f =  -df/f

  dS1 = dS * alpha + S * dalpha
  dS2 = dS / alpha - S * dalpha / alpha2

  dSnh1 = dSnh * beta + Snh * dbeta

  if (beta < 1e-4) then
    dSnh2 = -k1**4 * s_len**3 / (3 * ks3**2)
  else
    dSnh2 = dSnh / beta - Snh * dbeta / beta2
  endif

  dcoef1 = -2*ks2*r + ks2*dr - 4*k1*a + 4*k1*da
  dcoef2 = -2*ks2*q + ks2*dq - 4*k1*b + 4*k1*db                     

  t6(1,1) = m(1,1)*df_f + 2*ug*(fp*dC + C*dfp + fm*dCsh + Csh*dfm)
  t6(1,2) = m(1,2)*df_f + (2*ug/k1) * (dq*S1 + q*dS1 - dr*Snh1 - r*dSnh1)
  t6(1,3) = m(1,3)*df_f + (ks*ug/k1)*(-db*S1 - b*dS1 + da*Snh1 + a*dSnh1)
  t6(1,4) = m(1,4)*(df_f - 2) + 4*ks*ug*(-dC + dCsh) 

  t6(2,1) = m(2,1)*(df_f + 1) - &
              (ug/2)*(dcoef1*S2 + coef1*dS2 + dcoef2*Snh2 + coef2*dSnh2)
  t6(2,2) = t6(1,1)
  t6(2,3) = m(2,3)*(df_f - 2) + ks3*ug*(dC - dCsh) 
  t6(2,4) = m(2,4)*(df_f - 1) + ug*ks*(da*S2 + a*dS2 + db*Snh2 + b*dSnh2)

  t6(3,1) = -t6(2,4)
  t6(3,2) = -t6(1,4)
  t6(3,3) = m(3,3)*df_f + 2*ug*(fm*dC + C*dfm + fp*dCsh + Csh*dfp)
  t6(3,4) = m(3,4)*(df_f - 1) + 2*ug*(dr*S2 + r*dS2 + dq*Snh2 + q*dSnh2)

  t6(4,1) = -t6(2,3)        
  t6(4,2) = -t6(1,3)
  t6(4,3) = m(4,3)*(df_f + 2) + &
               (ug/(2*k1))*(-dcoef2*S1 - coef2*dS1 + dcoef1*Snh1 + coef1*dSnh1)
  t6(4,4) = t6(3,3)

!

  m(1:4,6) = matmul(t6(1:4,1:4), orb(1:4))
  m(5,1) = -m(2,6)*m(1,1) + m(1,6)*m(2,1) - m(4,6)*m(3,1) + m(3,6)*m(4,1)
  m(5,2) = -m(2,6)*m(1,2) + m(1,6)*m(2,2) - m(4,6)*m(3,2) + m(3,6)*m(4,2)
  m(5,3) = -m(2,6)*m(1,3) + m(1,6)*m(2,3) - m(4,6)*m(3,3) + m(3,6)*m(4,3)
  m(5,4) = -m(2,6)*m(1,4) + m(1,6)*m(2,4) - m(4,6)*m(3,4) + m(3,6)*m(4,4)

end subroutine

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------

subroutine mat6_multipole (knl, tilt, c00, factor, mat6)

  implicit none

  real(rdef) c00(6)
  real(rdef) mat6(6,6), kmat1(4,4), factor
  real(rdef) knl(0:), tilt(0:)

  integer n

!                        

  if (c00(1) == 0 .and. c00(3) == 0 .and. knl(1) == 0) return

  do n = 1, ubound(knl, 1)
    if (knl(n) /= 0) then
      call mat4_multipole (knl(n), tilt(n), n, c00, kmat1)
      mat6(2:4:2, 1:3:2) = mat6(2:4:2, 1:3:2) + factor * kmat1(2:4:2, 1:3:2)
    endif
  enddo

end subroutine

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!+
! MAT4_MULTIPOLE (KNL, TILT, N, C0, KICK_MAT)
!
! Subroutine to find the kick from a multipole
!
! Input:
!     C0   -- Coord_struct: coordinates of particle
!     KNL  -- Real(rdef): Strength of multipole
!     TILT -- Real(rdef): Tilt of multipole
!
! Output:
!     KICK_MAT(4,4) -- Real(rdef): Kick matrix
!-


subroutine mat4_multipole (knl, tilt, n, c0, kick_mat)

  implicit none

  real(rdef) c0(6), c_multi
  real(rdef) x_pos, y_pos, x, y, knl, tilt
  real(rdef) sin_ang, cos_ang, mat(2,2), rot(2,2)
  real(rdef) kick_mat(4,4)

  integer m, n

! init

  kick_mat = 0
  forall (m = 1:4) kick_mat(m,m) = 1

  x_pos = c0(1)
  y_pos = c0(3)
           
! simple case

  if (knl == 0 .or. (x_pos == 0 .and. y_pos == 0 .and. n /= 1)) then
    kick_mat(2:4:2, 1:3:2) = 0
    return
  endif

! get position of particle in frame of multipole

  if (tilt == 0) then
    x = x_pos
    y = y_pos
  else
    sin_ang = sin(tilt)
    cos_ang = cos(tilt)
    x =  x_pos * cos_ang + y_pos * sin_ang
    y = -x_pos * sin_ang + y_pos * cos_ang
  endif

! compute kick matrix

  mat = 0

  do m = 0, n, 2
    mat(1,1) = mat(1,1) +  &
                    knl * (n-m) * c_multi(n, m) * mexp(x, n-m-1) * mexp(y, m)
    mat(1,2) = mat(1,2) +  &
                    knl * m * c_multi(n, m) * mexp(x, n-m) * mexp (y, m-1)
  enddo

  do m = 1, n, 2
    mat(2,1) = mat(2,1) +  &
                    knl * (n-m) * c_multi(n, m) * mexp(x, n-m-1) * mexp(y, m)
    mat(2,2) = mat(2,2) +  &
                    knl * m * c_multi(n, m) * mexp(x, n-m) * mexp(y, m-1)
  enddo

! transform back to lab frame

  if (tilt /= 0) then
    rot(1,1) =  cos_ang
    rot(1,2) = -sin_ang
    rot(2,1) =  sin_ang
    rot(2,2) =  cos_ang
    mat = matmul(rot, mat)
    rot(1,2) =  sin_ang
    rot(2,1) = -sin_ang
    mat = matmul (mat, rot)
  endif

  kick_mat(2,1) = mat(1,1)
  kick_mat(2,3) = mat(1,2)
  kick_mat(4,1) = mat(2,1)
  kick_mat(4,3) = mat(2,2)

end subroutine

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------

function mexp (x, m)

  implicit none

  real(rdef) x, mexp
  integer m

!

  if (m < 0) then
    mexp = 0
  elseif (m == 0) then
    mexp = 1
  else
    mexp = x**m
  endif

end function

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------

subroutine bbi_slice_calc (n_slice, sig_z, z_slice)

  implicit none

  integer i, n_slice, n_slice_old / 0 /

  real(rdef) sig_z, z_slice(:), y, inverse, z_norm(100)

  external probability_funct

  save z_norm

!

  if (n_slice == 1) then
    z_slice(1) = 0
  elseif (n_slice > 1) then
    do i = 1, n_slice
      if (n_slice /= n_slice_old) then
        y = (i - 0.5) / n_slice - 0.5
        z_norm(i) = inverse(probability_funct, y, -5.0, 5.0, 1.0e-5)
      endif
      z_slice(i) = sig_z * z_norm(i)
    enddo
    n_slice_old = n_slice
  else
    type *, 'ERROR IN BBI_SLICE_CALC: N_SLICE IS NEGATIVE:', n_slice
    call err_exit
  endif

  z_slice(n_slice+1) = 0

end subroutine

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!+
! Subroutine mat6_add_tilt_at_end (mat6, tilt)
!
! Subroutine to add a tilt matrix to a transfer matrix
!     mat6 -> tilt_mat * mat6
!-

subroutine mat6_add_tilt_at_end (mat6, tilt)

  implicit none

  real(rdef) tilt, mat6(6,6), mm(6,6)
  real(rdef) c, s

  if (tilt == 0) return

  c = cos(tilt)
  s = sin(tilt)

  mm(1,1:6) = c * mat6(1,1:6) - s * mat6(3,1:6)
  mm(2,1:6) = c * mat6(2,1:6) - s * mat6(4,1:6)
  mm(3,1:6) = c * mat6(3,1:6) + s * mat6(1,1:6)
  mm(4,1:6) = c * mat6(4,1:6) + s * mat6(2,1:6)
  mm(5,1:6) =     mat6(5,1:6)
  mm(6,1:6) =     mat6(6,1:6)

  mat6 = mm

end subroutine

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!+      
! Subroutine tilt_mat6 (mat6, tilt)
!
! Subroutine to transform a 6x6 transfer matrix to a new reference frame
! that is tilted in (x, Px, y, Py) with respect to the old reference frame.
!     mat6 -> tilt_mat * mat6 * tilt_mat_inverse
!-

subroutine tilt_mat6 (mat6, tilt)

  implicit none

  real(rdef) tilt, mat6(6,6), mm(6,6)
  real(rdef) c, s

!

  if (tilt == 0) return

  c = cos(tilt)
  s = sin(tilt)

  mm(1,1:6) = c * mat6(1,1:6) - s * mat6(3,1:6)
  mm(2,1:6) = c * mat6(2,1:6) - s * mat6(4,1:6)
  mm(3,1:6) = c * mat6(3,1:6) + s * mat6(1,1:6)
  mm(4,1:6) = c * mat6(4,1:6) + s * mat6(2,1:6)
  mm(5,1:6) =     mat6(5,1:6)
  mm(6,1:6) =     mat6(6,1:6)

  mat6(1:6,1) = mm(1:6,1) * c - mm(1:6,3) * s
  mat6(1:6,2) = mm(1:6,2) * c - mm(1:6,4) * s
  mat6(1:6,3) = mm(1:6,3) * c + mm(1:6,1) * s
  mat6(1:6,4) = mm(1:6,4) * c + mm(1:6,2) * s
  mat6(1:6,5) = mm(1:6,5)
  mat6(1:6,6) = mm(1:6,6)
                     
end subroutine

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------

subroutine solenoid_mat_calc (ks, length, mat4)

  implicit none

  real(rdef) ks, length, kss, c, s, c2, s2, cs, ll, kl, kl2
  real(rdef) mat4(4,4)

!

  kss = ks / 2

  if (abs(length * kss) < 1e-5) then
    ll = length
    kl = kss * length 
    kl2 = kl**2
    mat4(1,:) = (/  1.0_rdef,   ll,       kl,        kl*ll    /)
    mat4(2,:) = (/ -kl * kss,   1.0_rdef, kl2*kss,   kl       /)
    mat4(3,:) = (/ -kl,        -kl*ll,    1.0_rdef,  ll       /)
    mat4(4,:) = (/  kl2*kss,   -ks,      -kl*kss,    1.0_rdef /)
    return
  endif

  c = cos(kss*length)
  s = sin(kss*length)
  c2 = c*c
  s2 = s*s
  cs = c*s

  mat4(1,1) = c2
  mat4(1,2) = cs / kss
  mat4(1,3) = cs
  mat4(1,4) = s2 / kss
  mat4(2,1) = -kss * cs
  mat4(2,2) = c2
  mat4(2,3) = -kss * s2 
  mat4(2,4) = cs
  mat4(3,1) = -cs
  mat4(3,2) = -s2 / kss
  mat4(3,3) = c2
  mat4(3,4) = cs / kss
  mat4(4,1) = kss * s2
  mat4(4,2) = -cs
  mat4(4,3) = -kss * cs
  mat4(4,4) = c2

end subroutine

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!+
! Subroutine ACCEL_SOL_MAT_CALC (LS, C_M, C_E, GAMMA_OLD, GAMMA_NEW, B_X, B_Y,
!   COORD, MAT4, VEC_ST)
!
!   Subroutine to calculate the 4x4 transfer matrix (excluding steerings) for a
! segment of an accelerating solenoid.  A vector is also calculated for the
! steerings.
! -- Created by Daniel Fromowitz, September 1999.
!
! Input:
!     LS        -- Real(rdef): length of the segment
!     C_M       -- Real(rdef): constant proportional to the longitudinal magnetic
!                         field
!     C_E       -- Real(rdef): constant proportional to the electric field
!     GAMMA_OLD -- Real(rdef): Lorentz factor at beginning of segment
!     GAMMA_NEW -- Real(rdef): Lorentz factor at end of segment
!     B_X       -- Real(rdef): Horizontal field of transverse steering
!     B_Y       -- Real(rdef): Vertical field of transverse steering
!     COORD(6)  -- Real(rdef): Starting position
!
! Output:
!     MAT4(4,4) -- Real(rdef): 4x4 transfer matrix excluding steerings
!     VEC_ST(4) -- Real(rdef): Vector due to steerings (assuming positrons)
!-

!$Id$
!$Log$
!Revision 1.5  2002/11/05 18:06:28  dcs
!Minor Mods
!
!Revision 1.4  2002/10/29 17:07:28  dcs
!*** empty log message ***
!
!Revision 1.3  2002/08/20 20:35:07  dcs
!symp_lie_bmad / symp_lie_ptc added
!
!Revision 1.3  2002/02/23 20:32:09  dcs
!Double/Single Real toggle added
!
!Revision 1.2  2001/09/27 18:31:47  rwh24
!UNIX compatibility updates
!

subroutine accel_sol_mat_calc (ls, c_m, c_e, gamma_old, gamma_new, b_x,  &
                                                     b_y, coord, mat4, vec_st)

  implicit none

  
  real(rdef) ls, c_m, c_e, gamma_old, gamma_new, b_x, b_y, mat4(4,4), vec_st(4)
  real(rdef) coef, cosr, sinr, denom, ratio, ratio_c_m, sinr_c_m, onecosr_c_m
  real(rdef) mat_st(4,2), coord(6)
  integer i

  if (abs(c_e) > 0.001) then
    ratio_c_m = log(gamma_new / gamma_old) / c_e
    ratio = c_m * ratio_c_m
  else
    ratio_c_m = ls / gamma_old * (1 - c_e * ls / (2 * gamma_old))
    ratio = c_m * ratio_c_m
  endif
  if (abs(c_m) > 0.001) then
    sinr_c_m = sin(ratio) / c_m
    onecosr_c_m = (1 - cos(ratio)) / c_m
  else
    sinr_c_m = ratio_c_m
    onecosr_c_m = c_m * ratio_c_m**2 / 2
  endif
  sinr = sin(ratio)
  cosr = cos(ratio)

  mat4(1,1) = 1
  mat4(1,2) = gamma_old * sinr_c_m
  mat4(1,3) = 0
  mat4(1,4) = gamma_old * onecosr_c_m
  mat4(2,1) = 0
  mat4(2,2) = cos(ratio) * gamma_old / gamma_new
  mat4(2,3) = 0
  mat4(2,4) = sin(ratio) * gamma_old / gamma_new
  mat4(3,1) = 0
  mat4(3,2) = -mat4(1,4)
  mat4(3,3) = 1
  mat4(3,4) = mat4(1,2)
  mat4(4,1) = 0
  mat4(4,2) = -mat4(2,4)
  mat4(4,3) = 0
  mat4(4,4) = mat4(2,2)

!     Steerings:

  if ((b_x /= 0.0) .or. (b_y /= 0.0)) then
    denom = c_e**2 + c_m**2
    if (denom > 2.e-6) then
      coef = c_light / (e_mass * 1.e9) / denom
      mat_st(1,1) = coef *  &
                    (c_m * ls - gamma_old * (c_e * onecosr_c_m + sinr))
      mat_st(1,2) = coef * (gamma_old * (cosr + c_e * sinr_c_m) - gamma_new)
      mat_st(2,1) = coef *  &
                   (c_m - gamma_old / gamma_new * (c_e * sinr + c_m * cosr))
      mat_st(2,2) = coef *  &
                   (gamma_old / gamma_new * (c_e * cosr - c_m * sinr) - c_e)
    else
      coef = c_light / (e_mass * 1.e9)  &
        * sqrt((1 + coord(2)**2 + coord(4)**2) / (gamma_old**2 - 1))
      mat_st(1,1) = 0
      mat_st(1,2) = -coef * ls**2 / 2
      mat_st(2,1) = 0
      mat_st(2,2) = -coef * ls
    endif
    mat_st(3,1) = -mat_st(1,2)
    mat_st(3,2) =  mat_st(1,1)
    mat_st(4,1) = -mat_st(2,2)
    mat_st(4,2) =  mat_st(2,1)
    do i = 1, 4
      vec_st(i) = mat_st(i,1) * b_x + mat_st(i,2) * b_y
    enddo
  else
    do i = 1, 4
      vec_st(i) = 0
    enddo
  endif

end subroutine


!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!+
! Subroutine drift_mat6_calc (mat6, length, orb)
!-

subroutine drift_mat6_calc (mat6, length, orb)

  implicit none

  real(rdef) orb(:)
  real(rdef) mat6(:,:), length, rel_E, len_E

!

  call mat_make_unit(mat6)

  if (length == 0) return

  rel_E = 1 + orb(6)
  len_E = length / rel_E**2

  mat6(1,2) = length / rel_E
  mat6(3,4) = length / rel_E
  mat6(1,6) = -orb(2) * len_E
  mat6(3,6) = -orb(4) * len_E
  mat6(5,2) = -orb(2) * len_E
  mat6(5,4) = -orb(4) * len_E
  mat6(5,6) = (orb(2)**2 + orb(4)**2) * len_E / rel_E

end subroutine

end module
