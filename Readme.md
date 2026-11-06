# PortableFileAssociator

Take your file associations with you. Open local files with your portable applications.

## Contents

- [Main window](#main-window)
- [Associations](#associations)
- [File Types](#file-types)
- [SendTo](#sendto)
- [Profile](#profile)
- [Theme](#theme)
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
| **Theme** | System / Light / Dark (see [Theme](#theme)). |

---

## Associations

| Field | Description |
|---|---|
| **Association Name** | The name of the association as recorded in the GUI list and INI file. It cannot include the characters `,` or `*`. |
| **Associated Types** | Where the entry appears (see the table below). |
| **Single file type** | Show the association only when **one** item is selected. With several items selected the entry is hidden. |
| **Title** | The name as it appears in the context menu. Make sure it is **unique** so it does not conflict with local entries. |
| **Context-menu icon** | Optional icon next to the entry (`.ico`, `.exe` or `.dll`). Relative paths are portable. |
| **Icon index** | Icon number inside a multi-icon file. Usually `0` for `.ico` files. |
| **Disabled** | Disable the current association without deleting it. |
| **Command** | The command line to execute (see [Command tokens](#command-tokens)). |

### Associated Types

| Type | Entry is added to | Registry location (HKCU) |
|---|---|---|
| `drives` | all drives | `Software\Classes\Drive\shell` |
| `file` | all files | `Software\Classes\*\shell` |
| `folder` | all folders | `Software\Classes\Directory\shell` |
| `background` | empty space of a folder window and of the Desktop (like "Open Terminal here") | `Software\Classes\Directory\Background\shell` |
| `recycle` | the Recycle Bin | `Software\Classes\CLSID\{645FF040-…}\shell` |
| `exe` / `com` | program files (their normal open action is not changed) | on the existing `exefile` / `comfile` class |
| `<extension>` | a specific file extension, e.g. `txt` (do not include the period) | `Software\Classes\PortableFileAssoc_<ext>\shell` |

Separate more than one type with the `|` (pipe) character, e.g. `file|folder` or `txt|log|ini`.

> **Note:** Older INI files that use `files` or `folders` still work. They are treated as `file` and `folder`.

### Single file type

- Works for the types `file`, `folder` and file extensions (e.g. `iso`).
- Unchecked: the entry is shown for single **and** multiple selection.
- Checked: the entry is shown only when exactly one item is selected.
- Not used by `drives`, `background` and `recycle`.
- The setting applies to every extension in the *Associated Types* box. Use two associations if you need different behaviour per extension.

### Command tokens

The application path must be surrounded by `"` (double quotes) if it contains spaces, and it cannot use environment variables.

| Token | Meaning |
|---|---|
| `%1` | Path of the clicked-on file, folder or drive. Explorer starts **one run per selected item**. |
| `%%1` | **All** selected items in **one** run, each in quotes. |
| `%V` | The current folder. Meant for the type `background` (also works for folders). |

**`%1` example**

```
"X:\PortableApps\App Path\app.exe" "%1"
```

**`%%1` example** — with three files selected, this runs `FastCopy.exe "file1" "file2" "file3"`:

```
"X:\FastCopy\FastCopy.exe" %%1
```

How `%%1` works:

- Explorer starts one process per selected item, so PFA registers a small wrapper (`PortableFileAssociator.exe multi_open ...`).
- The wrapper processes collect their files, and the first one starts your command. It waits about 0.7 seconds for the other files.
- Files are passed in name order, like Explorer's default sort.
- Very long selections are split into several runs (about 30000 characters per command line).

**`%V` examples**

```
"wt.exe" -d "%V"
cmd.exe /k cd /d "%V"
```

How `%V` works:

- The command is started inside that folder.
- A drive root such as `C:\` is passed safely (as `"C:\\"`), so terminals do not fail on the trailing backslash.
- For the type `background`, `%V`, `%1` and `%%1` all mean "this folder".

> **Note:** PFA must stay at the same place while associations are active, because `%%1` and `background` entries start `PortableFileAssociator.exe`.

### Buttons

| Button | Action |
|---|---|
| **...** (next to Command) | Browse for the program. Inserts `"%V"` when the type is only `background`, otherwise `"%1"`. |
| **Clear** | Clear all fields. |
| **Save** | Save association changes. Must be done after each change. Asks before overwriting an existing association. |
| **Delete** | Delete the selected association. The last association cannot be deleted. |
| **Done** | Close the association dialog. |
| **?** | Open this Readme. |

### INI format

Associations are stored in `Data\settings\<profile>_assoc.ini`, one section per association:

```ini
[My Association]
mode=iso|img
title=Open with MyApp
command='"..\MyApp\MyApp.exe" "%1"'
icon=...
disabled=4
single=1
```

`single=1` is only present when **Single file type** is checked.

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

The profile buttons are icons (New, Clone, Rename, Remove). They are greyed out and cannot be used while the associations are active.

---

## Theme

The dropdown at the bottom right of the main window sets the look of all PFA windows.

| Option | Behavior |
|---|---|
| **System** | Follow the Windows app theme (light or dark). |
| **Light** | Always light. |
| **Dark** | Always dark: window and title bar, text, inputs, lists, buttons, the tray menu and the profile icons (white instead of black). |

The choice is saved in `Data\settings\profile.ini`:

```ini
[profile]
theme=system
```

Allowed values: `system`, `light`, `dark`.

> **Note:** Windows' own message and file dialogs are not themed. Dark buttons, combo boxes and scroll bars need Windows 10 (1903) or newer; on older systems they stay light.

---

## Tray menu

Left-click the tray icon to show the main window. Right-click it to access these options.

| Item | Description |
|---|---|
| **Rebuild icon cache on change** | If activated, the icon cache is rebuilt after associations are added or removed, or after icon changes are applied. Disabled by default; enable it if filetypes show incorrect icons. *(NT/2000/XP only)* |
| **Refresh icons now** | Sends the `SHChangeNotify()` system message. If the option above is active, it also rebuilds the icon cache. On Windows Vista and newer this only sends the message. |
| **Remove associations on close** | If activated, the file associations are removed when the GUI is closed. |
| **Exit** | Close PFA. |

---

## System Restore

While nothing destructive should happen as a result of using this app, it's always a good idea to have a backup. Press **Create System Restore Point** to create one.

Remember, this is a safety measure. Under normal circumstances, adding and removing the file associations is all that is necessary.

---

## Modes of operation

If run directly, the program starts the GUI where you can add or remove associations, edit associations, file types and SendTo entries, or create a restore point. Depending on the *remove on close* setting, the file associations are optionally removed when the GUI is closed.

You can also run the program from the command line:

```
PortableFileAssociator.exe <param1> <param2>
```

`<param1>` can be one of:

| Value | Action |
|---|---|
| `add` | Adds the file associations, then exits. |
| `add_gui` | Adds the file associations and starts the GUI minimized to the tray. |
| `remove` | Removes the file associations, then exits. |

`<param2>` is optional and must specify the profile to activate and use. It is ignored if `<param1>` is `remove`.

The same options can be set in `Data\Settings\profile.ini`. This is useful if your launcher cannot pass command line arguments to program shortcuts. Individual arguments should not contain spaces:

```ini
[profile]
commandline=add_gui DefaultProfile
```

If PFA is already running, one command line parameter is available:

| Value | Action |
|---|---|
| `exit` | Close the running instance of PFA. File associations are removed based on the setting *Remove associations on close*. |

> **Internal parameters:** `multi_open` and `bg_open` are used by the context-menu entries created for `%%1` and `background` commands. They are not meant to be started by hand.

---

## Known issues / notes

- Windows 11 shows these (classic) context-menu entries under **Show more options**.
- **Single file type** relies on the Windows verb setting `MultiSelectModel=Single`. If an entry still appears with several items selected on your Windows version, leave the option unchecked.
- Message boxes, input boxes and file dialogs are drawn by Windows and do not follow the Dark theme.
- `background` entries do not appear in virtual folders such as This PC or Control Panel.
