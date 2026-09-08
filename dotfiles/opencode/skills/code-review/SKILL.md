---
name: code-review
description: Use when the user asks to review a pull request, do a code review, or analyze PR changes. Handles fetching PR diffs via gh CLI and producing structured review feedback locally without writing comments to the PR.
---

# Code Review Skill

## Purpose

Perform thorough code reviews of GitHub pull requests using the `gh` CLI. Produce structured, actionable feedback locally without posting comments to the PR unless explicitly asked.

## Workflow

### 1. Gather PR Metadata

```bash
gh pr view <PR_NUMBER> --json title,body,author,baseRefName,headRefName,additions,deletions,files,commits
```

Extract: title, author, branch names, file count, addition/deletion stats, commit messages.

### 2. Fetch the Full Diff

```bash
gh pr diff <PR_NUMBER>
```

If the diff is large (truncated), the full output is saved to a file. Use `Read` with offset/limit or `Grep` to navigate specific sections.

### 3. Retrieve Commit Messages

```bash
gh pr view <PR_NUMBER> --json commits --jq '.commits[].messageHeadline'
```

### 4. Deep-Dive into Key Files

For complex changes, read the full file content on the PR branch to understand context:

```bash
git show origin/<head-branch>:<file-path>
```

Or view the diff for a specific file:

```bash
git diff origin/<base-branch>...origin/<head-branch> -- <file-path>
```

If the branch is not available locally, rely on the `gh pr diff` output.

### 5. Analyze and Produce Review

Evaluate the changes against the criteria below, then output a structured review.

## Review Criteria

### Correctness
- Logic errors, off-by-one, null safety, race conditions
- Behavioral changes that may be unintentional (e.g., exception handling changes that lose information)
- API contract changes (signature changes, return type changes) and their downstream impact

### Design & Architecture
- Single Responsibility Principle violations
- Module/package placement (does the code live where it belongs?)
- Unnecessary coupling between components
- Breaking changes to public APIs without backward compatibility

### Performance
- Unnecessary allocations, repeated expensive computations
- Missing caching where data is recomputed across iterations
- Spark/distributed computing pitfalls (unnecessary actions, missing cache/persist, double reads)

### Readability & Maintainability
- Naming clarity (variables, methods, classes)
- Method length and complexity
- Dead code or unreachable branches
- Missing or misleading comments

### Testing
- Missing test coverage for new logic or edge cases
- Test quality (clear names, AAA pattern, meaningful assertions)
- Tests that verify implementation details rather than behavior

### Error Handling
- Swallowed exceptions, lost error context
- Missing null/empty checks on external inputs
- Generic catch blocks that hide specific failure modes

### Conventions
- Package naming, file organization
- Commit message quality and structure
- Consistency with existing codebase patterns

## Output Format

Structure the review as follows:

```markdown
## Code Review: PR #<NUMBER> - <TITLE>

**Title:** <title>
**Author:** <author>
**Branch:** `<head>` -> `<base>`
**Stats:** +<additions> / -<deletions> across <file_count> files (<commit_count> commits)

---

### Overall Assessment

<2-3 sentence summary of what the PR does and overall quality judgment>

---

### Issues / Concerns

#### 1. <Short Issue Title>

**File:** `<path/to/file.java>` (line/context reference if applicable)

<Description of the issue, why it matters, and a code snippet showing the problem>

<Suggested fix if applicable>

---

### Minor / Stylistic Notes

- <bullet points for non-blocking observations>

---

### Positives

- <bullet points acknowledging good patterns, clean refactors, or smart decisions>
```

## Guidelines

- Be direct and objective. Focus on technical accuracy over diplomacy.
- Prioritize issues by severity: correctness > security > performance > design > style.
- Always include file paths with enough context to locate the issue.
- Show code snippets for non-obvious issues.
- Acknowledge good work briefly - don't pad the review with praise.
- If the PR is purely mechanical (renames, formatting, dependency bumps), say so and keep the review short.
- For large PRs (50+ files), group findings by theme rather than listing per-file.
- Flag behavioral changes that are disguised as refactoring.
- Never post comments to the PR unless the user explicitly requests it.
