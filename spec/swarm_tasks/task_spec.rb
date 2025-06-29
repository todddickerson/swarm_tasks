require 'spec_helper'

RSpec.describe SwarmTasks::Task do
  describe '#initialize' do
    it 'initializes with id and state' do
      task = described_class.new('task-001', 'backlog')
      expect(task.id).to eq('task-001')
      expect(task.state).to eq('backlog')
    end
    
    it 'initializes with id, state, and content' do
      content = "---\ntitle: Test Task\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      expect(task.id).to eq('task-001')
      expect(task.state).to eq('active')
      expect(task.content).to eq(content)
    end
    
    it 'parses content when provided' do
      content = "---\ntitle: Test Task\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      expect(task.title).to eq('Test Task')
    end
  end
  
  describe '#title' do
    it 'returns title from metadata' do
      content = "---\ntitle: Sample Task\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      expect(task.title).to eq('Sample Task')
    end
    
    it 'returns nil when no metadata' do
      task = described_class.new('task-001', 'active', "Plain content")
      expect(task.title).to be_nil
    end
    
    it 'returns nil when no title in metadata' do
      content = "---\ntags: [ruby]\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      expect(task.title).to be_nil
    end
  end
  
  describe '#created_at' do
    it 'returns parsed time when valid' do
      time_str = '2024-12-29 10:30:00'
      content = "---\ncreated_at: '#{time_str}'\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      expect(task.created_at).to eq(Time.parse(time_str))
    end
    
    it 'returns nil when no created_at' do
      content = "---\ntitle: Test\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      expect(task.created_at).to be_nil
    end
    
    it 'returns nil when created_at is invalid' do
      content = "---\ncreated_at: invalid-date\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      expect(task.created_at).to be_nil
    end
    
    it 'handles date objects in metadata' do
      date = Date.today
      content = "---\ncreated_at: '#{date}'\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      expect(task.created_at).to be_a(Time)
    end
  end
  
  describe '#tags' do
    it 'returns tags array from metadata' do
      content = "---\ntags:\n- ruby\n- testing\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      expect(task.tags).to eq(['ruby', 'testing'])
    end
    
    it 'returns nil when no tags' do
      content = "---\ntitle: Test\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      expect(task.tags).to be_nil
    end
  end
  
  describe '#effort' do
    it 'returns effort from metadata' do
      content = "---\neffort: 8\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      expect(task.effort).to eq(8)
    end
    
    it 'returns nil when no effort' do
      content = "---\ntitle: Test\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      expect(task.effort).to be_nil
    end
  end
  
  describe '#to_h' do
    it 'returns hash with all attributes' do
      content = <<~YAML
        ---
        title: Complete Feature
        created_at: '2024-12-29 10:30:00'
        tags:
        - ruby
        - feature
        effort: 5
        ---
        
        Task description
      YAML
      
      task = described_class.new('task-001', 'active', content)
      hash = task.to_h
      
      expect(hash[:id]).to eq('task-001')
      expect(hash[:state]).to eq('active')
      expect(hash[:title]).to eq('Complete Feature')
      expect(hash[:created_at]).to eq(Time.parse('2024-12-29 10:30:00'))
      expect(hash[:tags]).to eq(['ruby', 'feature'])
      expect(hash[:effort]).to eq(5)
    end
    
    it 'omits nil values from hash' do
      task = described_class.new('task-001', 'active', "Plain content")
      hash = task.to_h
      
      expect(hash).to eq({
        id: 'task-001',
        state: 'active'
      })
    end
  end
  
  describe '#update_metadata' do
    it 'updates existing metadata' do
      content = "---\ntitle: Original Title\n---\n\nTask body"
      task = described_class.new('task-001', 'active', content)
      
      task.update_metadata('title' => 'Updated Title', 'effort' => 3)
      
      expect(task.title).to eq('Updated Title')
      expect(task.effort).to eq(3)
    end
    
    it 'creates metadata when none exists' do
      task = described_class.new('task-001', 'active', "Plain content")
      
      task.update_metadata('title' => 'New Title', 'tags' => ['important'])
      
      expect(task.title).to eq('New Title')
      expect(task.tags).to eq(['important'])
    end
    
    it 'regenerates content with updated metadata' do
      task = described_class.new('task-001', 'active', "Task body")
      
      task.update_metadata('title' => 'Test Task')
      
      expect(task.content).to include("---\ntitle: Test Task\n---")
      expect(task.content).to include("Task body")
    end
    
    it 'merges with existing metadata' do
      content = "---\ntitle: Original\ntags: [ruby]\n---\n\nBody"
      task = described_class.new('task-001', 'active', content)
      
      task.update_metadata('effort' => 5)
      
      expect(task.title).to eq('Original')
      expect(task.tags).to eq(['ruby'])
      expect(task.effort).to eq(5)
    end
  end
  
  describe 'content parsing' do
    context 'with valid YAML frontmatter' do
      it 'parses metadata and body separately' do
        content = "---\ntitle: Test\n---\n\nBody content"
        task = described_class.new('task-001', 'active', content)
        
        expect(task.title).to eq('Test')
        expect(task.instance_variable_get(:@body)).to eq("Body content")
      end
      
      it 'handles multiline body' do
        content = "---\ntitle: Test\n---\n\nLine 1\nLine 2\nLine 3"
        task = described_class.new('task-001', 'active', content)
        
        expect(task.instance_variable_get(:@body)).to eq("Line 1\nLine 2\nLine 3")
      end
    end
    
    context 'with invalid YAML' do
      it 'treats entire content as body' do
        content = "---\ninvalid: yaml: syntax\n---\n\nBody"
        task = described_class.new('task-001', 'active', content)
        
        expect(task.title).to be_nil
        expect(task.instance_variable_get(:@body)).to eq(content)
      end
    end
    
    context 'without frontmatter' do
      it 'treats entire content as body' do
        content = "Just plain text content"
        task = described_class.new('task-001', 'active', content)
        
        expect(task.title).to be_nil
        expect(task.instance_variable_get(:@body)).to eq(content)
      end
    end
    
    context 'with empty content' do
      it 'handles nil content' do
        task = described_class.new('task-001', 'active', nil)
        
        expect(task.title).to be_nil
        expect(task.content).to be_nil
      end
      
      it 'handles empty string content' do
        task = described_class.new('task-001', 'active', '')
        
        expect(task.title).to be_nil
        expect(task.content).to eq('')
      end
    end
  end
end