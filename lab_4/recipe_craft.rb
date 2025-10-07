class UnitConverter
  MASS = [:g, :kg].freeze
  VOL  = [:ml, :l].freeze
  PCS  = [:pcs].freeze

  FACTORS = {
    [:kg, :g]  => 1000.0,
    [:g,  :kg] => 1.0 / 1000.0,
    [:l,  :ml] => 1000.0,
    [:ml, :l]  => 1.0 / 1000.0,
    [:pcs, :pcs] => 1.0,
    [:g, :g] => 1.0,
    [:kg, :kg] => 1.0,
    [:ml, :ml] => 1.0,
    [:l, :l] => 1.0
  }.freeze

  def self.same_dimension?(from, to)
    return true if from == to
    [MASS, VOL, PCS].any? { |grp| grp.include?(from) && grp.include?(to) }
  end

  def self.base_of(unit)
    return :g   if MASS.include?(unit)
    return :ml  if VOL.include?(unit)
    return :pcs if unit == :pcs
    raise ArgumentError, "Невідома одиниця: #{unit}"
  end

  def self.convert(qty, from, to)
    raise ArgumentError, "Заборонено перетворювати масу↔об’єм" \
      unless same_dimension?(from, to)

    factor = FACTORS[[from, to]]
    raise ArgumentError, "Немає конверсії #{from}→#{to}" unless factor
    qty * factor
  end

  def self.to_base(qty, unit)
    convert(qty, unit, base_of(unit))
  end
end

class Ingredient
  attr_reader :name, :base_unit, :calories_per_base

  def initialize(name:, unit:, calories_per_unit:)
    @name = name
    @base_unit = UnitConverter.base_of(unit)
    @calories_per_base = calories_per_unit
  end
end


class Pantry
  def initialize
    @stock = Hash.new { |h, k| h[k] = { qty: 0.0, unit: nil } }
  end

  def add(name, qty, unit)
    base_qty = UnitConverter.to_base(qty, unit)
    base_unit = UnitConverter.base_of(unit)
    @stock[name][:unit] ||= base_unit
    unless @stock[name][:unit] == base_unit
      raise "Одиниці для #{name} не збігаються (#{@stock[name][:unit]} vs #{base_unit})"
    end
    @stock[name][:qty] += base_qty
  end

  # доступно в базових одиницях
  def available_for(name)
    (@stock[name] && @stock[name][:qty]) || 0.0
  end

  def unit_for(name)
    (@stock[name] && @stock[name][:unit]) || nil
  end
end

class Recipe
  Item = Struct.new(:ingredient, :qty, :unit, keyword_init: true)

  attr_reader :name, :steps, :items

  def initialize(name:, steps: [], items: [])
    @name  = name
    @steps = steps
    @items = items # масив Item
  end


  def need
    need_hash = Hash.new { |h, k| h[k] = { qty: 0.0, unit: nil } }
    @items.each do |it|
      base_qty  = UnitConverter.to_base(it.qty, it.unit)
      base_unit = UnitConverter.base_of(it.unit)
      name      = it.ingredient.name
      need_hash[name][:unit] ||= base_unit
      need_hash[name][:qty]  += base_qty
    end
    need_hash
  end
end


class Planner
  ResultLine = Struct.new(:name, :unit, :need, :have, :deficit, :cost_need, :cost_buy)


  def self.plan(recipes, pantry, price_list, ingredients_index)
    # 1) сума "потрібно" по всіх рецептах
    total_need = Hash.new { |h, k| h[k] = { qty: 0.0, unit: nil } }
    recipes.each do |r|
      r.need.each do |name, info|
        total_need[name][:unit] ||= info[:unit]
        total_need[name][:qty]  += info[:qty]
      end
    end


    lines = []
    total_calories = 0.0
    total_cost_need = 0.0
    total_cost_to_buy = 0.0

    total_need.keys.sort.each do |name|
      unit = total_need[name][:unit] || ingredients_index[name]&.base_unit || :pcs
      need = total_need[name][:qty]
      have = pantry.available_for(name)
      deficit = [need - have, 0.0].max

      price_per_base = price_list[name] || 0.0
      cost_need = need * price_per_base
      cost_buy  = deficit * price_per_base

      cal_per_base = ingredients_index[name]&.calories_per_base || 0.0
      calories = need * cal_per_base

      lines << ResultLine.new(name, unit, need, have, deficit, cost_need, cost_buy)
      total_calories += calories
      total_cost_need += cost_need
      total_cost_to_buy += cost_buy
    end

    {
      lines: lines,
      total_calories: total_calories,
      total_cost_need: total_cost_need,
      total_cost: total_cost_to_buy
    }
  end
