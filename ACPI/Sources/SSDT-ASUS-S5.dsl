// ASUS V3607VU BIOS .305: retain OEM preparation, then stop sleep-SMI interception
// only for Darwin S5. Use the firmware's named fields; do not guess I/O addresses.
// Pair with the existing, exact root _PTS -> ZPTS rename.
DefinitionBlock ("", "SSDT", 2, "ASUS", "V36S5", 2)
{
    External (ZPTS, MethodObj)
    External (_SB.PC00.XHCI.PMEE, FieldUnitObj)
    External (_SB.PC00.LPCB.SLPE, FieldUnitObj)
    Method (_PTS, 1, NotSerialized)
    {
        If (_OSI ("Darwin"))
        {
            If (Arg0 == 5) { Store ("ASUS-S5: entering OEM preparation", Debug) }
        }
        ZPTS (Arg0)
        If (_OSI ("Darwin"))
        {
            If (Arg0 == 5)
            {
                Store ("ASUS-S5: OEM complete; clearing PMEE and SLPE", Debug)
                \_SB.PC00.XHCI.PMEE = Zero
                \_SB.PC00.LPCB.SLPE = Zero
                Store ("ASUS-S5: ready for power off", Debug)
            }
        }
    }
}
