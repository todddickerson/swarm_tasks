# CLAUDE.md - Example Project Instructions for Claude Swarm

## Task Management Process

This project uses SwarmTasks for task management. All tasks are tracked by their location in the filesystem:
- `tasks/backlog/` - Tasks not yet started
- `tasks/active/` - Tasks currently being worked on
- `tasks/completed/` - Finished tasks

### Working with Tasks - Use the `swarm-tasks` Command
```bash
# List tasks
bundle exec swarm-tasks list          # Show all tasks
bundle exec swarm-tasks list active   # Show active tasks
bundle exec swarm-tasks list backlog  # Show backlog

# Move tasks between states
bundle exec swarm-tasks move <task-id> active     # Start working on a task
bundle exec swarm-tasks move <task-id> completed  # Mark task as done

# View task details
bundle exec swarm-tasks show <task-id>

# Get statistics
bundle exec swarm-tasks stats

# Create new tasks
bundle exec swarm-tasks create "Task Title" --effort 4 --tags backend,api

# For AI agents - use JSON output
bundle exec swarm-tasks list active --json
```

### For Swarm Agents
1. **Check for tasks**: `bundle exec swarm-tasks list active --json`
2. **Start a task**: `bundle exec swarm-tasks move <task-id> active`
3. **Complete a task**: `bundle exec swarm-tasks move <task-id> completed`
4. **Commit and push changes**: 
   ```bash
   git add -A
   git commit -m "Complete task: <task-id> - <description>"
   git push origin main  # or feature branch
   ```
5. **Never use manual mv commands** - always use the swarm-tasks gem

## Development Guidelines

### Git Workflow
Always commit and push after completing tasks. Use descriptive commit messages that reference the task ID.

### Testing
Run tests before marking a task as completed. Fix any failures.