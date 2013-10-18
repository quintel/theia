module GameSpec
  def self.run_checks(fixture, pieces, cycle)
    puts "Running checks"
    @@spec.describe "Frame ##{cycle}" do
      it 'should have detected the right pieces' do
        expect( fixture.sort ).to eq( pieces.sort )
      end
    end
  end

  def self.start(fixture, spec)
    @@spec = spec
    game = Theia::Mode::GameTest.new(fixture)
    game.start
  end
end
