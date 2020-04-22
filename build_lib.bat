@echo off
rem
rem   BUILD_LIB
rem
rem   Build the MDEV library.
rem
setlocal
call build_pasinit

call src_insall %srcdir% %libname%

call src_pas %srcdir% %libname%_check
call src_pas %srcdir% %libname%_dir
call src_pas %srcdir% %libname%_file
call src_pas %srcdir% %libname%_fw
call src_pas %srcdir% %libname%_fw_name
call src_pas %srcdir% %libname%_iface
call src_pas %srcdir% %libname%_lib
call src_pas %srcdir% %libname%_module
call src_pas %srcdir% %libname%_resolve
call src_pas %srcdir% %libname%_resolve_file
call src_pas %srcdir% %libname%_resolve_fw
call src_pas %srcdir% %libname%_resolve_mod
call src_pas %srcdir% %libname%_rd_file
call src_pas %srcdir% %libname%_rd_firmware
call src_pas %srcdir% %libname%_rd_interface
call src_pas %srcdir% %libname%_rd_module
call src_pas %srcdir% %libname%_rd_text
call src_pas %srcdir% %libname%_read_dir
call src_pas %srcdir% %libname%_read_file
call src_pas %srcdir% %libname%_show
call src_pas %srcdir% %libname%_show_list
call src_pas %srcdir% %libname%_wr_build
call src_pas %srcdir% %libname%_wr_ids
call src_pas %srcdir% %libname%_wr_ins_init
call src_pas %srcdir% %libname%_wr_ins_main
call src_pas %srcdir% %libname%_wr_mlist
call src_pas %srcdir% %libname%_wr_templ

call src_lib %srcdir% %libname%
call src_msg %srcdir% %libname%

call src_doc mdev
call src_doc mdev_file
