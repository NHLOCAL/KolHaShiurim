cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# --- START OF ADDED/MODIFIED SECTION ---

# Instead of relying on a global variable, let's explicitly define the binary name.
set(BINARY_NAME "torah_shiurim_transfer")

# Define the output directory for our bundled files.
set(BUNDLE_DIR "${CMAKE_BINARY_DIR}/runner/${CMAKE_BUILD_TYPE}")
set(BUNDLE_DATA_DIR "${BUNDLE_DIR}/data")

# --- END OF ADDED/MODIFIED SECTION ---


# Define the application target.
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

# This dependency ensures flutter_assemble runs before this target.
add_dependencies(${BINARY_NAME} flutter_assemble)


# --- START OF NEW SECTION (CORE FIX) ---
#
# This section replaces the fragile default installation process with a robust
# custom command that copies the necessary Flutter assets during the build.
# This avoids the MSB3073 error often seen in CI/CD environments.
#
add_custom_command(
  TARGET ${BINARY_NAME} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${FLUTTER_ICU_DATA_PATH}"
          "${BUNDLE_DATA_DIR}"
  COMMAND ${CMAKE_COMMAND} -E copy
          "${FLUTTER_WINDOWS_DLL_PATH}"
          "${BUNDLE_DIR}"
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${FLUTTER_ASSETS_DIR}"
          "${BUNDLE_DATA_DIR}/flutter_assets"
  COMMENT "Copying Flutter necessary assets."
)
# --- END OF NEW SECTION (CORE FIX) ---