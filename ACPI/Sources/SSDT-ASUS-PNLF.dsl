// Publish AppleBacklight's device for WhateverXe. No legacy PWM MMIO writes.
DefinitionBlock ("", "SSDT", 2, "ASUS", "V36PNLF", 1)
{
    External (_SB.PC00.GFX0, DeviceObj)
    Scope (\_SB.PC00.GFX0)
    {
        Device (PNLF)
        {
            Name (_HID, EisaId ("APP0002"))
            Name (_CID, "backlight")
            Name (_UID, 19)
            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin")) { Return (0x0B) }
                Return (Zero)
            }
        }
    }
}
