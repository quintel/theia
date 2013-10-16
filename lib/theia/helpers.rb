module Theia
  def self.data_path
    File.expand_path("../../../data", __FILE__)
  end

  def self.data_path_for(filename)
    File.join(data_path, filename)
  end

  def self.tmp_path
    data_path_for('tmp')
  end
end
