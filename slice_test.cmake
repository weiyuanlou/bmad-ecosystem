set (EXENAME slice_test)
set (SRC_FILES
  slice_test/slice_test.f90
)

set (INC_DIRS
)

set (LINK_LIBS
  bmad 
  sim_utils
  recipes_f-90_LEPP 
  forest 
)
