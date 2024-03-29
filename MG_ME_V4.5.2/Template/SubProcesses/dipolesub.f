************************************************************************
*                                                                      *
*     Original author: J. M. Campbell                                  *
*     August, 2001                                                     *
*                                                                      *
*     Adapted by RF and NG for MadGraph/MadEvent (June, 2008)          *
*                                                                      *
*                                                                      *
*     Calculates the dipole (chooses automatically the correct         *
*     structure) in the Catani-Seymour formulation hep-ph/9605323      *
*     convention: C_F=4/3  C_A=3 ,T_R=1/2                              *
*                                                                      *
*     Returns the dipoles in sub,subv                                  *
*                                                                      *
*     p(0:3,nexternal) is the momentum of the n+1 particle config      *
*                                                                      *
*     ip labels the emitter parton                                     *
*     jp labels the unresolved parton                                  *
*     kp labels the spectator parton                                   *
*     ijp labels the emitter parton before emittion                    *
*     kkp labels the spectator parton before emittion                  *
*                                                                      *
*     ig labels the emitter parton type                                *
*     jg labels the unresolved parton type                             *
*     kg labels the spectator parton type                              *
*     ijg labels the emitter parton before emittion type               *
*     kkg labels the spectator parton before emittion type             *
*                                                                      *
*     w1,w2 label the polarisation vector which are needed to          *
*           to contract the tensor V_mu_nu                             *
************************************************************************

      subroutine dipolesub(p,ip,jp,kp,ijp,kkp,ig,jg,kg,ijg,kkg,mass_i,mass_j,mass_k,w1,w2,sub,subv)
      implicit none
      include 'nexternal.inc'
      include 'coupl.inc'
c Arguments
      double precision p(0:3,nexternal),sub,mass_i,mass_j,mass_k
      integer ip,jp,kp,ijp,kkp,ig,jg,kg,ijg,kkg
      complex*16 w1(18),w2(18),subv
c Local
      double precision x,omx,z,omz,y,omy,u,omu,sij,sik,sjk,dot,vecsq,gsq
      double precision one,two,three,four,eight,cf,ca,lambda_tr,vij,vtildeij
      double precision musq_i,musq_j,musq_k,musq_ij,pij(0:3),msq_i,msq_j
      double precision msq_k,msq_ij,qtot(0:3),qsq,zm,omzm,pijsq
      parameter (one=1d0,two=2d0,three=3d0,four=4d0,eight=8d0)
      parameter (cf=4d0/3d0,ca=3d0)
      complex*16 vec1(0:3),vec1conjg(0:3),vec2(0:3),dotrc,dotcc
      integer i

      external lambda_tr

      logical firsttime
      data firsttime /.false./

      if (firsttime) then
         write (*,*)'Using the "dipolesub(..)" subroutine, '//
     &        'originally written by J.M. Campbell, Aug 2001.'
         write (*,*)'Adapted for MadDipole by '//
     &        'N. Greiner & R. Frederix Jun. 2008.'
         firsttime=.false.
      endif
      


C---Initialize the dipoles to zero
      sub  = 0d0
      subv = (0d0,0d0)

      sij = dot(p(0,ip),p(0,jp))
      sik = dot(p(0,ip),p(0,kp))
      sjk = dot(p(0,jp),p(0,kp))
      
      gsq = GG(1)**2

      do i=1,4
       vec1(i-1)=w1(i)
       vec1conjg(i-1)=dconjg(w1(i))
       vec2(i-1)=w2(i)
       pij(i-1)=p(i-1,ip)+p(i-1,jp)
       qtot(i-1)=p(i-1,ip)+p(i-1,jp)+p(i-1,kp)
      enddo

      if(mass_i.lt.1d-5.and.mass_k.lt.1d-5) then
      if ((ip .le. nincoming) .and. (kp .le. nincoming)) then
***********************************************************************
*************************** INITIAL-INITIAL ***************************
***********************************************************************
         omx=(sij+sjk)/sik
         x=one-omx
         vecsq=sij*sjk/sik

         if    (ig.eq.1.and.jg.eq.0) then
            sub = gsq/x/sij*(two/omx-one-x)
         elseif(ig.eq.0.and.jg.eq.1) then
            sub = gsq/x/sij/cf/two*(one-two*x*omx)
         elseif(ig.eq.1.and.jg.eq.1) then
           sub=DREAL(gsq/x/sij*cf/ca*(-dotcc(vec1conjg,vec1)*x+omx/x*two*sik/sij/sjk*
     &         (dotrc(p(0,jp),vec1conjg)-sij/sik*dotrc(p(0,kp),vec1conjg))*
     &         (dotrc(p(0,jp),vec1)-sij/sik*dotrc(p(0,kp),vec1))))
           subv=gsq/x/sij*cf/ca*(-dotcc(vec1conjg,vec2)*x+omx/x*two*sik/sij/sjk*
     &         (dotrc(p(0,jp),vec1conjg)-sij/sik*dotrc(p(0,kp),vec1conjg))*
     &         (dotrc(p(0,jp),vec2)-sij/sik*dotrc(p(0,kp),vec2)))  
         elseif(ig.eq.0.and.jg.eq.0) then
           sub=DREAL(two*gsq/x/sij*(-dotcc(vec1conjg,vec1)*(x/omx+x*omx)+
     &         omx/x*sik/sij/sjk*(dotrc(p(0,jp),vec1conjg)-sij/sik*
     &         dotrc(p(0,kp),vec1conjg))*(dotrc(p(0,jp),vec1)-sij/sik*
     &         dotrc(p(0,kp),vec1))))
           subv=two*gsq/x/sij*(-dotcc(vec1conjg,vec2)*(x/omx+x*omx)+
     &         omx/x*sik/sij/sjk*(dotrc(p(0,jp),vec1conjg)-sij/sik*
     &         dotrc(p(0,kp),vec1conjg))*(dotrc(p(0,jp),vec2)-sij/sik*
     &         dotrc(p(0,kp),vec2)))
           else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif

         
