{   File name suffix handling.
}
module mdev_suffix;
define mdev_suffix_find;
define mdev_suffix_id;
define mdev_suffix_lnam;
define mdev_suffix_fnam;
%include 'mdev2.ins.pas';
{
********************************************************************************
*
*   Subroutine MDEV_SUFFIX_FIND (LNAM, SUFF)
*
*   Find the suffix of the leafname LNAM, and return it in SUFF.  The suffix is
*   the part of the name after the first period.  Results are undefined when
*   LNAM is not a leafname.
}
procedure mdev_suffix_find (           {find suffix of file leafname}
  in      lnam: univ string_var_arg_t; {input name, must be leafname}
  in out  suff: univ string_var_arg_t); {returned suffix}
  val_param;

var
  p: sys_int_machine_t;                {parse index}

begin
  suff.len := 0;                       {init to no suffix}

  p := 1;                              {init parse index to start of leafname}
  while true do begin                  {scan the leafname}
    if p > lnam.len then return;       {got to end and found no period ?}
    if lnam.str[p] = '.' then exit;    {found start of suffix delimiter ?}
    p := p + 1;                        {advance to next character}
    end;                               {back to test this new character}

  string_substr (                      {extract suffix}
    lnam,                              {string to extract from}
    p + 1,                             {starting index to extract from}
    lnam.len,                          {ending index to extract from}
    suff);                             {returned suffix}
  end;
{
********************************************************************************
*
*   Function MDEV_SUFFIX_ID (SUFF)
*
*   Return the ID of the file name suffix SUFF.  SUFF must be the suffix without
*   the preceding period.
}
function mdev_suffix_id (              {determine id of file name suffix}
  in      suff: univ string_var_arg_t) {suffix, part after first period}
  :mdev_suffix_k_t;                    {returned suffix ID}
  val_param;

var
  usuf: string_leafname_t;             {upper case version of the suffix}
  pick: sys_int_machine_t;             {number of keyword picked from list}

begin
  usuf.max := size_char(usuf.str);     {init local var string}

  if suff.len <= 0 then begin          {no suffix ?}
    mdev_suffix_id := mdev_suffix_none_k;
    return;
    end;

  string_copy (suff, usuf);            {make local copy of the suffix}
  string_upcase (usuf);                {make upper case for case-independent matching}

  string_tkpick80 (usuf,               {pick the suffix from list}
    'INS.DSPIC DSPIC INS.ASPIC ASPIC INS.XC16 H XC16',
    pick);                             {1-N suffix picked from list}
  case pick of                         {which suffix is it ?}
1:  mdev_suffix_id := mdev_suffix_ins_dspic_k;
2:  mdev_suffix_id := mdev_suffix_dspic_k;
3:  mdev_suffix_id := mdev_suffix_ins_aspic_k;
4:  mdev_suffix_id := mdev_suffix_aspic_k;
5:  mdev_suffix_id := mdev_suffix_ins_xc16_k;
6:  mdev_suffix_id := mdev_suffix_h_k;
7:  mdev_suffix_id := mdev_suffix_xc16_k;
otherwise
    mdev_suffix_id := mdev_suffix_unknown_k;
    end;
  end;
{
********************************************************************************
*
*   Function MDEV_SUFFIX_LNAM (LNAM)
*
*   Returns the ID for the suffix of the leafname LNAM.  The result is indefined
*   unless LNAM is a leafname.
}
function mdev_suffix_lnam (            {get ID of leafname suffix}
  in      lnam: univ string_var_arg_t) {leafname to classify suffix of}
  :mdev_suffix_k_t;                    {suffix ID}
  val_param;

var
  suff: string_leafname_t;             {file name suffix (part after first .)}

begin
  suff.max := size_char(suff.str);     {init local var string}

  mdev_suffix_find (lnam, suff);       {extract the suffix into SUFF}
  mdev_suffix_lnam := mdev_suffix_id (suff); {return ID of the suffix}
  end;
{
********************************************************************************
*
*   Function MDEV_SUFFIX_FNAM (FNAM)
*
*   Returns the ID of the suffix of FNAM.  The suffix of a file is the part
*   after the first period of the leafname.
}
function mdev_suffix_fnam (            {return file name suffix ID}
  in      fnam: univ string_var_arg_t) {pathname to classify suffix of}
  :mdev_suffix_k_t;                    {ID of suffix found}
  val_param;

var
  dnam: string_treename_t;             {directory part of input name}
  lnam: string_leafname_t;             {leafname part of input name}

begin
  dnam.max := size_char(dnam.str);     {init local var string}
  lnam.max := size_char(lnam.str);

  string_pathname_split (              {get directory and leafname of input name}
    fnam,                              {input pathname}
    dnam,                              {returned directory part}
    lnam);                             {returned leaf file name}

  mdev_suffix_fnam := mdev_suffix_lnam (lnam);
  end;
