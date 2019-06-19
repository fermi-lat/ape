# FindReadline.cmake
#
# Finds the Readline library
#
# This will define the following variables
#
# READLINE_FOUND READLINE_INCLUDE_DIRS READLINE_LIBRARY
#
# along with the following input targets
#
# Readline::Readline
#
# Author: Alex Reustle - Alexander.Reustle@nasa.gov

# ##############################################################################
# Find the necessary headers and libraries
# ##############################################################################

find_path(Readline_INCLUDE_DIR
          NAMES readline.h
          HINTS ${CMAKE_INSTALL_PREFIX}
          PATH_SUFFIXES readline)

find_library(READLINE_LIBRARY
             NAMES readline
             HINTS ${CMAKE_INSTALL_PREFIX}
             PATH_SUFFIXES lib lib64)

find_library(NCURSES_LIBRARY
             NAMES ncurses
             HINTS ${CMAKE_INSTALL_PREFIX}
             PATH_SUFFIXES lib lib64)

# ##############################################################################
# Bookkeeping and warning if anything not found
mark_as_advanced(READLINE_FOUND
                 Readline_INCLUDE_DIR
                 READLINE_LIBRARY
                 NCURSES_LIBRARY)

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(Readline
                                  REQUIRED_VARS
                                  Readline_INCLUDE_DIR
                                  READLINE_LIBRARY
                                  NCURSES_LIBRARY)

# ##############################################################################
# Properly set variables and targets

# Set include dirs to parent, to enable includes like include
# <readline/readline.h>
if(READLINE_FOUND)
  get_filename_component(READLINE_INCLUDE_DIRS ${Readline_INCLUDE_DIR}
                         DIRECTORY)
endif()

# Create the target and declare the target properties.
if(READLINE_FOUND AND NOT TARGET Readline::Readline)

  add_library(Readline::Readline
              INTERFACE
              IMPORTED
              GLOBAL)
  target_include_directories(Readline::Readline
                             INTERFACE "${READLINE_INCLUDE_DIRS}")
  target_link_libraries(Readline::Readline
                        INTERFACE "${READLINE_LIBRARY}" "${NCURSES_LIBRARY}")

endif()
