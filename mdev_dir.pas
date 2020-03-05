module mdev_dir;
define mdev_dir_get;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_DIR_GET (MD, NAME, ENT_P)
*
*   Return ENT_P pointing to the global directories list entry for the directory
*   of name NAME.  NAME may be relative.
*
*   All directories are stored in the global directories list by absolute
*   pathname.  There is therfore a single unique directory descriptor for each
*   directory in the global list.  ENT_P is returned pointing to the global list
*   entry for that single unique descriptor.
*
*   If the directory is not already in the global directories list, then it is
*   added first.  It is added after the directory pointed to by MD.DIR_READ_P if
*   not NIL, otherwise it is added to the start of the global list.
}
procedure mdev_dir_get (               {find a specific directories list entry}
  in out  md: mdev_t;                  {MDEV library use state}
  in      name: univ string_var_arg_t; {directory name, need not be absolute}
  out     ent_p: mdev_dir_ent_p_t);    {pointer to global list entry for this dir}
  val_param;

var
  tnam: string_treename_t;             {directory full absolute pathname}
  dir_p: mdev_dir_p_t;                 {points to new directory descriptor}

begin
  tnam.max := size_char(tnam.str);     {init local var string}

  string_treename (name, tnam);        {make directory absolute pathname in TNAM}

  ent_p := md.dir_p;                   {init to first list entry}
  while ent_p <> nil do begin          {scan the directories list}
    if string_equal (                  {this directory is already in the list ?}
        ent_p^.dir_p^.name_p^, tnam)
        then begin
      return;                          {return existing list entry}
      end;
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;
{
*   The directory is not already in the list.
}
  util_mem_grab (                      {allocate mem for new directory descriptor}
    sizeof(dir_p^), md.mem_p^, false, dir_p);
  string_alloc (                       {allocate mem for the new dir name string}
    tnam.len, md.mem_p^, false, dir_p^.name_p);
  string_copy (tnam, dir_p^.name_p^);  {fill in full directory pathname}

  util_mem_grab (                      {allocate memory for the new list entry}
    sizeof(ent_p^), md.mem_p^, false, ent_p);
  ent_p^.dir_p := dir_p;               {save pointer in list entry}
  if md.dir_read_p = nil
    then begin                         {add new entry to start of list}
      ent_p^.next_p := md.dir_p;
      md.dir_p := ent_p;
      end
    else begin                         {add new entry after current}
      ent_p^.next_p := md.dir_read_p^.next_p;
      md.dir_read_p^.next_p := ent_p;
      end
    ;
  end;
