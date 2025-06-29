require 'spec_helper'

RSpec.describe SwarmTasks::Store do
  let(:store) { described_class.new }
  
  before do
    # Clear memoized values
    SwarmTasks.instance_variable_set(:@config, nil)
    SwarmTasks.instance_variable_set(:@root, nil)
  end
  
  describe '#initialize' do
    it 'uses provided root directory' do
      with_temp_dir do |dir|
        custom_root = File.join(dir, 'custom')
        FileUtils.mkdir_p(custom_root)
        store = described_class.new(custom_root)
        expect(store.root).to eq(custom_root)
      end
    end
    
    it 'uses SwarmTasks.root when no root provided' do
      with_temp_dir do
        store = described_class.new
        expect(store.root).to eq(SwarmTasks.root)
      end
    end
    
    it 'loads states from configuration' do
      with_temp_dir do
        config = { 'tasks_dir' => 'spec/fixtures/tasks', 'states' => ['todo', 'doing', 'done'] }
        File.write('.swarm_tasks.yml', config.to_yaml)
        
        store = described_class.new
        expect(store.states).to eq(['todo', 'doing', 'done'])
      end
    end
    
    it 'creates directories for all states' do
      with_temp_dir do
        store = described_class.new
        
        store.states.each do |state|
          expect(Dir.exist?(File.join(SwarmTasks.config['tasks_dir'], state))).to be true
        end
      end
    end
  end
  
  describe '#list' do
    context 'without state parameter' do
      it 'returns all tasks from all states' do
        with_temp_dir do
          store = described_class.new
          
          # Create sample tasks
          create_task('task-001', 'backlog', "---\ntitle: Task 1\ncreated_at: 2024-12-29 10:00:00\n---\n\nBody")
          create_task('task-002', 'active', "---\ntitle: Task 2\ncreated_at: 2024-12-29 11:00:00\n---\n\nBody")
          create_task('task-003', 'completed', "---\ntitle: Task 3\ncreated_at: 2024-12-29 12:00:00\n---\n\nBody")
          create_task('task-004', 'active', "---\ntitle: Task 4\ncreated_at: 2024-12-29 13:00:00\n---\n\nBody")
          
          tasks = store.list
          expect(tasks.map(&:id)).to contain_exactly('task-001', 'task-002', 'task-003', 'task-004')
        end
      end
      
      it 'returns tasks as Task objects' do
        with_temp_dir do
          store = described_class.new
          create_task('task-001', 'backlog', "---\ntitle: Task 1\n---\n\nBody")
          
          tasks = store.list
          expect(tasks).to all(be_a(SwarmTasks::Task))
        end
      end
    end
    
    context 'with state parameter' do
      it 'returns tasks only from specified state' do
        with_temp_dir do
          store = described_class.new
          create_task('task-001', 'backlog', "---\ntitle: Task 1\n---\n\nBody")
          create_task('task-002', 'active', "---\ntitle: Task 2\n---\n\nBody")
          create_task('task-003', 'active', "---\ntitle: Task 3\n---\n\nBody")
          
          tasks = store.list('active')
          expect(tasks.map(&:id)).to contain_exactly('task-002', 'task-003')
        end
      end
      
      it 'returns empty array for state with no tasks' do
        with_temp_dir do
          store = described_class.new
          
          # State directories are created by Store#initialize
          tasks = store.list('backlog')
          expect(tasks).to eq([])
        end
      end
      
      it 'raises error for invalid state' do
        with_temp_dir do
          store = described_class.new
          expect { store.list('invalid') }.to raise_error(ArgumentError, 'Invalid state: invalid')
        end
      end
    end
    
    it 'sorts tasks by created_at in descending order' do
      with_temp_dir do
        store = described_class.new
        create_task('task-001', 'active', "---\ntitle: Task 1\ncreated_at: 2024-12-29 10:00:00\n---\n\nBody")
        create_task('task-002', 'active', "---\ntitle: Task 2\ncreated_at: 2024-12-29 13:00:00\n---\n\nBody")
        
        tasks = store.list('active')
        expect(tasks.map(&:id)).to eq(['task-002', 'task-001'])
      end
    end
    
    it 'handles tasks without created_at' do
      with_temp_dir do
        store = described_class.new
        create_task('task-001', 'backlog', "---\ntitle: No date\n---\n\nBody")
        
        tasks = store.list('backlog')
        expect(tasks.map(&:id)).to include('task-001')
      end
    end
  end
  
  describe '#find' do
    it 'finds task by id' do
      with_temp_dir do
        store = described_class.new
        create_task('task-001', 'active', "---\ntitle: Test Task\n---\n\nBody")
        
        task = store.find('task-001')
        expect(task).to be_a(SwarmTasks::Task)
        expect(task.id).to eq('task-001')
        expect(task.state).to eq('active')
        expect(task.title).to eq('Test Task')
      end
    end
    
    it 'returns nil for non-existent task' do
      with_temp_dir do
        store = described_class.new
        task = store.find('non-existent')
        expect(task).to be_nil
      end
    end
    
    it 'searches across all states' do
      with_temp_dir do
        store = described_class.new
        create_task('task-001', 'backlog', "---\ntitle: Backlog Task\n---\n\nBody")
        create_task('task-002', 'completed', "---\ntitle: Completed Task\n---\n\nBody")
        
        task = store.find('task-002')
        expect(task).not_to be_nil
        expect(task.state).to eq('completed')
      end
    end
  end
  
  describe '#move' do
    it 'moves task file to new state directory' do
      with_temp_dir do
        store = described_class.new
        create_task('task-001', 'backlog', "---\ntitle: Moving Task\n---\n\nBody")
        task = store.find('task-001')
        
        store.move(task, 'active')
        
        expect(File.exist?(File.join(SwarmTasks.config['tasks_dir'], 'backlog', 'task-001.md'))).to be false
        expect(File.exist?(File.join(SwarmTasks.config['tasks_dir'], 'active', 'task-001.md'))).to be true
      end
    end
    
    it 'updates task metadata with new state and timestamp' do
      with_temp_dir do
        store = described_class.new
        create_task('task-001', 'backlog', "---\ntitle: Moving Task\n---\n\nBody")
        task = store.find('task-001')
        
        store.move(task, 'active')
        
        moved_task = store.find('task-001')
        expect(moved_task.content).to include('status: active')
        expect(moved_task.content).to include('updated_at:')
      end
    end
    
    it 'raises error for invalid state' do
      with_temp_dir do
        store = described_class.new
        create_task('task-001', 'backlog', "---\ntitle: Task\n---\n\nBody")
        task = store.find('task-001')
        
        expect { store.move(task, 'invalid') }.to raise_error(ArgumentError, 'Invalid state: invalid')
      end
    end
    
    it 'preserves task content while updating metadata' do
      with_temp_dir do
        store = described_class.new
        create_task('task-001', 'backlog', "---\ntitle: Moving Task\n---\n\nBody")
        task = store.find('task-001')
        
        store.move(task, 'completed')
        moved_task = store.find('task-001')
        
        expect(moved_task.title).to eq('Moving Task')
        expect(moved_task.content).to include('Body')
      end
    end
  end
  
  describe '#create' do
    it 'creates task file in correct state directory' do
      with_temp_dir do
        store = described_class.new
        task = SwarmTasks::Task.new('new-task', 'backlog', "---\ntitle: New Task\n---\n\nContent")
        store.create(task)
        
        expect(File.exist?(File.join(SwarmTasks.config['tasks_dir'], 'backlog', 'new-task.md'))).to be true
      end
    end
    
    it 'writes task content to file' do
      with_temp_dir do
        store = described_class.new
        content = "---\ntitle: New Task\ntags: [test]\n---\n\nTask content"
        task = SwarmTasks::Task.new('new-task', 'active', content)
        store.create(task)
        
        file_content = File.read(File.join(SwarmTasks.config['tasks_dir'], 'active', 'new-task.md'))
        expect(file_content).to eq(content)
      end
    end
  end
  
  describe '#statistics' do
    it 'returns count of tasks per state' do
      with_temp_dir do
        store = described_class.new
        
        # Create tasks in different states
        create_task('task-001', 'backlog', "Content")
        create_task('task-002', 'backlog', "Content")
        create_task('task-003', 'active', "Content")
        create_task('task-004', 'completed', "Content")
        create_task('task-005', 'completed', "Content")
        create_task('task-006', 'completed', "Content")
        
        stats = store.statistics
        
        expect(stats['backlog']).to eq(2)
        expect(stats['active']).to eq(1)
        expect(stats['completed']).to eq(3)
      end
    end
    
    it 'returns zero for empty states' do
      with_temp_dir do
        store = described_class.new
        stats = store.statistics
        
        # All states should exist with count 0
        store.states.each do |state|
          expect(stats[state]).to eq(0)
        end
      end
    end
    
    it 'includes all configured states' do
      with_temp_dir do
        store = described_class.new
        stats = store.statistics
        
        store.states.each do |state|
          expect(stats).to have_key(state)
        end
      end
    end
  end
  
  describe '#valid_state?' do
    before do
      with_temp_dir do
        @store = described_class.new
      end
    end
    
    it 'returns true for valid states' do
      @store.states.each do |state|
        expect(@store.valid_state?(state)).to be true
      end
    end
    
    it 'returns false for invalid states' do
      expect(@store.valid_state?('invalid')).to be false
      expect(@store.valid_state?('unknown')).to be false
      expect(@store.valid_state?(nil)).to be false
    end
  end
  
  private
  
  def create_task(id, state, content)
    dir = File.join(SwarmTasks.config['tasks_dir'], state)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "#{id}.md"), content)
  end
  
  def create_empty_state(state)
    dir = File.join(SwarmTasks.config['tasks_dir'], state)
    FileUtils.mkdir_p(dir)
  end
end