{   Resolve dependencies of a firmware.
}
module mdev_resolve_fw;
define mdev_resolve_fw;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Local function MODULE_IN_FW (MOD, FW)
*
*   Determines whether the module MOD is included in the firmware FW.  TRUE for
*   included, FALSE for not.
}
function module_in_fw (                {determine whether a module is in a FW}
  in var  mod: mdev_mod_t;             {the module}
  in      fw: mdev_fw_t)               {the firmware}
  :boolean;                            {the module is in the firmware}
  val_param; internal;

var
  ent_p: mdev_mod_ent_p_t;             {points to modules list entry this FW}

begin
  module_in_fw := true;                {init to the module is in this firmware}

  ent_p := fw.mod_p;                   {init to first module in FW list}
  while ent_p <> nil do begin          {back here each new module list entry}
    if ent_p^.mod_p = addr(mod) then return; {found module in FW list ?}
    ent_p := ent_p^.next_p             {to next list entry}
    end;                               {back to check this new list entry}

  module_in_fw := false;               {whole list checked, module not found}
  end;
{
********************************************************************************
*
*   Function MODULE_SUPPORTED (MOD, FW, MODSTART_P)
*
*   Check whether the module MOD can be supported by the firmware FW.
*   MODSTART_P is the pointer to the modules list entry for this firmware where
*   to start checking provided interfaces at.  The function returns TRUE iff the
*   firmware and its modules starting at MODSTART_P provide all the interfaces
*   required by the module MOD.
}
function module_supported (            {check whether module supported by firmware}
  in      mod: mdev_mod_t;             {the module to check for support for}
  in      fw: mdev_fw_t;               {firmare that might support the module}
  in      modstart_p: mdev_mod_ent_p_t) {first FW module to check providing ifaces}
  :boolean;                            {the module is supported}
  val_param; internal;

type
  req_t =                              {array of pointers to required interfaces}
    array[1..1] of mdev_iface_p_t;

var
  ifcent_p: mdev_iface_ent_p_t;        {points to current interfaces list entry}
  nreq: sys_int_machine_t;             {number of remaining unsatisfied required ifaces}
  req_p: ^req_t;                       {list of required interfaces}
  ii: sys_int_machine_t;               {scratch integer and loop counter}
  modent_p: mdev_mod_ent_p_t;          {pointer to FW modules list entry}

label
  leave;
{
****************************************
*
*   Private subroutine CHECK_IFACE (IFACE)
*
*   Check the interface IFACE for being a required interface for the module.  If
*   so, that interface is removed from the required list, and NREQ is updated to
*   the number of remaining required but unprovided interfaces.
}
procedure check_iface (                {check for this is a required interface}
  in var  iface: mdev_iface_t);        {the interface being provided}
  val_param; internal;

var
  ii: sys_int_machine_t;               {1-N required interface list entry}

begin
  for ii := 1 to nreq do begin         {scan the list of required interfaces}
    if addr(iface) = req_p^[ii] then begin {found matching req interface list entry ?}
      if ii <> nreq then begin         {this is not last list entry ?}
        req_p^[ii] := req_p^[nreq];    {move last list entry into open slot}
        end;
      nreq := nreq - 1;                {count one less required interface left}
      return;                          {found match, no point looking further}
      end;
    end;                               {back to check next required iface list entry}
  end;
{
****************************************
*
*   Start of MODULE_SUPPORTED.
}
begin
  module_supported := true;            {init to all required interfaces provided}
{
*   Create a local list of the interfaces required by the module.  REQ_P will
*   point to a array of interfaces, and NREQ will be the number of required
*   interfaces.  NREQ is guaranteed to be at least 1, else this section returns
*   directly indicating that the module is supported (since there are no
*   interfaces it requires).
}
  nreq := 0;                           {init number of required interfaces}
  ifcent_p := mod.uses_p;              {init to first required interface in list}
  while ifcent_p <> nil do begin       {scan the list}
    nreq := nreq + 1;                  {count one more required interface}
    ifcent_p := ifcent_p^.next_p;      {to next list entry}
    end;                               {back to check this new list entry}
  if nreq = 0 then return;             {no requirements, module is supported ?}

  sys_mem_alloc (                      {allocate mem for remaining req ifaces list}
    nreq * sizeof(req_p^[1]),          {amount of memory to allocate}
    req_p);                            {returned pointer to the new memory}
  ifcent_p := mod.uses_p;              {init to first required interface in list}
  ii := 1;                             {init index of next entry to fill in}
  while ifcent_p <> nil do begin       {scan the list}
    req_p^[ii] := ifcent_p^.iface_p;   {save pointer to this required interface}
    ii := ii + 1;                      {update index to store next interface at}
    ifcent_p := ifcent_p^.next_p;      {to next list entry}
    end;                               {back to check this new list entry}
{
*   Scan the list of interfaces provided directly by the firmware.
}
  ifcent_p := fw.impl_p;               {init to first list entry}
  while ifcent_p <> nil do begin       {back here each new list entry}
    check_iface (ifcent_p^.iface_p^);  {check iface, cross off required list}
    if nreq <= 0 then goto leave;      {all required interfaces provided ?}
    ifcent_p := ifcent_p^.next_p;      {to next list entry}
    end;                               {back to check this new list entry}
{
*   Run thru each of the modules in the firmware and check the interfaces they
*   provide for matching required interfaces.
}
  modent_p := modstart_p;              {init to first module list entry to look at}
  while modent_p <> nil do begin       {back here each new module in FW list}
    ifcent_p := modent_p^.mod_p^.impl_p; {init to first implemented interfaces list entry}
    while ifcent_p <> nil do begin     {scan the interfaces implemented by this module}
      check_iface (ifcent_p^.iface_p^); {check this interface for satisfying a requirement}
      if nreq <= 0 then goto leave;    {all required interfaces provide ?}
      ifcent_p := ifcent_p^.next_p;    {to next provided interface in the list}
      end;                             {back to check next provided interface}
    modent_p := modent_p^.next_p;      {to next module in this firmware}
    end;                               {back to check interfaces provided by this module}

  module_supported := false;           {not all required interfaces were provided}

