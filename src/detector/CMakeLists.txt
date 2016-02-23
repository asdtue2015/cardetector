cmake_minimum_required(VERSION 2.8.3)

project(detector)
#set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

if(NOT WIN32)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall")
endif()
find_package( OpenCV REQUIRED )
find_package(CUDA REQUIRED )


include_directories( ${CUDA_INCLUDE_PATH} ${OpenCV_INCLUDE_PATH})


add_executable( detector detector.cpp)
target_link_libraries( detector ${OpenCV_LIBS} ${CUDA_LIBS}  )

