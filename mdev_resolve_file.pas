{   Resolve dependencies of files.
}
module mdev_resolve_file;
define mdev_resolve_file;
%include 'mdev2.ins.pas';

type
  link_p_t = ^link_t;
  link_t = record                      {one link in dependencies hierarchy chain}
    file_p: mdev_file_p_t;             {pointer to file for this link}
    prev_p: link_p_t;                  {pointer to previous link}
    end;
{
********************************************************************************
*
*   Local subroutine ADD_DEPENDENCIES (MD, FILE, LIST_P)
*
*   Make sure that all dependencies of the file FILE are in the list pointed to
*   by LIST_P.
}
procedure add_dependencies (           {add file dependencies to list}
  in out  md: mdev_t;                  {MDEV library use state}
  in var  file: mdev_file_t;           {file to add dependencies of}
  in out  list_p: mdev_file_ent_p_t;   {list to add dependencies to}
  in var  prevlink: link_t);           {link to previous file in hierarchy}
  val_param; internal;

var
  link_p: link_p_t;                    {pointer to current link in hierarchy chain}
  newlink: link_t;                     {hierarchy chain link for this new level}
  ent_p: mdev_file_ent_p_t;            {pointer to subordinate file list entry}

label
  circular;

begin
{
*   Check for circular dependency.
}
  link_p := addr(prevlink);            {init to lowest level in hierarchy chain}
  while link_p <> nil do begin         {back here each link until top}
    if addr(file) = link_p^.file_p     {new file is already in the hierarchy ?}
      then goto circular;              {go handle the circular dependency}
    link_p := link_p^.prev_p;          {to next level up in the hierarchy}
    end;                               {back to check this new level}
{
*   This new file does not represent a circular dependency.
}
  newlink.file_p := addr(file);        {fill in new hierarchy chain link}
  newlink.prev_p := addr(prevlink);

  ent_p := file.dep_p;                 {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    mdev_file_in_list (md, ent_p^.file_p^, list_p); {make sure file is in list}
    add_dependencies (                 {recursively add dependencies to the list}
      md,                              {MDEV library use state}
      ent_p^.file_p^,                  {file to add dependencies of}
      list_p,                          {pointer to list to add the files to}
      newlink);                        {current hierachy chain link}
    ent_p := ent_p^.next_p             {to next list entry}
    end;                               {back to process this new list entry}
  return;
{
*   The new file is in a previous level of the hierarchy chain.  That means it
*   circularly depends on itself.
}
circular:                              {circular dependency detected}
  writeln;
  writeln ('***** ERROR: Circular file dependency.  Lowest to highest order:');
  writeln ('  ', file.name_p^.str:file.name_p^.len);
  link_p := addr(prevlink);
  while link_p <> nil do begin         {scan up the hierarchy chain}
    writeln ('  ', link_p^.file_p^.name_p^.str:link_p^.file_p^.name_p^.len);
    link_p := link_p^.prev_p;
    end;
  sys_bomb;                            {abort the program with error}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_RESOLVE_FILE (MD, FILE)
*
*   Resolve nested dependencies of the file FILE.
}
procedure mdev_resolve_file (          {resolve dependencies of a file}
  in out  md: mdev_t;                  {MDEV library use state}
  in out  file: mdev_file_t);          {file to resolve dependencies of}
  val_param;

var
  ent_p: mdev_file_ent_p_t;            {pointer to dependencies list entry}
  link: link_t;                        {chain link for top level in hierarchy}

begin
  link.file_p := addr(file);           {fill in top level link of hierarchy chain}
  link.prev_p := nil;

  ent_p := file.dep_p;                 {init to first list entry}
  while ent_p <> nil do begin          {back here each new list entry}
    add_dependencies (md, ent_p^.file_p^, file.dep_p, link); {add dependencies to list}
    ent_p := ent_p^.next_p;            {to next list entry}
    end;                               {back to process this new list entry}
  end;
