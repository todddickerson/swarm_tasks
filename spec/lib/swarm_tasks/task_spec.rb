# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SwarmTasks::Task do
  describe 'frontmatter handling' do
    let(:task_id) { 'test-123' }
    let(:initial_state) { 'todo' }
    let(:new_state) { 'in-progress' }

    context 'when moving a task between buckets' do
      it 'does not duplicate frontmatter delimiters' do
        # Task content with frontmatter

        # Create content with frontmatter - manually to avoid YAML delimiter issues
        content = "---\ntitle: Test Task\ncreated_at: '2025-06-29T05:54:00-05:00'\ntags:\n  - test\n  - frontmatter\neffort: 2\n---\n\nThis is a test task content."

        # Create the task
        task = described_class.new(task_id, initial_state, content)

        # Verify initial content has correct frontmatter
        expect(task.title).to eq('Test Task')
        expect(task.tags).to eq(['test', 'frontmatter'])
        expect(task.effort).to eq(2)

        # Count delimiters in initial content
        initial_delimiter_count = task.content.scan('---').size
        puts "Initial delimiter count: #{initial_delimiter_count}"

        # Update metadata to simulate moving to a new state
        task.update_metadata('status' => new_state, 'updated_at' => Time.now.iso8601)

        # Count delimiters after update
        updated_delimiter_count = task.content.scan('---').size
        puts "Updated delimiter count: #{updated_delimiter_count}"
        puts "Content after update:\n#{task.content}"

        # Verify content after update
        expect(updated_delimiter_count).to eq(initial_delimiter_count) # Same number of delimiters
        expect(task.content).to include('Test Task') # Title preserved
        expect(task.content).to include('test') # Tags preserved
        expect(task.content).to include('frontmatter') # Tags preserved
        expect(task.content).to include('effort: 2') # Effort preserved
        expect(task.content).to include('This is a test task content.') # Body preserved
      end
    end
  end
end