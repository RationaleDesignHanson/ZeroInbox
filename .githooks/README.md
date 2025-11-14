# Git Hooks for Zero Inbox

This directory contains git hooks for enforcing code quality and design system standards.

## Pre-commit Hook

**Location**: `.git/hooks/pre-commit`
**Purpose**: Enforces DesignTokens usage, prevents hardcoded design values

### What It Checks

The pre-commit hook scans all staged Swift files in `Zero_ios_2/Zero/Views/` for:

1. **Hardcoded Opacity Values**
   - ❌ `.opacity(0.6)`
   - ✅ `.opacity(DesignTokens.Opacity.textDisabled)`

2. **Hardcoded Corner Radius**
   - ❌ `.cornerRadius(12)`
   - ✅ `.cornerRadius(DesignTokens.Radius.button)`

3. **Hardcoded Padding**
   - ❌ `.padding(16)`
   - ✅ `.padding(DesignTokens.Spacing.component)`

### How It Works

1. Hook runs automatically before each commit
2. Scans only staged View files for violations
3. Shows helpful suggestions for correct tokens
4. Blocks commit if violations found

### Example Output

```bash
🔍 Checking for hardcoded design values...

Checking for hardcoded .opacity() values...

❌ Hardcoded opacity in: Zero_ios_2/Zero/Views/SimpleCardView.swift
   Found: .opacity(0.6)
   Use: DesignTokens.Opacity.textDisabled

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Found 1 file(s) with hardcoded design values.

Please use DesignTokens instead of hardcoded values.

To bypass this check (not recommended):
  git commit --no-verify
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Token Suggestions

The hook provides intelligent suggestions based on the value:

| Value | Suggested Token |
|-------|----------------|
| `0.05` | `DesignTokens.Opacity.glassUltraLight` |
| `0.1` | `DesignTokens.Opacity.glassLight` |
| `0.2` | `DesignTokens.Opacity.overlayLight` |
| `0.3` | `DesignTokens.Opacity.overlayMedium` |
| `0.5` | `DesignTokens.Opacity.overlayStrong` |
| `0.6` | `DesignTokens.Opacity.textDisabled` |
| `0.7` | `DesignTokens.Opacity.textSubtle` |
| `0.8` | `DesignTokens.Opacity.textTertiary` |
| `0.9` | `DesignTokens.Opacity.textSecondary` |
| `1.0` | `DesignTokens.Opacity.textPrimary` |

| Value | Suggested Token |
|-------|----------------|
| `4` | `DesignTokens.Radius.minimal` |
| `8` | `DesignTokens.Radius.chip` |
| `12` | `DesignTokens.Radius.button` |
| `16` | `DesignTokens.Radius.card` |
| `20` | `DesignTokens.Radius.modal` |
| `999` | `DesignTokens.Radius.circle` |

| Value | Suggested Token |
|-------|----------------|
| `4` | `DesignTokens.Spacing.minimal` |
| `6` | `DesignTokens.Spacing.tight` |
| `8` | `DesignTokens.Spacing.inline` |
| `12` | `DesignTokens.Spacing.element` |
| `16` | `DesignTokens.Spacing.component` |
| `20` | `DesignTokens.Spacing.section` |
| `24` | `DesignTokens.Spacing.card` |

### Bypassing the Hook

If you absolutely need to bypass the hook (not recommended):

```bash
git commit --no-verify
```

**Only use this for:**
- Legacy code that will be refactored later
- Third-party code
- Emergency hotfixes (but create a follow-up issue!)

### Installation

The hook is already installed at `.git/hooks/pre-commit`. To reinstall:

```bash
cp .githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Benefits

1. **Consistency**: Enforces design system usage automatically
2. **Education**: Teaches developers the correct tokens
3. **Prevention**: Stops hardcoded values before they enter the codebase
4. **Maintainability**: Makes future design changes easier

### Troubleshooting

**Hook not running?**
- Check that `.git/hooks/pre-commit` exists
- Verify it's executable: `ls -la .git/hooks/pre-commit`
- Make sure you're not using `--no-verify`

**False positives?**
- The hook only checks View files in `Zero_ios_2/Zero/Views/`
- Config files and other code are exempt
- If you have a legitimate use case, document it with a comment

### Future Enhancements

- [ ] Check for hardcoded colors (hex values)
- [ ] Verify font sizes match Typography tokens
- [ ] Lint for consistent spacing between elements
- [ ] Integrate with CI/CD for remote validation
