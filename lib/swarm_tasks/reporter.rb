# frozen_string_literal: true

module SwarmTasks
  class Reporter
    def initialize(store)
      @store = store
    end
    
    def generate_report(since: nil, format: :text)
      tasks = @store.list
      
      if since
        cutoff = case since
        when String then Time.parse(since)
        when Time then since
        else raise ArgumentError, "Invalid since parameter"
        end
        
        tasks = tasks.select { |t| t.created_at && t.created_at >= cutoff }
      end
      
      report_data = {
        generated_at: Time.now,
        task_count: tasks.count,
        by_state: @store.statistics,
        recent_completions: recent_completions(tasks),
        effort_summary: effort_summary(tasks)
      }
      
      case format
      when :json
        JSON.pretty_generate(report_data)
      when :text
        format_text_report(report_data)
      else
        raise ArgumentError, "Unknown format: #{format}"
      end
    end
    
    private
    
    def recent_completions(tasks)
      tasks
        .select { |t| t.state == 'completed' }
        .first(10)
        .map(&:to_h)
    end
    
    def effort_summary(tasks)
      by_state = {}
      @store.states.each do |state|
        state_tasks = tasks.select { |t| t.state == state }
        total_effort = state_tasks.map { |t| t.effort || 0 }.sum
        by_state[state] = {
          count: state_tasks.count,
          total_effort: total_effort
        }
      end
      by_state
    end
    
    def format_text_report(data)
      lines = []
      lines << "Task Report"
      lines << "Generated: #{data[:generated_at]}"
      lines << "=" * 40
      lines << ""
      lines << "Summary:"
      lines << "Total Tasks: #{data[:task_count]}"
      lines << ""
      lines << "By State:"
      data[:by_state].each do |state, count|
        lines << "  #{state.capitalize}: #{count}"
      end
      lines << ""
      lines << "Effort Summary:"
      data[:effort_summary].each do |state, info|
        lines << "  #{state.capitalize}: #{info[:count]} tasks, #{info[:total_effort]}h total"
      end
      
      lines.join("\n")
    end
  end
end