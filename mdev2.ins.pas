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

procedure mdev_file_get (              {get specific files list entry}
  in out  md: mdev_t;                  {MDEV library use state}
  in      fnam: univ string_var_arg_t; {file name, need not be absolute}
  out     ent_p: mdev_file_ent_p_t);   {pointer to global list entry for this file}
  val_param; extern;

procedure mdev_fw_get (                {get a specific firmware list entry}
  in out  md: mdev_t;                  {MDEV library use state}
  in      name: univ string_var_arg_t; {namespace hierarchy and firmware name}
  out     ent_p: mdev_fw_ent_p_t);     {pointer to global list entry for this fw}
  val_param; extern;

procedure mdev_iface_get (             {get specific interfaces list entry}
  in out  md: mdev_t;                  {MDEV library use state}
  in      name: univ string_var_arg_t; {interface name, case-sensitive}
  out     ent_p: mdev_iface_ent_p_t);  {returned pointer to global list entry}
  val_param; extern;

procedure mdev_mod_get (               {get a specific modules list entry}
  in out  md: mdev_t;                  {MDEV library use state}
  in      name: univ string_var_arg_t; {module name, case-sensitive}
  out     ent_p: mdev_mod_ent_p_t);    {pointer to global list entry for this module}
  val_param; extern;

procedure mdev_rd_firmware (           {read FIRMWARE command}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param; extern;

procedure mdev_rd_interface (          {read INTERFACE command}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param; extern;

procedure mdev_rd_text (               {read arbitrary wrappable text}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  out     str_p: string_var_p_t);      {returned pointer to new string}
  val_param; extern;

procedure mdev_rd_module (             {read MODULE command}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
  val_param; extern;

procedure mdev_show_desc (             {show description text}
  in      desc: univ string_var_arg_t; {description string, may be long}
  in      indent: sys_int_machine_t);  {number of space to indent each new line}
  val_param; extern;
