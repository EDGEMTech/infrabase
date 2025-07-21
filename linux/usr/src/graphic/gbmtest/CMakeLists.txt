
add_executable(gbmtest
    common.c
    cube-smooth.c
    esTransform.c
    gbmtest.c
    perfcntrs.c
)

# With static libraries
#target_link_libraries(gbmtest -Wl,-Bstatic gbm drm -Wl,-Bdynamic expat m  EGL GLESv2)

# With dynamic libraries
target_link_libraries(gbmtest gbm drm m EGL GLESv2)


