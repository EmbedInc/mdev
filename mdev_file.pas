module mdev_file;
define mdev_file_get;
define mdev_file_in_list;
define mdev_file_add_list;
define mdev_file_suffix;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_FILE_GET (MD, FNAM, ENT_P)
*
*   Return ENT_P pointing to the global files list entry for the file FNAM.  The
*   global list entry is created if it does not already exist.
*
*   FNAM may be a relative pathname.  The absolute pathname derived from it will
*   be used to identify files list entries.  Only the absolute pathname is
*   stored for each files list entry.
}
procedure mdev_file_get (              {get specific files list entry}
  in out  md: mdev_t;                  {MDEV library use state}
  in      fnam: univ string_var_arg_t; {file name, need not be absolute}
  out     ent_p: mdev_file_ent_p_t);   {pointer to global list entry for this file}
  val_param;

var
  tnam: string_treename_t;             {directory full absolute pathname}
  obj_p: mdev_file_p_t;                {points to new file descriptor}

begin
  tnam.max := size_char(tnam.str);     {init local var string}

  string_treename (fnam, tnam);        {make absolute pathname in TNAM}

  ent_p := md.file_p;                  {init to first list entry}
  while ent_p <> nil do begin          {scan the directories list}
    if string_equal (                  {this file is already in the list ?}
        ent_p^.file_p^.name_p^, tnam)
        then begin
      return;                          {return existing list entry}
      end;
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;
{
*   The directory is not already in the list.
}
  util_mem_grab (                      {allocate mem for new descriptor}
    sizeof(obj_p^), md.mem_p^, false, obj_p);
  string_alloc (                       {allocate mem for the new name string}
    tnam.len, md.mem_p^, false, obj_p^.name_p);
  string_copy (tnam, obj_p^.name_p^);  {fill in name}
  obj_p^.dep_p := nil;                 {fill in rest of descriptor}

  util_mem_grab (                      {allocate memory for the new list entry}
    sizeof(ent_p^), md.mem_p^, false, ent_p);
  ent_p^.file_p := obj_p;              {save pointer in list entry}
  ent_p^.next_p := md.file_p;          {link new entry to start of list}
  md.file_p := ent_p;
  end;
{
********************************************************************************
*
*   Subroutine MDEV_FILE_IN_LIST (MD, FILE, LIST_P)
*
*   Make sure that the file FILE is in the list of files pointed to by LIST_P.
}
procedure mdev_file_in_list (          {insure file is in list}
  in out  md: mdev_t;                  {MDEV library use state}
  in var  file: mdev_file_t;           {the file}
  in out  list_p: mdev_file_ent_p_t);  {pointer to the list}
  val_param;

var
  ent_p: mdev_file_ent_p_t;            {pointer to list entry}

begin
  ent_p := list_p;                     {init to first list entry}
  while ent_p <> nil do begin          {back here each new list entry}
    if ent_p^.file_p = addr(file)      {the file is already in the list ?}
      then return;
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to check this new list entry}

  util_mem_grab (                      {allocate memory for the new list entry}
    sizeof(ent_p^), md.mem_p^, false, ent_p);
  ent_p^.file_p := addr(file);         {fill in the list entry}
  ent_p^.next_p := list_p;             {link new entry to start of list}
  list_p := ent_p;
  end;
{
********************************************************************************
*
*   Subroutine MDEV_FILE_ADD_LIST (MD, SRCLIST_P, DSTLIST_P)
*
*   Make sure all the files in the list pointed to by SRCLIST_P are in the list
*   pointed to by DSTLIST_P.  Put another way, all the files in the SRCLIST_P^
*   list are added to the DSTLIST_P^ list except those that are already there.
}
procedure mdev_file_add_list (         {add list of files to existing list}
  in out  md: mdev_t;                  {MDEV library use state}
  in      srclist_p: mdev_file_ent_p_t; {pointer to list of files to add}
  in out  dstlist_p: mdev_file_ent_p_t); {pointer to list to add the files to}
  val_param;