***********************************************************************
***************************INITIAL-FINAL *****************************
***********************************************************************
      elseif ((ip .le. nincoming) .and. (kp .gt. nincoming)) then
         omx=sjk/(sij+sik)
         x=one-omx
         u=sij/(sij+sik)
         omu=sik/(sij+sik)
         if    (ig.eq.1.and.jg.eq.0) then
            sub = gsq/x/sij*(two/(omx+u)-one-x)
         elseif(ig.eq.0.and.jg.eq.1) then 
            sub = gsq/x/sij/cf/two*(one-two*x*omx)
         elseif(ig.eq.1.and. jg.eq.1) then
           sub=DREAL(gsq/x/sij*cf/ca*(-dotcc(vec1conjg,vec1)*x+omx/x*two*u*omu/sjk*
     &         (dotrc(p(0,jp),vec1conjg)/u-dotrc(p(0,kp),vec1conjg)/omu)*
     &         (dotrc(p(0,jp),vec1)/u-dotrc(p(0,kp),vec1)/omu)))
           subv=gsq/x/sij*cf/ca*(-dotcc(vec1conjg,vec2)*x+omx/x*two*u*omu/sjk*
     &         (dotrc(p(0,jp),vec1conjg)/u-dotrc(p(0,kp),vec1conjg)/omu)*
     &         (dotrc(p(0,jp),vec2)/u-dotrc(p(0,kp),vec2)/omu))
         elseif(ig.eq.0.and.jg.eq.0) then
           sub=DREAL((two*gsq)/x/sij*(-dotcc(vec1conjg,vec1)*(one/(omx+u)-one
     &         +x*omx)+omx/x*u*omu/sjk*(dotrc(p(0,jp),vec1conjg)/u
     &         -dotrc(p(0,kp),vec1conjg)/omu)*(dotrc(p(0,jp),vec1)/u
     &         -dotrc(p(0,kp),vec1)/omu)))
           subv=(two*gsq)/x/sij*(-dotcc(vec1conjg,vec2)*(one/(omx+u)-one
     &         +x*omx)+omx/x*u*omu/sjk*(dotrc(p(0,jp),vec1conjg)/u
     &         -dotrc(p(0,kp),vec1conjg)/omu)*(dotrc(p(0,jp),vec2)/u
     &         -dotrc(p(0,kp),vec2)/omu))
         else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif


***********************************************************************
*************************** FINAL-INITIAL *****************************
***********************************************************************
      elseif ((ip .gt. nincoming) .and. (kp .le. nincoming)) then

         omx=sij/(sjk+sik)
         x=one-omx
         z=sik/(sik+sjk)
         omz=sjk/(sik+sjk)
                
         if    (ig.eq.1.and.jg.eq.0) then
            sub =gsq/x/sij*(two/(omz+omx)-one-z)
          elseif(ig.eq.0.and.jg.eq.0) then
           sub=DREAL(two*gsq/x/sij*(-dotcc(vec1conjg,vec1)*(one/(omz+omx)+
     &         one/(z+omx)-two)+one/sij*(z*dotrc(p(0,ip),vec1conjg)-
     &         omz*dotrc(p(0,jp),vec1conjg))*(z*dotrc(p(0,ip),vec1)-
     &         omz*dotrc(p(0,jp),vec1))))
           subv=two*gsq/x/sij*(-dotcc(vec1conjg,vec2)*(one/(omz+omx)+
     &         one/(z+omx)-two)+one/sij*(z*dotrc(p(0,ip),vec1conjg)-
     &         omz*dotrc(p(0,jp),vec1conjg))*(z*dotrc(p(0,ip),vec2)-
     &         omz*dotrc(p(0,jp),vec2)))
          elseif(ig.eq.1.and.jg.eq.1) then
           sub=DREAL(gsq/(two*x*ca*sij)*(-dotcc(vec1conjg,vec1)-two/sij*
     &         (z*dotrc(p(0,ip),vec1conjg)-omz*dotrc(p(0,jp),vec1conjg))*
     &         (z*dotrc(p(0,ip),vec1)-omz*dotrc(p(0,jp),vec1))))
           subv=gsq/(two*x*ca*sij)*(-dotcc(vec1conjg,vec2)-two/sij*
     &         (z*dotrc(p(0,ip),vec1conjg)-omz*dotrc(p(0,jp),vec1conjg))*
     &         (z*dotrc(p(0,ip),vec2)-omz*dotrc(p(0,jp),vec2)))
         else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif



