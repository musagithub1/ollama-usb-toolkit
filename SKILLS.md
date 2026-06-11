# Creating Custom Skills for Claw

## Quick Start: Build Your First Skill in 5 Minutes

### Step 1: Create the Skill Folder
```bash
mkdir skills/hello-world
```

### Step 2: Create SKILL.md
```markdown
# Hello World Skill

When the user asks you to greet someone, use this skill.

Command: `greet --name "Alice"`
Returns: A personalized greeting
```

### Step 3: Create skill.py
```python
def greet(name):
    return f"Hello, {name}! Welcome to Claw!"
```

### Step 4: Register in config/agent.json
```json
{
  "enabled_skills": ["hello-world"]
}
```

### Step 5: Restart and Test
Run the toolkit and ask: "Can you greet my friend Alice?"

## Advanced: Skills with External APIs
Skills can:

- Read/write local files
- Run Python code
- Execute whitelisted shell commands
- Access system info

But NEVER:

- Make network requests (sandbox blocks this)
- Write outside the USB folder
- Execute unapproved commands

## Sharing Skills
Submit your skills to the GitHub repo:

1. Fork the toolkit
2. Add your skill to `skills/`
3. Include documentation
4. Open a PR
