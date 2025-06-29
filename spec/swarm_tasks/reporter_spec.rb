require 'spec_helper'
require 'json'

RSpec.describe SwarmTasks::Reporter do
  let(:store) { SwarmTasks::Store.new }
  let(:reporter) { described_class.new(store) }
  
  before do
    # Clear memoized values
    SwarmTasks.instance_variable_set(:@config, nil)
    SwarmTasks.instance_variable_set(:@root, nil)
  end
  
  describe '#initialize' do
    it 'initializes with a store' do
      expect(reporter.instance_variable_get(:@store)).to eq(store)
    end
  end
  
  describe '#generate_report' do
    
    describe 'text format (default)' do
      it 'generates text report with all sections' do
        with_temp_dir do
          # Create sample tasks with different states and timestamps
          create_task_with_metadata('task-001', 'backlog', {
            'title' => 'Backlog Task 1',
            'created_at' => '2024-12-25 10:00:00',
            'effort' => 4
          })
          
          create_task_with_metadata('task-002', 'backlog', {
            'title' => 'Backlog Task 2',
            'created_at' => '2024-12-26 10:00:00',
            'effort' => 6
          })
          
          create_task_with_metadata('task-003', 'active', {
            'title' => 'Active Task',
            'created_at' => '2024-12-27 10:00:00',
            'effort' => 8
          })
          
          create_task_with_metadata('task-004', 'completed', {
            'title' => 'Completed Task 1',
            'created_at' => '2024-12-28 10:00:00',
            'effort' => 3
          })
          
          create_task_with_metadata('task-005', 'completed', {
            'title' => 'Completed Task 2',
            'created_at' => '2024-12-29 10:00:00',
            'effort' => 5
          })
          
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          report = reporter.generate_report
        
          expect(report).to include('Task Report')
          expect(report).to include('Generated:')
          expect(report).to include('Summary:')
          expect(report).to include('Total Tasks: 5')
          expect(report).to include('By State:')
          expect(report).to include('Backlog: 2')
          expect(report).to include('Active: 1')
          expect(report).to include('Completed: 2')
          expect(report).to include('Effort Summary:')
        end
      end
      
      it 'includes effort totals by state' do
        with_temp_dir do
          create_task_with_metadata('task-001', 'backlog', {'effort' => 4})
          create_task_with_metadata('task-002', 'backlog', {'effort' => 6})
          create_task_with_metadata('task-003', 'active', {'effort' => 8})
          create_task_with_metadata('task-004', 'completed', {'effort' => 3})
          create_task_with_metadata('task-005', 'completed', {'effort' => 5})
          
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          report = reporter.generate_report
        
          expect(report).to include('Backlog: 2 tasks, 10h total')
          expect(report).to include('Active: 1 tasks, 8h total')
          expect(report).to include('Completed: 2 tasks, 8h total')
        end
      end
      
      it 'handles tasks without effort' do
        with_temp_dir do
          create_task_with_metadata('task-001', 'backlog', {'effort' => 10})
          create_task_with_metadata('task-002', 'backlog', {
            'title' => 'No Effort Task',
            'created_at' => '2024-12-30 10:00:00'
          })
          
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          report = reporter.generate_report
          expect(report).to include('Backlog: 2 tasks, 10h total') # no effort = 0
        end
      end
    end
    
    describe 'JSON format' do
      it 'generates JSON report' do
        with_temp_dir do
          create_task_with_metadata('task-001', 'backlog', {'title' => 'Task 1'})
          create_task_with_metadata('task-002', 'active', {'title' => 'Task 2'})
          create_task_with_metadata('task-003', 'completed', {'title' => 'Task 3'})
          
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          report_json = reporter.generate_report(format: :json)
          report = JSON.parse(report_json)
        
          expect(report['task_count']).to eq(3)
          expect(report['by_state']).to eq({
            'backlog' => 1,
            'active' => 1,
            'completed' => 1
          })
          expect(report['recent_completions']).to be_an(Array)
          expect(report['effort_summary']).to be_a(Hash)
        end
      end
      
      it 'includes recent completions' do
        with_temp_dir do
          create_task_with_metadata('task-001', 'completed', {'title' => 'Completed 1'})
          create_task_with_metadata('task-002', 'completed', {'title' => 'Completed 2'})
          
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          report_json = reporter.generate_report(format: :json)
          report = JSON.parse(report_json)
        
          completions = report['recent_completions']
          expect(completions.length).to eq(2)
          expect(completions.map { |t| t['id'] }).to contain_exactly('task-001', 'task-002')
        end
      end
      
      it 'includes effort summary by state' do
        with_temp_dir do
          create_task_with_metadata('task-001', 'backlog', {'effort' => 4})
          create_task_with_metadata('task-002', 'backlog', {'effort' => 6})
          create_task_with_metadata('task-003', 'active', {'effort' => 8})
          create_task_with_metadata('task-004', 'completed', {'effort' => 3})
          create_task_with_metadata('task-005', 'completed', {'effort' => 5})
          
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          report_json = reporter.generate_report(format: :json)
          report = JSON.parse(report_json)
        
          effort = report['effort_summary']
          expect(effort['backlog']).to eq({ 'count' => 2, 'total_effort' => 10 })
          expect(effort['active']).to eq({ 'count' => 1, 'total_effort' => 8 })
          expect(effort['completed']).to eq({ 'count' => 2, 'total_effort' => 8 })
        end
      end
    end
    
    describe 'with since parameter' do
      it 'filters tasks by creation date (string)' do
        with_temp_dir do
          create_task_with_metadata('task-001', 'backlog', {'created_at' => '2024-12-25 10:00:00'})
          create_task_with_metadata('task-002', 'backlog', {'created_at' => '2024-12-27 10:00:00'})
          create_task_with_metadata('task-003', 'active', {'created_at' => '2024-12-28 10:00:00'})
          
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          report = reporter.generate_report(since: '2024-12-27')
        
          expect(report).to include('Total Tasks: 2') # Only tasks from 27th onwards
        end
      end
      
      it 'filters tasks by creation date (Time object)' do
        with_temp_dir do
          create_task_with_metadata('task-001', 'backlog', {'created_at' => '2024-12-27 10:00:00'})
          create_task_with_metadata('task-002', 'active', {'created_at' => '2024-12-28 10:00:00'})
          create_task_with_metadata('task-003', 'completed', {'created_at' => '2024-12-29 10:00:00'})
          
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          cutoff = Time.parse('2024-12-28 00:00:00')
          report = reporter.generate_report(since: cutoff)
        
          expect(report).to include('Total Tasks: 2') # Only tasks from 28th onwards
        end
      end
      
      it 'excludes tasks without created_at' do
        with_temp_dir do
          create_task_with_metadata('task-001', 'backlog', {'created_at' => '2024-12-25 10:00:00'})
          create_task_with_metadata('task-002', 'active', {'created_at' => '2024-12-26 10:00:00'})
          create_task_with_metadata('task-no-date', 'backlog', {
            'title' => 'No Date Task'
          })
          
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          report = reporter.generate_report(since: '2024-12-25')
          expect(report).to include('Total Tasks: 2') # Excludes the no-date task
        end
      end
      
      it 'raises error for invalid since parameter' do
        with_temp_dir do
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          expect { reporter.generate_report(since: 123) }
            .to raise_error(ArgumentError, 'Invalid since parameter')
        end
      end
    end
    
    describe 'with invalid format' do
      it 'raises error for unknown format' do
        with_temp_dir do
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          expect { reporter.generate_report(format: :xml) }
            .to raise_error(ArgumentError, 'Unknown format: xml')
        end
      end
    end
    
    describe 'recent completions' do
      it 'returns maximum 10 most recent completed tasks' do
        with_temp_dir do
          # Create 12 completed tasks
          12.times do |i|
            create_task_with_metadata("completed-#{i}", 'completed', {
              'title' => "Completed Task #{i}",
              'created_at' => "2024-12-#{15 + i} 10:00:00"
            })
          end
          
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          report_json = reporter.generate_report(format: :json)
          report = JSON.parse(report_json)
          
          expect(report['recent_completions'].length).to eq(10)
        end
      end
      
      it 'returns completed tasks ordered by creation date' do
        with_temp_dir do
          create_task_with_metadata('task-001', 'completed', {'created_at' => '2024-12-28 10:00:00'})
          create_task_with_metadata('task-002', 'completed', {'created_at' => '2024-12-29 10:00:00'})
          
          store = SwarmTasks::Store.new
          reporter = described_class.new(store)
          report_json = reporter.generate_report(format: :json)
          report = JSON.parse(report_json)
          
          completions = report['recent_completions']
          # Most recent first
          expect(completions.first['id']).to eq('task-002')
          expect(completions.last['id']).to eq('task-001')
        end
      end
    end
  end
  
  private
  
  def create_task_with_metadata(id, state, metadata)
    content = "---\n#{metadata.to_yaml.strip}\n---\n\nTask body"
    dir = File.join(SwarmTasks.config['tasks_dir'], state)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "#{id}.md"), content)
  end
end