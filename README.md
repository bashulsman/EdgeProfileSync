# Edge Profile Sync - Intune Win32 App

Interactive tool that lets users backup their Microsoft Edge profiles to OneDrive
or restore them on a new machine. Installed system-wide (Program Files) by Intune
with admin rights; users run the tool with their own rights from Start Menu.

---

## Version history

| Version | Date       | Changes                         |
|---------|------------|---------------------------------|
| 1.0     | 2026-05-29 | Initial release (based on Chrome Profile Sync v5.0) |

---

## How it works

```
Intune (System/admin) installs to:
  C:\Program Files\EdgeProfileSync\          <- InstallEdge.ps1, UninstallEdge.ps1, DetectEdge.ps1
  C:\ProgramData\Microsoft\Windows\          <- Start Menu shortcut (all users)
    Start Menu\Programs\Edge Profile Sync.lnk

User opens Edge Profile Sync from Start Menu:
  - Dialog shows LOCAL PROFILES and ONEDRIVE BACKUP side by side
  - Real account names shown where available (Microsoft/Google display name + email)
  - System Profile, Guest Profile, GuestWebAppProfile1 are hidden

  [Backup to OneDrive]       [Restore from OneDrive]    [Reset & Restore]
  Old machine: copy          New machine: copy           Wipe broken Edge
  profiles to OneDrive,      profiles from OneDrive      data, restore
  keep local intact          directly to local disk      from backup

All profile files are copied to local disk on Restore - no OneDrive
dependency when Edge opens. 100% local read.

Per-user data stays in AppData (no admin needed at runtime):
  %LOCALAPPDATA%\EdgeProfileSync\config.json    <- saved OneDrive selection
  %LOCALAPPDATA%\Logs\EdgeProfileSync\          <- activity logs
  %LOCALAPPDATA%\Microsoft\Edge\User Data       <- Edge profiles (local)
  OneDrive\EdgeProfileBackup\                   <- backup folder
```

---

## Files

| File                | Purpose                                                         |
|---------------------|-----------------------------------------------------------------|
| InstallEdge.ps1     | Main tool (UI) + Setup mode for Intune deployment               |
| UninstallEdge.ps1   | Removes Program Files folder and Start Menu shortcut            |
| DetectEdge.ps1      | Intune detection - checks Program Files and shortcut            |

Package these three files together with IntuneWinAppUtil, using InstallEdge.ps1
as the setup file.

---

## Step 1 - Package with IntuneWinAppUtil

1. Download **IntuneWinAppUtil.exe** from Microsoft:
   https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/releases

