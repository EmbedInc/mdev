/*   Error and status messages relating to the MDEV library.
/*
msg err1
  lan english -def
    Sharing of interface %p2s by module %p1s on line %p3i of file "%p4s"
    is inconsistent with a previous declaration.
msg err2
  lan english -def
    Interface "%p1s" is undefined.
msg err3
  lan english -def
    Interface "%p1s" is undefined, referenced by firmware "%p2s".
msg err4
  lan english -def
    Interface "%p1s" is undefined, referenced by module "%p2s".
msg err5
  lan english -def
    Invalid module ID %p1i encountered on line %p2i of file "%p3s".
msg err6
  lan english -def
    Attempt to assign duplicate ID to module within firmware on line %p2i
    of file "%p3s".  This module was previously assigned ID %p1i.
msg err7
  lan english -def
    ID %p1i was previously assigned to module "%p2s".  Error occurred on
    line %p3i of file "%p4s".
msg err8
  lan english -def
    File name "%p1s" does not end in ".ins.dspic".
msg err9
  lan english -def
    Unrecognized command "%p1s" on line %p2i of file "%p3s".
msg err10
  lan english -def
    Extra token "%p1s" found on line %p2i of file "%p3s".
msg err11
  lan english -def
    Module entry point name previously set.  Error encountered on line
    %p1i of file "%p2s".
msg err12
  lan english -def
    File "%p1s" has no suffix to identify its type.
msg err13
  lan english -def
    No generic file name left after suffix is removed from "%p1s".
msg err14
  lan english -def
    The file name suffix "%p1s" of file "%p2s" is not recognized.
msg err15
  lan english -def
    File "%p1s" is not a buildable type.
msg err16
  lan english -def
    Module deconfig entry point name previously set.  Error encountered on
    line %p1i of file "%p2s".
/*
/*   Error messages written directly by top level programs.
/*
msg nofwname
  lan english -def
    No firmware name supplied, and none could be inferred.
