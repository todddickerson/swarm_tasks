# SwarmTasks

A simple, directory-based task management system designed for AI agents and human developers. Perfect for Claude Swarm projects and any project that needs lightweight task tracking.

## Features

- 📁 **Directory-based organization** - Tasks are just files in folders (backlog/active/completed)
- 🤖 **AI-friendly** - Simple CLI with JSON output for autonomous agents
- 🔄 **Git-friendly** - All changes are tracked as file movements
- 🚀 **Zero dependencies** - Works with basic Ruby installation
- 🎯 **Simple and focused** - Does one thing well

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'swarm_tasks'
```

Or install it yourself as:

```bash
$ gem install swarm_tasks
```

## Usage

### Basic Commands

```bash
# List all tasks
swarm-tasks list

# List tasks by state
swarm-tasks list backlog
swarm-tasks list active
swarm-tasks list completed

# Move a task between states
swarm-tasks move my-task-id active
swarm-tasks move my-task-id completed

# Show task details
swarm-tasks show my-task-id

# Get statistics
swarm-tasks stats

# JSON output for AI agents
swarm-tasks list --json
```

### Directory Structure

```
tasks/
├── backlog/      # Tasks not yet started
├── active/       # Tasks currently being worked on
└── completed/    # Finished tasks
```

### Task File Format

Tasks are markdown files with optional YAML front matter:

```markdown
---
title: "Implement user authentication"
created_at: 2025-06-28T10:00:00Z
effort: 4
tags: [backend, security]
---

## Description
Implement secure user authentication system...

## Acceptance Criteria
- [ ] Users can sign up
- [ ] Users can log in
- [ ] Passwords are securely hashed
```

### Configuration

Create a `.swarm_tasks.yml` file in your project root:

```yaml
# Directory containing task folders
tasks_dir: "tasks"

# Task states (first is default for new tasks)
states:
  - backlog
  - active
  - completed

# Optional: Default values for new tasks
defaults:
  effort: 4
  tags: []

# Optional: Git integration
integrations:
  git_commit_on_move: true
  commit_template: "Task {{action}}: {{task_id}} - {{title}}"
```

## For Claude Swarm / AI Agents

This gem is designed to work seamlessly with AI agents:

```bash
# Get all active tasks as JSON
swarm-tasks list active --json

# Move task when starting work
swarm-tasks move implement-feature active

# Move task when done
swarm-tasks move implement-feature completed
```

The JSON output includes all task metadata for easy parsing by agents.

### Example Integration

See the `examples/` directory for sample configurations:
- `examples/CLAUDE.md` - Sample instructions for AI agents
- `examples/claude-swarm.yml` - Sample swarm configuration showing task integration

These examples demonstrate how to integrate swarm_tasks into your Claude Swarm workflow for autonomous task management.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/anthropics/swarm_tasks.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).