var
  ent_p: mdev_file_ent_p_t;            {pointer to source list entry}

begin
  ent_p := srclist_p;                  {init to first source list entry}
  while ent_p <> nil do begin          {back here each new source list entry}
    mdev_file_in_list (                {make sure this source file is in dest list}
      md, ent_p^.file_p^, dstlist_p);
    ent_p := ent_p^.next_p;            {to next source list entry}
    end;                               {back to process this new source list entry}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_FILE_SUFFIX (TNAM, DIR, GNAM, SUFF, STAT)
*
*   Determine the directory, generic name (name without the file name suffix),
*   and the file name suffix of the treename TNAM.  STAT is set to indicate
*   error if no file name is left after the suffix is removed, the treename has
*   no suffix, or the suffix is not recognized.  SUFF is returned a valid value
*   to the extent possible, even when STAT is set to indicate error.
}
procedure mdev_file_suffix (           {get suffix, gnam, and directory of file}
  in      tnam: univ string_var_arg_t; {full input treename}
  in out  dir: univ string_var_arg_t;  {directory containing file}
  in out  gnam: univ string_var_arg_t; {generic name of file, without suffix}
  out     suff: mdev_suffix_k_t;       {ID for the file name suffix}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  tk: string_var32_t;                  {scratch token}
  fnam: string_leafname_t;             {name of while within its directory}
  p: sys_int_machine_t;                {parse index}
  suffid: sys_int_machine_t;           {ID for the suffix of FNAM}

label
  err_tnam;

begin
  tk.max := size_char(tk.str);         {init local var strings}
  fnam.max := size_char(fnam.str);
  sys_error_none (stat);               {init to no error encountered}

  string_pathname_split (tnam, dir, fnam); {find directory and leafname in directory}

  p := fnam.len;                       {init to last char of input file name}
  while p > 0 do begin                 {scan backwards looking for "."}
    if fnam.str[p] = '.' then exit;    {found separator before file name suffix ?}
    p := p - 1;                        {no, go to next previous character}
    end;                               {back to check this new character}
  if p <= 0 then begin                 {no suffix ?}
    suff := mdev_suffix_none_k;
    string_copy (fnam, gnam);
    sys_stat_set (mdev_subsys_k, mdev_stat_nbnosuff_k, stat);
    goto err_tnam;                     {add file name to STAT and abort}
    end;

  string_substr (                      {extract generic file name}
    fnam,                              {input string}
    1,                                 {start index}
    p - 1,                             {end index}
    gnam);                             {returned file name without the suffix}

  string_substr (                      {extract file name suffix}
    fnam,                              {input string}
    p + 1,                             {start index}
    fnam.len,                          {end index}
    tk);                               {returned file name suffix}
  string_tkpick80 (tk,                 {pick suffix from list}
    'dspic xc16',                      {list of suffixes}
    suffid);                           {returned 1-N ID of the suffix}
  case suffid of                       {which type of file is this ?}
1:  suff := mdev_suffix_dspic_k;
2:  suff := mdev_suffix_xc16_k;
otherwise
    suff := mdev_suffix_unknown_k;
    sys_stat_set (mdev_subsys_k, mdev_stat_nbunsuff_k, stat);
    sys_stat_parm_vstr (tk, stat);     {add suffix}
    goto err_tnam;                     {add file name and abort}
    end;

  if gnam.len <= 0 then begin          {no file name left after suffix removed ?}
    sys_stat_set (mdev_subsys_k, mdev_stat_nbnofnam_k, stat);
    goto err_tnam;                     {add file name to STAT and abort}
    end;

  return;                              {normal return point, no error}
{
*   An error has ocurred.  STAT is partially set.  The file name will be added
*   as its next parameter, then this routine will return.
}
err_tnam:
  sys_stat_parm_vstr (tnam, stat);     {add file name as error parameter}
  end;
