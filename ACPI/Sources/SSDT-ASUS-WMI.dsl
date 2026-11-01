// ASUS V3607VU BIOS .305: WMNB unconditionally creates five DWORD fields.
// AsusSMC 1.4.1 supplies two DWORDs (8 bytes); preserve them and zero-pad to 20.
// Pair ONLY with the scoped WMNB -> XWNB rename of the matching DSDT.
DefinitionBlock ("", "SSDT", 2, "ASUS", "V36WMI", 1)
{
    External (_SB.ATKD, DeviceObj)
    External (_SB.ATKD.XWNB, MethodObj)
    Scope (\_SB.ATKD)
    {
        Method (WMNB, 3, Serialized)
        {
            If (_OSI ("Darwin"))
            {
                If (ObjectType (Arg2) == 0x03)
                {
                    If (SizeOf (Arg2) < 0x14)
                    {
                        Concatenate (Arg2, Buffer (0x14) {}, Local0)
                        Mid (Local0, Zero, 0x14, Local0)
                        Return (XWNB (Arg0, Arg1, Local0))
                    }
                }
            }
            Return (XWNB (Arg0, Arg1, Arg2))
        }
    }
}
