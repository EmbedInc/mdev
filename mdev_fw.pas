module mdev_fw;
define mdev_fw_get;
define mdev_fw_find;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local subroutine FW_SEARCH (MD, CONT, FWNAME, ENT_P)
*
*   Return ENT_P pointing to the global firmwares list entry for the firmware
*   indentified by CONT and FWNAME.  CONT is the context hierarch, and FWNAME is
*   the bare firmware name within the context.
*
*   ENT_P is returned NIL if no matching firmware is found in the list.
}
procedure fw_search (                  {get a specific firmware list entry}
  in      md: mdev_t;                  {MDEV library use state}
  in      cont: univ string_var_arg_t; {firmware name context hierarchy}
  in      fwname: univ string_var_arg_t; {bare firmare name}
  out     ent_p: mdev_fw_ent_p_t);     {pointer to global list entry for this fw}
  val_param; internal;

var
  obj_p: mdev_fw_p_t;                  {pointer to firmware descriptor}

label
  next_ent;

begin
  ent_p := md.fw_p;                    {init to first firmware in list}
  while ent_p <> nil do begin          {scan the list}
    obj_p := ent_p^.fw_p;              {get pointer to the firmware object}
    if not string_equal(obj_p^.context_p^, cont) {context doesn't match ?}
      then goto next_ent;
    if not string_equal(obj_p^.name_p^, fwname) {firmware name doesn't match ?}
      then goto next_ent;
    return;                            {found matching existing list entry}
next_ent:                              {done with this list entry, on to next}
    ent_p := ent_p^.next_p;            {advance to next list entry}
    end;                               {back to check this new list entry}
  end;
{
********************************************************************************
*
*   Local subroutine FW_ADD (MD, CONT, FWNAME, ENT_P)
*
*   Add the firmware with context CONT and bare name FWNAME to the global
*   firmwares list.  ENT_P is returned pointing to the new list entry.
}
procedure fw_add (                     {add firmware to global list}
  in out  md: mdev_t;                  {MDEV library use state}
  in      cont: univ string_var_arg_t; {firmware name context hierarchy}
  in      fwname: univ string_var_arg_t; {bare firmare name}
  out     ent_p: mdev_fw_ent_p_t);     {returned pointer to new list entry}
  val_param; internal;

var
  obj_p: mdev_fw_p_t;                  {pointer to new firmware descriptor}
  ii: sys_int_machine_t;               {scratch integer and loop counter}

begin
  util_mem_grab (                      {allocate mem for new descriptor}
    sizeof(obj_p^), md.mem_p^, false, obj_p);
  string_alloc (                       {allocate mem for context string}
    cont.len, md.mem_p^, false, obj_p^.context_p);
  string_copy (cont, obj_p^.context_p^); {set context string}
  string_alloc (                       {allocate mem for name string}
    fwname.len, md.mem_p^, false, obj_p^.name_p);
  string_copy (fwname, obj_p^.name_p^); {set firmware name}
  obj_p^.impl_p := nil;                {init to no interfaces implemented}
  obj_p^.templ_p := nil;               {init to no file dependencies}
  obj_p^.tmbld_p := nil;
  obj_p^.files_p := nil;
  obj_p^.incl_p := nil;
  obj_p^.mod_p := nil;                 {init to no modules supported}
  for ii := mdev_modid_min_k to mdev_modid_max_k do begin {init to no module IDs assigned}
    obj_p^.modids[ii].mod_p := nil;
    obj_p^.modids[ii].used := false;
    end;

  util_mem_grab (                      {allocate mem for new list entry}
    sizeof(ent_p^), md.mem_p^, false, ent_p);
  ent_p^.next_p := md.fw_p;            {fill in list entry}
  ent_p^.fw_p := obj_p;
  md.fw_p := ent_p;                    {link to start of list}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_FW_GET (MD, NAME, ENT_P)
*
*   Return ENT_P pointing to the global firmwares list entry for the firmware
*   indentified by NAME.  NAME is the firmware name within a hierarchy, in most
*   global to most local order.  The names of the hierarchy levels are
*   separated from each other by one space.  The hierarcy names are
*   case-sensitive.  The last token in the list is the actual firmware name.
*
*   The global firmwares list entry for this firmware is created if it does not
*   already exist.
}
procedure mdev_fw_get (                {get a specific firmware list entry}
  in out  md: mdev_t;                  {MDEV library use state}
  in      name: univ string_var_arg_t; {namespace hierarchy and firmware name}
  out     ent_p: mdev_fw_ent_p_t);     {pointer to global list entry for this fw}
  val_param;

var
  cont: string_var132_t;               {context part of firmware name}
  fwname: string_var32_t;              {bare firmware name without context}

begin
  cont.max := size_char(cont.str);     {init local var strings}
  fwname.max := size_char(fwname.str);

  mdev_fw_name_split (name, cont, fwname); {get context and bare firmware name}

  fw_search (md, cont, fwname, ent_p); {look for the firmware in existing list}
  if ent_p <> nil then return;         {found the firmare list entry ?}

  fw_add (md, cont, fwname, ent_p);    {create new list entry, get pointer to it}
  end;
{
********************************************************************************
*
*   Subroutine MDEV_FW_FIND (MD, NAME, MAKE, FW_P)
*
*   Find the firmware of name NAME within the MDEV data of the library use state
*   MD.  FW_P is returned pointing to the resulting firmware descriptor.
*
*   MAKE of TRUE causes a empty firmware descriptor to be created if not found.
*   When MAKE is FALSE and no firmare of the indicated name is found, then FW_P
*   is returned NIL.
}
procedure mdev_fw_find (               {find firmware by name}
  in out  md: mdev_t;                  {MDEV library use state}
  in      name: univ string_var_arg_t; {name of the firmware to find}
  in      make: boolean;               {make FW descriptor if not exist}
  out     fw_p: mdev_fw_p_t);          {returned pointer to FW desc, NIL if none and not make}
  val_param;

var
  ent_p: mdev_fw_ent_p_t;              {pointer to firmwares list entry}

var
  cont: string_var132_t;               {context part of firmware name}
  fwname: string_var32_t;              {bare firmware name without context}

begin
  cont.max := size_char(cont.str);     {init local var strings}
  fwname.max := size_char(fwname.str);

  mdev_fw_name_split (name, cont, fwname); {get context and bare firmware name}

  fw_search (md, cont, fwname, ent_p); {look for the firmware in existing list}
  if ent_p <> nil then begin           {found existing list entry ?}
    fw_p := ent_p^.fw_p;               {return pointer to the firmware descriptor}
    return;
    end;

  if not make then begin               {don't create blank entry ?}
    fw_p := nil;                       {indicate returning without firmware desc}
    return;
    end;

  fw_add (md, cont, fwname, ent_p);    {create new list entry, get pointer to it}
  fw_p := ent_p^.fw_p;                 {return pointer to the firmware descriptor}
  end;
