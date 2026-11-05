PortableFileAssociator v3.0.0.0 - EXE/COM Association Type Update

The Association editor now accepts `exe` and `com` in Associated Types without showing the previous warning or skipping the entry.

For safety, these entries add only a custom Explorer context-menu command to the existing Windows classes (`exefile` / `comfile`). They do not replace the default Open action or register EXE/COM as PFA-managed default file types.

When associations are removed, the matching custom context-menu entries are removed as well.

Compile PortableFileAssociator.au3 with AutoIt to create the executable. This source update has not been runtime-tested on Windows in this environment.
