function(hvx_add_script_target target script)
  cmake_parse_arguments(ARG "" "" "ARGS;DEPENDS" ${ARGN})
  add_custom_target("${target}"
    COMMAND bash "${HVX_PROJECT_ROOT}/${script}" ${ARG_ARGS}
    WORKING_DIRECTORY "${HVX_PROJECT_ROOT}"
    COMMENT "Running ${target}"
    USES_TERMINAL
    VERBATIM
  )
  if(ARG_DEPENDS)
    add_dependencies("${target}" ${ARG_DEPENDS})
  endif()
endfunction()

