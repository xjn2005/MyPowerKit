# PowerShell Profile Installer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a portable, repeatable installer that registers the repository's four utility scripts as short PowerShell commands and documents its use.

**Architecture:** A root-level `install.ps1` resolves utility scripts from `$PSScriptRoot`, validates them, and owns one marker-delimited block in a selected PowerShell profile. A root-level `README.md` explains installation, profile reload, command names, portability, and repeat installation.

**Tech Stack:** PowerShell 5.1+, Markdown

---

### Task 1: Implement the profile installer

**Files:**
- Create: `install.ps1`

- [ ] **Step 1: Define inputs, command mappings, and validation**

Add an optional `ProfilePath` parameter defaulting to `$PROFILE`. Define the four command-to-script mappings with an ordered dictionary. Resolve every source script relative to `$PSScriptRoot` and throw before touching the profile if any file is absent.

- [ ] **Step 2: Generate a safely quoted managed profile block**

Escape apostrophes in resolved Windows paths by doubling them inside PowerShell single-quoted strings. Generate functions in this form:

```powershell
function pcdoctor { & 'C:\resolved\repository\powershell\pc-doctor.ps1' @args }
```

Place all functions between unique `# >>> scripts utilities >>>` and `# <<< scripts utilities <<<` markers.

- [ ] **Step 3: Add idempotent profile updating**

Create the profile parent directory and file if needed. If the marker-delimited block exists, replace it once; otherwise append it with correct newline separation. Preserve all content outside the managed block and write UTF-8.

- [ ] **Step 4: Print the reload instruction**

After success, display the profile location and tell the user to run:

```powershell
. $PROFILE
```

### Task 2: Document installation and commands

**Files:**
- Create: `README.md`

- [ ] **Step 1: Document installation**

Explain that the installer modifies the PowerShell profile, not the registry. Show these commands from the repository root:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
. $PROFILE
```

Clarify that the execution-policy command is only needed when local policy blocks the script.

- [ ] **Step 2: Document command mappings and lifecycle**

List `pcdoctor`, `memtop`, `netcheck`, and `wslstop` with their backing scripts. Explain that new PowerShell sessions load the profile automatically and that moving the repository requires rerunning `install.ps1`.

### Task 3: Verify behavior without changing the real profile

**Files:**
- Test: `install.ps1`

- [ ] **Step 1: Run initial installation against a temporary profile**

Invoke `install.ps1 -ProfilePath <temporary-file>` and verify all four functions and both markers are present with resolved paths.

- [ ] **Step 2: Verify repeat installation and content preservation**

Add unrelated content outside the generated block, rerun the installer, and verify the unrelated content remains while each marker and function occurs exactly once.

- [ ] **Step 3: Verify invocation from another working directory**

Load the temporary profile from a different directory and confirm all four functions resolve to the repository scripts. Do not invoke the utilities themselves because they perform real machine diagnostics or state changes.

- [ ] **Step 4: Inspect the final diff**

Run `git diff --check` and `git status --short`. Do not stage or commit files, per user instruction.
