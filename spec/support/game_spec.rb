module GameSpec
  def self.run_checks(fixture, pieces, cycle)

    describe "Video '#{ fixture.name }', frame ##{cycle}", video: true do
      it 'should have detected the right pieces' do
        frame = fixture.frames[cycle]
        expect( frame.sort ).to eq( pieces.sort )
      end
    end

  end

  def self.start(fixture)
    game = Theia::Mode::GameTest.new(fixture)
    game.start
  end
end
