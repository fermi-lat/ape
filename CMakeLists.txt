cmake_minimum_required(VERSION 3.11)

project(ape
  VERSION 0.0.0
  LANGUAGES C
  )

add_library(ape STATIC
  heacore/ape/src/ape_binary.c
  heacore/ape/src/ape_error.c
  heacore/ape/src/ape_io.c
  heacore/ape/src/ape_list.c
  heacore/ape/src/ape_msg.c
  heacore/ape/src/ape_par.c
  heacore/ape/src/ape_par_group.c
  heacore/ape/src/ape_session.c
  heacore/ape/src/ape_test.c
  heacore/ape/src/ape_trad.c
  heacore/ape/src/ape_util.c
  heacore/ape/src/pil.c
  heacore/ape/src/pil_error.c
)
add_library(ST::ape ALIAS ape)
target_include_directories(ape
  PUBLIC
    $<INSTALL_INTERFACE:include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/heacore/ape/include>
)

add_executable(pcheck heacore/ape/src/pcheck/pcheck.c)
add_executable(pget heacore/ape/src/pget/pget.c)
add_executable(plist heacore/ape/src/plist/plist.c)
add_executable(pquery heacore/ape/src/pquery/pquery.c)
add_executable(pquery2 heacore/ape/src/pquery2/pquery2.c)
add_executable(pset heacore/ape/src/pset/pset.c)
add_executable(punlearn heacore/ape/src/punlearn/punlearn.c)
target_link_libraries(pcheck ST::ape)
target_link_libraries(pget ST::ape)
target_link_libraries(plist ST::ape)
target_link_libraries(pquery ST::ape)
target_link_libraries(pquery2 ST::ape)
target_link_libraries(pset ST::ape)
target_link_libraries(punlearn ST::ape)



include(GNUInstallDirs)
set(INSTALL_CONFIGDIR ${CMAKE_INSTALL_LIBDIR}/cmake/ape)

install(DIRECTORY heacore/ape/include DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(TARGETS ape pcheck pget plist pquery pquery2 pset punlearn
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  )

install(TARGETS ape
  EXPORT apeTargets
  DESTINATION ${CMAKE_INSTALL_LIBDIR}
  )

install(EXPORT apeTargets
  NAMESPACE    ST::
  DESTINATION  ${INSTALL_CONFIGDIR}
  )

#Create a ConfigVersion.cmake file
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/apeConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(
  ${CMAKE_CURRENT_LIST_DIR}/cmake/apeConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/apeConfig.cmake
  INSTALL_DESTINATION ${INSTALL_CONFIGDIR}
)

install(
  FILES
    ${CMAKE_CURRENT_BINARY_DIR}/apeConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/apeConfigVersion.cmake
  DESTINATION ${INSTALL_CONFIGDIR}
)

export(EXPORT apeTargets
  FILE ${CMAKE_CURRENT_BINARY_DIR}/apeTargets.cmake
  NAMESPACE ST::
)

#Register package in user's package registry
export(PACKAGE ape)
