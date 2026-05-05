# SkwirlsAI Roadmap

## Current State (v0.1 — Completed)
- Local LLM inference via llama.cpp (Gemma 4 models)
- Remote endpoint support (Ollama, OpenAI-compatible)
- Acorn system (custom personas with system prompts, icons, colors)
- Conversation management with search, pin, archive, delete
- RAG: BM25 keyword search + direct file content injection
- Acorn-scoped knowledge base (documents persist across all chats for an acorn)
- File attachment preview chips in chat + attachment indicators on sent messages
- Right-click context menus for desktop UX (acorns, conversations)
- Top-positioned snackbar notifications
- SVL brand theming (dark, amber, teal)
- Model download/management with progress tracking

---

## Tier 1 — Near-term (Next Up)

### 1. Tool Calling Framework
**Status: In Progress**
- Define a `Skill` data model (name, description, parameter schema, execution type)
- Tool call parser: detect JSON tool-call blocks in LLM output
- Tool execution engine: dispatch calls, collect results, feed back to LLM
- Multi-turn tool loop: LLM calls tool → gets result → reasons → calls another or responds
- Safety: confirmation prompts for destructive actions, sandboxed execution
- Built-in tools to ship first:
  - `read_file` — read a file from disk
  - `list_files` — list directory contents
  - `search_knowledge_base` — BM25/semantic search over acorn documents
  - `write_file` — create/overwrite a file (with user confirmation)
  - `web_search` — basic web search (stretch)

### 2. SkwirlSkills Library UI
**Status: Planned**
- SkwirlSkills screen accessible from settings or sidebar
- List all available SkwirlSkills with enable/disable toggles
- Per-acorn SkwirlSkill assignment (which acorns can use which SkwirlSkills)
- SkwirlSkill detail view: name, description, parameters, usage stats
- Visual indicator in chat when a SkwirlSkill is being used

### 3. Embedding Model for RAG
**Status: Planned**
- Integrate a small local embedding model (e.g., all-MiniLM-L6-v2, ~23MB)
- Vector store in Isar (or SQLite with vector extension)
- Cosine similarity search alongside/replacing BM25
- Embed documents at ingestion time
- Embed user queries at search time
- Fallback to BM25 if embedding model not downloaded

---

## Tier 2 — Mid-term

### 4. Self-Creating SkwirlSkills
- LLM can generate new SkwirlSkill definitions (JSON schema + Dart/script execution code)
- User approval flow before registering a new SkwirlSkill
- SkwirlSkill code runs in a sandboxed isolate
- SkwirlSkills persist to disk and load on app start
- SkwirlSkill versioning and update mechanism
- Inspired by: Zo Computer's self-building ClickUp API integration

### 5. Google Workspace SkwirlSkills
- OAuth2 authentication flow (already partially scaffolded)
- Google Sheets SkwirlSkill: read/write/append rows
- Gmail SkwirlSkill: read inbox, draft messages, send (with confirmation)
- Google Calendar SkwirlSkill: read events, create events
- Google Drive SkwirlSkill: list/search/download files

### 6. External API SkwirlSkills
- HTTP request SkwirlSkill (GET/POST/PUT/DELETE with auth headers)
- Telegram Bot API SkwirlSkill (send messages, notifications)
- Generic REST API SkwirlSkill template for user-defined endpoints

---

## Tier 3 — Longer-term

### 7. Background Agent Daemon
- Windows system tray app / Linux systemd service
- App can run headless in background
- Scheduled workflow execution (cron-like)
- Process management: start, stop, monitor background agents
- Resource-aware: pause when system is under load

### 8. Workflow Builder
- Define multi-step agentic workflows (trigger → skills → output)
- Visual or text-based workflow editor
- Workflow templates for common patterns
- Variables and conditional logic between steps
- Example: "Every morning at 8am → web research prospects → add to Google Sheets → draft Gmail → notify via Telegram"

### 9. Notification & Alert Channels
- Telegram bot notifications
- Desktop OS notifications (Windows toast, Linux notify-send)
- Email notifications via Gmail skill
- Webhook support for external integrations

---

## Architecture Notes

### Tool Calling Flow
```
User message → LLM generates response
  → If response contains tool call JSON:
    1. Parse tool name + arguments
    2. Look up skill in registry
    3. Execute skill (with safety checks)
    4. Append tool result to conversation
    5. Send updated context back to LLM
    6. Repeat until LLM gives final answer
  → If no tool call: display response normally
```

### SkwirlSkill Definition Schema
```json
{
  "name": "read_file",
  "description": "Read the contents of a file from disk",
  "parameters": {
    "type": "object",
    "properties": {
      "path": { "type": "string", "description": "Absolute file path" }
    },
    "required": ["path"]
  },
  "execution_type": "built_in",
  "requires_confirmation": false
}
```

### Self-Created SkwirlSkill Schema
```json
{
  "name": "clickup_create_task",
  "description": "Create a task in ClickUp",
  "parameters": { ... },
  "execution_type": "http",
  "endpoint": "https://api.clickup.com/api/v2/list/{list_id}/task",
  "method": "POST",
  "headers": { "Authorization": "{{CLICKUP_API_KEY}}" },
  "body_template": "{ \"name\": \"{{name}}\", \"description\": \"{{description}}\" }",
  "requires_confirmation": true
}
```