***********************************************************************
**************************** FINAL-FINAL ******************************
***********************************************************************
      elseif ((ip .gt. nincoming) .and. (kp .gt. nincoming)) then
         y=sij/(sij+sjk+sik)
         z=sik/(sjk+sik)
         omz=one-z
         omy=one-y
              
         if    (ig.eq.1.and.jg.eq.0) then
            sub = gsq/sij*(two/(one-z*omy)-one-z)
          elseif(ig.eq.1.and.jg.eq.1) then
           sub=DREAL(gsq/(ca*two*sij)*(-dotcc(vec1conjg,vec1)-two/sij*
     &         (z*dotrc(p(0,ip),vec1conjg)-omz*dotrc(p(0,jp),vec1conjg))*
     &         (z*dotrc(p(0,ip),vec1)-omz*dotrc(p(0,jp),vec1))))
           subv=gsq/(ca*two*sij)*(-dotcc(vec1conjg,vec2)-two/sij*
     &         (z*dotrc(p(0,ip),vec1conjg)-omz*dotrc(p(0,jp),vec1conjg))*
     &         (z*dotrc(p(0,ip),vec2)-omz*dotrc(p(0,jp),vec2)))
          elseif(ig.eq.0.and.jg.eq.0) then
           sub=DREAL(two*gsq/sij*(-dotcc(vec1conjg,vec1)*(one/(one-z*omy)+
     &         one/(one-omz*omy)-two)+one/sij*(z*dotrc(p(0,ip),vec1conjg)-omz*
     &         dotrc(p(0,jp),vec1conjg))*(z*dotrc(p(0,ip),vec1)-omz*dotrc(p(0,jp),vec1))))
           subv=two*gsq/sij*(-dotcc(vec1conjg,vec2)*(one/(one-z*omy)+
     &         one/(one-omz*omy)-two)+one/sij*(z*dotrc(p(0,ip),vec1conjg)-omz*
     &         dotrc(p(0,jp),vec1conjg))*(z*dotrc(p(0,ip),vec2)-omz*dotrc(p(0,jp),vec2)))
         else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif
      endif


      else
c  Massive case
      msq_i=mass_i**2
      msq_k=mass_k**2
      msq_j=mass_j**2
      if(mass_i .eq.mass_j) then
       msq_ij=0d0
      else
       msq_ij=msq_i
      endif
      qsq=dot(qtot,qtot)


      if ((ip .le. nincoming) .and. (kp .le. nincoming)) then
***********************************************************************
*************************** INITIAL-INITIAL ***************************
***********************************************************************
         omx=(sij+sjk)/sik
         x=one-omx
         vecsq=sij*sjk/sik

         if    (ig.eq.1.and.jg.eq.0) then
            sub = gsq/x/sij*(two/omx-one-x)
         elseif(ig.eq.0.and.jg.eq.1) then
            sub = gsq/x/sij/cf/two*(one-two*x*omx)
         elseif(ig.eq.1.and.jg.eq.1) then
           sub=DREAL(gsq/x/sij*cf/ca*(-dotcc(vec1conjg,vec1)*x+omx/x*two*sik/sij/sjk*
     &         (dotrc(p(0,jp),vec1conjg)-sij/sik*dotrc(p(0,kp),vec1conjg))*
     &         (dotrc(p(0,jp),vec1)-sij/sik*dotrc(p(0,kp),vec1))))
           subv=gsq/x/sij*cf/ca*(-dotcc(vec1conjg,vec2)*x+omx/x*two*sik/sij/sjk*
     &         (dotrc(p(0,jp),vec1conjg)-sij/sik*dotrc(p(0,kp),vec1conjg))*
     &         (dotrc(p(0,jp),vec2)-sij/sik*dotrc(p(0,kp),vec2)))  
         elseif(ig.eq.0.and.jg.eq.0) then
           sub=DREAL(two*gsq/x/sij*(-dotcc(vec1conjg,vec1)*(x/omx+x*omx)+
     &         omx/x*sik/sij/sjk*(dotrc(p(0,jp),vec1conjg)-sij/sik*
     &         dotrc(p(0,kp),vec1conjg))*(dotrc(p(0,jp),vec1)-sij/sik*
     &         dotrc(p(0,kp),vec1))))
           subv=two*gsq/x/sij*(-dotcc(vec1conjg,vec2)*(x/omx+x*omx)+
     &         omx/x*sik/sij/sjk*(dotrc(p(0,jp),vec1conjg)-sij/sik*
     &         dotrc(p(0,kp),vec1conjg))*(dotrc(p(0,jp),vec2)-sij/sik*
     &         dotrc(p(0,kp),vec2)))
           else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif

         
