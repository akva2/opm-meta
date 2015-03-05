project(OPM-meta)

# Options
option(RUN_TESTS "Run tests and submit to the dash?" OFF)

enable_language(C)
enable_language(CXX)
enable_language(Fortran)

if(RUN_TESTS)
  find_program(CTEST_EXECUTABLE NAMES ctest ctest28)
  set(BUILD_COMMAND ${CTEST_EXECUTABLE} -D Nightly)
  enable_testing()
  message("Tests will be run and submitted to the dash (for the OPM modules)")
else()
  set(BUILD_COMMAND make)
endif()

# Macros
function(from_git upstreamname repo revision)
  if("${ARGV3}" STREQUAL "notest")
    set(mBUILD_COMMAND)
  else()
    set(mBUILD_COMMAND BUILD_COMMAND ${BUILD_COMMAND})
  endif()
  set(patch_command)
  if(NOT "${${upstreamname}_PATCHES}" STREQUAL "")
    foreach(patch ${${upstreamname}_PATCHES})
      list(APPEND patch_command PATCH_COMMAND patch -p1 < ${patch})
    endforeach()
  endif()
  externalproject_add(${upstreamname}
                      GIT_REPOSITORY ${repo}
                      PREFIX ${upstreamname}
                      ${patch_command}
                      GIT_TAG ${revision}
                      ${mBUILD_COMMAND}
                      CONFIGURE_COMMAND PKG_CONFIG_PATH=${CMAKE_BINARY_DIR}/installed/lib/pkgconfig ${CMAKE_COMMAND} -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/installed <SOURCE_DIR> -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} ${common_options} ${${upstreamname}_CMAKE_FLAGS})
endfunction()

function(from_git_dunecontrol upstreamname repo revision)
  if("${ARGV3}" STREQUAL "notest")
    set(mBUILD_COMMAND)
  else()
    set(mBUILD_COMMAND BUILD_COMMAND ${BUILD_COMMAND})
  endif()
  externalproject_add(${upstreamname}
                      GIT_REPOSITORY ${repo}
                      PREFIX ${upstreamname}
                      GIT_TAG ${revision}
                      ${mBUILD_COMMAND}
                      UPDATE_COMMAND PKG_CONFIG_PATH=${CMAKE_BINARY_DIR}/installed/lib/pkgconfig ${CMAKE_BINARY_DIR}/installed/bin/dunecontrol autogen
                      CONFIGURE_COMMAND PKG_CONFIG_PATH=${CMAKE_BINARY_DIR}/installed/lib/pkgconfig ${CMAKE_COMMAND} -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/installed <SOURCE_DIR> -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} ${${upstreamname}_CMAKE_FLAGS} ${common_options}
                      INSTALL_DIRECTORY installed)
endfunction()

macro(from_tarball_dunecontrol name)
  externalproject_add(${name}
                      URL http://www.dune-project.org/download/2.2.1/${name}-2.2.1.tar.gz
                      UPDATE_COMMAND PKG_CONFIG_PATH=${CMAKE_BINARY_DIR}/installed/lib/pkgconfig ${CMAKE_BINARY_DIR}/installed/bin/dunecontrol autogen
                      PREFIX ${name}
                      CONFIGURE_COMMAND PKG_CONFIG_PATH=${CMAKE_BINARY_DIR}/installed/lib/pkgconfig <SOURCE_DIR>/configure --prefix ${CMAKE_BINARY_DIR}/installed WORKING_DIRECTORY <SOURCE_DIR>
                      INSTALL_DIRECTORY installed)
endmacro()

macro(set_if_not_present var value)
  if(NOT ${var})
    set(${var} ${value})
  endif()
endmacro()

cmake_minimum_required(VERSION 2.8)
include(ExternalProject)

if(RELEASE_VERSION STREQUAL "2013.03")
  set(DUNE_VERSION v2.2.1)
  set(OPM_VERSION  release/2013.03/final)
  set(ERT_VERSION  release/2013.03/final)
endif()

if(RELEASE_VERSION STREQUAL "2013.10")
  set(DUNE_VERSION v2.2.1)
  set(OPM_VERSION  release/2013.10)
  set(ERT_VERSION  release/2013.10/final2)
endif()

set_if_not_present(DUNE_VERSION "v2.3.1")
set_if_not_present(OPM_VERSION  "origin/master")
set_if_not_present(ERT_VERSION  "origin/master")

if(RELEASE_VERSION)
  message(STATUS "Building OPM release ${RELEASE_VERSION}")
endif()

if(EXISTS /etc/redhat-release)
  file(STRINGS /etc/redhat-release redhat_release)
  if(${redhat_release} MATCHES "5.")
    set(common_options -DCMAKE_CXX_COMPILER=g++44
                       -DCMAKE_C_COMPILER=gcc44
                       -DCMAKE_Fortran_COMPILER=gfortran44
                       -DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH})
    if(BOOST_INCLUDEDIR)
      list(APPEND common_options -DBOOST_INCLUDEDIR=${BOOST_INCLUDEDIR}
                                 -DBOOST_LIBRARYDIR=${BOOST_LIBRARYDIR})
    endif()
  endif()
endif()

if(CMAKE_TOOLCHAIN_FILE)
  list(APPEND common_options -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})
endif()

