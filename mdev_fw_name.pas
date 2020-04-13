module mdev_fw_name;
define mdev_fw_name_path;
define mdev_fw_name_make;
define mdev_fw_name_split;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_FW_NAME_PATH (FW, FWPATH)
*
*   Return the full pathname of the firmware FW in FWPATH.  The resulting string
*   is guaranteed to have no leading and trailing blanks, and tokens will be
*   separated by single blanks.
}
procedure mdev_fw_name_path (          {get full pathname of a particular firmware}
  in      fw: mdev_fw_t;               {firmware to get full pathname of}
  in out  fwpath: univ string_var_arg_t); {returned full firmware pathname}
  val_param;

begin
  fwpath.len := 0;                     {init returned path to empty}
  if fw.context_p <> nil then begin    {context path exists ?}
    string_copy (fw.context_p^, fwpath); {init returned path with context}
    end;
  string_append_token (fwpath, fw.name_p^); {add the bare firmware name}
  end;
{
********************************************************************************
*
*   Function MDEV_FW_NAME_MAKE (MD, FW, FWPATH)
*
*   Make the full firmware pathname in FWPATH, given a possible firmware name or
*   pathname in FW.  Defaults are applied as necessary.
*
*   The MDEV file set should already have been read since some defaults depend
*   on what firmwares are known.
*
*   The function returns TRUE iff a firmware could be unambiguously determined
*   from all the available information.  When the function returns FALSE,
*   FWPATH will be set to the empty string.
}
function mdev_fw_name_make (           {make full firmware name string, applies defaults}
  in out  md: mdev_t;                  {MDEV library use state}
  in      fw: univ string_var_arg_t;   {input FW name, may be empty to full path}
  in out  fwpath: univ string_var_arg_t) {returned full firmware name path}
  :boolean;                            {success, FWPATH contains valid firmware name}
  val_param;

const
  evname = 'FWNAME';                   {name of environment variable with FW name}

var
  fwn: string_var1024_t;               {input firmware name}
  tk: string_var32_t;                  {scratch token}
  fw_p: mdev_fw_p_t;                   {pointer to known firmware}
  ent_p: mdev_fw_ent_p_t;              {pointer to current firmwares list entry}
  stat: sys_err_t;

label
  fail;

begin
  fwn.max := size_char(fwn.str);       {init local var strings}
  tk.max := size_char(tk.str);

  mdev_fw_name_make := true;           {init to returning with firmware pathname}
{
*   Get the environment variable default if FW was the empty string.  The
*   effective input string going forward will be FWN.
}
  string_copy (fw, fwn);               {init input name to value passed in FW}
  if fwn.len <= 0 then begin           {nothing passed in, check environment var ?}
    string_vstring (tk, evname, size_char(evname)); {make var string envvar name}
    sys_envvar_get (tk, fwn, stat);    {try to get environment variable value}
    if sys_error(stat) then begin      {didn't get envvar name ?}
      fwn.len := 0;                    {as if empty string}
      end;
    end;
  string_unpad (fwn);                  {truncate any trailing blanks}
{
*   Handle case of empty input string.  There must be exactly one known firmware
*   to get the name of.
}
  if fwn.len <= 0 then begin           {handle case of empty string as input}
    if md.fw_p = nil                   {no known firmware ?}
      then goto fail;
    if md.fw_p^.next_p <> nil          {more than one known firmware ?}
      then goto fail;
    fw_p := md.fw_p^.fw_p;             {get pointer to the single known firmare}
    mdev_fw_name_path (fw_p^, fwpath); {get full pathname of this firmware}
    return;
    end;
{
*   Handle case where the input name is already a path.  If so, return it.
*   If not returning, leave the bare firmware name in TK.
}
  mdev_fw_name_split (fwn, fwpath, tk); {get context and bare name}
  if fwpath.len > 0 then begin         {already have context path ?}
    string_append_token (fwpath, tk);  {add bare name to complete path}
    return;                            {return it}
    end;
{
*   The input name is just the bare firmware name.  This must match exactly one
*   known firmware.  The bare firmware name is in TK.
}
  fw_p := nil;                         {init to no matching firmware found}
  ent_p := md.fw_p;                    {init to first list entry}
  while ent_p <> nil do begin          {scan the firmwares list entries}
    if string_equal(ent_p^.fw_p^.name_p^, tk) then begin {found matching firmware ?}
      if fw_p <> nil then goto fail;   {previous match, match not unique ?}
      fw_p := ent_p^.fw_p;             {save pointer to matching firmware}
      end;
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to check next firmware in list}

  if fw_p <> nil then begin            {found exactly one matching firmware ?}
    mdev_fw_name_path (fw_p^, fwpath); {return the full pathname of this firmware}
    return;
    end;

fail:                                  {couldn't resolve firmware pathname}
  mdev_fw_name_make := false;
  fwpath.len := 0;
  end;
{
********************************************************************************
*
*   Subroutine MDEV_FW_NAME_SPLIT (FWPATH, CONTEXT, NAME)
*
*   Split the full firmware pathname in FWPATH into its context path and bare
*   name in CONTEXT and NAME, respectively.
}
procedure mdev_fw_name_split (         {split firmware pathname into context and name}
  in      fwpath: univ string_var_arg_t; {full firmware pathname}
  in out  context: univ string_var_arg_t; {returned context part of FW name}
  in out  name: univ string_var_arg_t); {returned bare firmware name}
  val_param;

var
  p: string_index_t;                   {FWPATH parse index}
  tk: string_var32_t;                  {pathname component}
  stat: sys_err_t;

begin
  tk.max := size_char(tk.str);         {init local var string}

  context.len := 0;                    {init accumulated context string to empty}
  name.len := 0;                       {init to no previous pathname component}

  p := 1;                              {init input path parse index}
  while true do begin                  {back here each token in input path}
    string_token (fwpath, p, tk, stat);
    if sys_error(stat) then return;    {done parsing the input string ?}
    if (tk.len > 0) and (name.len > 0) then begin
      string_append_token (context, name); {previous component to end of context}
      end;
    string_copy (tk, name);            {last token becomes bare name for now}
    end;                               {back for next token in input string}
  end;
