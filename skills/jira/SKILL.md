---
name: jira
description: Fetch a Jira issue and work out an approach for it together with the user. Use when the user names a Jira issue key (TEST-123) or types /jira.
argument-hint: <ISSUE-KEY>
allowed-tools: Bash(jira issue view:*), Read, Grep, Glob, Write
---

# Jira issue to shared plan

Turn a Jira issue into an approach the user has agreed to: fetch it, understand it, look at the actual code, then plan **with** the user. Do not start implementing — that is `/implement`'s job.

## 1. Validate the key

The issue key arrives as `$ARGUMENTS`. Accept it only if it matches `^[A-Z][A-Z0-9]*-[0-9]+$`.

Argument substitution is not shell-escaped, so an unchecked key reaches the shell verbatim — `TEST-1; rm -rf .` would run. Pass the key to `jira` as a single argument and never assemble a command string around it.

If no key was given, or it fails the check, ask for one. Never guess a key and never list issues to find a likely candidate.

## 2. Fetch it

```bash
jira issue view <KEY> --plain --comments 10
```

`--plain` is the readable form and enough for most tickets. Add `--raw` only when you need exact field values (epic link, team, target dates) and pull those with `jq` instead of reading the whole JSON — the custom field ids live in the user's jira-cli config.

This skill is read-only. `jira issue view` is the only subcommand it may run.

## 3. When the fetch fails

Never hand back the raw error. jira-cli reports HTTP failures as `Received unexpected response '<code> '`, which on its own tells the user nothing. Map it:

| Symptom | Cause | What to tell the user |
| --- | --- | --- |
| Connection refused, timeout, DNS failure | The Jira host is on an internal network | Connect the VPN, then retry |
| `401`, or `429` with no other explanation | `JIRA_API_TOKEN` is missing or expired — some instances answer an unauthenticated request with a rate-limit code instead of 401 | Check that the variable is set in the current shell, create a new personal access token if it expired, put it in `~/.secrets.zsh`, open a new shell |
| `404`, usually with `Issue Does Not Exist` | Wrong key, or no permission for that project | Confirm the key; ask whether they can open it in the browser |
| `jira: command not found`, or no config file | jira-cli is not set up on this machine | `brew bundle`, then `jira init` against the Jira server |

A repeated `429` on an authenticated request is a real rate limit: wait rather than retry in a loop.

## 4. Summarise, and name what is missing

Report compactly: type, status, assignee, epic or parent, description, acceptance criteria, linked and blocking issues, and any comment that changed the direction of the ticket.

Then the part that matters most: state what the ticket does **not** settle. Missing acceptance criteria, a description that contradicts the comments, undefined domain terms, no scope boundary, no definition of done. This list is what the planning conversation in step 6 is for.

## 5. Look at the code

Derive search terms from the ticket — components, class and file names, domain vocabulary, error strings — and locate the affected code with Grep and Glob. Read the files that look central.

The goal is a plan that names real paths and reuses functions that already exist, not a list of generic steps. Say which files you expect to change and which ones you only read to understand the area.

If the current directory has nothing to do with the ticket, say so and ask which repository to look at. Do not invent a connection.

## 6. Plan together

- Ask at most three questions at a time, and only where different answers lead to different work. Do not ask what the ticket or the code already answers.
- Where there is a genuine fork, give two options with their trade-off and a recommendation — not an exhaustive survey.
- Then propose ordered steps. Each step names the files it touches and how to verify it. Call out the risky step explicitly.
- Keep the plan in the conversation. Do not write code in this skill.

When the user is happy with the plan, make two offers:

- Save it as `docs/plans/<KEY>.md` in the current repository. Confirm the path first, and keep the issue key and a one-line summary at the top so the file is findable later.
- Hand over to `/implement` to carry the plan out.

## Never write to Jira

No comments, no transitions, no assignee changes, no worklogs — not even when asked directly. Say that the skill is read-only by design and let the user do it themselves. `allowed-tools` permits only `jira issue view`, so a write attempt fails anyway.
