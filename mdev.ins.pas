{   Public include file for the MDEV library.  This library can read MDEV files,
*   and maintains data structures corresponding to the information in a MDEV
*   file set.
}
const
  mdev_subsys_k = -70;                 {MDEV library subsystem ID}
  mdev_stat_share_k = 1;               {sharing discrepancy with module references}
  mdev_stat_unface_k = 2;              {undefined interface, no FW or module}
  mdev_stat_unface_fw_k = 3;           {undefined iface, ref to firmware}
  mdev_stat_unface_mod_k = 4;          {undefined iface, ref to module}
  mdev_stat_badid_k = 5;               {invalid module ID}
  mdev_stat_dupid_k = 6;               {duplicate module ID}
  mdev_stat_idused_k = 7;              {module ID already in use}
  mdev_stat_ninsdspic_k = 8;           {not .ins.dspic file}
  mdev_stat_mlcmd_k = 9;               {bad MLIST file command}
  mdev_stat_extra_k = 10;              {extra token found at end of line from file}

  mdev_modid_min_k = 1;                {minimum valid module ID}
  mdev_modid_max_k = 254;              {maximum valid module ID}

type
  mdev_mod_p_t = ^mdev_mod_t;          {points to descriptor for one MDEV module}
  mdev_mod_ent_p_t = ^mdev_mod_ent_t;  {points to one entry in list of modules}
  mdev_dir_p_t = ^mdev_dir_t;          {points to descriptor for one directory}
  mdev_dir_ent_p_t = ^mdev_dir_ent_t;  {points to one entry in list of directories}
  mdev_file_p_t = ^mdev_file_t;        {points to descriptor of one file}
  mdev_file_ent_p_t = ^mdev_file_ent_t; {points to one entry in list of files}
  mdev_iface_p_t = ^mdev_iface_t;      {points to descriptor for one interface}
  mdev_iface_ent_p_t = ^mdev_iface_ent_t; {points to one entry in list of interfaces}
  mdev_fw_p_t = ^mdev_fw_t;            {points to descriptor for one firmware}
  mdev_fw_ent_p_t = ^mdev_fw_ent_t;    {points to one entry in list of firmwares}

  mdev_iface_t = record                {information about one interface}
    name_p: string_var_p_t;            {points to the interface name, case-sensitive}
    desc_p: string_var_p_t;            {points to description string}
    impl_p: mdev_mod_ent_p_t;          {list of modules that implement this interface}
    fw_p: mdev_fw_ent_p_t;             {list of firmwares implementing iface directly}
    end;

  mdev_iface_ent_t = record            {one entry in list of interfaces}
    next_p: mdev_iface_ent_p_t;        {points to next list entry}
    iface_p: mdev_iface_p_t;           {points to the interface descriptor}
    shared: boolean;                   {this interface use shareable with others}
    end;

  mdev_file_t = record                 {information about one source or required file}
    name_p: string_var_p_t;            {points to full file pathname}
    dep_p: mdev_file_ent_p_t;          {list of files this file depends on}
    end;

  mdev_file_ent_t = record             {one entry in list of files}
    next_p: mdev_file_ent_p_t;         {points to next list entry}
    file_p: mdev_file_p_t;             {points to the file descriptor}
    end;

  mdev_dir_t = record                  {information about one directory with MDEV files}
    name_p: string_var_p_t;            {points to full pathname}
    end;

  mdev_dir_ent_t = record              {one entry in list of directories}
    next_p: mdev_dir_ent_p_t;          {points to next list entry}
    dir_p: mdev_dir_p_t;               {points to the directory descriptor}
    end;

  mdev_mod_t = record                  {information about one module}
    name_p: string_var_p_t;            {points to module name, mixed case}
    desc_p: string_var_p_t;            {points to description string}
    uses_p: mdev_iface_ent_p_t;        {list of interfaces required by this module}
    impl_p: mdev_iface_ent_p_t;        {list of interfaces implemented by this module}
    templ_p: mdev_file_ent_p_t;        {list of template files to customize and include}
    files_p: mdev_file_ent_p_t;        {list of referenced files}
    incl_p: mdev_file_ent_p_t;         {list of include files}
    end;

  mdev_mod_ent_t = record              {one entry in list of modules}
    next_p: mdev_mod_ent_p_t;          {points to next list entry}
    mod_p: mdev_mod_p_t;               {points to the module descriptor}
    end;

  mdev_modid_t = record                {info about a module ID within a firmware}
    mod_p: mdev_mod_p_t;               {pointer to the module, NIL for none}
    used: boolean;                     {this module is actually used within the FW}
    end;

  mdev_modids_t =                      {array of module IDs for a firmware}
    array[mdev_modid_min_k .. mdev_modid_max_k] of mdev_modid_t;

  mdev_fw_t = record                   {information about one firmware}
    context_p: string_var_p_t;         {firmware name context hierarchy, NIL for top}
    name_p: string_var_p_t;            {firmware name}
    impl_p: mdev_iface_ent_p_t;        {list of interfaces implemented by this firmware}
    templ_p: mdev_file_ent_p_t;        {list of template files to customize and include}
    files_p: mdev_file_ent_p_t;        {list of referenced files}
    incl_p: mdev_file_ent_p_t;         {list of include files}
    mod_p: mdev_mod_ent_p_t;           {list of modules this firmware can support}
    modids: mdev_modids_t;             {module for each possible module ID}
    end;

  mdev_fw_ent_t = record               {one entry in list of firmwares}
    next_p: mdev_fw_ent_p_t;           {points to next list entry}
    fw_p: mdev_fw_p_t;                 {points to the firwmware descriptor}
    end;

  mdev_p_t = ^mdev_t;
  mdev_t = record                      {state for one use of this library}
    mem_p: util_mem_context_p_t;       {points to mem context for this lib use}
    dir_p: mdev_dir_ent_p_t;           {list of directories that might contain MDEV files}
    dir_read_p: mdev_dir_ent_p_t;      {points to dir currently being read}
    iface_p: mdev_iface_ent_p_t;       {list of all interfaces}
    file_p: mdev_file_ent_p_t;         {list of all files}
    mod_p: mdev_mod_ent_p_t;           {list of all modules}
    fw_p: mdev_fw_ent_p_t;             {list of all firmwares}
    end;
{
*   Subroutines and functions.
}
procedure mdev_check (                 {check all data for errors}
  in out  md: mdev_t;                  {MDEV library use state}
  out     stat: sys_err_t);            {returned error status}
  val_param; extern;

