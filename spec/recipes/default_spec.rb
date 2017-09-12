require 'spec_helper'

describe 'hashicorp_install_test::default' do
  context 'with ubuntu 14.04' do
    let(:platform) { 'ubuntu' }
    let(:version) { '14.04' }
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: platform, version: version)
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
  end
end
