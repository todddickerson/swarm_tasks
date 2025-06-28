# frozen_string_literal: true

require 'thor'
require 'json'

module SwarmTasks
  class CLI < Thor
    desc "list [STATE]", "List tasks, optionally filtered by state"
    option :json, type: :boolean, desc: "Output in JSON format"
    def list(state = nil)
      store = Store.new
      tasks = store.list(state)
      
      if options[:json]
        puts JSON.pretty_generate(tasks.map(&:to_h))
      else
        if tasks.empty?
          puts "No tasks found"
        else
          table = TTY::Table.new(header: ['Status', 'ID', 'Title', 'Created'])
          
          tasks.each do |task|
            status_color = case task.state
            when 'active' then :yellow
            when 'completed' then :green
            else :white
            end
            
            table << [
              pastel.decorate(task.state.upcase, status_color),
              task.id,
              task.title || 'Untitled',
              task.created_at&.strftime('%Y-%m-%d') || 'Unknown'
            ]
          end
          
          puts table.render(:unicode)
        end
      end
    end
    
    desc "show TASK_ID", "Show details of a specific task"
    def show(task_id)
      store = Store.new
      task = store.find(task_id)
      
      if task
        puts task.content
      else
        error "Task '#{task_id}' not found"
      end
    end
    
    desc "move TASK_ID STATE", "Move a task to a new state"
    def move(task_id, new_state)
      store = Store.new
      
      unless store.valid_state?(new_state)
        error "Invalid state '#{new_state}'. Valid states: #{store.states.join(', ')}"
      end
      
      task = store.find(task_id)
      unless task
        error "Task '#{task_id}' not found"
      end
      
      if task.state == new_state
        puts "Task is already in #{new_state}"
        return
      end
      
      store.move(task, new_state)
      puts "Moved task '#{task_id}' from #{task.state} to #{new_state}"
      
      # Git commit if configured
      if SwarmTasks.config.dig('integrations', 'git_commit_on_move')
        commit_message = SwarmTasks.config.dig('integrations', 'commit_template')
          &.gsub('{{action}}', "moved to #{new_state}")
          &.gsub('{{task_id}}', task_id)
          &.gsub('{{title}}', task.title || 'Untitled') || 
          "Task moved: #{task_id} to #{new_state}"
          
        system("git add -A && git commit -m \"#{commit_message}\"")
      end
    end
    
    desc "create TITLE", "Create a new task"
    option :effort, type: :numeric, desc: "Estimated effort in hours"
    option :tags, type: :array, desc: "Tags for the task"
    def create(title)
      store = Store.new
      task_id = title.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
      filename = "#{Time.now.strftime('%Y-%m-%d')}-#{task_id}"
      
      metadata = {
        'title' => title,
        'created_at' => Time.now.iso8601,
        'effort' => options[:effort] || SwarmTasks.config.dig('defaults', 'effort'),
        'tags' => options[:tags] || SwarmTasks.config.dig('defaults', 'tags') || []
      }
      
      content = <<~MARKDOWN
        ---
        #{metadata.to_yaml.strip}
        ---
        
        # #{title}
        
        ## Description
        
        [Add description here]
        
        ## Acceptance Criteria
        
        - [ ] [Add criteria here]
        
      MARKDOWN
      
      task = Task.new(filename, 'backlog', content)
      store.create(task)
      
      puts "Created task '#{filename}' in backlog"
    end
    
    desc "stats", "Show task statistics"
    def stats
      store = Store.new
      stats = store.statistics
      
      table = TTY::Table.new(header: ['State', 'Count'])
      stats.each do |state, count|
        table << [state.capitalize, count]
      end
      table << :separator
      table << ['Total', stats.values.sum]
      
      puts table.render(:unicode)
    end
    
    desc "version", "Show version"
    def version
      puts "SwarmTasks #{SwarmTasks::VERSION}"
    end
    
    private
    
    def pastel
      @pastel ||= Pastel.new
    end
    
    def error(message)
      puts pastel.red("Error: #{message}")
      exit 1
    end
  end
end