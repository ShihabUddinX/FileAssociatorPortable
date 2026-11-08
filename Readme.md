# FileAssociatorPortable

*(formerly PortableFileAssociator)*

**Version 3.0.0.5**

**Owner / Trademark:** ShihabUddinX · Original work by Erik Pilsits

Take your file associations with you. Open local files with your portable applications.

## Contents

- [Main window](#main-window)
- [Associations](#associations)
- [File Types](#file-types)
- [SendTo](#sendto)
- [Profile](#profile)
- [Settings](#settings)
- [Tray menu](#tray-menu)
- [System Restore](#system-restore)
- [Modes of operation](#modes-of-operation)
- [Known issues / notes](#known-issues--notes)

---

## Main window

| Control | What it does |
|---|---|
| **Add File Associations** | Writes all enabled associations of the active profile to the registry (HKCU only). |
| **Remove File Associations** | Removes them again and restores what was backed up. |
| **Associations** | Opens the association editor (context-menu entries). |
| **File Types** | Opens the file type editor (icons, defaults, "New" menu). |
| **SendTo** | Opens the SendTo editor. |
| **Create System Restore Point** | Creates a Windows restore point (see [System Restore](#system-restore)). |
| **Profile** | Profile selection and profile buttons (see [Profile](#profile)). |
| **Settings** (gear icon, bottom right) | Theme, start and exit options, update check, splash screen (see [Settings](#settings)). |
| **Version** | The version number (e.g. `v3.0.0.5`) is shown at the bottom left of the main window. It is also the file version of `FileAssociatorPortable.exe`. |
| **Owner** | ShihabUddinX (owner and trademark). Also written in the file properties of `FileAssociatorPortable.exe` (Company, Legal copyright, Legal trademarks). Original work by Erik Pilsits. |

---

## Associations

| Field | Description |
|---|---|
| **Association Name** | The name of the association as recorded in the GUI list and INI file. It cannot include the characters `,` or `*`. |
| **Associated Types** | File **extensions only**, separated by `\|`, e.g. `txt\|log\|ini` (do not include the period). Disabled while **Files** is ticked. |
| **Also add to** | Five tick boxes for the special targets (see below). |
| **Single file type** | Show the association only when **one** item is selected. With several items selected the entry is hidden. |
| **Run as Admin** | Start the command with administrator rights (UAC prompt). See [Run as Admin](#run-as-admin). |
| **Disabled** | Disable the current association without deleting it. |
| **Title** | The name as it appears in the context menu. Make sure it is **unique** so it does not conflict with local entries. |
| **Context-menu icon** | Optional icon next to the entry (`.ico`, `.exe` or `.dll`). Relative paths are portable. |
| **Icon index** | Icon number inside a multi-icon file. Usually `0` for `.ico` files. |
| **Command** | The command line to execute (see [Command tokens](#command-tokens)). |
| **Folder Command** | Command for folders (see [Folder Command and Drive Command](#folder-command-and-drive-command)). |
| **Drive Command** | Command for drives (see [Folder Command and Drive Command](#folder-command-and-drive-command)). |

### Targets

**File extensions** go into *Associated Types*. `exe` and `com` add an entry to program files without changing their normal open action.

The special targets are tick boxes under **Also add to**. Any combination can be ticked, together with file extensions.

| Tick box | Entry is added to | Registry location (HKCU) |
|---|---|---|
| **Files** | all files, any extension (`*` wildcard) | `Software\Classes\*\shell` |
| **Folders** | all folders (*Folder Command*) | `Software\Classes\Directory\shell` |
| **Drives** | all drives (*Drive Command*) | `Software\Classes\Drive\shell` |
| **Recycle Bin** | the Recycle Bin | `Software\Classes\CLSID\{645FF040-…}\shell` |
| **Background** | empty space of a folder window and of the Desktop (like "Open Terminal here") | `Software\Classes\Directory\Background\shell` |
| *extension* | a specific file extension, e.g. `txt` | `Software\Classes\PortableFileAssoc_<ext>\shell` and `Software\Classes\SystemFileAssociations\.<ext>\shell` |

> **Files** already covers every file, so the *Associated Types* box is disabled while it is ticked.

> **Migration:** Older INI files that listed `drives`, `files`, `folders`, `recycle` or `background` in the Associated Types box are converted automatically when the profile is loaded. The word is removed from the box and the matching tick box is set. If `files` was used, the extension list is dropped (Files covers every file). An association that was only for drives keeps its old command as the Drive Command. These words can no longer be typed into the Associated Types box.
>
> Older folders-only associations that kept their command in `command` are converted too: the command becomes the `foldercommand` (and the `drivecommand` as well, if Drives is ticked and has no Drive Command).

### Run as Admin

- Tick **Run as Admin** to start the command with administrator rights. Windows asks for confirmation (UAC) each time the entry is used.
- Works for **Files**, **Folders**, **Drives**, **Background** and file extensions. Not used by **Recycle Bin**.
- The setting applies to every target of the association. Use two associations if you need different behaviour.
- Admin entries do not start your program directly. They start `FileAssociatorPortable.exe` (internal parameters `multi_open_admin` / `bg_open_admin`), which then starts the program elevated. PFA must stay at the same place while associations are active.
- Unchecked: the command runs normally.

### Single file type

- Works for **Files**, **Folders**, **Drives** and file extensions (e.g. `iso`).
- Unchecked: the entry is shown for single **and** multiple selection.
- Checked: the entry is shown only when exactly one item is selected.
- Not used by Recycle Bin and Background.
- The setting applies to every target of the association. Use two associations if you need different behaviour.

### Command tokens

The application path must be surrounded by `"` (double quotes) if it contains spaces, and it cannot use environment variables.

| Token | Meaning |
|---|---|
| `%1` | Path of the clicked-on file, folder or drive. Explorer starts **one run per selected item**. |
| `%%1` | **All** selected items in **one** run, each in quotes. |
| `%V` | The current folder. Meant for **Background** (also works for folders). |

**`%1` example**

```
"X:\PortableApps\App Path\app.exe" "%1"
```

**`%%1` example** — with three files selected, this runs `FastCopy.exe "file1" "file2" "file3"`:

```
"X:\FastCopy\FastCopy.exe" %%1
```

How `%%1` works:

- Explorer starts one process per selected item, so PFA registers a small wrapper (`FileAssociatorPortable.exe multi_open ...`).
- The wrapper processes collect their files, and the first one starts your command. It waits about 1.5 seconds for the other files.
- Files are passed in name order, like Explorer's default sort.
- Very long selections are split into several runs (about 30000 characters per command line).
- `%%1` works for **Files**, **Folders**, **Drives** and file extensions. With Folders or Drives it passes all selected folders / drives in one run.
- A drive root such as `E:\` is passed safely (as `"E:\\"`), so the closing quote is not swallowed.
- The command is started with `ShellExecute`, so programs that need administrator rights (for example FastCopy) show the normal Windows confirmation (UAC) instead of failing silently. Tick **Run as Admin** to always start the command elevated.

**`%V` examples**

```
"wt.exe" -d "%V"
cmd.exe /k cd /d "%V"
```

How `%V` works:

- The command is started inside that folder.
- A drive root such as `C:\` is passed safely (as `"C:\\"`), so terminals do not fail on the trailing backslash.
- For **Background**, `%V`, `%1` and `%%1` all mean "this folder".
- With **Run as Admin**, `%1` commands of Files, Folders and Drives are started the same way (through PFA), and `%V` / `%1` mean "the clicked-on item".

> **Note:** PFA must stay at the same place while associations are active, because `%%1` and Background entries start `FileAssociatorPortable.exe`.

The **Command** box is disabled when only **Folders** and / or **Drives** are ticked (no Files, Recycle Bin, Background or extensions). Then each ticked Folders / Drives box must have its own Folder Command / Drive Command. Otherwise the Command is needed.

### Folder Command and Drive Command

**Folder Command** is enabled only when **Folders** is ticked, **Drive Command** only when **Drives** is ticked. In a Folder Command use `%1` for the folder (one run per folder) or `%%1` for all selected folders in one run.

If a Folder Command / Drive Command is empty and the association also has other targets (Files, Recycle Bin, Background or extensions), folders / drives simply use the **Command**. Fill them in when folders or drives need a different command line.

| Association targets | Command | Folder / Drive Command |
|---|---|---|
| Only **Folders**, Folder Command filled in | disabled | used for folders |
| Only **Drives**, Drive Command filled in | disabled | used for drives |
| Only **Folders** or only **Drives**, command empty | – | Save shows an error, the command is required |
| **Folders** + **Drives** + **Background** | used for Background, and for folders / drives without their own command | used for folders / drives when filled in |

A drive path such as `E:\` ends with a backslash, so write `%1` or `%V` **without quotes** in the Drive Command. In a Command, `"E:\"` would turn into an escaped quote and many programs fail.

Example — the same portable terminal for folders, background and drives:

```
Command:        "E:\PortableApps\TerminalPortable\TerminalPortable.exe" -d "%1"
Folder Command: "E:\PortableApps\TerminalPortable\TerminalPortable.exe" -d "%1"
Drive Command:  "E:\PortableApps\TerminalPortable\TerminalPortable.exe" -d %1
```

(`-d %V` works as well.)

### Buttons

| Button | Action |
|---|---|
| **...** (next to Command) | Browse for the program. Inserts `"%V"` when Background is the only target, otherwise `"%1"`. |
| **...** (next to Folder Command) | Browse for the program. Inserts `"%1"`. |
| **...** (next to Drive Command) | Browse for the program. Inserts `%1`. |
| **Clear** | Clear all fields. |
| **Save** | Save association changes. Must be done after each change. Asks before overwriting an existing association. |
| **Delete** | Delete the selected association. The last association cannot be deleted. |
| **Done** | Close the association dialog. |
| **?** | Open this Readme in a window. The Readme is built into the program, no Readme file is needed. |

### INI format

Associations are stored in `Data\settings\<profile>_assoc.ini`, one section per association:

```ini
[My Association]
mode=iso|img
files=1
folders=1
drives=1
recycle=1
background=1
title=Open with MyApp
command='"..\MyApp\MyApp.exe" "%1"'
foldercommand='"..\MyApp\MyApp.exe" "%1"'
drivecommand='"..\MyApp\MyApp.exe" %1'
icon=...
disabled=4
single=1
admin=1
```

- `mode` holds the file extensions only.
- `files`, `folders`, `drives`, `recycle`, `background`, `single` and `admin` are only present when the tick box is checked (`=1`).
- `foldercommand` and `drivecommand` are only present when a Folder Command / Drive Command is set.

---

## File Types

| Field | Description |
|---|---|
| **Association** | Filter the list of file types by association name. Choose *All* to show every extension. |
| **File Type** | The selected file type. |
| **Default PFA Association** | Default PFA association for the selected extension (double-click action). |
| **Hide extension** | Prevent the selected extension from being displayed in Explorer. |
| **Copy Host Associations** | Copy the associations already present on the host computer for the selected extension. |
| **Host Precedence** | If a host default association exists, it takes precedence over the PFA default. |
| **Iconfile** | The file to extract the icon from (`.exe`, `.dll` or `.ico`). Used when a host association is not the default action. |
| **Index** | Index of the embedded icon in a multi-icon resource. Use the arrow buttons or type the index. `.ico` files do not use an index; leave it at `0`. |
| **Show in New menu in context menu** | Adds the file type to Explorer's right-click → New submenu. |
| **New menu name** | Name shown under right-click → New. Default: `PFA_<extension> File`. |
| **Use template file** | New items are created from a template instead of an empty file (see below). |
| **Save File Type** | Save file type changes. Must be done after each change. |
| **Done** | Close the dialog. Prompts to apply changes if any were made while the associations are active. |

> **Note:** The index in the dialog will not exactly match the index used by Windows, however the correct Windows index is saved and written to the registry.

**Template files:** PFA looks for the exact filename `Data\newitems\<EXTENSION IN CAPITALS>.<extension>` (e.g. `Data\newitems\TXT.txt`). A message appears if the file is missing. The host's own "New" entry for the extension is backed up and restored when the associations are removed.

### Default association and icon behavior

For new file extensions, the icon is initially set to the first association defined in the INI file that is associated with the extension.

When selecting a host default, PFA first looks for an explicitly defined one. If none exists, it searches for a registry verb named `open` and uses that.

What PFA does when applying the default association and icon depends on several factors:

1. **A PFA default association is selected**
   - **Host Precedence selected:** If a host default association exists it is set as the default and the host `DefaultIcon` is used. If there is no `DefaultIcon`, the PFA icon is used. If no host default is found, the PFA default association and icon are used. If no default is found and no PFA default is set, the OS decides and the PFA icon is used.
   - **Host Precedence not selected:** The default action is set to the selected PFA association. The `DefaultIcon` is the user-defined icon from this dialog.
2. **No PFA default association is selected**
   - **Copy Host Associations selected:** If a host default association exists it is set as the default and the host `DefaultIcon` is used. If there is no `DefaultIcon`, the PFA icon is used. If no host default action is found, the OS decides, and the PFA-defined icon is used.
   - **Copy Host Associations not selected:** No default action is defined and the OS decides. The PFA-defined icon is used.

---

## SendTo

Shortcuts defined here show up in the system's **Send to →** context menu.

| Control | Description |
|---|---|
| **ListView** | Lists the defined shortcut names and targets. Drag and drop files or folders onto it to add shortcuts (you are asked for a shortcut name and optional parameters). |
| **Add...** | Add a shortcut by browsing to it. |
| **Remove** | Remove a shortcut from the list. |
| **Clear** | Clear all shortcuts from the list. |
| **Save** | Save the current settings. |
| **Done** | Close the dialog (asks to save unsaved changes). |

---

## Profile

Settings are stored per profile in `Data\settings\<profile>_assoc.ini`, `_state.ini`, `_types.ini` and `_sendto.ini`.

| Control | Description |
|---|---|
| **Dropdown** | Displays the active profile. Switch profiles by choosing a new one. |
| **New** | Create a new profile. |
| **Clone** | Create a copy of an existing profile. |
| **Rename** | Rename the active profile. |
| **Remove** | Remove the active profile. This action cannot be undone. |

The last used profile is stored as `active` in `Data\settings\profile.ini`.

The profile buttons are icons (New, Clone, Rename, Remove). They are greyed out and cannot be used while the associations are active.

---

## Settings

Click the **gear icon** at the bottom right of the main window. Every option is saved as soon as it is changed (no Save button). They are stored in `Data\settings\settings.ini` (`[settings]` section), the splash screen option in `FileAssociatorPortable.ini` next to the exe. `Data\settings\profile.ini` only keeps profile data (`[profile] active=<last used profile>`).

| Option | Description | Saved as |
|---|---|---|
| **Theme** | **System** follows the Windows app theme, **Light** is always light, **Dark** is always dark (window and title bar, text, inputs, lists, buttons, tray menu, icons). | `theme=system \| light \| dark` |
| **Add associations on start** | The associations of the last active profile are added automatically when PFA is started without command line arguments. | `addassociationonstart=true \| false` |
| **Remove associations on exit** | The file associations are removed again when PFA is closed (Exit, close button, Windows shutdown). On by default. | `removeonexit=true \| false` |
| **Check for updates on startup** | Looks for a newer version in the background each time PFA starts (a message only appears when a newer version exists). The tray item **Check for updates** checks at any time. | `checkupdateonstartup=true \| false` |
| **Start minimized** | On: PFA starts minimized to the tray. Off: the main window is shown. | `startminimized=true \| false` |
| **Disable splash screen** | No splash screen when PFA starts. | `DisableSplash=true` in `FileAssociatorPortable.ini` |
| **Close button (X) minimizes to the tray** | The close button hides the window in the tray instead of exiting (use the tray item **Exit** to quit). Off by default. | `closetotray=true \| false` |

Values: `true`, `1`, `yes`, `on` = on; `false`, `0` or blank = off.

```ini
[settings]
theme=dark
addassociationonstart=true
removeonexit=true
checkupdateonstartup=true
startminimized=false
closetotray=false
```

**Update from an older version:** the first time this version starts (no `settings.ini` yet) the old settings are taken over automatically: `theme` and `commandline=add_gui` (-> add associations on start + start minimized, and its profile name) from `profile.ini`, the per-profile *remove on close* state, and `DisableUpdateCheck=true` from `FileAssociatorPortable.ini`. The old `commandline` and `theme` lines are then removed from `profile.ini`.

> **Note:** Windows' own message and file dialogs are not themed. Dark buttons, combo boxes and scroll bars need Windows 10 (1903) or newer; on older systems they stay light.

---

## Tray menu

Left-click the tray icon to show the main window. Right-click it to access these options.

| Item | Description |
|---|---|
| **Refresh icons now** | Sends the `SHChangeNotify()` system message so Explorer refreshes the icons. |
| **Check for updates** | Checks online if a newer version of PFA is available (needs an internet connection). |
| **Exit** | Close PFA. |

*Add associations on start* and *Remove associations on exit* are in the [Settings](#settings) window.

---

## System Restore

While nothing destructive should happen as a result of using this app, it's always a good idea to have a backup. Press **Create System Restore Point** to create one.

Remember, this is a safety measure. Under normal circumstances, adding and removing the file associations is all that is necessary.

---

## Modes of operation

If run directly, the program starts the GUI where you can add or remove associations, edit associations, file types and SendTo entries, or create a restore point. Depending on the setting **Remove associations on exit**, the file associations are removed when PFA is closed.

You can also run the program from the command line:

```
FileAssociatorPortable.exe <param1> <param2>
```

`<param1>` can be one of:

| Value | Action |
|---|---|
| `add` | Adds the file associations, then exits. |
| `add_gui` | Adds the file associations and starts the GUI minimized to the tray. |
| `remove` | Removes the file associations, then exits. |

`<param2>` is optional and must specify the profile to activate and use. It is ignored if `<param1>` is `remove`. If it is left out, the **last active profile** is used (the profile selected the last time PFA was used, stored as `active` in `Data\Settings\profile.ini`).

```
FileAssociatorPortable.exe add_gui                  (last active profile)
FileAssociatorPortable.exe add_gui DefaultProfile   (this profile)
```

Without command line arguments the [Settings](#settings) decide: **Add associations on start** adds the associations of the last active profile, **Start minimized** starts the GUI in the tray. Older versions used `commandline=add_gui` in `Data\Settings\profile.ini` for this; that line is no longer read (it is taken over into the Settings automatically). A launcher that can pass arguments can still use the command line above.

If PFA is already running, one command line parameter is available:

| Value | Action |
|---|---|
| `exit` | Close the running instance of PFA. File associations are removed based on the setting *Remove associations on exit*. |

> **Internal parameters:** `multi_open` and `bg_open` are used by the context-menu entries created for `%%1` and Background commands. `multi_open_admin` and `bg_open_admin` are the same with **Run as Admin** (elevated start). They are not meant to be started by hand.

---

## Known issues / notes

- The program was renamed from PortableFileAssociator to FileAssociatorPortable. The old `PortableFileAssociator.ini` (`DisableSplash` / `DisableUpdateCheck`) is copied to `FileAssociatorPortable.ini` automatically. `Data\settings` and the registry entries (`PortableFileAssoc_<ext>`) keep their names, so profiles and **Remove File Associations** keep working. Entries added by the old exe start the old exe: remove the associations with the old version first (or Remove, then Add once with the new exe).
- Windows' own default app for an extension (Settings > Default apps, e.g. WinRAR for zip) is left alone unless a PFA default association takes over that extension. In that case the key is renamed, not copied, while the associations are active, so the default app is back after Remove. If Windows refuses the rename, the default app is left untouched (the PFA default may then not take effect).
- Windows 11 shows these (classic) context-menu entries under **Show more options**.
- **Single file type** relies on the Windows verb setting `MultiSelectModel=Single`. If an entry still appears with several items selected on your Windows version, leave the option unchecked.
- Message boxes, input boxes and file dialogs are drawn by Windows and do not follow the Dark theme.
- Background entries do not appear in virtual folders such as This PC or Control Panel.
- File extension entries are also written to `SystemFileAssociations\.<ext>\shell`, so they show up even when Windows has a default app chosen for the extension (typical for media files such as mp3 and mp4). Use **Remove File Associations** and **Add File Associations** once after updating.
- **Run as Admin** shows the Windows confirmation (UAC) every time the entry is used. It is not available for the Recycle Bin.
- After updating PFA, use **Remove File Associations** and then **Add File Associations** once, so the new commands (`%%1`, Run as Admin, Folder Command) are written to the registry.

---

## Owner / Trademark

FileAssociatorPortable is owned by **ShihabUddinX**. ShihabUddinX is a trademark of ShihabUddinX.
Original work by Erik Pilsits.
