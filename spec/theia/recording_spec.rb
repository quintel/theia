require 'spec_helper'

describe Recording do

  let(:recording) { Recording.new }

  describe '#frames' do

    context 'with no frames' do

      it 'is empty' do
        expect(Recording.new.frames).to be_empty
      end

    end

    context 'with frames' do

      it 'is not empty' do
        frame = Frame.new(recording)
        expect(recording.frames).to include(frame)
      end

      it 'ditches frames when it hits MAX_FRAMES' do
        recording = Recording.new
        frame = Frame.new(recording)
        Recording::MAX_FRAMES.times { Frame.new(recording) }
        expect(recording.frames).to_not include frame
      end

    end

  end

end
