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

procedure mdev_file_add_list (         {add list of files to existing list}
  in out  md: mdev_t;                  {MDEV library use state}
  in      srclist_p: mdev_file_ent_p_t; {pointer to list of files to add}
  in out  dstlist_p: mdev_file_ent_p_t); {pointer to list to add the files to}
  val_param; extern;

procedure mdev_file_get (              {get specific files list entry}
  in out  md: mdev_t;                  {MDEV library use state}
  in      fnam: univ string_var_arg_t; {file name, need not be absolute}
  out     ent_p: mdev_file_ent_p_t);   {pointer to global list entry for this file}
  val_param; extern;

procedure mdev_file_in_list (          {insure file is in list}
  in out  md: mdev_t;                  {MDEV library use state}
  in var  file: mdev_file_t;           {the file}
  in out  list_p: mdev_file_ent_p_t);  {pointer to the list}
  val_param; extern;

procedure mdev_file_suffix (           {get suffix, gnam, and directory of file}
  in      tnam: univ string_var_arg_t; {full input treename}
  in out  dir: univ string_var_arg_t;  {directory containing file}
  in out  gnam: univ string_var_arg_t; {generic name of file, without suffix}
  out     id: mdev_suffix_k_t;         {ID for the file name suffix}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure mdev_file_templname_resolve ( {make actual file name from template name}
  in      templ: univ string_var_arg_t; {template file name}
  in      fwname: univ string_var_arg_t; {firmware name}
  out     dnam: univ string_var_arg_t); {resolved template destination file leafname}
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

procedure mdev_mod_link (              {link module to start of list}
  in out  md: mdev_t;                  {MDEV library use state}
  in var  mod: mdev_mod_t;             {module to add list entry for}
  in out  list_p: mdev_mod_ent_p_t);   {pointer to list to add entry to}
  val_param; extern;

procedure mdev_resolve_file (          {resolve dependencies of a file}
  in out  md: mdev_t;                  {MDEV library use state}
  in out  file: mdev_file_t);          {file to resolve dependencies of}
  val_param; extern;

procedure mdev_resolve_fw (            {resolve dependencies of a firmware}
  in out  md: mdev_t;                  {MDEV library use state}
  in out  fw: mdev_fw_t);              {firmware to resolve dependencies of}
  val_param; extern;

procedure mdev_resolve_mod (           {resolve dependencies of a module}
  in out  md: mdev_t;                  {MDEV library use state}
  in out  mod: mdev_mod_t);            {module to resolve dependencies of}
  val_param; extern;

procedure mdev_rd_file (               {read FILE command}
  in out  mr: mdev_read_t;             {MDEV file reading state}
  in out  stat: sys_err_t);            {completion status, caller init to no err}
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

procedure mdev_suffix_find (           {find suffix of file leafname}
  in      lnam: univ string_var_arg_t; {input name, must be leafname}
  in out  suff: univ string_var_arg_t); {returned suffix}
  val_param; extern;

function mdev_suffix_fnam (            {return file name suffix ID}
  in      fnam: univ string_var_arg_t) {pathname to classify suffix of}
  :mdev_suffix_k_t;                    {ID of suffix found}
  val_param; extern;

function mdev_suffix_id (              {determine id of file name suffix}
  in      suff: univ string_var_arg_t) {suffix, part after first period}
  :mdev_suffix_k_t;                    {returned suffix ID}
  val_param; extern;

function mdev_suffix_lnam (            {get ID of leafname suffix}
  in      lnam: univ string_var_arg_t) {leafname to classify suffix of}
  :mdev_suffix_k_t;                    {suffix ID}
  val_param; extern;
