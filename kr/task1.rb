class Bag
  include Enumerable
  def initialize(items = [])
    @items = items
  end
  # Мінімальний набір для Enumerable
  def each(&block)
    @items.each(&block)
  end
  def size
    @items.size
  end
  # Додати елемент до колекції
  def add(item)
    @items << item
  end
  # Запити
  def median
    return nil if @items.empty?
    sorted = @items.sort
    mid = sorted.size / 2

    if sorted.size.odd?
      sorted[mid]
    else
      (sorted[mid - 1] + sorted[mid]) / 2.0
    end
  end
  def frequencies
    @items.each_with_object(Hash.new(0)) { |item, hash| hash[item] += 1 }
  end
end
# === Приклад використання ===
bag = Bag.new([3, 1, 2, 2, 5, 3, 3])
puts "Усі елементи: #{bag.to_a}"
puts "Розмір: #{bag.size}"
puts "Медіана: #{bag.median}"
puts "Частоти: #{bag.frequencies}"
puts "Максимум: #{bag.max}"
puts "Сума: #{bag.sum}"
puts "Середнє: #{bag.sum / bag.size.to_f}"