***********************************************************************
***************************INITIAL-FINAL *****************************
***********************************************************************
      elseif ((ip .le. nincoming) .and. (kp .gt. nincoming)) then
         omx=sjk/(sij+sik)
         x=one-omx
         u=sij/(sij+sik)
         omu=sik/(sij+sik)

         if    (ig.eq.1.and.jg.eq.0) then
            sub = gsq/x/sij*(two/(omx+u)-one-x)
         elseif(ig.eq.0.and.jg.eq.1) then 
            sub = gsq/x/sij/cf/two*(one-two*x*omx)
         elseif(ig.eq.1.and. jg.eq.1) then
           sub=DREAL(gsq/x/sij*cf/ca*(-dotcc(vec1conjg,vec1)*x+omx/x*two*u*omu/sjk*
     &         (dotrc(p(0,jp),vec1conjg)/u-dotrc(p(0,kp),vec1conjg)/omu)*
     &         (dotrc(p(0,jp),vec1)/u-dotrc(p(0,kp),vec1)/omu)))
           subv=gsq/x/sij*cf/ca*(-dotcc(vec1conjg,vec2)*x+omx/x*two*u*omu/sjk*
     &         (dotrc(p(0,jp),vec1conjg)/u-dotrc(p(0,kp),vec1conjg)/omu)*
     &         (dotrc(p(0,jp),vec2)/u-dotrc(p(0,kp),vec2)/omu))
         elseif(ig.eq.0.and.jg.eq.0) then
           sub=DREAL((two*gsq)/x/sij*(-dotcc(vec1conjg,vec1)*(one/(omx+u)-one
     &         +x*omx)+omx/x*u*omu/sjk*(dotrc(p(0,jp),vec1conjg)/u
     &         -dotrc(p(0,kp),vec1conjg)/omu)*(dotrc(p(0,jp),vec1)/u
     &         -dotrc(p(0,kp),vec1)/omu)))
           subv=(two*gsq)/x/sij*(-dotcc(vec1conjg,vec2)*(one/(omx+u)-one
     &         +x*omx)+omx/x*u*omu/sjk*(dotrc(p(0,jp),vec1conjg)/u
     &         -dotrc(p(0,kp),vec1conjg)/omu)*(dotrc(p(0,jp),vec2)/u
     &         -dotrc(p(0,kp),vec2)/omu))
         else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif


***********************************************************************
*************************** FINAL-INITIAL *****************************
***********************************************************************
      elseif ((ip .gt. nincoming) .and. (kp .le. nincoming)) then

         omx=(sij-0.5d0*(msq_ij-msq_i-msq_j))/(sjk+sik)
         x=one-omx
         z=sik/(sik+sjk)
         omz=sjk/(sik+sjk)
