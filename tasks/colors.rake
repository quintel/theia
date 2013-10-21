require 'text-table'
require_relative '../lib/theia'

desc "Print a table with distance values between colors"
task :colors do
  pieces = Theia::Piece.all

  table = Text::Table.new
  table.head = [''] + pieces.map(&:key)
  table.rows = []

  pieces.each do |left|
    line = [left.key]
    pieces.each do |right|
      value = (left.compare(right.color) * 100)
      case value
      when 0
        line << '-'
      else
        line << "%.4f" % value
      end
    end

    table.rows << line
  end

  puts table
end
