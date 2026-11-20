cmake_minimum_required(VERSION 3.20)
project(plasma-taskmanager-rules VERSION 0.1.0 LANGUAGES CXX)

set(QT_MIN_VERSION "6.6")
set(KF6_MIN_VERSION "6.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Core Qml Quick Test DBus)
find_package(Plasma REQUIRED)
find_package(KF6I18n ${KF6_MIN_VERSION} REQUIRED)
find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Gui)

set(PLASMOID_ID "com.github.vincentullmann.taskmanagerrules")

include(CTest)
add_subdirectory(plugin)


# Plasmoid package (QML + JS + metadata). Installed as a plain Plasma/Applet package.
install(DIRECTORY package/
        DESTINATION ${KDE_INSTALL_DATADIR}/plasma/plasmoids/${PLASMOID_ID}
        PATTERN "*~" EXCLUDE)

