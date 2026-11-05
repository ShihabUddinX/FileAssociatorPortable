PortableFileAssociator - Template File support

New File Types option:
- Enable "Show in New menu in context menu" to register the extension in Explorer's New submenu.
- Enable "Use template file" and select a template file.
- The selected template is registered through the standard ShellNew FileName value.
- If Use template file is unchecked, PFA uses the previous NullFile behavior to create an empty file.
- Template paths inside the PFA folder are stored as relative paths for portability.
- Put reusable templates in Data\newitems and select them with Browse.

Windows Explorer controls the final suggested filename in the New submenu. The file is created with the selected file type extension; Explorer may prepend its standard "New" naming text based on the registered file type display name.

Compatibility:
- Existing settings remain valid. Missing usetemplate values default to unchecked.
- Existing ShellNew settings are backed up and restored by PFA's existing backup mechanism.

Compile PortableFileAssociator.au3 with AutoIt 3. The source has not been compiled or runtime-tested in this environment.
