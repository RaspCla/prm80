Version 5.1
===========
Error corrections (Claude!: made with Claude, marked "Claude!:" in the source code)
* Reverse mode: RX frequency and shift are now taken from the channel in the RAM with its own shift (before: frequency of the factory channel list in the EPROM, shift of the channel tuned before). Reverse only works with shift enabled.
* Reverse while scanning uses the scanned channel (before: the channel the scan started on)
* "M" command: checksums are updated, a changed default shift and scan duration are used at once (before: the RAM was thrown away at the next start because of the wrong checksum)
* "S" command: default shift and scan duration of the EEPROM are used at once
* "E" command: while scanning the channel being received is reported
* Scan: no endless loop any more if all channels are locked out (the scan stops), channel number after "Q" while scanning corrected
* TX while scanning: the scanned channel is kept as current channel (display and "E" showed the start channel before)
* "N" and "Q" commands stop the scan; "Q" tunes to channel 0
* "D" command: the power setting is kept after a restart, a frequency set with "R" is no longer reset to the channel frequency

Version 5.0
===========
* Channel specific shift added
* Modified 'C' command to print also shift/split
* Modified 'P' command to enter also shift/split
* Added RSSI to "E" command
* usage of 3 additional display digits to display split frequency (PRM8070 only)
* added support for HAMLIB (V4.5 or higher)

Version 4.0
===========
* Shift commutation feature disabled on [PRM8060](doc/PRM8060.md).
* Channels scanning added. Lock out available on [PRM8070](doc/PRM8070.md) or via [PC programming](doc/Computer_commands_V4.md).
* RSSI indicator.
* [PRM8070](doc/PRM8070.md) support.
* [UHF](doc/Prm80x0_430.bin.md) version for 70cm operations

Version 3.0
===========
* [Computer control](doc/Computer_control.md) for channel programming, debugging... [List of computer commands](doc/Computer_commands_V3.md)
* [1750Hz](doc/1750Hz_tone.md) from the front face.

Version 2.1
===========
* Power switching, shift activation, reverse mode and reset feature bugs fixed.

Version 2.0
===========
* Backup system state when turning off the transceiver.
* Up to 66 fixed channels.
* [1750Hz](doc/1750Hz_tone.md)

Version 1.0
===========
* Initial version with basic system feature
* Up to 50 fixed channels.
