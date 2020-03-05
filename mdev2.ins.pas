{   Private include file for modules implementing the MDEV library.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'mdev.ins.pas';

procedure mdev_dir_get (               {find a specific directories list entry}
  in out  md: mdev_t;                  {MDEV library use state}
  in      name: univ string_var_arg_t; {directory name, need not be absolute}
  out     ent_p: mdev_dir_ent_p_t);    {pointer to global list entry for this dir}
  val_param; extern;
