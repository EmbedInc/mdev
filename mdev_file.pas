module mdev_file;
define mdev_file_get;
define mdev_file_in_list;
define mdev_file_add_list;
define mdev_file_suffix;
define mdev_file_templname_resolve;
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
*   Subroutine MDEV_FILE_SUFFIX (TNAM, DIR, GNAM, ID, STAT)
*
*   Determine the directory, generic name (name without the file name suffix),
*   and the file name suffix of the treename TNAM.  STAT is set to indicate
*   error if no file name is left after the suffix is removed, the treename has
*   no suffix, or the suffix is not recognized.  ID is returned a valid value
*   to the extent possible, even when STAT is set to indicate error.
}
procedure mdev_file_suffix (           {get suffix, gnam, and directory of file}
  in      tnam: univ string_var_arg_t; {full input treename}
  in out  dir: univ string_var_arg_t;  {directory containing file}
  in out  gnam: univ string_var_arg_t; {generic name of file, without suffix}
  out     id: mdev_suffix_k_t;         {ID for the file name suffix}
  out     stat: sys_err_t);            {completion status}
  val_param;

var
  fnam: string_leafname_t;             {name of file within its directory}
  suff: string_leafname_t;             {file name suffix}
  gend: sys_int_machine_t;             {string index of end of generic name}

label
  err_tnam;

begin
  fnam.max := size_char(fnam.str);     {init local var strings}
  suff.max := size_char(suff.str);
  sys_error_none (stat);               {init to no error encountered}

  string_pathname_split (tnam, dir, fnam); {find directory and leafname in directory}
  mdev_suffix_find (fnam, suff);       {extract the suffix into SUFF}

  gend := fnam.len - suff.len - 1;     {init GNAM end for normal case}
  if                                   {special case of no suffix delimiter ?}
      (suff.len = 0) and               {no suffix characters}
      (fnam.str[fnam.len] <> '.')      {file name doesn't end with "." ?}
      then begin
    gend := fnam.len;                  {generic name is whole file name}
    end;
  string_substr (                      {extract the generic name}
    fnam,                              {input name}
    1,                                 {starting index}
    gend,                              {ending index}
    gnam);                             {returned extracted substring}

  id := mdev_suffix_id (suff);         {get and return the suffix ID}

  case id of                           {check for error cases}
mdev_suffix_none_k: begin              {no suffix}
      sys_stat_set (mdev_subsys_k, mdev_stat_nbnosuff_k, stat);
      goto err_tnam;                   {add file name to STAT and abort}
      end;
mdev_suffix_unknown_k: begin           {not a recognized suffix}
      sys_stat_set (mdev_subsys_k, mdev_stat_nbunsuff_k, stat);
      sys_stat_parm_vstr (suff, stat); {add suffix}
      goto err_tnam;                   {add file name and abort}
      end;
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
{
********************************************************************************
*
*   Subroutine MDEV_FILE_TEMPLNAME_RESOLVE (TEMPL, FWNAME, DNAM)
*
*   Resolve the template file name TEMPL to the name of the local modified copy
*   in DNAM.  FWNAME is the name of the firmware the template is being modified
*   for.
}
procedure mdev_file_templname_resolve ( {make actual file name from template name}
  in      templ: univ string_var_arg_t; {template file name}
  in      fwname: univ string_var_arg_t; {firmware name}
  out     dnam: univ string_var_arg_t); {resolved template destination file leafname}
  val_param;

var
  snam: string_leafname_t;             {source file leafname}
  snaml: string_leafname_t;            {lower case version of SNAM}
  tk: string_treename_t;               {scratch string}
  ind: string_index_t;                 {string index}

begin
  snam.max := size_char(snam.str);     {init local var strings}
  snaml.max := size_char(snaml.str);
  tk.max := size_char(tk.str);

  string_pathname_split (templ, tk, snam); {get source file leasname into SNAM}
  string_copy (snam, snaml);           {make lower case copy for pattern matching}
  string_downcase (snam);
  string_vstring (tk, 'qqq'(0), -1);   {make the pattern to look for}
  string_find (tk, snam, ind);         {look for pattern in source file name}
  if ind = 0
    then begin                         {source file name does not contain pattern}
      string_copy (snam, dnam);        {use template file leafname directly}
      end
    else begin                         {source file name contains pattern at IND}
      string_substr (                  {copy part of filename before pattern}
        snam,                          {source string}
        1,                             {starting index to copy from}
        ind - 1,                       {ending index to copy from}
        dnam);                         {output string}
      string_append (dnam, fwname);    {add firmware name in place of pattern}
      ind := ind + tk.len;             {first index after pattern in source string}
      string_substr (                  {get part of source string after pattern}
        snam,                          {source string}
        ind,                           {starting index to copy from}
        snam.len,                      {ending index to copy from}
        tk);                           {returned substring}
      string_append (dnam, tk);        {add the substring to end of dest snam}
      end
    ;
  end;
