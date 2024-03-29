cmake_minimum_required(VERSION 3.18)

project(ape VERSION 3 LANGUAGES C)

# ##############################################################################
# Specify needed external dependencies
# ##############################################################################

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
find_package(READLINE REQUIRED MODULE)
list(REMOVE_AT CMAKE_MODULE_PATH -1)

# ##############################################################################
# Declare targets
# ##############################################################################
add_library(ape SHARED
            src/ape_binary.c
            src/ape_error.c
            src/ape_io.c
            src/ape_list.c
            src/ape_msg.c
            src/ape_par.c
            src/ape_par_group.c
            src/ape_session.c
            src/ape_test.c
            src/ape_trad.c
            src/ape_util.c
            src/pil.c
            src/pil_error.c)

add_library(ST::ape ALIAS ape)

add_executable(pcheck src/pcheck/pcheck.c)
add_executable(pget src/pget/pget.c)
add_executable(plist src/plist/plist.c)
add_executable(pquery src/pquery/pquery.c)
add_executable(pquery2 src/pquery2/pquery2.c)
add_executable(pset src/pset/pset.c)
add_executable(punlearn src/punlearn/punlearn.c)

# ##############################################################################
# Specify target properties
# ##############################################################################
set_target_properties(ape PROPERTIES OUTPUT_NAME "ape_${PROJECT_VERSION}")

target_include_directories(
  ape
  PUBLIC $<INSTALL_INTERFACE:include>
         $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

target_link_libraries(ape PRIVATE READLINE::READLINE)

target_compile_definitions(ape PRIVATE USE_READLINE)

target_link_libraries(pcheck ST::ape)
target_link_libraries(pget ST::ape)
target_link_libraries(plist ST::ape)
target_link_libraries(pquery ST::ape)
target_link_libraries(pquery2 ST::ape)
target_link_libraries(pset ST::ape)
target_link_libraries(punlearn ST::ape)

# ##############################################################################
# Specify Installation destinations
# ##############################################################################

include(GNUInstallDirs)
set(CONFIG_INSTALLDIR lib/cmake/ape)

install(DIRECTORY include/ape DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(FILES include/pil.h include/pil_error.h
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(TARGETS ape
                pcheck
                pget
                plist
                pquery
                pquery2
                pset
                punlearn
        EXPORT apeTargets
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(EXPORT apeTargets NAMESPACE ST:: DESTINATION ${CONFIG_INSTALLDIR})

# Create a ConfigVersion.cmake file
include(CMakePackageConfigHelpers)

configure_package_config_file(${CMAKE_CURRENT_LIST_DIR}/cmake/Config.cmake.in
                              ${CMAKE_CURRENT_BINARY_DIR}/apeConfig.cmake
                              INSTALL_DESTINATION
                              ${CONFIG_INSTALLDIR})

write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/apeConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY AnyNewerVersion)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/apeConfig.cmake
              ${CMAKE_CURRENT_BINARY_DIR}/apeConfigVersion.cmake
        DESTINATION ${CONFIG_INSTALLDIR})

export(EXPORT apeTargets
       FILE ${CMAKE_CURRENT_BINARY_DIR}/apeTargets.cmake
       NAMESPACE ST::)

# Register package in user's package registry
export(PACKAGE ape)
