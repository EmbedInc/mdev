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

  mdev_resolve (md);                   {resolve dependencies, add modules to FWs}
  mdev_show (md, 0);                   {show the results}
  mdev_lib_end (md);                   {end use of the MDEV library}
  end.
