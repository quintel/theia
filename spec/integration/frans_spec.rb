require 'spec_helper'

describe '"frans" integration test', :integration do
  let(:capture) { Theia::Spec::ImageCapture.new('spec/fixtures/frans') }

  it 'should find all the pieces' do
    expect(capture).to run_game(game).matching(
      add_pieces(:gas_car, :gas_car),
      add_pieces(:electric_car),
      add_pieces(:gas_plant, :gas_plant, :coal_plant),
      add_pieces(:wind_turbine, :wind_turbine),
      add_pieces(:led_light), # Should actually be 2x LED
      add_pieces(:incandescent_light),
      add_pieces(:pv_panel, :pv_panel),
      add_pieces(:nuclear_plant, :thermal_collector),
      add_pieces(:thermal_collector),
    )
  end
end # "frans" integration test
