require 'spec_helper'

describe 'fixtures' do

  describe 'tmp dir' do

    it 'returns correct directory' do
      expect(Theia.data_path).to match /tmp/
    end

    it 'contains pieces' do
      expect(Dir["#{ Theia.data_path }/*"]).to include(match(/pieces\.yml/))
    end

  end

end
