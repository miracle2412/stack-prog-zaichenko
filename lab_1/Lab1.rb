def word_stats(text)
  words = text.split(/\s+/)
  count = words.size
  longest = words.max_by { |w| w.length }
  unique_count = words.map(&:downcase).uniq.size

  puts "Кількість слів: #{count}"
  puts "Найдовше слово: #{longest}"
  puts "Унікальних слів: #{unique_count}"
end

print "Введіть рядок: "
user_input = gets.chomp
word_stats(user_input)
