macro(set_os_flags src_file)
    # sets os specific compile definintions for source files. This is currently
  # superfluous because debugging without these global flags set has not been
  # done
  if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
    set_source_files_properties(${src_file} PROPERTIES COMPILE_DEFINITIONS "LINUX;LINUX2")
  elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin")
    remove_definitions("-DLINUX")
    set_source_files_properties(${src_file} PROPERTIES COMPILE_DEFINITIONS "LINUX;DARWIN")
    message(STATUS "Configuring on/for macOS")
  elseif("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
    message(FATAL_ERROR "Windows is not supported for this build")
  else()
    message(STATUS "Configuring on/for ${CMAKE_SYSTEM_NAME}. Not sure if this will work...")
  endif()
endmacro()


function(quotize input basename)
  set(output "${basename}.h")
  add_custom_command(OUTPUT "${output}"
    COMMAND quotize "${basename}" < "${input}" > "${output}"
    MAIN_DEPENDENCY quotize)
endfunction(quotize)



macro(get_afni_rpath)
  ## Needed for correct linking when installing.
  ## see https://gitlab.kitware.com/cmake/community/wikis/doc/cmake/RPATH-handling
  # get_property(_nifti TARGET NIFTI::niftiio PROPERTY LOCATION)
  # get_filename_component(_nifti_libraries ${_nifti} DIRECTORY)
  # get_property(_gifti TARGET GIFTI::giftiio PROPERTY LOCATION)
  # get_filename_component(_gifti_libraries ${_gifti} DIRECTORY)
  if(TARGET_TYPE MATCHES "LIBRARY")
    set(INSTALL_PATH ${AFNI_INSTALL_LIBRARY_DIR})
  else()  
    set(INSTALL_PATH ${AFNI_INSTALL_RUNTIME_DIR})
  endif()
  # Prepare RPATH
  file(RELATIVE_PATH _rel_afni ${INSTALL_PATH} ${AFNI_INSTALL_LIBRARY_DIR})
  # file(RELATIVE_PATH _rel_nifti ${INSTALL_PATH} ${_nifti_libraries})
  # file(RELATIVE_PATH _rel_gifti ${INSTALL_PATH} ${_gifti_libraries})
  if(APPLE)
    set(afni_target_RPATH 
      "@loader_path/${_rel_afni}"
      # "@loader_path/${_rel_nifti}"
      # "@loader_path/${_rel_gifti}"
      )
  else()
    set(afni_target_RPATH 
      "\$ORIGIN/${_rel_afni}"
      # "\$ORIGIN/${_rel_nifti}"
      # "\$ORIGIN/${_rel_gifti}"
      )
  endif()
  # file(TO_NATIVE_PATH "${_rpath}" afni_target_RPATH)
endmacro()

macro(add_afni_target_properties target)
  # this macro sets some default properties for targets in this project
  get_target_property(TARGET_TYPE ${target} TYPE)
  get_afni_rpath()

  # Set the target properties
  if(NOT DEFINED ENV{CONDA_BUILD})
    set_target_properties(${target} PROPERTIES
      SKIP_BUILD_RPATH OFF
      BUILD_WITH_INSTALL_RPATH OFF
      INSTALL_RPATH "${afni_target_RPATH}"
      INSTALL_RPATH_USE_LINK_PATH ON
      )
  endif()
  set_target_properties(${target} PROPERTIES
    MACOSX_RPATH ON
    )

  if (CONDA_BUILD)
    set_target_properties(${target} PROPERTIES
      INSTALL_RPATH "${afni_target_RPATH}"
      )
  endif()
    # INSTALL_RPATH_USE_LINK_PATH ON
    # SKIP_BUILD_RPATH OFF
    # BUILD_WITH_INSTALL_RPATH OFF
endmacro()

function(check_header_has_been_created HEADER_PATH)
  if (NOT EXISTS "${HEADER_PATH}")
    file(WRITE ${HEADER_PATH} "\
    #define AFNI_VERSION_LABEL    \"AFNI_${GIT_REPO_VERSION}\"
    #define AFNI_VERSION_PLATFORM \"${CMAKE_SYSTEM_NAME}_cmake\" \
    ")
  endif()
endfunction()