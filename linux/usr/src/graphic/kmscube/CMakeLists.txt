set(CMAKE_BUILD_TYPE Debug)

add_executable(kmscube
    common.c
    cube-smooth.c
    cube-tex.c
    drm-atomic.c
    drm-common.c
    drm-legacy.c
    drm-offscreen.c
    esTransform.c
    frame-512x512-NV12.c
    frame-512x512-RGBA.c
    kmscube.c
    perfcntrs.c

)

find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBDRM REQUIRED libdrm)
pkg_check_modules(LIBGBM REQUIRED gbm)
pkg_check_modules(EGL REQUIRED egl)
pkg_check_modules(OPENGLES2 REQUIRED glesv2)

#target_link_libraries(kmscube -Wl,-Bstatic  gbm drm cairo png freetype expat pixman-1 z -Wl,-Bdynamic fontconfig m wayland-server EGL GLESv2)
target_include_directories(kmscube PUBLIC ${LIBDRM_INCLUDE_DIRS} ${LIBGBM_INCLUDE_DIRS} ${EGL_INCLUDE_DIRS} ${OPENGLES2_INCLUDE_DIRS})

target_link_libraries(kmscube ${LIBDRM_LIBRARIES} ${LIBGBM_LIBRARIES} ${EGL_LIBRARIES} ${OPENGLES2_LIBRARIES} m)
