module mdev_file;
define mdev_file_get;
define mdev_file_in_list;
define mdev_file_add_list;
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
