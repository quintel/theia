class Array
  def sum
    inject(0.0) { |sum, el| sum += el }
  end

  def mean
    sum / size
  end
end
