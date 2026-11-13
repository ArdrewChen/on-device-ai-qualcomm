file(GLOB DEPLOY_FEATURE_DIRS LIST_DIRECTORIES true CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_SOURCE_DIR}/*"
)
foreach(feature_dir IN LISTS DEPLOY_FEATURE_DIRS)
  if(IS_DIRECTORY "${feature_dir}" AND EXISTS "${feature_dir}/CMakeLists.txt")
    get_filename_component(feature_name "${feature_dir}" NAME)
    message(STATUS "Deploy feature: ${feature_name}")
    add_subdirectory("${feature_dir}")
  endif()
endforeach()

