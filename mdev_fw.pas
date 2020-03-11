module mdev_fw;
define mdev_fw_get;
%include 'mdev2.ins.pas';
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
  p: string_index_t;                   {input name parse index}
  obj_p: mdev_fw_p_t;                  {pointer to firmware descriptor}
  ii: sys_int_machine_t;               {scratch integer and loop counter}

label
  next_ent;

begin
  cont.max := size_char(cont.str);     {init local var strings}
  fwname.max := size_char(fwname.str);

  p := name.len;                       {init to last character in name string}
  while (p >= 1) and then (name.str[p] <> ' ') do begin {back to find last blank}
    p := p - 1;
    end;
  string_substr (name, p+1, name.len, fwname); {extract just the leaf name}
  string_substr (name, 1, p-1, cont);  {extract context part of full name}

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
{
*   This firmware is not currently in the list.
}
  util_mem_grab (                      {allocate mem for new descriptor}
    sizeof(obj_p^), md.mem_p^, false, obj_p);
  string_alloc (                       {allocate mem for context string}
    cont.len, md.mem_p^, false, obj_p^.context_p);
  string_copy (cont, obj_p^.context_p^); {set context string}
  string_alloc (                       {allocate mem for name string}
    name.len, md.mem_p^, false, obj_p^.name_p);
  string_copy (fwname, obj_p^.name_p^); {set firmware name}
  obj_p^.mod_p := nil;                 {init to no interfaces implemented}
  for ii := mdev_modid_min_k to mdev_modid_max_k do begin {init to no module IDs assigned}
    obj_p^.modids[ii] := nil;
    end;

  util_mem_grab (                      {allocate mem for new list entry}
    sizeof(ent_p^), md.mem_p^, false, ent_p);
  ent_p^.next_p := md.fw_p;            {fill in list entry}
  ent_p^.fw_p := obj_p;
  md.fw_p := ent_p;                    {link to start of list}
  end;
