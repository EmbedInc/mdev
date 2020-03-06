{   Program MDEV_BUILD [firmware]
*
*   Adds qualifying MDEV modules to a firmware build.
}
program mdev_build;
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'hier.ins.pas';
%include 'mdev.ins.pas';

var
  md: mdev_t;                          {MDEV library state}
  stat: sys_err_t;                     {completion status}

begin
  mdev_lib_start (md, util_top_mem_context); {start use of the MDEV library}
  mdev_read_dirs (                     {read MDEV file set}
    md,                                {MDEV library state}
    string_v('.'),                     {start in current directory}
    stat);
  sys_error_abort (stat, '', '', nil, 0);

  writeln;
  writeln ('Directories:');
  mdev_show_list_dir (md.dir_p, 2);

  writeln;
  writeln ('Interfaces:');
  mdev_show_list_iface (md.iface_p, 2);

  writeln;
  writeln ('Files:');
  mdev_show_list_file (md.file_p, 2);

  writeln;
  writeln ('Modules:');
  mdev_show_list_mod (md.mod_p, 2);

  writeln;
  writeln ('Firmwares:');
  mdev_show_list_fw (md.fw_p, 2);

  mdev_lib_end (md);                   {end use of the MDEV library}
  end.
