set (EXENAME tao)
set (SRC_FILES
  program/tao_program.f90
)

set (INC_DIRS
  ../include
  include
)

set (LINK_LIBS
  tao 
  bmad 
  sim_utils
  recipes_f-90_LEPP 
  xsif 
  pgplot 
  forest 
  readline
  curses
  termcap
)