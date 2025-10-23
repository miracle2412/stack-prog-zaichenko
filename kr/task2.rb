require 'csv'
require 'bigdecimal'
require 'time'

# === Клас StreamingCSVParser ===
class StreamingCSVParser
  def initialize(file_path, casters = {})
    @file_path = file_path
    @casters = casters
  end
  def parse
    raise "Файл не знайдено: #{@file_path}" unless File.exist?(@file_path)
    CSV.foreach(@file_path, headers: true) do |row|
      yield cast_row(row.to_h)
    end
  end
  private
  def cast_row(row_hash)
    row_hash.transform_values.with_index do |val, _i|
      key = row_hash.keys[_i]
      caster = @casters[key]
      cast_value(val, caster)
    end
  end
  def cast_value(val, caster)
    return nil if val.nil? || val.strip.empty?
    case caster
    when :int
      val.to_i
    when :decimal
      BigDecimal(val)
    when :time
      Time.parse(val)
    else
      val
    end
  rescue ArgumentError
    val
  end
end
# === Приклад використання ===
if __FILE__ == $0
  parser = StreamingCSVParser.new(
    "data.csv",
    {
      "age" => :int,
      "price" => :decimal,
      "created_at" => :time
    }
  )
  parser.parse do |row|
    puts row.inspect
  end
end
