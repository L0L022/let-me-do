cmake_minimum_required(VERSION 2.6)
project(let-me-do)
find_package(Gettext REQUIRED)

set(LET-ME-DO_PATH "${CMAKE_INSTALL_PREFIX}/bin/let-me-do" CACHE FILEPATH "let-me-do program path")
set(LET-ME-DO-POLKIT_PATH "${CMAKE_INSTALL_PREFIX}/bin/let-me-do-polkit" CACHE FILEPATH "let-me-do-polkit program path")
set(LOCALE_PATH "${CMAKE_INSTALL_PREFIX}/share/locale" CACHE FILEPATH "locale path")

configure_file(let-me-do.bash let-me-do.bash)
configure_file(let-me-do-polkit.bash let-me-do-polkit.bash)
configure_file(let-me-do.desktop let-me-do.desktop)
configure_file(polkit/org.freedesktop.let-me-do.policy polkit/org.freedesktop.let-me-do.policy)

gettext_create_translations(po/let-me-do.pot ALL po/fr.po)

#install target
install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/let-me-do.bash"
        DESTINATION "${CMAKE_INSTALL_PREFIX}/bin"
        RENAME let-me-do)

install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/let-me-do-polkit.bash"
        DESTINATION "${CMAKE_INSTALL_PREFIX}/bin"
      RENAME let-me-do-polkit)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/let-me-do.desktop"
        DESTINATION "${CMAKE_INSTALL_PREFIX}/share/applications")

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/polkit/org.freedesktop.let-me-do.policy"
        DESTINATION "${CMAKE_INSTALL_PREFIX}/share/polkit-1/actions")

#uninstall target
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake)