2. Place all three scripts in a folder, e.g. `C:\Packaging\EdgeProfileSync\scripts\`

3. Run:
   ```cmd
   IntuneWinAppUtil.exe -c "C:\Packaging\EdgeProfileSync\scripts" -s InstallEdge.ps1 -o "C:\Packaging\EdgeProfileSync\output"
   ```
   This produces `InstallEdge.intunewin`.

---

## Step 2 - Create the Win32 App in Intune

Go to: **Intune portal > Apps > Windows > Add > Windows app (Win32)**

Upload `InstallEdge.intunewin` when prompted.

### App information tab

| Field       | Value                                                                 |
|-------------|-----------------------------------------------------------------------|
| Name        | Edge Profile Sync                                                     |
| Description | Backup and restore Microsoft Edge profiles via OneDrive.              |
| Publisher   | Hulsman Systems                                                       |
| Version     | 1.0                                                                   |
| Category    | Productivity                                                          |

### Program tab

| Field                   | Value                                                                                        |
|-------------------------|----------------------------------------------------------------------------------------------|
| Install command         | `powershell.exe -ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -File InstallEdge.ps1 -Setup` |
| Uninstall command       | `powershell.exe -ExecutionPolicy Bypass -NonInteractive -WindowStyle Hidden -Command "& (Join-Path $Env:ProgramFiles 'EdgeProfileSync\UninstallEdge.ps1')"` |
| Install behavior        | **System** (admin rights needed for Program Files and all-users shortcut)                    |
| Device restart behavior | No specific action                                                                           |

### Requirements tab

| Field           | Value                   |
|-----------------|-------------------------|
| OS architecture | 64-bit                  |
| Minimum OS      | Windows 10 21H1 (19043) |

### Detection rules tab

| Field                          | Value                        |
|--------------------------------|------------------------------|
| Rules format                   | Use a custom detection script |
| Script file                    | Upload `DetectEdge.ps1`      |
| Run script as 32-bit process   | No                           |
| Enforce script signature check | No                           |

### Assignments tab

| Field                          | Value                                                   |
|--------------------------------|---------------------------------------------------------|
| Required                       | Assign to device group for automatic deployment         |
| Available for enrolled devices | Or assign to user group for self-service via Company Portal |

---

## Step 3 - User experience

1. Intune installs the app silently (System context, no user interaction)
2. User finds **Edge Profile Sync** in the Start Menu
3. Opens the tool - dialog shows local and OneDrive profiles

**On the old machine:**
- Click **Backup to OneDrive**
- Edge closes, caches are cleared, profiles are copied to `OneDrive\EdgeProfileBackup\`
- Local Edge profiles remain intact and unchanged
- Wait for OneDrive to finish syncing (green checkmark in taskbar)

**On the new machine:**
- Open the tool from Start Menu
- Click **Restore from OneDrive**
- Edge closes, all profiles are copied from OneDrive directly to local disk
- Edge opens with all profiles available immediately - no OneDrive sync needed

**If something is broken:**
- Click **Reset & Restore**
- Broken Edge data is renamed to a `.broken_<timestamp>` backup
- If an OneDrive backup exists it is restored immediately
- If no backup exists, Edge starts fresh

---

## Three-button reference

| Button | Colour | When to use |
|---|---|---|
| Backup to OneDrive | Blue | On your current / old machine before decommissioning |
| Restore from OneDrive | Green | On a new or reinstalled machine |
| Reset & Restore | Orange | When Edge is broken or corrupted |

---

## Differences from Chrome Profile Sync

| | Chrome Profile Sync | Edge Profile Sync |
|---|---|---|
| Script names | Install.ps1 | InstallEdge.ps1 |
| Program Files | ChromeProfileSync\ | EdgeProfileSync\ |
| Start Menu | Chrome Profile Sync | Edge Profile Sync |
| User Data path | \Google\Chrome\User Data | \Microsoft\Edge\User Data |
| Process closed | chrome.exe | msedge.exe |
| OneDrive backup | ChromeProfileBackup\ | EdgeProfileBackup\ |
| Config / logs | ChromeProfileSync\ | EdgeProfileSync\ |
| Extra hidden folder | - | GuestWebAppProfile1 |

Both tools can be installed on the same machine simultaneously without conflict.

---

## Important notes

**Edge profile path:** Edge stores profiles in the same structure as Chrome
(`Default`, `Profile 1`, `Profile 2`, ...) under
`%LOCALAPPDATA%\Microsoft\Edge\User Data`. The tool automatically detects
and skips internal folders (`System Profile`, `Guest Profile`, `GuestWebAppProfile1`).

**Profile names:** If profiles show as generic names (`Profile 1`, `Profile 14`,
etc.), this means they were not signed in to a Microsoft or Google account in
Edge. You can rename them in Edge via `Settings > Profiles` or sign in to the
relevant account to restore the display name automatically.

**Saved passwords and cookies (DPAPI):** Edge encrypts credentials using the
Windows Data Protection API (DPAPI), which is tied to the Windows user account
on a specific machine.

| Scenario | Credentials |
|---|---|
| Restore on the **same machine** | Passwords and cookies should work |
| Restore on a **new machine** | Passwords and cookies cannot be transferred |
| Restore after **Windows reinstall** | Passwords and cookies cannot be transferred |

Bookmarks, extensions, history, and settings restore correctly in all scenarios.

**OneDrive must be signed in** before using the tool. The tool resolves the
correct OneDrive account by matching the user's UPN against connected accounts
in the registry. When multiple OneDrives are connected and no match is found,
a selector dialog appears. Use the **Browse...** button if the automatic
selection is wrong.

**Uninstall** removes only the Program Files folder and Start Menu shortcut.
Edge profiles and the OneDrive backup are not affected.

**DiskCacheSize policy (recommended):** Set via Intune Settings Catalog to
cap Edge cache growth per profile:

| Policy (Microsoft Edge)  | Value       |
|--------------------------|-------------|
| DiskCacheSize            | `268435456` |

---

## Logs

User activity logs:
```
%LOCALAPPDATA%\Logs\EdgeProfileSync\EdgeProfileSync_<timestamp>.log
```

Uninstall log (system):
```
C:\ProgramData\Logs\EdgeProfileSync\Uninstall_<timestamp>.log
```
