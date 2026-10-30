# PowerShell Profile Installer Design

## Goal

Provide a portable installer for the four PowerShell utility scripts in this
repository. A user can clone or copy the repository to any location, run the
installer, reload their PowerShell profile, and invoke the utilities by short
command names.

## Files

- `install.ps1` at the repository root installs the profile functions.
- `README.md` documents installation, profile reload, available commands, and
  how to rerun the installer after moving the repository.
- The existing scripts remain in `powershell/` and are not modified.

## Installer Behavior

1. Resolve each utility script relative to the installer's own directory by
   using `$PSScriptRoot`; no repository path is hard-coded.
2. Verify that all four utility scripts exist before changing the user's
   profile. If validation fails, report the missing file and leave the profile
   unchanged.
3. Create the profile's parent directory and profile file when necessary.
4. Generate these profile functions, forwarding all arguments with `@args`:
   - `pcdoctor` invokes `powershell/pc-doctor.ps1`.
   - `memtop` invokes `powershell/memtop.ps1`.
   - `netcheck` invokes `powershell/net-check.ps1`.
   - `wslstop` invokes `powershell/wsl-stop.ps1`.
5. Place the generated functions between unique start and end comments. On a
   later run, replace that managed block instead of appending a duplicate. Any
   profile content outside the managed block remains unchanged.
6. Write the profile as UTF-8 and print a success message that tells the user
   to run `. $PROFILE` in the current PowerShell session.

The generated profile functions contain the resolved absolute script paths.
This makes command invocation independent of the current working directory.
If the repository is moved, rerunning `install.ps1` updates those paths.

## Documentation

The README will show:

```powershell
.\install.ps1
. $PROFILE
```

It will explain that the installer edits the PowerShell profile rather than the
Windows registry, list the four command names, and note that new PowerShell
sessions load the profile automatically.

## Error Handling and Verification

- Installer validation occurs before any profile mutation.
- Paths are quoted safely so locations containing spaces or apostrophes work.
- Verification will use a temporary profile path so the real user profile is
  not changed during testing.
- The test will cover initial installation, repeated installation without
  duplication, preservation of unrelated profile content, and invocation from
  a different working directory.
