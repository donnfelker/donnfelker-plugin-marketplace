# Linear — platform-specific notes

*Stub — fill this in the first time you run the plan-to-tickets skill against Linear.*

When you do, capture these specifics (mirror the structure of `clickup.md`):

- **MCP tools you'll use**: the exact tool names for create / update / dependency / delete.
- **Description field**: does Linear's create-issue API render markdown by default, or is there a separate field?
- **Status workflow**: Linear uses team-scoped workflow states (e.g., `Backlog`, `Todo`, `In Progress`, `Done`). Exact strings vary per team — confirm with the operator and document them here.
- **Dependency direction**: Linear supports issue relations (`blocks` / `blocked-by` / `related` / `duplicate`). Document which direction to fire calls in and which relation type to use.
- **Subtask / parent-child semantics**: Linear has both sub-issues (true parent-child) and project hierarchies. Pick the right model for the plan's shape.
- **Cycle / project assignment**: Linear issues belong to a team and optionally a project / cycle. Document how to set these on create.
- **Labels**: how to apply labels at create time and whether they need to pre-exist.
- **Rate limits**: any limits hit during a large batch, and what's a safe parallel-batch size.
- **Known quirks**: anything that wasted time on the first run.

Until this file is filled in, fall back to the generic SKILL.md guidance and verify each step against Linear's actual behavior.