end


#  Інгредієнти (калорійність)
ingredients = [
  Ingredient.new(name: "яйце",   unit: :pcs, calories_per_unit: 72.0),
  Ingredient.new(name: "молоко", unit: :ml,  calories_per_unit: 0.06),
  Ingredient.new(name: "борошно",unit: :g,   calories_per_unit: 3.64),
  Ingredient.new(name: "паста",  unit: :g,   calories_per_unit: 3.5),
  Ingredient.new(name: "соус",   unit: :ml,  calories_per_unit: 0.2),
  Ingredient.new(name: "сир",    unit: :g,   calories_per_unit: 4.0)
]
ING = ingredients.map { |i| [i.name, i] }.to_h

#  Комора
pantry = Pantry.new
pantry.add("борошно", 1.0, :kg)
pantry.add("молоко",  0.5, :l)
pantry.add("яйце",    6,   :pcs)
pantry.add("паста",   300, :g)
pantry.add("сир",     150, :g)

#  Ціни
price_list = {
  "борошно" => 0.02,   # грн за 1 г
  "молоко"  => 0.015,  # грн за 1 мл
  "яйце"    => 6.0,    # грн за 1 шт
  "паста"   => 0.03,   # грн за 1 г
  "соус"    => 0.025,  # грн за 1 мл
  "сир"     => 0.08    # грн за 1 г
}

#  Рецепти
omlet = Recipe.new(
  name: "Омлет",
  steps: ["Збити яйця з молоком і борошном", "Посмажити на пательні"],
  items: [
    Recipe::Item.new(ingredient: ING["яйце"],   qty: 3,   unit: :pcs),
    Recipe::Item.new(ingredient: ING["молоко"], qty: 100, unit: :ml),
    Recipe::Item.new(ingredient: ING["борошно"],qty: 20,  unit: :g)
  ]
)

pasta = Recipe.new(
  name: "Паста",
  steps: ["Зварити пасту", "Додати соус і сир"],
  items: [
    Recipe::Item.new(ingredient: ING["паста"], qty: 200, unit: :g),
    Recipe::Item.new(ingredient: ING["соус"],  qty: 150, unit: :ml),
    Recipe::Item.new(ingredient: ING["сир"],   qty: 50,  unit: :g)
  ]
)

plan = Planner.plan([omlet, pasta], pantry, price_list, ING)


def fmt_qty(q, unit)
  # друк у базових од.: г / мл / шт
  case unit
  when :g   then "#{q.round(2)} г"
  when :ml  then "#{q.round(2)} мл"
  when :pcs then "#{q.round(2)} шт"
  else          "#{q.round(2)} #{unit}"
  end
end

puts "=== План приготування: Омлет + Паста ==="
plan[:lines].each do |ln|
  puts "#{ln.name.capitalize.ljust(10)} | потрібно: #{fmt_qty(ln.need, ln.unit)}" \
         " | є: #{fmt_qty(ln.have, ln.unit)} | дефіцит: #{fmt_qty(ln.deficit, ln.unit)}"
end

puts "-" * 70
puts "total_calories: #{plan[:total_calories].round(2)} ккал"
puts "total_cost:     #{plan[:total_cost].round(2)} грн (докупити)"
puts "— довідково: повна вартість інгредієнтів для рецептів: "\
       "#{plan[:total_cost_need].round(2)} грн"
