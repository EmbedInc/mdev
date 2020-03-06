@echo off
rem
rem   BUILD_LIB
rem
rem   Build the MDEV library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_pas %srcdir% %libname%_dir
call src_pas %srcdir% %libname%_lib
call src_pas %srcdir% %libname%_rd_firmware
call src_pas %srcdir% %libname%_read_dir
call src_pas %srcdir% %libname%_read_file
call src_pas %srcdir% %libname%_show
call src_pas %srcdir% %libname%_show_list

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%

call src_doc mdev
call src_doc mdev_file
