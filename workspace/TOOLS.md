# Tools — user notes

Built-in tools available to the agent (function-calling):

| Tool          | Purpose                                                   |
|---------------|-----------------------------------------------------------|
| `read_file`   | Read a UTF-8 text file from the USB                       |
| `write_file`  | Create / overwrite a text file inside `workspace/`        |
| `list_dir`    | List files in a directory                                 |
| `run_shell`   | Run a shell command (sandboxed allow-list by default)     |
| `remember`    | Append a durable fact to `MEMORY.md`                      |
| `recall`      | Search `MEMORY.md` and daily notes for a keyword          |
| `current_time`| Get current local time / date                             |
| `system_info` | OS / RAM / CPU / GPU summary                              |

Add or remove notes here freely; this file is just guidance for the agent.
