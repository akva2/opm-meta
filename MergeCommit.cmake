find_package(Git REQUIRED)

macro(sanity_check message)
  if(status_code)
    message(FATAL_ERROR "${message}")
  endif()
endmacro()

set(all_modules opm-parser opm-core opm-material opm-verteq
                opm-autodiff dune-cornerpoint ewoms
                opm-polymer opm-porsol opm-upscaling)

# Setup modules
set(check_base $ENV{MODULES})
if(NOT modules)
  set(modules ${all_modules})
endif()

# Setup commit id
set(commit_id $ENV{COMMIT_ID})
if(NOT commit_id)
  message(FATAL_ERROR "Need a commit id")
endif()

# Setup push user
set(push_user $ENV{PUSH_USER})
if(NOT commit_id)
  set(push_user akva2)
endif()

set(build $ENV{BUILD})
if(NOT build)
  set(build 1)
endif()

# make directory
make_directory(merge-${commit_id})

# git init
execute_process(COMMAND ${GIT_EXECUTABLE} init .
                WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/merge-${commit_id}
                RESULT_VARIABLE status_code)
sanity_check("Failed to initialize git")

foreach(module ${all_modules})
  # git add remote
  execute_process(COMMAND ${GIT_EXECUTABLE} remote add ${module}
                          ${CMAKE_BINARY_DIR}/${module}/src/${module}
                  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/merge-${commit_id}
                  RESULT_VARIABLE status_code)
  execute_process(COMMAND ${GIT_EXECUTABLE} remote set-url --push ${module}
                          https://github.com/${pushuser}/${module}
                  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/merge-${commit_id}
                  RESULT_VARIABLE status_code)
  sanity_check("Failed to add remote for ${module}")
  # git fetch remote
  execute_process(COMMAND ${GIT_EXECUTABLE} fetch ${module}
                  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/merge-${commit_id}
                  RESULT_VARIABLE status_code)
  sanity_check("Failed to fetch remote for ${module}")
  # setup branch
  execute_process(COMMAND ${GIT_EXECUTABLE} branch ${module} ${module}/master
                  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/merge-${commit_id}
                  RESULT_VARIABLE status_code)
  sanity_check("Failed to fetch remote for ${module}")
endforeach()

set(successful_modules)
foreach(module ${modules})
  execute_process(COMMAND ${GIT_EXECUTABLE} checkout ${module}
                  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/merge-${commit_id}
                  RESULT_VARIABLE status_code)
  sanity_check("Failed to checkout ${module}")

  execute_process(COMMAND ${GIT_EXECUTABLE} cherry-pick ${commit_id}
                  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/merge-${commit_id}
                  RESULT_VARIABLE status_code)
  if(status_code)
    execute_process(COMMAND ${GIT_EXECUTABLE} cherry-pick --abort
                    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/merge-${commit_id}
                    RESULT_VARIABLE status_code)
   sanity_check("Failed to undo cherry-pick for ${module}")
  else()
    list(APPEND succesful_modules ${module})
  endif()
endforeach()

if(build)
  foreach(module ${all_modules})
    list(APPEND cmake_args -D${module}_REPO=${CMAKE_BINARY_DIR}/merge-${commit_id}
                           -D${module}_VERSION=origin/${module})
  endforeach()
  make_directory(${CMAKE_BINARY_DIR}/merge-${commit_id}/build)
  execute_process(COMMAND ${CMAKE_COMMAND} ${PROJECT_SOURCE_DIR}
                          -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
                          -DDUNE_VERSION=${DUNE_VERSION}
                          ${cmake_args}
		  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/merge-${commit_id}/build
                  RESULT_VARIABLE status_code)
  sanity_check("Failed to configure test build")
  execute_process(COMMAND make
		  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/merge-${commit_id}/build
                  RESULT_VARIABLE status_code)
  sanity_check("Failed to build test build")
endif()

message("Applied to ${succesful_modules}")
