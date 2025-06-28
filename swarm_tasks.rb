# frozen_string_literal: true

require_relative "swarm_tasks/version"
require_relative "swarm_tasks/cli"
require_relative "swarm_tasks/task"
require_relative "swarm_tasks/store"
require_relative "swarm_tasks/reporter"

module SwarmTasks
  class Error < StandardError; end
  
  class << self
    def config
      @config ||= load_config
    end
    
    def root
      @root ||= find_project_root
    end
    
    private
    
    def load_config
      config_path = File.join(root, ".swarm_tasks.yml")
      if File.exist?(config_path)
        require 'yaml'
        YAML.load_file(config_path)
      else
        default_config
      end
    end
    
    def default_config
      {
        "tasks_dir" => "tasks",
        "states" => ["backlog", "active", "completed"],
        "defaults" => {
          "effort" => 4,
          "tags" => []
        }
      }
    end
    
    def find_project_root
      current = Dir.pwd
      while current != "/" && !File.exist?(File.join(current, ".swarm_tasks.yml"))
        current = File.dirname(current)
      end
      
      if File.exist?(File.join(current, ".swarm_tasks.yml"))
        current
      else
        Dir.pwd
      end
    end
  end
end