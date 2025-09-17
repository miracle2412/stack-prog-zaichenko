def play_game
  secret = rand(1..100)
  attempts = 0

  puts "Було загадане число від 1 до 100. Спробуй вгадати його!"

  loop do
    print "Введи своє припущення: "
    guess = gets.to_i
    attempts += 1

    if guess < secret
      puts "Число більше!"
    elsif guess > secret
      puts "Число менше!"
    else
      puts "Вітаю, ти вгадав! Число було #{secret}."
      puts "Ти використав #{attempts} спроб."
      break
    end
  end
end


play_game
