# Compile the helper directly: the QML module library hides its symbols.
qt_add_executable(tst_iohelper tst_iohelper.cpp ../iohelper.cpp ../iohelper.h)
target_include_directories(tst_iohelper PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/..)
target_link_libraries(tst_iohelper PRIVATE Qt6::Core Qt6::Qml Qt6::Test)
add_test(NAME tst_iohelper COMMAND tst_iohelper)

qt_add_executable(qml_runner qml_runner.cpp)
target_link_libraries(qml_runner PRIVATE Qt6::Core Qt6::Qml)
add_test(NAME tst_configstore
         COMMAND qml_runner ${CMAKE_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/qml/tst_configstore.qml)
set_tests_properties(tst_configstore PROPERTIES TIMEOUT 30)
