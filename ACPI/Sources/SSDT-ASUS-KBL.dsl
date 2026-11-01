// ASUS V3607VU BIOS .305: adapt AsusSMC's 0..255 level to ASUS WMI's 0..3.
// Uses the firmware's own SLKB method; no guessed EC register writes.
DefinitionBlock ("", "SSDT", 2, "ASUS", "V36KBL", 1)
{
    External (_SB.ATKD, DeviceObj)
    External (_SB.ATKD.SLKB, MethodObj)
    Scope (\_SB.ATKD)
    {
        Method (SKBV, 1, Serialized)
        {
            If (_OSI ("Darwin"))
            {
                Local0 = Arg0
                If (Local0 > 255) { Local0 = 255 }
                If (Local0 == Zero) { SLKB (Zero) }
                Else
                {
                    Local0 = ((Local0 * 3 + 254) / 255)
                    SLKB (Local0 | 0x80)
                }
            }
            Return (Arg0)
        }
        Method (_INI, 0, NotSerialized)
        {
            If (_OSI ("Darwin")) { SLKB (0x82) }
        }
    }
    Scope (\_SB)
    {
        Device (ALS0)
        {
            Name (_HID, "ACPI0008")
            Name (_CID, "smc-als")
            Name (_ALI, 150)
            Name (_ALR, Package () { Package () { 100, 150 } })
            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin")) { Return (0x0B) }
                Return (Zero)
            }
        }
    }
}