leave:                                 {req list allocated, function value set}
  sys_mem_dealloc (req_p);             {deallocate local required interfaces list}
  end;
{
********************************************************************************
*
*   Local subroutine ASSIGN_ID (FW, MOD)
*
*   Assign the module ID for the module MOD within the firmware FW.
}
procedure assign_id (                  {assign ID to module within firmware}
  in out  fw: mdev_fw_t;               {the firmware to assign ID within}
  in var  mod: mdev_mod_t);            {the module to assign the ID to}
  val_param; internal;

var
  id: sys_int_machine_t;               {1-255 module ID}
  open: sys_int_machine_t;             {first open ID}

begin
{
*   Check for this module already has a ID assigned.  While at it, save the
*   first unused ID in case we need to assign a new one.
}
  open := 0;                           {init to no open ID found}
  for id := 1 to 255 do begin          {scan the possible module IDs}
    if fw.modids[id] = addr(mod) then return; {this module already has ID ?}
    if                                 {found first open ID ?}
        (open = 0) and                 {not previously found ?}
        (fw.modids[id] = nil)          {this ID is open ?}
        then begin
      open := id;                      {save first open ID}
      end;
    end;                               {back to check next ID}
{
*   The module does not already have a ID assigned.  OPEN is the first open ID.
}
  fw.modids[open] := addr(mod);        {assign first open ID to the module}
  end;
{
********************************************************************************
*
*   Local subroutine MDEV_RESOLVE_FW (MD, FW)
*
*   Resolve the set of modules for the firmware FW.
}
procedure mdev_resolve_fw (            {resolve modules for specific firmware}
  in out  md: mdev_t;                  {MDEV library use state}
  in out  fw: mdev_fw_t);              {the firmware to resolve modules for}
  val_param;

var
  modstart_p: mdev_mod_ent_p_t;        {first mod to check for providing ifaces}
  modent_p: mdev_mod_ent_p_t;          {points to current global modules list entry}
  mod_p: mdev_mod_p_t;                 {points to current module being checked}
  newmod: boolean;                     {a new module was added to the firmware}
  newent_p: mdev_mod_ent_p_t;          {points to newly added FW modules list entry}

label
  next_mod, rescan;

begin
{
*   Resolve the nested module/interface dependencies and make a flat list of the
*   modules this firmware can support.
}
rescan:                                {back here to check again after module(s) added}
  newmod := false;                     {init to no new module added this pass}
  modstart_p := fw.mod_p;              {init where to start looking for interfaces}

  modent_p := md.mod_p;                {init to first global modules list entry}
  while modent_p <> nil do begin       {back here each new module to test}
    mod_p := modent_p^.mod_p;          {get pointer to the module to check}
    if module_in_fw (mod_p^, fw)       {this module is already in the firmware ?}
      then goto next_mod;
    if not module_supported (mod_p^, fw, modstart_p) {this module not supported ?}
      then goto next_mod;
    {
    *   Add the module MOD_P^ to the firmware.
    }
    util_mem_grab (                    {allocate memory for the new modules list entry}
      sizeof(newent_p^), md.mem_p^, false, newent_p);
    newent_p^.mod_p := mod_p;          {fill in the list entry}
    newent_p^.next_p := fw.mod_p;      {link to start of modules list for this FW}
    fw.mod_p := newent_p;

    assign_id (fw, mod_p^);            {assign ID to this module within this FW}
    newmod := true;                    {indicate a module was added}

next_mod:                              {done with this module, on to next}
    modent_p := modent_p^.next_p       {to next global modules list entry}
    end;                               {back to check this new module}

  if newmod then goto rescan;          {new module added, support could have changed ?}
{
*   Resolve the nested file dependencies and make flat dependencies lists.
}
  modent_p := fw.mod_p;                {init to first module in list}
  while modent_p <> nil do begin       {back here each new module}
    mod_p := modent_p^.mod_p;          {get pointer to this module descriptor}
    mdev_file_add_list (md, mod_p^.templ_p, fw.templ_p); {add mod's files to FW}
    mdev_file_add_list (md, mod_p^.files_p, fw.files_p);
    mdev_file_add_list (md, mod_p^.incl_p, fw.incl_p);
    modent_p := modent_p^.next_p;      {to next module in this firmware}
    end;                               {back to process this new module}
  end;
