# frozen_string_literal: true

require 'yaml'
require 'time'

module SwarmTasks
  class Task
    attr_reader :id, :state, :content
    
    def initialize(id, state, content = nil)
      @id = id
      @state = state
      @content = content
      parse_content if content
    end
    
    def title
      @metadata['title'] if @metadata
    end
    
    def created_at
      return nil unless @metadata && @metadata['created_at']
      Time.parse(@metadata['created_at'].to_s)
    rescue
      nil
    end
    
    def tags
      @metadata['tags'] if @metadata
    end
    
    def effort
      @metadata['effort'] if @metadata
    end
    
    def to_h
      {
        id: @id,
        state: @state,
        title: title,
        created_at: created_at,
        tags: tags,
        effort: effort
      }.compact
    end
    
    def update_metadata(updates)
      @metadata ||= {}
      @metadata.merge!(updates)
      regenerate_content
    end
    
    private
    
    def parse_content
      return unless @content
      
      if @content =~ /\A---\s*\n(.*?)\n---\s*\n(.*)/m
        begin
          @metadata = YAML.safe_load($1) || {}
          @body = $2
        rescue
          @metadata = {}
          @body = @content
        end
      else
        @metadata = {}
        @body = @content
      end
    end
    
    def regenerate_content
      if @metadata && !@metadata.empty?
        @content = "---\n#{@metadata.to_yaml.strip}\n---\n\n#{@body}"
      else
        @content = @body
      end
    end
  end
end