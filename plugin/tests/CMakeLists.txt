# Compile the helper directly: the QML module library hides its symbols.
qt_add_executable(tst_iohelper tst_iohelper.cpp ../iohelper.cpp ../iohelper.h)
target_include_directories(tst_iohelper PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/..)
target_link_libraries(tst_iohelper PRIVATE Qt6::Core Qt6::Qml Qt6::Test)
add_test(NAME tst_iohelper COMMAND tst_iohelper)
