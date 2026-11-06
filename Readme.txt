==========
README.TXT
==========

PortableFileAssociator
Take your file associations with you.  Open local files with your portable applications.


Main Window:
============
Add File Associations    = Writes all enabled associations of the active profile to the registry (HKCU only).

Remove File Associations = Removes them again and restores what was backed up.

Configuration:
   Associations = Opens the association editor (context-menu entries).
   File Types   = Opens the file type editor (icons, defaults, "New" menu).
   SendTo       = Opens the SendTo editor.

System Restore:
   Create System Restore Point = Creates a Windows restore point (see "System Restore" below).

Profile  = Profile selection and the profile buttons (see "Profile" below).

Theme    = System / Light / Dark (see "Theme" below).


Associations:
=============
Association Name = The name of the association as recorded in the GUI list and INI file.
                   It cannot include the characters ',' or '*'.

Associated Types = drives     -> add to all drives (HKCU\Software\Classes\Drive\shell)
                   file       -> add to all files (HKCU\Software\Classes\*\shell)
                   folder     -> add to all folders (HKCU\Software\Classes\Directory\shell)
                   background -> add to the empty space of a folder window and of the Desktop,
                                 like "Open Terminal here"
                                 (HKCU\Software\Classes\Directory\Background\shell)
                   recycle    -> add to the Recycle Bin
                   exe / com  -> add an entry to program files (their normal open action is not changed)
                   <file extension> -> add to a specific file extension, ie 'txt' (do not include period [.])

                   NOTE:  Separate more than one type with the | (pipe) character, ie file|folder or txt|log|ini

                   NOTE:  Older INI files that use 'files' or 'folders' still work; they are treated as
                          'file' and 'folder'.

Single file type = Show the association only when ONE item is selected.  When several items are selected
                   the entry is hidden in the context menu.  Works for the types file, folder and file
                   extensions (ie iso).  Unchecked = the entry is shown for single and multiple selection.
                   (Not used by drives, background and recycle.  The setting applies to every extension in
                   the Associated Types box; use two associations if you need different behaviour.)

Title = File Association Name as it will appear in the file's context menu (make sure it is UNIQUE so
        it does not conflict with local entries).

Context-menu icon = Optional icon shown next to the entry (.ico, .exe or .dll).  Relative paths are portable.
Icon index        = Icon number inside a multi-icon file.  Usually 0 for .ico files.

Disabled = Check this box to disable the current association.

Command = Command line to execute.  The application path must be surrounded by " (double quotes) if it
          contains spaces and cannot use environment variables.  Use these tokens (placeholders) for the
          clicked-on item(s):

          %1   = path of the clicked-on file, folder or drive.  Explorer starts one run per selected item.
                 Example -  "X:\PortableApps\App Path\app.exe" "%1"

          %%1  = ALL selected items in ONE run, each one in quotes.
                 Example -  "X:\FastCopy\FastCopy.exe" %%1
                 With three files selected this runs:  FastCopy.exe "file1" "file2" "file3"
                 Notes:  Explorer starts one process per selected item, so PFA registers a small
                 wrapper (PortableFileAssociator.exe multi_open ...).  The wrapper processes collect their
                 files and the first one starts your command (it waits about 0.7 seconds for the other
                 files).  Files are passed in name order, like Explorer's default sort.  Very long
                 selections are split into several runs (about 30000 characters per command line).

          %V   = the current folder.  Meant for the type 'background' (and also works for folders).
                 Example -  "wt.exe" -d "%V"      or      cmd.exe /k cd /d "%V"
                 Notes:  The command is started inside that folder.  A drive root such as C:\ is passed
                 safely (as "C:\\"), so terminals do not fail on the trailing backslash.  For the type
                 'background' %V, %1 and %%1 all mean "this folder".

          NOTE:  PFA must stay at the same place while associations are active, because %%1 and
                 background entries start PortableFileAssociator.exe.

"..." (next to Command) = Browse for the program.  Inserts "%V" when the type is only 'background',
                          otherwise "%1".

Clear = Clear all fields.

Save = Save any association changes.  Must be done after each change.  Asks before overwriting an
       existing association.

Delete = Delete selected association.  The last association cannot be deleted.

Done = Closes the association dialog.

? = Opens this Readme.

Associations are stored in Data\settings\<profile>_assoc.ini, one section per association:

    [My Association]
    mode=iso|img
    title=Open with MyApp
    command='"..\MyApp\MyApp.exe" "%1"'
    icon=...
    disabled=4
    single=1

('single=1' is only present when "Single file type" is checked.)


File Types:
===========
Association = Filter the list of file types by association name.  Choose All to show every extension.

File Type = Selected file type.

Default PFA Association = Default PFA association for the selected extension (dbl-click action).

Hide Extension = Prevent the selected extension from being displayed in Explorer.

Copy Host Associations = Copy the file type associations already present on the host computer for the
                         selected extension.

Host Precedence = If host default association exists, it will take precedence over the PFA default.

Iconfile = The file to extract the icon from.  This can be an .exe, .dll, or .ico file.  Used when a
           Host computer association is not the default action.

Index = The index of the embedded icon in a multi-icon resource.  Locate the desired icon with the arrow
        buttons or type the index in the input box.  .ico files do not use an index, leave it set to 0.

        NOTE:  The index in the dialog will not exactly match the index used by Windows, however the
               correct Windows index will be saved and written to the registry.

Show in New menu in context menu = Adds the file type to Explorer's right-click > New submenu.

New menu name = Name shown under right-click > New.  Default: PFA_<extension> File.

