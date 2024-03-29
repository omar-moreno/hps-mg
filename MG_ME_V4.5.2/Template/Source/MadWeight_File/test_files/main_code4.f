C+-----------------------------------------------------------------------+
C|                         MAIN CODE FOR MADWEIGHT                       |
C|                                                                       |
C|     Author: Pierre Artoisenet (UCL-CP3)                               |
C|             Olivier Mattelaer (UCL-CP3)                               |
C+-----------------------------------------------------------------------+
C|     This file is generated automaticly by MADWEIGHT-ANALYZER          |
C+-----------------------------------------------------------------------+     
      subroutine main_code(x,n_var)
C+-----------------------------------------------------------------------+
C|     Central Routine for the change of variable choice                 |
C|       - num_sol: number of the solution to charge                     |
C|       - x      : random number from vegas                             |
C+-----------------------------------------------------------------------+

	integer config,perm_pos
	common /to_config/ config,perm_pos
	double precision x(20)
	integer n_var
	double precision    S,X1,X2,PSWGT,JAC
        common /PHASESPACE/ S,X1,X2,PSWGT,JAC
c
	double precision multi_channel_weight
	external multi_channel_weight
c
	include 'd_choices.inc'
C+-----------------------------------------------------------------------+
C|     Scedullar Part					                 |
C+-----------------------------------------------------------------------+    

       if (config.eq.1) then 
C+-----------------------------------------------------------------------+
C|                                                                       |
C|        ** Enlarged Contraint Sector global information **             |
C|                                                                       |
C|    Class: B                                                           |
C|    particle in ECS : 4(missing)    3(visible)                         |
C|    blob linked are generated by :                                     |
C|                                                                       |
C|                                                                       |
C+-----------------------------------------------------------------------+



        call class_b(4,3,-1)
        call block_stat(1,'b-4')
        if (jac.le.0d0) return


        jac=jac*multi_channel_weight(1)

        endif
        return
        end
