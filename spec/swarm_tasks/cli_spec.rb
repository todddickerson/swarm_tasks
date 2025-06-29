require 'spec_helper'
require 'tty-table'

RSpec.describe SwarmTasks::CLI do
  let(:cli) { described_class.new }
  
  before do
    # Clear memoized values
    SwarmTasks.instance_variable_set(:@config, nil)
    SwarmTasks.instance_variable_set(:@root, nil)
  end
  
  describe '#list' do
    context 'with tasks' do
      it 'lists all tasks in table format' do
        with_temp_dir do
          create_sample_task('task-001', 'backlog', 'Task 1', '2024-12-29 10:00:00')
          create_sample_task('task-002', 'active', 'Task 2', '2024-12-29 11:00:00')
          create_sample_task('task-003', 'completed', 'Task 3', '2024-12-29 12:00:00')
          
          # Stub TTY Screen methods
          allow(TTY::Screen).to receive(:width).and_return(80)
          
          output = capture_stdout { cli.list }
          
          expect(output).to include('Status')
          expect(output).to include('ID')
          expect(output).to include('Title')
          expect(output).to include('Created')
          expect(output).to include('task-001')
          expect(output).to include('task-002')
          expect(output).to include('task-003')
          expect(output).to include('Task 1')
          expect(output).to include('Task 2')
          expect(output).to include('Task 3')
        end
      end
      
      it 'lists tasks for specific state' do
        with_temp_dir do
          create_sample_task('task-001', 'backlog', 'Task 1')
          create_sample_task('task-002', 'active', 'Task 2')
          create_sample_task('task-003', 'completed', 'Task 3')
          
          # Stub TTY Screen methods
          allow(TTY::Screen).to receive(:width).and_return(80)
          
          output = capture_stdout { cli.list('active') }
          
          expect(output).to include('task-002')
          expect(output).to include('Task 2')
          expect(output).not_to include('task-001')
          expect(output).not_to include('task-003')
        end
      end
      
      it 'outputs JSON when json option is set' do
        with_temp_dir do
          create_sample_task('task-001', 'backlog', 'Task 1')
          create_sample_task('task-002', 'active', 'Task 2')
          create_sample_task('task-003', 'completed', 'Task 3')
          
          cli.options = { json: true }
          output = capture_stdout { cli.list }
          
          json = JSON.parse(output)
          expect(json).to be_an(Array)
          expect(json.length).to eq(3)
          expect(json.map { |t| t['id'] }).to contain_exactly('task-001', 'task-002', 'task-003')
        end
      end
    end
    
    context 'without tasks' do
      it 'displays no tasks message' do
        with_temp_dir do
          output = capture_stdout { cli.list }
          expect(output).to include('No tasks found')
        end
      end
    end
    
    it 'handles invalid state gracefully' do
      with_temp_dir do
        expect { cli.list('invalid') }.to raise_error(ArgumentError, /Invalid state/)
      end
    end
  end
  
  describe '#show' do
    it 'displays task content' do
      with_temp_dir do
        content = "---\ntitle: Test Task\n---\n\nTask content here"
        create_task_with_content('task-001', 'active', content)
        
        output = capture_stdout { cli.show('task-001') }
        
        expect(output).to include('title: Test Task')
        expect(output).to include('Task content here')
      end
    end
    
    it 'shows error for non-existent task' do
      expect { cli.show('non-existent') }.to raise_error(SystemExit)
      
      output = capture_stdout do
        begin
          cli.show('non-existent')
        rescue SystemExit
        end
      end
      
      expect(output).to include("Error: Task 'non-existent' not found")
    end
  end
  
  describe '#move' do
    it 'moves task to new state' do
      with_temp_dir do
        create_sample_task('task-001', 'backlog', 'Test Task')
        
        output = capture_stdout { cli.move('task-001', 'active') }
        
        expect(output).to include("Moved task 'task-001' from backlog to active")
        
        # Verify task was moved
        expect(File.exist?(File.join(SwarmTasks.config['tasks_dir'], 'active', 'task-001.md'))).to be true
        expect(File.exist?(File.join(SwarmTasks.config['tasks_dir'], 'backlog', 'task-001.md'))).to be false
      end
    end
    
    it 'shows error for invalid state' do
      with_temp_dir do
        create_sample_task('task-001', 'backlog', 'Test Task')
        
        expect { cli.move('task-001', 'invalid') }.to raise_error(SystemExit)
        
        output = capture_stdout do
          begin
            cli.move('task-001', 'invalid')
          rescue SystemExit
          end
        end
        
        expect(output).to include("Error: Invalid state 'invalid'")
        expect(output).to include("Valid states:")
      end
    end
    
    it 'shows error for non-existent task' do
      with_temp_dir do
        expect { cli.move('non-existent', 'active') }.to raise_error(SystemExit)
      end
    end
    
    it 'handles task already in target state' do
      with_temp_dir do
        create_sample_task('task-001', 'backlog', 'Test Task')
        
        output = capture_stdout { cli.move('task-001', 'backlog') }
        expect(output).to include('Task is already in backlog')
      end
    end
    
    context 'with git integration' do
      it 'creates git commit when configured' do
        config = {
          'tasks_dir' => 'spec/fixtures/tasks',
          'states' => ['backlog', 'active', 'completed'],
          'integrations' => {
            'git_commit_on_move' => true,
            'commit_template' => 'Task {{task_id}}: {{action}} - {{title}}'
          }
        }
        File.write('.swarm_tasks.yml', config.to_yaml)
        
        # Clear config cache
        SwarmTasks.instance_variable_set(:@config, nil)
        
        expect(cli).to receive(:system).with(/git add -A && git commit/)
        cli.move('task-001', 'active')
      end
    end
  end
  
  describe '#create' do
    it 'creates new task with title' do
      with_temp_dir do
        output = capture_stdout { cli.create('New Feature Task') }
        
        expect(output).to match(/Created task '.*new-feature-task' in backlog/)
        
        # Verify task was created
        store = SwarmTasks::Store.new
        tasks = store.list('backlog')
        expect(tasks.length).to eq(1)
        expect(tasks.first.title).to eq('New Feature Task')
      end
    end
    
    it 'generates task id from title' do
      with_temp_dir do
        cli.create('Complex Task: With Special Characters!')
        
        store = SwarmTasks::Store.new
        tasks = store.list('backlog')
        expect(tasks.first.id).to match(/^\d{4}-\d{2}-\d{2}-complex-task-with-special-characters$/)
      end
    end
    
    it 'includes effort option' do
      with_temp_dir do
        cli.options = { effort: 8 }
        cli.create('Task with effort')
        
        store = SwarmTasks::Store.new
        task = store.list('backlog').first
        expect(task.effort).to eq(8)
      end
    end
    
    it 'includes tags option' do
      with_temp_dir do
        cli.options = { tags: ['feature', 'urgent'] }
        cli.create('Task with tags')
        
        store = SwarmTasks::Store.new
        task = store.list('backlog').first
        expect(task.tags).to eq(['feature', 'urgent'])
      end
    end
    
    it 'uses default configuration values' do
      with_temp_dir do
        config = {
          'tasks_dir' => 'spec/fixtures/tasks',
          'states' => ['backlog', 'active', 'completed'],
          'defaults' => {
            'effort' => 6,
            'tags' => ['default-tag']
          }
        }
        File.write('.swarm_tasks.yml', config.to_yaml)
        SwarmTasks.instance_variable_set(:@config, nil)
        
        cli.create('Task with defaults')
        
        store = SwarmTasks::Store.new
        task = store.list('backlog').first
        expect(task.effort).to eq(6)
        expect(task.tags).to eq(['default-tag'])
      end
    end
    
    it 'creates task with template content' do
      with_temp_dir do
        cli.create('New Task')
        
        store = SwarmTasks::Store.new
        task = store.list('backlog').first
        expect(task.content).to include('# New Task')
        expect(task.content).to include('## Description')
        expect(task.content).to include('## Acceptance Criteria')
        expect(task.content).to include('- [ ]')
      end
    end
  end
  
  describe '#stats' do
    it 'displays statistics table' do
      with_temp_dir do
        create_sample_task('task-001', 'backlog', 'Task 1')
        create_sample_task('task-002', 'backlog', 'Task 2')
        create_sample_task('task-003', 'active', 'Task 3')
        create_sample_task('task-004', 'completed', 'Task 4')
        create_sample_task('task-005', 'completed', 'Task 5')
        create_sample_task('task-006', 'completed', 'Task 6')
        
        # Stub TTY Screen methods
        allow(TTY::Screen).to receive(:width).and_return(80)
        
        output = capture_stdout { cli.stats }
        
        expect(output).to include('State')
        expect(output).to include('Count')
        expect(output).to include('Backlog')
        expect(output).to include('2')
        expect(output).to include('Active')
        expect(output).to include('1')
        expect(output).to include('Completed')
        expect(output).to include('3')
        expect(output).to include('Total')
        expect(output).to include('6')
      end
    end
  end
  
  describe '#version' do
    it 'displays version' do
      output = capture_stdout { cli.version }
      expect(output).to include("SwarmTasks #{SwarmTasks::VERSION}")
    end
  end
  
  private
  
  def create_sample_task(id, state, title, created_at = nil)
    metadata = { 'title' => title }
    metadata['created_at'] = created_at if created_at
    
    content = "---\n#{metadata.to_yaml.strip}\n---\n\nTask body"
    create_task_with_content(id, state, content)
  end
  
  def create_task_with_content(id, state, content)
    dir = File.join(SwarmTasks.config['tasks_dir'], state)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "#{id}.md"), content)
  end
end