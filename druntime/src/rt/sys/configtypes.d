module rt.sys.configtypes;


// This selects the type of system call for the POSIX osGetStackBottom function
enum PThreadGetStackBottomType
{
    None,
    PThread_Getattr_NP,
    PThread_Attr_Get_NP
}