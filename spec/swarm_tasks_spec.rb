require 'spec_helper'

RSpec.describe SwarmTasks do
  describe '.config' do
    context 'when config file exists' do
      it 'loads configuration from .swarm_tasks.yml' do
        with_temp_dir do |dir|
          config_content = {
            'tasks_dir' => 'custom_tasks',
            'states' => ['todo', 'doing', 'done'],
            'defaults' => {
              'effort' => 8,
              'tags' => ['feature']
            }
          }
          
          File.write('.swarm_tasks.yml', config_content.to_yaml)
          
          # Clear memoized values
          described_class.instance_variable_set(:@config, nil)
          described_class.instance_variable_set(:@root, nil)
          
          expect(described_class.config).to eq(config_content)
        end
      end
    end
    
    context 'when config file does not exist' do
      it 'returns default configuration' do
        with_temp_dir do
          # Clear memoized values
          described_class.instance_variable_set(:@config, nil)
          described_class.instance_variable_set(:@root, nil)
          
          expect(described_class.config).to eq({
            'tasks_dir' => 'tasks',
            'states' => ['backlog', 'active', 'completed'],
            'defaults' => {
              'effort' => 4,
              'tags' => []
            }
          })
        end
      end
    end
    
    it 'memoizes the configuration' do
      with_temp_dir do
        # Clear memoized values
        described_class.instance_variable_set(:@config, nil)
        described_class.instance_variable_set(:@root, nil)
        
        config1 = described_class.config
        config2 = described_class.config
        
        expect(config1).to be(config2) # Same object reference
      end
    end
  end
  
  describe '.root' do
    context 'when .swarm_tasks.yml exists in current directory' do
      it 'returns current directory' do
        with_temp_dir do
          FileUtils.touch('.swarm_tasks.yml')
          
          # Clear memoized value
          described_class.instance_variable_set(:@root, nil)
          
          expect(described_class.root).to eq(Dir.pwd)
        end
      end
    end
    
    context 'when .swarm_tasks.yml exists in parent directory' do
      it 'returns parent directory containing config file' do
        with_temp_dir do
          parent_dir = Dir.pwd
          FileUtils.touch('.swarm_tasks.yml')
          FileUtils.mkdir('subdirectory')
          
          Dir.chdir('subdirectory') do
            # Clear memoized value
            described_class.instance_variable_set(:@root, nil)
            
            expect(described_class.root).to eq(parent_dir)
          end
        end
      end
    end
    
    context 'when .swarm_tasks.yml does not exist' do
      it 'returns current working directory' do
        with_temp_dir do
          # Clear memoized value
          described_class.instance_variable_set(:@root, nil)
          
          expect(described_class.root).to eq(Dir.pwd)
        end
      end
    end
    
    context 'when searching from deeply nested directory' do
      it 'finds config file in ancestor directory' do
        with_temp_dir do
          root_dir = Dir.pwd
          FileUtils.touch('.swarm_tasks.yml')
          FileUtils.mkdir_p('level1/level2/level3')
          
          Dir.chdir('level1/level2/level3') do
            # Clear memoized value
            described_class.instance_variable_set(:@root, nil)
            
            expect(described_class.root).to eq(root_dir)
          end
        end
      end
    end
    
    it 'memoizes the root directory' do
      with_temp_dir do
        # Clear memoized value
        described_class.instance_variable_set(:@root, nil)
        
        root1 = described_class.root
        root2 = described_class.root
        
        expect(root1).to be(root2) # Same object reference
      end
    end
  end
  
  describe 'Error class' do
    it 'inherits from StandardError' do
      expect(SwarmTasks::Error).to be < StandardError
    end
    
    it 'can be raised with a message' do
      expect { raise SwarmTasks::Error, "Something went wrong" }
        .to raise_error(SwarmTasks::Error, "Something went wrong")
    end
  end
  
  describe 'VERSION constant' do
    it 'is defined' do
      expect(SwarmTasks::VERSION).to be_a(String)
      expect(SwarmTasks::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end
end