module Theia

  # Public: Returns the base data path.
  def self.data_path
    File.expand_path("../../../data", __FILE__)
  end

  # Public: Returns the path for a file or directory within the base data
  #         path.
  def self.data_path_for(filename)
    File.join(data_path, filename)
  end

  # Public: Returns the temporary files path.
  def self.tmp_path
    data_path_for('tmp')
  end

end # Theia
