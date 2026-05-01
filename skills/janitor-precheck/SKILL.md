---
name: janitor-precheck
description: "Check if a new skill overlaps with your existing ones before installing. Use when the user wants to evaluate a skill before adding it, check for duplicates pre-install, or verify a GitHub skill won't conflict."
metadata:
  version: 2.0.0
---

# Pre-Install Overlap Check

Check if a new skill would duplicate existing ones before installing it.

## Important: Ask for input first

If the user did not provide a GitHub URL or local path, ASK them before running the script:
"Which skill do you want to check? Give me a GitHub URL (e.g. `https://github.com/user/repo/tree/main/skills/skill-name`) or a local path."

Do NOT run the script without a source argument.

The `<scripts_dir>` is the `scripts/` directory next to the `skills/` folder that contains this skill.

## How to Run

```bash
bash <scripts_dir>/precheck.sh <github-url-or-path> [--json]
```

## Accepted input formats

- GitHub skill folder URL: `https://github.com/user/repo/tree/main/skills/skill-name`
- GitHub repo root (single SKILL.md): `https://github.com/user/my-skill`
- Local path: `~/path/to/skill/`

## How It Works

1. Fetches the SKILL.md from the given GitHub URL or local path
2. Extracts description and trigger keywords
3. Compares against all installed skills using Jaccard similarity
4. Reports overlap level:
   - **0-30%**: Safe to install, no significant overlap
   - **30-60%**: Moderate overlap, review before installing
   - **60%+**: High overlap, likely duplicate of existing skill

## Output

```
=== Skills Janitor - Pre-Install Check ===

  Checking: marketing-seo-v2
  Keywords: seo, audit, ranking, technical, meta, tags

  Scanned 35 installed skills

  --- HIGH OVERLAP (likely duplicates) ---
    [72%] marketing-seo-audit (user)
         Shared: seo, audit, ranking, meta
         Existing desc: audit seo issues on your site...

  VERDICT: High overlap detected - likely duplicate
```

## After Checking

- If HIGH overlap: consider using the existing skill instead
- If MODERATE overlap: review both descriptions to see if they serve different purposes
- If SAFE: go ahead and install

## Related Skills

- For checking existing duplicates: `/janitor-report`
- For full inventory: `/janitor-audit`
