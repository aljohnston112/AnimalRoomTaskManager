cmake_minimum_required(VERSION 3.31.10)
project(TaskManager)

set(CMAKE_CXX_STANDARD 26)

add_executable(
        TaskManager
        main.cpp
        Normalizer.cpp
        Normalizer.h
)

add_custom_command(
        TARGET TaskManager POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        "${CMAKE_SOURCE_DIR}/functional_dependencies.txt"
        $<TARGET_FILE_DIR:TaskManager>/functional_dependencies.txt
)
