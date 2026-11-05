PortableFileAssociator - Template lookup rules update

File Types GUI behavior:
- If "Show in New menu in context menu" is unchecked, "Use template file" is unchecked and disabled.
- When Show in New menu is enabled, Use template file becomes available.
- Custom template file selection has been removed. PFA automatically looks for a fixed filename in Data\newitems.

Template filename convention:
- For extension kdbx, create: Data\newitems\KDBX.kdbx
- For extension txt, create: Data\newitems\TXT.txt
- In general: Data\newitems\{UPPERCASE_EXTENSION}.{extension}

Behavior:
- Use template file unchecked: PFA uses the standard ShellNew NullFile behavior (empty file).
- Use template file checked: PFA registers the matching file from Data\newitems.
- If the matching template is missing, PFA displays a message asking the user to add the exact expected filename. It will not silently create an empty file for that extension's New menu entry.
- The New menu item is not registered for an extension with a missing required template; the remaining file association setup continues normally.
- The Data\newitems folder is created automatically if missing.

Legacy INI template paths are no longer used. The old "usetemplate" setting is retained; the old "template" path is cleared when the File Type is saved.

Compile PortableFileAssociator.au3 with AutoIt 3. This source has not been compiled or runtime-tested in this environment.
