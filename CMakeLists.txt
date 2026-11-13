cmake_minimum_required(VERSION 3.22)

project(Hvx VERSION 0.3.0 LANGUAGES NONE)

set(HVX_PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
set(HVX_DEFAULT_FEATURE "tiny_cnn" CACHE STRING "Default feature for hvx_pipeline")
include("${HVX_PROJECT_ROOT}/cmake/HvxTargets.cmake")

if(NOT EXISTS "${HVX_PROJECT_ROOT}/nn/${HVX_DEFAULT_FEATURE}/CMakeLists.txt"
   OR NOT EXISTS "${HVX_PROJECT_ROOT}/deploy/${HVX_DEFAULT_FEATURE}/CMakeLists.txt")
  message(FATAL_ERROR
    "Default feature '${HVX_DEFAULT_FEATURE}' must exist under both nn/ and deploy/."
  )
endif()

# Runtime is shared by all feature targets.
add_subdirectory(runtime)

# Feature identities are directory names under nn/ and deploy/.
add_subdirectory(nn)
add_subdirectory(deploy)

add_custom_target(hvx_help
  COMMAND "${CMAKE_COMMAND}" -E echo "Hvx feature targets"
  COMMAND "${CMAKE_COMMAND}" -E echo "Runtime: hvx_doctor, hvx_runtime_image, hvx_runtime_shell"
  COMMAND "${CMAKE_COMMAND}" -E echo "NN features are named hvx_nn_<feature>_*"
  COMMAND "${CMAKE_COMMAND}" -E echo "Deploy features are named hvx_deploy_<feature>_*"
  COMMAND "${CMAKE_COMMAND}" -E echo "Run: cmake --build build --target help | grep hvx_"
  VERBATIM
)

if(TARGET "hvx_pipeline_${HVX_DEFAULT_FEATURE}")
  add_custom_target(hvx_pipeline
    COMMAND "${CMAKE_COMMAND}" --build "${CMAKE_BINARY_DIR}"
      --target "hvx_pipeline_${HVX_DEFAULT_FEATURE}"
    COMMENT "Running pipeline for ${HVX_DEFAULT_FEATURE}"
    USES_TERMINAL
    VERBATIM
  )
endif()

add_custom_target(hvx_clean
  COMMAND "${CMAKE_COMMAND}" -E rm -rf
    "${HVX_PROJECT_ROOT}/artifacts/nn"
    "${HVX_PROJECT_ROOT}/artifacts/deploy"
  COMMENT "Removing generated NN and deploy artifacts"
  VERBATIM
)