Use template file = New items are created from a template instead of an empty file.  PFA looks for the
                    exact filename  Data\newitems\<EXTENSION IN CAPITALS>.<extension>  (ie Data\newitems\TXT.txt).
                    A message appears if the file is missing.  The host's own "New" entry for the extension
                    is backed up and restored when the associations are removed.

Save File Type = Save any file type changes.  Must be done after each change.

Done = Closes the file type edit dialog, and prompts to apply changes if any have been made while the
       associations are active.


For new file extensions, the icon will initially be set to the first association defined in the INI file
which is associated with the extension.

When selecting a host default, PFA first looks to see if one is explicitly defined.  If so this association
is used.  If not, PFA searches for a registry verb named 'open' and uses this association.

PFA's behavior when applying the default association and icon depends on several factors:

1)  A PFA default association is selected:
a)  Host Precedence is selected:  If a host default association exists it will be set as the default and the
host DefaultIcon will be used.  If a DefaultIcon does not exist, the PFA icon will be used.  If a host default
is not found, the PFA default association and DefaultIcon will be used.  If no default is found and no PFA
default is set, then the OS will decide what association to use and the PFA icon will be used.
b)  Host Precedence is not selected:  The default action for this extension will be set to the selected
PFA association.  The DefaultIcon will be set to the user-defined icon from this dialog.

2)  No PFA default association is selected:
a)  Copy Host Associations is selected:  If a host default association exists it will be set as the default
and the host DefaultIcon will be used.  If a DefaultIcon does not exist, the PFA icon will be used.
If no host default action is found, then the OS will decide what action to use as the default.  The PFA
defined icon will be used.
b)  Copy Host Associations is not selected:  No default action is defined and the OS will decide.  The PFA
defined icon will be used.


SendTo:
=======
Shortcuts defined here will show up in the system's 'Send to ->' context menu.

ListView = Lists the currently defined shortcut names and targets.  Drag-and-drop files / folders onto this
           control to add new shortcuts (you are asked for a shortcut name and optional parameters).

Add... = Add a shortcut by browsing to it.

Remove = Remove a shortcut from the listview.

Clear = Clear all shortcuts from the listview.

Save = Save the current settings.

Done = Close the dialog (asks to save unsaved changes).


Profile:
========
Profile settings are stored per profile (Data\settings\<profile>_assoc.ini, _state.ini, _types.ini,
_sendto.ini).

Dropdown = Displays the active profile.  Switch profiles by choosing a new one.

New    = Create a new profile.

Clone  = Create a copy of an existing profile.

Rename = Rename the active profile.

Remove = Remove the active profile.  This action cannot be undone.

The profile buttons are icons (New, Clone, Rename, Remove).  They are shown greyed out and cannot be used
while the associations are active.


Theme:
======
The dropdown at the bottom right of the main window sets the look of all PFA windows.

System = Follow the Windows app theme (light or dark).
Light  = Always light.
Dark   = Always dark.  Window and title bar, text, inputs, lists, buttons, the tray menu and the
         profile icons (white instead of black) use dark colors.

The choice is saved in Data\settings\profile.ini ([profile] theme=system|light|dark).

NOTE:  Windows' own message and file dialogs are not themed.  Dark buttons, combo boxes and scroll bars
       need Windows 10 (1903) or newer; on older systems they stay light.


Tray Menu:
==========
Left-click the tray icon to show the main window.  Right-click it to access these options.

Rebuild icon cache on change = If activated, the icon cache is rebuilt after associations are added or removed,
                               or after icon changes are applied.

                               Disabled by default, enable this option if you have problems with incorrect
                               icons being displayed for filetypes.
                               (NT/2000/XP only)

Refresh icons now = Sends the SHChangeNotify() system message.  If the above option is active, then it will
                    also rebuild the icon cache.

                    NOTE:  On Windows Vista+ this will only send the SHChangeNotify() message.

Remove associations on close = If activated, when the GUI is closed the file associations will be removed.

Exit = Close PFA.


System Restore:
===============
While nothing destructive should happen as a result of using this app, it's always a good idea to have a backup.
Press the Create System Restore Point button to create a System Restore Point.

Remember, this is a safety measure.  Under normal circumstances, Adding and Removing the file associations is
all that is necessary.


Modes of Operation:
===================
If run directly, the program starts the GUI where you can add or remove the associations, edit the
associations, file types and SendTo entries, or create a restore point.  Depending on the 'remove on close'
setting, the file associations will optionally be removed when the GUI is closed.

You can also run the program via command line: PortableFileAssociator.exe <param1> <param2>

<param1> can be one of the following:

add = Adds the file associations, then exits.
add_gui = Adds the file associations, starts the GUI minimized to the tray.
remove = Removes the file associations, then exits.

<param2> is an optional parameter and must specify the profile to activate and use.  This parameter is
ignored if <param1> is 'remove'.

The same command line options may be specified in the 'Data\Settings\profile.ini' file.  This may be
useful if your launcher is unable to specify command line arguments to program shortcuts.  Individual
arguments should not contain spaces.  Use the following format:

[profile]
commandline=add_gui DefaultProfile

If PFA is already running, there is one command line parameter available:

exit = Close the running instance of PFA.  File associations are removed based on the setting
       'remove associations on close'.

Internal parameters:  multi_open and bg_open are used by the context-menu entries created for %%1 and
'background' commands.  They are not meant to be started by hand.


Known Issues / Notes:
=====================
- Windows 11 shows these (classic) context-menu entries under "Show more options".
- 'Single file type' relies on the Windows verb setting MultiSelectModel=Single.  If an entry still appears
  with several items selected on your Windows version, leave the option unchecked.
- Message boxes, input boxes and file dialogs are drawn by Windows and do not follow the Dark theme.
- 'background' entries do not appear in virtual folders such as This PC or Control Panel.