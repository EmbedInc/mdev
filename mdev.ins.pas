{   Public include file for the MDEV library.  This library can read MDEV files,
*   and maintains data structures corresponding to the information in a MDEV
*   file set.
}
const
  mdev_subsys_k = -70;                 {MDEV library subsystem ID}

  mdev_modid_min_k = 1;                {minimum valid module ID}
  mdev_modid_max_k = 255;              {maximum valid module ID}

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

  mdev_mod_ent_t = record              {one entry in list of modules}
    next_p: mdev_mod_ent_p_t;          {points to next list entry}
    mod_p: mdev_mod_p_t;               {points to the module descriptor}
    end;

  mdev_mod_t = record                  {information about one module}
    name_p: string_var_p_t;            {points to module name, mixed case}
    desc_p: string_var_p_t;            {points to description string}
    uses_p: mdev_iface_ent_p_t;        {list of interfaces required by this module}
    impl_p: mdev_iface_ent_p_t;        {list of interfaces implemented by this module}
    templ_p: mdev_file_ent_p_t;        {list of template files to customize and include}
    files_p: mdev_file_ent_p_t;        {list of referenced files}
    end;

  mdev_modids_t =                      {array of module IDs for a firmware}
    array[mdev_modid_min_k .. mdev_modid_max_k] of
    mdev_mod_p_t;                      {pointer to module for each possible ID}

  mdev_fw_t = record                   {information about one firmware}
    context_p: string_var_p_t;         {firmware name context hierarchy, NIL for top}
    name_p: string_var_p_t;            {firmware name, upper case}
    impl_p: mdev_iface_ent_p_t;        {list of interfaces implemented by this firmware}
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