function mdev_fw_name_make (           {make full firmware name string, applies defaults}
  in out  md: mdev_t;                  {MDEV library use state}
  in      fw: univ string_var_arg_t;   {input FW name, may be empty to full path}
  in out  fwpath: univ string_var_arg_t) {returned full firmware name path}
  :boolean;                            {success, FWPATH contains valid firmware name}
  val_param; extern;

procedure mdev_fw_name_path (          {get full pathname of a particular firmware}
  in      fw: mdev_fw_t;               {firmware to get full pathname of}
  in out  fwpath: univ string_var_arg_t); {returned full firmware pathname}
  val_param; extern;

procedure mdev_fw_name_split (         {split firmware pathname into context and name}
  in      fwpath: univ string_var_arg_t; {full firmware pathname}
  in out  context: univ string_var_arg_t; {returned context part of FW name}
  in out  name: univ string_var_arg_t); {returned bare firmware name}
  val_param; extern;

procedure mdev_fw_find (               {find firmware by name}
  in out  md: mdev_t;                  {MDEV library use state}
  in      name: univ string_var_arg_t; {name of the firmware to find}
  in      make: boolean;               {make FW descriptor if not exist}
  out     fw_p: mdev_fw_p_t);          {returned pointer to FW desc, NIL if none and not make}
  val_param; extern;

procedure mdev_lib_end (               {end library use instance, deallocate resources}
  in out  md: mdev_t);                 {library use state, returned invalid}
  val_param; extern;

procedure mdev_lib_start (             {start a new MDEV library use instance}
  out     md: mdev_t;                  {library use state to initialize}
  in out  mem: util_mem_context_t);    {parent mem context, subordinate will be created}
  val_param; extern;

procedure mdev_read_dir (              {read all MDEV files in directory}
  in out  md: mdev_t;                  {lib use state to add the information to}
  in      dir: univ string_var_arg_t;  {directory name}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure mdev_read_dirs (             {read MDEV files in dir and all referenced dirs}
  in out  md: mdev_t;                  {lib use state to add the information to}
  in      dir: univ string_var_arg_t;  {starting directory name}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure mdev_read_file (             {read one MDEV file}
  in out  md: mdev_t;                  {lib use state to add the information to}
  in      fnam: univ string_var_arg_t; {name of file to read, ".mdev" assumed}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure mdev_resolve (               {resolve dependencies, add modules to FWs}
  in out  md: mdev_t);                 {MDEV library use state}
  val_param; extern;

procedure mdev_show (                  {show all MDEV data}
  in      md: mdev_t;                  {library use instance to show data of}
  in      indent: sys_int_machine_t);  {indentation level, 0 for none}
  val_param; extern;

procedure mdev_show_fw (               {show a single firmware}
  in      fw: mdev_fw_t);              {the firmware to show data of}
  val_param; extern;

procedure mdev_show_list_dir (         {show directories list}
  in      list_p: mdev_dir_ent_p_t;    {pointer to first list entry}
  in      indent: sys_int_machine_t;   {number of spaces to indent each line}
  in      sub: boolean);               {show sub-level information}
  val_param; extern;

procedure mdev_show_list_file (        {show files list}
  in      list_p: mdev_file_ent_p_t;   {pointer to first list entry}
  in      indent: sys_int_machine_t;   {number of spaces to indent each line}
  in      sub: boolean);               {show sub-level information}
  val_param; extern;

procedure mdev_show_list_fw (          {show firmwares list}
  in      list_p: mdev_fw_ent_p_t;     {pointer to first list entry}
  in      indent: sys_int_machine_t;   {number of spaces to indent each line}
  in      sub: boolean);               {show sub-level information}
  val_param; extern;

procedure mdev_show_list_iface (       {show interfaces list}
  in      list_p: mdev_iface_ent_p_t;  {pointer to first list entry}
  in      indent: sys_int_machine_t;   {number of spaces to indent each line}
  in      sub: boolean);               {show sub-level information}
  val_param; extern;

procedure mdev_show_list_mod (         {show MDEV modules list}
  in      list_p: mdev_mod_ent_p_t;    {pointer to first list entry}
  in      indent: sys_int_machine_t;   {number of spaces to indent each line}
  in      sub: boolean);               {show sub-level information}
  val_param; extern;

procedure mdev_wr_build (              {write BUILD_MDEVS scripts}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure mdev_wr_ids (                {write MDEV and H files with assigned module IDs}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure mdev_wr_ids_cs (             {write CS file with info about this firmare}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure mdev_wr_ins_init (           {write initialization include file}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure mdev_wr_ins_main (           {write main MDEV include file}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure mdev_wr_mlist (              {edit MLIST file to include MDEV modules}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;

procedure mdev_wr_templ_list (         {write the source files modified from templates}
  in      fw: mdev_fw_t;               {the target firmare}
  in      verbose: boolean;            {show more than just changes}
  out     stat: sys_err_t);            {completion status}
  val_param; extern;
