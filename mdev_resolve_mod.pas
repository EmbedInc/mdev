{   Resolve dependencies of modules.
}
module mdev_resolve_mod;
define mdev_resolve_mod;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine ADD_DEPENDENCIES (MD, FLIST_P, ADDLIST_P)
*
*   Add the nested dependencies of all files in the list pointed to by FLIST_P
*   to the list pointed to by ADDLIST_P.
}
procedure add_dependencies (           {add file dependencies to list}
  in out  md: mdev_t;                  {MDEV library use state}
  in      flist_p: mdev_file_ent_p_t;  {files to add dependencies of}
  in out  addlist_p: mdev_file_ent_p_t); {files list to add dependencies to}
  val_param; internal;

var
  ent_p: mdev_file_ent_p_t;            {pointer to list entry}
  dep_p: mdev_file_ent_p_t;            {pointer to dependency entry of curr file}

begin
  ent_p := flist_p;                    {init to first entry of list to scan}
  while ent_p <> nil do begin          {back here each new file in the list}
    dep_p := ent_p^.file_p^.dep_p;     {init to first dependency of this file}
    while dep_p <> nil do begin        {back here each new dependency of this file}
      mdev_file_in_list (md, dep_p^.file_p^, addlist_p); {make sure dep is in list}
      dep_p := dep_p^.next_p;          {to next dependency of this file}
      end;                             {back to process the new dependency}
    ent_p := ent_p^.next_p;            {to next file in source list}
    end;                               {back to process this new source list file}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_RESOLVE_MOD (MD, MOD)
*
*   Resolve nested dependencies of the module MOD.
}
procedure mdev_resolve_mod (           {resolve dependencies of a module}
  in out  md: mdev_t;                  {MDEV library use state}
  in out  mod: mdev_mod_t);            {module to resolve dependencies of}
  val_param;

begin
  add_dependencies (md, mod.templ_p, mod.files_p);
  add_dependencies (md, mod.files_p, mod.files_p);
  add_dependencies (md, mod.incl_p, mod.files_p);
  end;
