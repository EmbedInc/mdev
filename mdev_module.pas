module mdev_module;
define mdev_mod_link;
define mdev_mod_get;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_MOD_LINK (MD, MOD, LIST_P)
*
*   Link the module MOD to the start of the modules list at LIST_P.  No checking
*   is done whether the module is already in the list.  A new list entry will be
*   created, and linked to the start of the list.  LIST_P will therefore be
*   returned pointing to the new list entry.
}
procedure mdev_mod_link (              {link module to start of list}
  in out  md: mdev_t;                  {MDEV library use state}
  in var  mod: mdev_mod_t;             {module to add list entry for}
  in out  list_p: mdev_mod_ent_p_t);   {pointer to list, will point to new entry}
  val_param;

var
  ent_p: mdev_mod_ent_p_t;             {pointer to the new list entry}

begin
  util_mem_grab (                      {allocate mem for new list entry}
    sizeof(ent_p^), md.mem_p^, false, ent_p);

  ent_p^.next_p := list_p;             {fill in list entry}
  ent_p^.mod_p := addr(mod);

  list_p := ent_p;                     {update list pointer to new entry}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_MOD_GET (MD, NAME, ENT_P)
*
*   Return ENT_P pointing to the global modules list entry for the module of
*   name NAME.  The interface and global list entry is created if it does not
*   already exist.
}
procedure mdev_mod_get (               {get a specific modules list entry}
  in out  md: mdev_t;                  {MDEV library use state}
  in      name: univ string_var_arg_t; {module name, case-sensitive}
  out     ent_p: mdev_mod_ent_p_t);    {pointer to global list entry for this module}
  val_param;

var
  obj_p: mdev_mod_p_t;                 {pointer to module descriptor}

begin
  ent_p := md.mod_p;                   {init to first list entry}
  while ent_p <> nil do begin          {scan the list}
    if string_equal (ent_p^.mod_p^.name_p^, name) {found existing entry ?}
      then return;
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;
{
*   This is a new module.
}
  util_mem_grab (                      {allocate mem for new descriptor}
    sizeof(obj_p^), md.mem_p^, false, obj_p);
  string_alloc (                       {allocate mem for name string}
    name.len, md.mem_p^, false, obj_p^.name_p);
  string_copy (name, obj_p^.name_p^);  {set name}
  obj_p^.cfgent_p := nil;              {init remaining descriptor fields}
  obj_p^.desc_p := nil;
  obj_p^.uses_p := nil;
  obj_p^.impl_p := nil;
  obj_p^.templ_p := nil;
  obj_p^.files_p := nil;
  obj_p^.incl_p := nil;
  obj_p^.build_p := nil;

  mdev_mod_link (md, obj_p^, md.mod_p); {link to start of global modules list}
  ent_p := md.mod_p;                   {return pointer to new list entry}
  end;
