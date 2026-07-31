# Tools

The repository includes a tools registry for agent-compatible marketing tools.

## Registry

```
tools/
├── REGISTRY.md              # Index of all tools with capabilities
├── clis/                    # Zero-dependency Node.js CLI tools (Node 18+)
├── composio/                # Composio integration layer
└── integrations/            # Detailed per-tool integration guides
    ├── ga4.md
    ├── stripe.md
    ├── rewardful.md
    └── ...
```

- **Tool discovery** — read `tools/REGISTRY.md` for available tools and capabilities.
- **Integration details** — see `tools/integrations/{tool}.md` for API endpoints,
  auth, and common operations.

## CLI Tools

`tools/clis/*.js` are zero-dependency Node.js scripts (Node 18+). Verify them with:

```bash
node --check tools/clis/<name>.js          # syntax check
node tools/clis/<name>.js                   # show usage (no args = help)
node tools/clis/<name>.js <cmd> --dry-run   # preview request without sending
```

## MCP-Enabled Tools

Native MCP servers exist for: ga4, stripe, mailchimp, google-ads, resend, zapier,
zoominfo, clay, supermetrics, coupler, outreach, crossbeam, introw, composio.

## Composio (Integration Layer)

For tools without native MCP servers — HubSpot, Salesforce, Meta Ads, LinkedIn Ads,
Google Sheets, Slack, Notion — **Composio** provides MCP access via a single server.

- Setup: `tools/integrations/composio.md`
- Full toolkit mapping: `tools/composio/marketing-tools.md`

## How Skills Use Tools

Skills reference relevant tools for implementation, for example:

- `referrals` → rewardful, tolt, dub-co, mention-me
- `analytics` → ga4, mixpanel, segment
- `emails` → customer-io, mailchimp, resend
- `ads` → google-ads, meta-ads, linkedin-ads
