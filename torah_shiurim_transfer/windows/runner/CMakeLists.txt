cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)


# Find the flutter managed directory.
get_filename_component(FLUTTER_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../flutter" ABSOLUTE)
include(${FLUTTER_ROOT}/generated_config.cmake)
# === END OF CRITICAL FIX ===


# Define the application target.
# Your original `add_executable` block is preserved.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Ensure the Flutter tool builds assets before this target.
add_dependencies(${BINARY_NAME} flutter_assemble)


# === START OF ROBUST FILE COPY COMMAND ===
# This custom command runs *after* the build and copies all necessary files
# to the final output directory. Because we included generated_config.cmake
# above, the variables FLUTTER_..._PATH are now correctly defined.

add_custom_command(
  TARGET ${BINARY_NAME} POST_BUILD
  # Create the data directory if it doesn't exist.
  COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/runner/${CMAKE_BUILD_TYPE}/data"
  # Copy the ICU data file.
  COMMAND ${CMAKE_COMMAND} -E copy
          "${FLUTTER_ICU_DATA_PATH}"
          "${CMAKE_BINARY_DIR}/runner/${CMAKE_BUILD_TYPE}/data/icudtl.dat"
  # Copy the main Flutter DLL.
  COMMAND ${CMAKE_COMMAND} -E copy
          "${FLUTTER_WINDOWS_DLL_PATH}"
          "${CMAKE_BINARY_DIR}/runner/${CMAKE_BUILD_TYPE}/"
  # Copy the entire assets directory.
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${FLUTTER_ASSETS_DIR}"
          "${CMAKE_BINARY_DIR}/runner/${CMAKE_BUILD_TYPE}/data/flutter_assets"
  COMMENT "Copying Flutter necessary assets."
)
# === END OF ROBUST FILE COPY COMMAND ===