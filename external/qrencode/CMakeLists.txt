cmake_minimum_required(VERSION 3.6)

set(lib_name qrencode)
set(target_name ext_${lib_name})

project(${lib_name} VERSION 4.0.2 LANGUAGES C)

set(${target_name}_src
    qrencode.c
    qrinput.c
    bitstream.c
    qrspec.c
    rsecc.c
    split.c
    mask.c
    mqrspec.c
    mmask.c
)
add_library(${target_name} STATIC
  ${${target_name}_src}
)

target_include_directories(${target_name} PUBLIC ..)
add_definitions(-DSTATIC_IN_RELEASE=static)
add_definitions(-DMAJOR_VERSION=${PROJECT_VERSION_MAJOR})
add_definitions(-DMINOR_VERSION=${PROJECT_VERSION_MINOR})
add_definitions(-DMICRO_VERSION=${PROJECT_VERSION_PATCH})
add_definitions(-DVERSION="${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}")
add_definitions(-DHAVE_SDL=0)

set_target_properties(${target_name}
    PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    FOLDER "External"
)


