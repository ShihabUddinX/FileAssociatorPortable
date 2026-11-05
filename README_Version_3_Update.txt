PortableFileAssociator 3.0.0.0 - metadata and tray cleanup

Changes:
- File version updated from 2.2.1.8 to 3.0.0.0.
- Publisher / CompanyName resource metadata set to ShihabUddinX.
- ProductName resource metadata set to PortableFileAssociator.
- Main window title changed from PFA to PortableFileAssociator.
- The secondary-instance command handler now finds the main window using the new title.
- Removed the tray menu items "Check for updates..." and "Check on startup".
- Removed automatic update checking on startup and its obsolete state setting/toggle handler.
- Kept the internal version comparison routine because it is also used for profile/state migration.

Build:
Compile PortableFileAssociator.au3 with AutoIt 3. The executable version and publisher fields are set through AutoIt3Wrapper resource directives.

Testing note:
This source was statically checked for the requested edits, but it has not been compiled or runtime-tested in this environment.
