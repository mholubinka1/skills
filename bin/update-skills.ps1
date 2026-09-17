# update-skills.ps1 - refresh ~/.claude/skills from this repo's main branch.
#
# Native PowerShell port of bin/update-skills: fast-forwards this clone to
# origin/main, bootstraps the local .venv and the pre-commit hooks on first
# run, then runs sync_claude_skills.py. Safe to run from any directory.
# Refuses to run if the working tree is dirty - it never stashes, resets, or
# force-pulls. No Git Bash dependency.

# Deliberately not $ErrorActionPreference = 'Stop': PowerShell promotes a
# native command's stderr output into a terminating error under 'Stop',
# which would crash the whole script the moment a probed interpreter (e.g.
# the Windows Store `python3` alias stub) writes to stderr, instead of
# letting the explicit $LASTEXITCODE checks below handle it gracefully —
# the same "probe by running, check the exit code" contract as the bash
# version's `>/dev/null 2>&1` probe.
$BRANCH = 'main'

function Say([string]$Message) {
    Write-Host "==> $Message"
}

function Die([string]$Message) {
    Write-Error "update-skills: $Message"
    exit 1
}

# --- resolve the repo root from this script's own location ------------------
$binDir = $PSScriptRoot
$repo = Split-Path -Parent $binDir

Set-Location $repo

if (-not (Test-Path (Join-Path $repo 'sync_claude_skills.py'))) {
    Die "$repo does not look like the skills repo (no sync_claude_skills.py) - run the copy that lives in the cloned repo's bin/."
}

git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) {
    Die "$repo is not a git work tree."
}

# --- guard: refuse on a dirty working tree --------------------------------
$dirty = git status --porcelain
if ($dirty) {
    Write-Host "update-skills: working tree has uncommitted changes - aborting." -ForegroundColor Red
    Write-Host ""
    git status
    exit 1
}

# --- refresh the branch --------------------------------------------------
Say "Switching to $BRANCH"
git checkout $BRANCH
if ($LASTEXITCODE -ne 0) {
    Die "'git checkout $BRANCH' failed - see the git output above for the reason."
}

Say "Fast-forwarding to origin/$BRANCH"
git pull --ff-only origin $BRANCH
if ($LASTEXITCODE -ne 0) {
    Write-Host "update-skills: 'git pull --ff-only origin $BRANCH' failed - see the git output above for the reason." -ForegroundColor Red
    Write-Host "If the histories have diverged, resolve it by hand; update-skills will not force or reset."
    Write-Host "It could also be a network or auth problem reaching origin."
    exit 1
}

# --- resolve Python interpreters ----------------------------------------
# Shape matches .pre-commit-config.yaml's sync-claude-skills hook: venv
# interpreter first, system interpreters only as a fallback to *create* the
# venv, never to run pip or the sync - every install and the sync itself run
# against the venv, so `pip install` can't leak into system/user
# site-packages. The system-candidate list itself differs (py/python here,
# not that hook's python3/python) - see the Windows-native rationale below.

function Test-RunsOk([string]$Interpreter) {
    if (-not $Interpreter) { return $false }
    # 'pass', not '': PowerShell silently drops a truly-empty-string argument
    # when invoking a native executable under `-File` execution, which would
    # otherwise turn "python -c ''" into "python -c" (a real usage error) and
    # make every interpreter probe fail, even a working one.
    & $Interpreter -c 'pass' *> $null
    return $LASTEXITCODE -eq 0
}

$sysPy = $null
# Windows-native candidates only: `py` (the official launcher, tried first
# since it reliably resolves to a real interpreter) then `python`. `python3`
# is deliberately not probed here -- on native Windows it is essentially
# always either absent or the Windows Store's non-functional alias stub (see
# Test-RunsOk above), never a real interpreter, unlike on macOS/Linux where
# bin/update-skills probes it first for good reason.
foreach ($candidate in @('py', 'python')) {
    if (Get-Command $candidate -ErrorAction SilentlyContinue) {
        if (Test-RunsOk $candidate) {
            $sysPy = $candidate
            break
        }
    }
}

function Get-VenvPython {
    $candidate = Join-Path $repo '.venv\Scripts\python.exe'
    if (Test-Path $candidate) {
        return $candidate
    }
    return $null
}

# --- first-run bootstrap: .venv + pre-commit hooks ----------------------
$venvPy = Get-VenvPython
if ($venvPy -and -not (Test-RunsOk $venvPy)) {
    Die ".venv exists but its interpreter ($venvPy) won't run - delete .venv and re-run."
}
if (-not $venvPy) {
    if (-not $sysPy) {
        Die "no working py or python found; cannot create .venv."
    }
    Say "Creating .venv"
    & $sysPy -m venv .venv
    $venvPy = Get-VenvPython
    if (-not (Test-RunsOk $venvPy)) {
        Die "created .venv but its interpreter is missing or won't run - your platform's python venv package is probably absent; install it and re-run. (Refusing to fall back to system Python: that would install pre-commit globally.)"
    }
}

# hooks_ok - true only if BOTH hook types this repo configures
# (default_install_hook_types in .pre-commit-config.yaml: pre-commit, post-commit)
# are present and pre-commit-generated. Checking just hooks/pre-commit would let
# a lone pre-commit hook mask a missing post-commit hook - and post-commit is
# the one that runs sync_claude_skills.py.
function Test-HooksOk {
    foreach ($hook in @('pre-commit', 'post-commit')) {
        $hookPath = git rev-parse --git-path "hooks/$hook"
        if (-not (Test-Path $hookPath)) { return $false }
        if (-not (Select-String -Path $hookPath -Pattern 'pre-commit\.com' -Quiet)) { return $false }
    }
    return $true
}

& $venvPy -m pre_commit --version *> $null
if ($LASTEXITCODE -ne 0) {
    Say "Installing pre-commit into .venv"
    & $venvPy -m pip install --quiet pre-commit
    if ($LASTEXITCODE -ne 0) {
        Die "'pip install pre-commit' failed - see the output above for the reason."
    }
}
if (-not (Test-HooksOk)) {
    Say "Installing git hooks"
    & $venvPy -m pre_commit install *> $null
    if ($LASTEXITCODE -ne 0) {
        Die "'pre-commit install' failed - see the output above for the reason."
    }
}

# --- sync --------------------------------------------------------------
Say "Syncing skills to ~/.claude/skills"
& $venvPy sync_claude_skills.py
if ($LASTEXITCODE -ne 0) {
    Die "sync_claude_skills.py failed - see the output above for the reason."
}

Say "Done - ~/.claude/skills is up to date with origin/$BRANCH."
