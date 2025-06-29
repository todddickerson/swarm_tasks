require 'spec_helper'

RSpec.describe 'SwarmTasks::VERSION' do
  it 'is defined' do
    expect(SwarmTasks::VERSION).to be_a(String)
  end
  
  it 'follows semantic versioning format' do
    expect(SwarmTasks::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
  
  it 'has major, minor, and patch versions' do
    parts = SwarmTasks::VERSION.split('.')
    expect(parts.length).to eq(3)
    expect(parts).to all(match(/\A\d+\z/))
  end
end