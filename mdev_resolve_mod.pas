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
    if ent_p^.file_p^.name_p^.len > 0 then begin {not empty file name ?}
      dep_p := ent_p^.file_p^.dep_p;   {init to first dependency of this file}
      while dep_p <> nil do begin      {back here each new dependency of this file}
        mdev_file_in_list (md, dep_p^.file_p^, addlist_p); {make sure dep is in list}
        dep_p := dep_p^.next_p;        {to next dependency of this file}
        end;                           {back to process the new dependency}
      end;
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

var
  tk: string_treename_t;

begin
  tk.max := size_char(tk.str);         {init local var string}
{
*   Set the configuration entry point name to its default unless it has been
*   explicitly set.
}
  if mod.cfgent_p = nil then begin     {configuration entry point not set ?}
    string_copy (mod.name_p^, tk);     {init entry point name with module name}
    string_appends (tk, '_cfg'(0));    {make the full default entry point name}
    string_alloc (                     {alloc mem for entry point name string}
      tk.len,                          {string length}
      md.mem_p^,                       {memory context}
      false,                           {won't individually deallocate this}
      mod.cfgent_p);                   {returned pointer to the new string}
    string_copy (tk, mod.cfgent_p^);   {fill in the new string}
    end;
{
*   Update the list of files this module depends on.  This is all the files
*   directly referenced by the module, and all their dependencies.
}
  add_dependencies (md, mod.templ_p, mod.files_p);
  add_dependencies (md, mod.incl_p, mod.files_p);
  add_dependencies (md, mod.build_p, mod.files_p);
  add_dependencies (md, mod.files_p, mod.files_p);
  end;
