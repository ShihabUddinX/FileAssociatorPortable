PortableFileAssociator 3.0.0.0 - Association File Types Filter Fix

Changes:
- The File Types association filter now excludes associations that contain only special shell targets.
- Special targets excluded from the File Types list: drive, drives, files, folders, recycle, exe, com, and blank entries.
- Associations that contain at least one normal extension remain visible, even if they also contain special targets.
- Both the All Associations list and individual association filters now use the same special-target filtering and case-insensitive duplicate handling.
- The selected association's file-type list is populated only from its actual valid extensions; empty groups are not shown.

Version: 3.0.0.0
Publisher: ShihabUddinX

Note: Source-level update only. AutoIt compilation and Windows runtime testing were not available in this environment.