c         musq_i=msq_i/sqrt(two*(dot(p(0,ip),p(0,kp))+dot(p(0,jp),p(0,kp))
c     &           -omx*msq_k
c         musq_j=msq_j/sqrt(two*(dot(p(0,ip),p(0,kp))+dot(p(0,jp),p(0,kp))
c     &           -omx*msq_k
c         musq_k=msq_k/sqrt(two*(dot(p(0,ip),p(0,kp))+dot(p(0,jp),p(0,kp))
c     &           -omx*msq_k
         if    (ig.eq.1.and.jg.eq.0) then
            sub =two*gsq/x/(dot(pij,pij)-msq_ij)*(two/(omz+omx)-one-z-msq_i/sij)
c           print*, p(0,jp)
          elseif(ig.eq.0.and.jg.eq.0) then
           sub=DREAL(two*gsq/x/sij*(-dotcc(vec1conjg,vec1)*(one/(omz+omx)+
     &         one/(z+omx)-two)+one/sij*(z*dotrc(p(0,ip),vec1conjg)-
     &         omz*dotrc(p(0,jp),vec1conjg))*(z*dotrc(p(0,ip),vec1)-
     &         omz*dotrc(p(0,jp),vec1))))
           subv=two*gsq/x/sij*(-dotcc(vec1conjg,vec2)*(one/(omz+omx)+
     &         one/(z+omx)-two)+one/sij*(z*dotrc(p(0,ip),vec1conjg)-
     &         omz*dotrc(p(0,jp),vec1conjg))*(z*dotrc(p(0,ip),vec2)-
     &         omz*dotrc(p(0,jp),vec2)))
          elseif(ig.eq.1.and.jg.eq.1) then
           sub=DREAL(gsq/(x*ca*(dot(pij,pij)-msq_ij))*(-dotcc(vec1conjg,vec1)-four/dot(pij,pij)*
     &         (z*dotrc(p(0,ip),vec1conjg)-omz*dotrc(p(0,jp),vec1conjg))*
     &         (z*dotrc(p(0,ip),vec1)-omz*dotrc(p(0,jp),vec1))))
           subv=gsq/(x*ca*(dot(pij,pij)-msq_ij))*(-dotcc(vec1conjg,vec2)-four/dot(pij,pij)*
     &         (z*dotrc(p(0,ip),vec1conjg)-omz*dotrc(p(0,jp),vec1conjg))*
     &         (z*dotrc(p(0,ip),vec2)-omz*dotrc(p(0,jp),vec2)))
         else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif



***********************************************************************
**************************** FINAL-FINAL ******************************
***********************************************************************
      elseif ((ip .gt. nincoming) .and. (kp .gt. nincoming)) then
         y=sij/(sij+sjk+sik)
         z=sik/(sjk+sik)
         omz=one-z
         omy=one-y
         musq_i=msq_i/qsq
         musq_j=msq_j/qsq
         musq_k=msq_k/qsq
         musq_ij=msq_ij/qsq
         pijsq=dot(pij,pij)
c         print*, mass_i,mass_j,mass_k,msq_i,msq_j,msq_k,msq_ij
         vij=sqrt((two*musq_k+(one-musq_i-musq_j-musq_k)*omy)**2-four*musq_k)/
     &       ((one-musq_i-musq_j-musq_k)*omy)
         vtildeij=sqrt(lambda_tr(one,musq_ij,musq_k))/(one-musq_ij-musq_k)
         zm=z-0.5d0*(1d0-vij)
         omzm=omz-0.5d0*(1d0-vij)
         if(ig.eq.1.and.jg.eq.0) then
            sub = two*gsq/(pijsq-msq_ij)*(two/(one-z*omy)-vtildeij/vij*(one+z+msq_i/sij))
c            print*,sub,gsq/sij*(two/(one-z*omy)-one-z)
c sub = gsq/sij*(two/(one-z*omy)-one-z)
c            print*,sub/(gsq/sij*(two/(one-z*omy)-one-z))
          elseif(ig.eq.1.and.jg.eq.1) then
           sub=DREAL(gsq/(ca*(dot(pij,pij)-msq_ij)*vij)*(-dotcc(vec1conjg,vec1)-four/dot(pij,pij)*
     &         (zm*dotrc(p(0,ip),vec1conjg)-omzm*dotrc(p(0,jp),vec1conjg))*
     &         (zm*dotrc(p(0,ip),vec1)-omzm*dotrc(p(0,jp),vec1))))
           subv=gsq/(ca*(dot(pij,pij)-msq_ij)*vij)*(-dotcc(vec1conjg,vec2)-four/dot(pij,pij)*
     &         (zm*dotrc(p(0,ip),vec1conjg)-omzm*dotrc(p(0,jp),vec1conjg))*
     &         (zm*dotrc(p(0,ip),vec2)-omzm*dotrc(p(0,jp),vec2)))
          elseif(ig.eq.0.and.jg.eq.0) then
           sub=DREAL(four*gsq/(dot(pij,pij)-msq_ij)*(-dotcc(vec1conjg,vec1)*(one/(one-z*omy)+
     &         one/(one-omz*omy)-two/vij)+one/sij/vij*(zm*dotrc(p(0,ip),vec1conjg)-omzm*
     &         dotrc(p(0,jp),vec1conjg))*(zm*dotrc(p(0,ip),vec1)-omzm*dotrc(p(0,jp),vec1))))
           subv=four*gsq/(dot(pij,pij)-msq_ij)*(-dotcc(vec1conjg,vec2)*(one/(one-z*omy)+
     &         one/(one-omz*omy)-two/vij)+one/sij/vij*(zm*dotrc(p(0,ip),vec1conjg)-omzm*
     &         dotrc(p(0,jp),vec1conjg))*(zm*dotrc(p(0,ip),vec2)-omzm*dotrc(p(0,jp),vec2)))
         else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif

      endif


      endif

      return

      end


      subroutine dipolesubqed(p,ip,jp,kp,ijp,kkp,ig,jg,kg,ijg,kkg,qint1,qint2,
     &                          mass_i,mass_j,mass_k,w1,w2,sub,subv)
! ******************************************************
! This is the equivalent subroutine as dipolesub above,
! but for photon radiation
! ******************************************************
      implicit none
      include 'nexternal.inc'
      include 'coupl.inc'
c Arguments
      double precision p(0:3,nexternal),sub,mass_i,mass_j,mass_k
      integer ip,jp,kp,ijp,kkp,ig,jg,kg,ijg,kkg,qint1,qint2
      complex*16 w1(18),w2(18),subv
c Local
      double precision x,omx,z,omz,y,omy,u,omu,sij,sik,sjk,dot,vecsq,gsq
      double precision one,two,three,four,eight,cf,ca,lambda_tr,vij,vtildeij
      double precision musq_i,musq_j,musq_k,musq_ij,pij(0:3),msq_i,msq_j
      double precision msq_k,msq_ij,qtot(0:3),qsq,zm,omzm,pijsq,qem(2)
      double precision pbijsq,crij,srij,pia(0:3),piasq,pbiasq,cria,sria
      real*8 subvr, dotij,dotik,dotjk,nc
      parameter (one=1d0,two=2d0,three=3d0,four=4d0,eight=8d0)
      parameter (cf=4d0/3d0,ca=3d0)
      complex*16 vec1(0:3),vec1conjg(0:3),vec2(0:3),dotrc,dotcc
      integer i,qint(2),nu

      external lambda_tr

      logical firsttime
      data firsttime /.false./

      if (firsttime) then
         write (*,*)'Using the "dipolesub(..)" subroutine, '//
     &        'originally written by J.M. Campbell, Aug 2001.'
         write (*,*)'Adapted for MadDipole by N. Greiner, May 2010.'
         firsttime=.false.
      endif


C---Initialize the dipoles to zero
      sub  = 0d0
      subv = (0d0,0d0)

      sij = dot(p(0,ip),p(0,jp))
      sik = dot(p(0,ip),p(0,kp))
      sjk = dot(p(0,jp),p(0,kp))
      
      gsq = DReal(gal(1))**2

c  extract the electromagnetic charge out of integers
      qint(1)=qint1
      qint(2)=qint2
      do i=1,2
       if(qint(i).eq.23) then
         qem(i)=2d0/3d0
       elseif(qint(i).eq.-23) then
         qem(i)=-2d0/3d0
       elseif(qint(i).eq.13) then
         qem(i)=1d0/3d0
       elseif(qint(i).eq.-13) then
         qem(i)=-1d0/3d0
       elseif(qint(i).eq.1) then
         qem(i)=1d0
       elseif(qint(i).eq.-1) then
         qem(i)=-1d0
       endif
      enddo
c      print*, qem(1), qem(2)

c determine the color factor for final-final a -> f fbar splitting
      if(abs(qem(1)).eq.1d0.or.ig.ne.jg) then
        nc=1d0
      elseif(abs(qem(1)).ne.1d0.and.ig.eq.jg) then
        nc=3d0
      endif

      do i=1,4
       vec1(i-1)=w1(i)
       vec1conjg(i-1)=dconjg(w1(i))
       vec2(i-1)=w2(i)
       pij(i-1)=p(i-1,ip)+p(i-1,jp)
       qtot(i-1)=p(i-1,ip)+p(i-1,jp)+p(i-1,kp)
      enddo

      if(mass_i.lt.1d-5.and.mass_k.lt.1d-5) then
      if ((ip .le. nincoming) .and. (kp .le. nincoming)) then
***********************************************************************
*************************** INITIAL-INITIAL ***************************
***********************************************************************
         omx=(sij+sjk)/sik
         x=one-omx
         vecsq=sij*sjk/sik

         if    (ig.eq.1.and.jg.eq.0) then
            sub = qem(1)*qem(2)*gsq/x/sij*(two/omx-one-x)
c          print*, p(0,1),p(1,1),p(2,1),p(3,1)
         elseif(ig.eq.0.and.jg.eq.1) then
            sub = nc*qem(1)*qem(2)*gsq/x/sij*(one-two*x*omx)
         elseif(ig.eq.1.and.jg.eq.1) then
           sub=DREAL(qem(1)*qem(2)*gsq/x/sij*(-dotcc(vec1conjg,vec1)*x+omx/x*two*sik/sij/sjk*
     &         (dotrc(p(0,jp),vec1conjg)-sij/sik*dotrc(p(0,kp),vec1conjg))*
     &         (dotrc(p(0,jp),vec1)-sij/sik*dotrc(p(0,kp),vec1))))
           subv=qem(1)*qem(2)*gsq/x/sij*(-dotcc(vec1conjg,vec2)*x+omx/x*two*sik/sij/sjk*
     &         (dotrc(p(0,jp),vec1conjg)-sij/sik*dotrc(p(0,kp),vec1conjg))*
     &         (dotrc(p(0,jp),vec2)-sij/sik*dotrc(p(0,kp),vec2)))  
         else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif

         
***********************************************************************
***************************INITIAL-FINAL *****************************
***********************************************************************
      elseif ((ip .le. nincoming) .and. (kp .gt. nincoming)) then
         omx=sjk/(sij+sik)
         x=one-omx
         u=sij/(sij+sik)
         omu=sik/(sij+sik)
         if    (ig.eq.1.and.jg.eq.0) then
            sub = qem(1)*qem(2)*gsq/x/sij*(two/(omx+u)-one-x)
         elseif(ig.eq.0.and.jg.eq.1) then 
            sub = nc*qem(1)*qem(2)*gsq/x/sij*(one-two*x*omx)
         elseif(ig.eq.1.and. jg.eq.1) then
           sub=DREAL(qem(1)*qem(2)*gsq/x/sij*(-dotcc(vec1conjg,vec1)*x+omx/x*two*u*omu/sjk*
     &         (dotrc(p(0,jp),vec1conjg)/u-dotrc(p(0,kp),vec1conjg)/omu)*
     &         (dotrc(p(0,jp),vec1)/u-dotrc(p(0,kp),vec1)/omu)))
           subv=qem(1)*qem(2)*gsq/x/sij*(-dotcc(vec1conjg,vec2)*x+omx/x*two*u*omu/sjk*
     &         (dotrc(p(0,jp),vec1conjg)/u-dotrc(p(0,kp),vec1conjg)/omu)*
     &         (dotrc(p(0,jp),vec2)/u-dotrc(p(0,kp),vec2)/omu))
         else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif


***********************************************************************
*************************** FINAL-INITIAL *****************************
***********************************************************************
      elseif ((ip .gt. nincoming) .and. (kp .le. nincoming)) then

         omx=sij/(sjk+sik)
         x=one-omx
         z=sik/(sik+sjk)
         omz=sjk/(sik+sjk)
                
         if    (ig.eq.1.and.jg.eq.0) then
c           print*, 'spaeter', qem(1),qem(2)
            sub =qem(1)*qem(2)*gsq/x/sij*(two/(omz+omx)-one-z)
          elseif(ig.eq.1.and.jg.eq.1) then
           sub=DREAL(nc*qem(1)*qem(2)*gsq/(x*sij)*(-dotcc(vec1conjg,vec1)-two/sij*
     &         (z*dotrc(p(0,ip),vec1conjg)-omz*dotrc(p(0,jp),vec1conjg))*
     &         (z*dotrc(p(0,ip),vec1)-omz*dotrc(p(0,jp),vec1))))
           subv=nc*qem(1)*qem(2)*gsq/(x*sij)*(-dotcc(vec1conjg,vec2)-two/sij*
     &         (z*dotrc(p(0,ip),vec1conjg)-omz*dotrc(p(0,jp),vec1conjg))*
     &         (z*dotrc(p(0,ip),vec2)-omz*dotrc(p(0,jp),vec2)))
         else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif



***********************************************************************
**************************** FINAL-FINAL ******************************
***********************************************************************
      elseif ((ip .gt. nincoming) .and. (kp .gt. nincoming)) then
         y=sij/(sij+sjk+sik)
         z=sik/(sjk+sik)
         omz=one-z
         omy=one-y
              
         if    (ig.eq.1.and.jg.eq.0) then
            sub = qem(1)*qem(2)*gsq/sij/omy*(two/(one-z*omy)-one-z)
          elseif(ig.eq.1.and.jg.eq.1) then
           sub=DREAL(nc*qem(1)*qem(2)*gsq/(sij)*(-dotcc(vec1conjg,vec1)-two/sij*
     &         (z*dotrc(p(0,ip),vec1conjg)-omz*dotrc(p(0,jp),vec1conjg))*
     &         (z*dotrc(p(0,ip),vec1)-omz*dotrc(p(0,jp),vec1))))
           subv=nc*qem(1)*qem(2)*gsq/(sij)*(-dotcc(vec1conjg,vec2)-two/sij*
     &         (z*dotrc(p(0,ip),vec1conjg)-omz*dotrc(p(0,jp),vec1conjg))*
     &         (z*dotrc(p(0,ip),vec2)-omz*dotrc(p(0,jp),vec2)))
         else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif
      endif


      else


c  Massive case
      msq_i=mass_i**2
      msq_k=mass_k**2
      msq_j=mass_j**2
      if(mass_i .eq.mass_j) then
       msq_ij=0d0
      else
       msq_ij=msq_i
      endif
c      qsq=dot(qtot,qtot)


      if ((ip .le. nincoming) .and. (kp .le. nincoming)) then
***********************************************************************
*************************** INITIAL-INITIAL ***************************
***********************************************************************
        omx=(sij+sjk)/sik
        x=one-omx

         if    (ig.eq.1.and.jg.eq.0) then
            sub = qem(1)*qem(2)*gsq/x/sij*(two/omx-one-x-x*msq_i/sij)
c          print*, p(0,1),p(1,1),p(2,1),p(3,1)
         elseif(ig.eq.0.and.jg.eq.1) then
            sub = nc*qem(1)*qem(2)*gsq/x/sij*(one-two*x*omx+x*msq_i/sij)
         elseif(ig.eq.1.and.jg.eq.1) then
           sub=DREAL(qem(1)*qem(2)*gsq/x/sij*(-dotcc(vec1conjg,vec1)*x+omx/x*two*sik/sij/sjk*
     &         (dotrc(p(0,jp),vec1conjg)-sij/sik*dotrc(p(0,kp),vec1conjg))*
     &         (dotrc(p(0,jp),vec1)-sij/sik*dotrc(p(0,kp),vec1))))
           subv=qem(1)*qem(2)*gsq/x/sij*(-dotcc(vec1conjg,vec2)*x+omx/x*two*sik/sij/sjk*
     &         (dotrc(p(0,jp),vec1conjg)-sij/sik*dotrc(p(0,kp),vec1conjg))*
     &         (dotrc(p(0,jp),vec2)-sij/sik*dotrc(p(0,kp),vec2)))  
         else
            write (*,*) 'Error in dipolesub, wrong dipolestructure'
            return
         endif

         
***********************************************************************
***************************INITIAL-FINAL *****************************
***********************************************************************
      elseif ((ip .le. nincoming) .and. (kp .gt. nincoming)) then
        do nu=0,3
         pia(nu)=p(nu,kp)+p(nu,jp)-p(nu,ip)
        enddo
        piasq=dot(pia,pia)
        pbiasq=piasq-msq_i-msq_j-msq_k
        omx=sjk/(sij+sik)
        x=one-omx
        z=sik/(sik+sij)
        cria=sqrt((pbiasq+2d0*msq_i*x)**2-4d0*msq_i*piasq*x**2)/
     &       sqrt(lambda_tr(piasq,msq_i,msq_k))
        sria=1d0+pbiasq*(pbiasq+2d0*msq_i)/lambda_tr(piasq,msq_i,msq_k)*omx/x

        if (ig.eq.1.and.jg.eq.0) then
c          subv = qem(1)*qem(2)*gsq*msq_i/(2d0*dot(p(0,ip),p(0,jp))**2)*omx**2/x
          sub = qem(1)*qem(2)*gsq/sij/x*(2d0/(2d0-x-z)-cria*(1d0+x)-x*msq_i/sij)!-Dreal(subv)
        elseif(ig.eq.0.and.jg.eq.1) then
          sub = nc*qem(1)*qem(2)*gsq/x/sij*(one-two*x*omx+x*msq_j/sij)
        elseif(ig.eq.1.and. jg.eq.1) then
          sub=DREAL(gsq/x/sij*(-dotcc(vec1conjg,vec1)*x+omx/x*two*u*omu/sjk*
     &        (dotrc(p(0,jp),vec1conjg)/u-dotrc(p(0,kp),vec1conjg)/omu)*
     &        (dotrc(p(0,jp),vec1)/u-dotrc(p(0,kp),vec1)/omu)))
          subv=gsq/x/sij*(-dotcc(vec1conjg,vec2)*x+omx/x*two*u*omu/sjk*
     &        (dotrc(p(0,jp),vec1conjg)/u-dotrc(p(0,kp),vec1conjg)/omu)*
     &        (dotrc(p(0,jp),vec2)/u-dotrc(p(0,kp),vec2)/omu))
        else
           write (*,*) 'Error in dipolesub, wrong dipolestructure'
           return
        endif


***********************************************************************
*************************** FINAL-INITIAL *****************************
***********************************************************************
      elseif ((ip .gt. nincoming) .and. (kp .le. nincoming)) then
        do nu=0,3
         pia(nu)=p(nu,ip)+p(nu,jp)-p(nu,kp)
        enddo

        piasq=dot(pia,pia)
        pbiasq=piasq-msq_i-msq_j-msq_k
        omx=sij/(sjk+sik)
        x=one-omx
        z=sik/(sik+sjk)
        omz=sjk/(sik+sjk)


        cria=sqrt((pbiasq+2d0*msq_k*x)**2-4d0*msq_k*piasq*x**2)/
     &       sqrt(lambda_tr(piasq,msq_k,msq_i))
        sria=1d0+pbiasq*(pbiasq+2d0*msq_k)/lambda_tr(piasq,msq_k,msq_i)*omx/x


        if    (ig.eq.1.and.jg.eq.0) then
c         subv = qem(1)*qem(2)*gsq*msq_i/(2d0*sij**2)*omz**2/z*sria/x
          sub = qem(1)*qem(2)*gsq/sij/x*(2d0/(2d0-x-z)-1d0-z
     &         -msq_i/sij)!-Dreal(subv)
        elseif(ig.eq.1.and.jg.eq.1) then
          sub=DREAL(nc*qem(1)*qem(2)*gsq/(x*(dot(pij,pij)-msq_ij))
     &          *(-dotcc(vec1conjg,vec1)-four/dot(pij,pij)*
     &         (z*dotrc(p(0,ip),vec1conjg)-omz*dotrc(p(0,jp),vec1conjg))*
     &         (z*dotrc(p(0,ip),vec1)-omz*dotrc(p(0,jp),vec1))))
          subv=nc*qem(1)*qem(2)*gsq/(x*(dot(pij,pij)-msq_ij))*
     &         (-dotcc(vec1conjg,vec2)-four/dot(pij,pij)*
     &         (z*dotrc(p(0,ip),vec1conjg)-omz*dotrc(p(0,jp),vec1conjg))*
     &         (z*dotrc(p(0,ip),vec2)-omz*dotrc(p(0,jp),vec2)))
        else
           write (*,*) 'Error in dipolesub, wrong dipolestructure'
           return
        endif



***********************************************************************
**************************** FINAL-FINAL ******************************
***********************************************************************
      elseif ((ip .gt. nincoming) .and. (kp .gt. nincoming)) then
        do nu=0,3
         pij(nu)=p(nu,ip)+p(nu,kp)+p(nu,jp)
        enddo
        pijsq=dot(pij,pij)
        pbijsq=pijsq-msq_i-msq_j-msq_k
        y=sij/(sij+sjk+sik)
        z=sik/(sjk+sik)
        omz=one-z
        omy=one-y
        crij=sqrt((2d0*msq_k+pbijsq*omy)**2-4d0*pijsq*msq_k)
     &       /sqrt(lambda_tr(pijsq,msq_i,msq_k))
        srij=1d0-(2d0*msq_k*(2d0*msq_i+pbijsq)/lambda_tr(pijsq,msq_i,msq_k)*y/omy)


        if(ig.eq.1.and.jg.eq.0) then
c          subv = qem(1)*qem(2)*gsq*msq_i/(2d0*dot(p(0,ip),p(0,jp))**2)*omz**2/z
c     &           *srij/crij
c         print*, 'hier ff', nc
          sub = qem(1)*qem(2)*gsq/sij/crij*(2d0/(1-z*omy)-1d0-z-msq_i/sij)!-Dreal(subv)
        elseif(ig.eq.1.and.jg.eq.1) then
          sub=DREAL(nc*qem(1)*qem(2)*gsq/((dot(pij,pij)-msq_ij)*vij)
     &         *(-dotcc(vec1conjg,vec1)-four/dot(pij,pij)*
     &         (zm*dotrc(p(0,ip),vec1conjg)-omzm*dotrc(p(0,jp),vec1conjg))*
     &         (zm*dotrc(p(0,ip),vec1)-omzm*dotrc(p(0,jp),vec1))))
          subv=nc*qem(1)*qem(2)*gsq/((dot(pij,pij)-msq_ij)*vij)
     &         *(-dotcc(vec1conjg,vec2)-four/dot(pij,pij)*
     &         (zm*dotrc(p(0,ip),vec1conjg)-omzm*dotrc(p(0,jp),vec1conjg))*
     &         (zm*dotrc(p(0,ip),vec2)-omzm*dotrc(p(0,jp),vec2)))
        else
           write (*,*) 'Error in dipolesub, wrong dipolestructure'
           return
        endif

      endif


      endif

      return

      end
      


      complex*16 function dotrc(pr,pc)
      implicit none
      double precision pr(0:3)
      complex*16 pc(0:3)
      dotrc=pr(0)*pc(0)-pr(1)*pc(1)-pr(2)*pc(2)-pr(3)*pc(3)
      end

      complex*16 function dotcc(pc1,pc2)
      implicit none
      complex*16 pc1(0:3),pc2(0:3)
      dotcc=pc1(0)*pc2(0)-pc1(1)*pc2(1)-pc1(2)*pc2(2)-pc1(3)*pc2(3)
      end
