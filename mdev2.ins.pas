{   Private include file for modules implementing the MDEV library.
}
%include 'sys.ins.pas';
%include 'util.ins.pas';
%include 'string.ins.pas';
%include 'file.ins.pas';
%include 'hier.ins.pas';
%include 'mdev.ins.pas';

type
  mdev_read_t = record                 {state for reading one MDEV file}
    md_p: mdev_p_t;                    {pointer to MDEV library use state}
    rd: hier_read_t;                   {hierarchical file reading state}
    end;

procedure mdev_dir_get (               {find a specific directories list entry}
  in out  md: mdev_t;                  {MDEV library use state}
  in      name: univ string_var_arg_t; {directory name, need not be absolute}
  out     ent_p: mdev_dir_ent_p_t);    {pointer to global list entry for this dir}
  val_param; extern;

procedure mdev_rd_firmware (           {read FIRMWARE command}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param; extern;

procedure mdev_show_desc (             {show description text}
  in      desc: univ string_var_arg_t; {description string, may be long}
  in      indent: sys_int_machine_t);  {number of space to indent each new line}
  val_param; extern;
