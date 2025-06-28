# frozen_string_literal: true

require 'fileutils'

module SwarmTasks
  class Store
    attr_reader :root, :states
    
    def initialize(root = nil)
      @root = root || SwarmTasks.root
      @tasks_dir = File.join(@root, SwarmTasks.config['tasks_dir'])
      @states = SwarmTasks.config['states']
      ensure_directories
    end
    
    def list(state = nil)
      if state
        raise ArgumentError, "Invalid state: #{state}" unless valid_state?(state)
        list_tasks_in_state(state)
      else
        @states.flat_map { |s| list_tasks_in_state(s) }
      end
    end
    
    def find(task_id)
      @states.each do |state|
        path = File.join(@tasks_dir, state, "#{task_id}.md")
        if File.exist?(path)
          content = File.read(path)
          return Task.new(task_id, state, content)
        end
      end
      nil
    end
    
    def move(task, new_state)
      raise ArgumentError, "Invalid state: #{new_state}" unless valid_state?(new_state)
      
      old_path = File.join(@tasks_dir, task.state, "#{task.id}.md")
      new_path = File.join(@tasks_dir, new_state, "#{task.id}.md")
      
      FileUtils.mv(old_path, new_path)
      
      # Update metadata
      task.update_metadata('status' => new_state, 'updated_at' => Time.now.iso8601)
      File.write(new_path, task.content)
    end
    
    def create(task)
      path = File.join(@tasks_dir, task.state, "#{task.id}.md")
      File.write(path, task.content)
    end
    
    def statistics
      stats = {}
      @states.each do |state|
        dir = File.join(@tasks_dir, state)
        stats[state] = Dir.glob(File.join(dir, "*.md")).count
      end
      stats
    end
    
    def valid_state?(state)
      @states.include?(state)
    end
    
    private
    
    def ensure_directories
      @states.each do |state|
        dir = File.join(@tasks_dir, state)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      end
    end
    
    def list_tasks_in_state(state)
      dir = File.join(@tasks_dir, state)
      return [] unless Dir.exist?(dir)
      
      Dir.glob(File.join(dir, "*.md")).map do |file|
        id = File.basename(file, ".md")
        content = File.read(file)
        Task.new(id, state, content)
      end.sort_by { |t| t.created_at || Time.at(0) }.reverse
    end
  end
end