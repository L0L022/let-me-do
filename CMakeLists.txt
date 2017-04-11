cmake_minimum_required(VERSION 2.6)
project(let_me_do)
find_package(Gettext REQUIRED)

set(LET_ME_DO_PATH "${CMAKE_INSTALL_PREFIX}/bin/let_me_do" CACHE FILEPATH "let_me_do program path.")
set(LOCALE_PATH "${CMAKE_INSTALL_PREFIX}/share/locale" CACHE FILEPATH "locale path.")

configure_file(let_me_do.bash let_me_do.bash)
configure_file(let_me_do.desktop let_me_do.desktop)
configure_file(polkit/org.freedesktop.let_me_do.policy polkit/org.freedesktop.let_me_do.policy)

gettext_create_translations(po/let_me_do.pot ALL po/fr.po)

#install target
install(PROGRAMS "${CMAKE_CURRENT_BINARY_DIR}/let_me_do.bash"
        DESTINATION "${CMAKE_INSTALL_PREFIX}/bin"
        RENAME let_me_do)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/let_me_do.desktop"
        DESTINATION "${CMAKE_INSTALL_PREFIX}/share/applications")

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/polkit/org.freedesktop.let_me_do.policy"
        DESTINATION "${CMAKE_INSTALL_PREFIX}/share/polkit-1/actions")

#uninstall target
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake/cmake_uninstall.cmake)