# List of dune repos
foreach(dune_repo dune-common;dune-geometry;dune-grid;dune-istl;dune-localfunctions)
  set_if_not_present(${dune_repo}_REPO http://git.dune-project.org/repositories/${dune_repo})
  set_if_not_present(${dune_repo}_VERSION ${DUNE_VERSION})
  message("${dune_repo}: ${${dune_repo}_VERSION} ${${dune_repo}_REPO}")
endforeach()

# List of OPM repos
foreach(opm_repo opm-core;dune-cornerpoint;opm-porsol;
                 opm-upscaling;opm-polymer;opm-autodiff;
                 opm-material;opm-verteq;opm-parser;ewoms)
  if(NOT ${opm_repo}_DISABLED)
    set_if_not_present(${opm_repo}_REPO git://github.com/OPM/${opm_repo})
    set_if_not_present(${opm_repo}_VERSION ${OPM_VERSION})
    message("${opm_repo}: ${${opm_repo}_VERSION} ${${opm_repo}_REPO}")
  endif()
endforeach()

# Add targets
if(DUNE_VERSION STREQUAL "v2.2.1")
  # Use tarballs since bootstrapping is broken on precise
  ExternalProject_ADD(dune-common
                      URL http://www.dune-project.org/download/2.2.1/dune-common-2.2.1.tar.gz
                      UPDATE_COMMAND bin/dunecontrol autogen
                      PREFIX dune-common
                      CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix ${CMAKE_BINARY_DIR}/installed WORKING_DIRECTORY <SOURCE_DIR>
                      INSTALL_DIRECTORY installed)
  from_tarball_dunecontrol(dune-geometry)
  from_tarball_dunecontrol(dune-grid)
  from_tarball_dunecontrol(dune-istl)
  from_tarball_dunecontrol(dune-localfunctions)
else()
  foreach(dune_repo dune-common;dune-geometry;dune-grid;dune-istl;dune-localfunctions)
    from_git(${dune_repo} ${${dune_repo}_REPO} ${${dune_repo}_VERSION} notest)
  endforeach()
endif()

if(ERT_VERSION STREQUAL "origin/master")
  externalproject_add(ert
                      GIT_REPOSITORY git://github.com/Ensembles/ert
                      GIT_TAG ${ERT_VERSION}
                      PREFIX ert
                      CONFIGURE_COMMAND ${CMAKE_COMMAND} -DBUILD_SHARED_LIBS=1 -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/installed <SOURCE_DIR>/devel ${common_options})
else()
  externalproject_add(ert
                      GIT_REPOSITORY git://github.com/Ensembles/ert
                      UPDATE_COMMAND git checkout ${ERT_VERSION}
                      PREFIX ert
                      CONFIGURE_COMMAND ${CMAKE_COMMAND} -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/installed <SOURCE_DIR>/devel -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DBUILD_SHARED_LIBS=0 ${common_options})
endif()

foreach(opm_repo opm-core;dune-cornerpoint;opm-porsol;opm-upscaling;opm-polymer)
  from_git(${opm_repo} ${${opm_repo}_REPO} ${${opm_repo}_VERSION})
endforeach()

# Setup dependencies
add_dependencies(dune-geometry    dune-common)
add_dependencies(dune-grid        dune-geometry)
add_dependencies(dune-istl        dune-common)
add_dependencies(dune-cornerpoint opm-core dune-grid)
add_dependencies(dune-localfunctions dune-geometry)
add_dependencies(opm-porsol       opm-core dune-cornerpoint)
add_dependencies(opm-upscaling    opm-porsol)
add_dependencies(opm-polymer      opm-core)
add_dependencies(opm-core         dune-common dune-istl)

if(NOT RELEASE_VERSION STREQUAL "2013.03")
  if (RELEASE_VERSION STREQUAL "2013.10")
    set(eigen_VERSION 9f6cc779)
  else()
    set(eigen_VERSION 4454cb96)
  endif()
  externalproject_add(eigen3
                      GIT_REPOSITORY git://github.com/OPM/eigen3
                      PREFIX eigen3
                      UPDATE_COMMAND git checkout ${eigen_VERSION}
                      CMAKE_ARGS -DEIGEN_TEST_NO_OPENGL=1 -DEIGEN_BUILD_PKGCONFIG=0 -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/installed)

  foreach(opm_repo opm-autodiff;opm-material;opm-verteq;ewoms)
    if(NOT ${opm_repo}_DISABLED)
      from_git(${opm_repo} ${${opm_repo}_REPO} ${${opm_repo}_VERSION})
    endif()
  endforeach()

  add_dependencies(opm-core ert)
  add_dependencies(opm-material dune-common dune-istl opm-core)
  add_dependencies(opm-verteq   opm-core)
  add_dependencies(opm-autodiff opm-core eigen3 dune-cornerpoint opm-material)
  add_dependencies(opm-porsol   opm-material)
  if(NOT ewoms_DISABLED)
    add_dependencies(ewoms dune-grid dune-localfunctions dune-istl opm-core opm-material)
  endif()
endif()

if(NOT RELEASE_VERSION STREQUAL "2013.03" AND NOT RELEASE_VERSION STREQUAL "2013.10")
  foreach(opm_repo opm-parser)
    if(NOT ${opm_repo}_DISABLED)
      from_git(${opm_repo} ${${opm_repo}_REPO} ${${opm_repo}_VERSION})
    endif()
  endforeach()
  add_dependencies(opm-core    opm-parser)
  add_dependencies(opm-parser  ert)
  add_dependencies(opm-polymer opm-autodiff)
endif()

add_custom_target(merge-commit
                  COMMAND ${CMAKE_COMMAND}
		  -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
		  -DCMAKE_BINARY_DIR=${CMAKE_BINARY_DIR}
		  -DPROJECT_SOURCE_DIR=${PROJECT_SOURCE_DIR}
                  -DDUNE_VERSION=${DUNE_VERSION}
		  -P ${PROJECT_SOURCE_DIR}/MergeCommit.cmake)

add_dependencies(merge-commit opm-verteq opm-polymer opm-upscaling)
