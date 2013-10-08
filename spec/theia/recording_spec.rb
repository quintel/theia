require 'spec_helper'

describe Recording do

  describe '#frames' do
    context 'with no frames' do
      it 'is empty' do
        expect(Recording.new.frames).to be_empty
      end
    end
    context 'with frames' do
      it 'is not empty' do
        recording = Recording.new
        frame = Frame.new(recording)
        expect(recording.frames).to include(frame)
      end
    end
  end
end
