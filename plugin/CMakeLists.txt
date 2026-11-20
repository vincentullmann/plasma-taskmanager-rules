qt_policy(SET QTP0001 NEW)

# KDECMakeSettings drops the "lib" prefix from modules; the QML engine looks for lib<plugin>.so.
set(CMAKE_SHARED_MODULE_PREFIX "lib")

qt_add_qml_module(tmrules_io
    URI com.github.vincentullmann.taskmanagerrules.io
    VERSION 1.0
    PLUGIN_TARGET tmrules_ioplugin
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/com/github/vincentullmann/taskmanagerrules/io
    SOURCES
        iohelper.h
        iohelper.cpp
)
target_link_libraries(tmrules_io PUBLIC Qt6::Core Qt6::Qml)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

# Standard Qt QML import layout: <QML dir>/com/github/.../io/{qmldir,lib*plugin.so}
set(_tmrules_io_dest ${KDE_INSTALL_QMLDIR}/com/github/vincentullmann/taskmanagerrules/io)
install(TARGETS tmrules_ioplugin LIBRARY DESTINATION ${_tmrules_io_dest})
install(TARGETS tmrules_io LIBRARY DESTINATION ${KDE_INSTALL_LIBDIR})
install(FILES ${CMAKE_BINARY_DIR}/com/github/vincentullmann/taskmanagerrules/io/qmldir DESTINATION ${_tmrules_io_dest})
install(FILES ${CMAKE_BINARY_DIR}/com/github/vincentullmann/taskmanagerrules/io/tmrules_io.qmltypes DESTINATION ${_tmrules_io_dest} OPTIONAL)
