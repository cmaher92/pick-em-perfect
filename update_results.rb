require 'pg'
require 'pry'

conn = PG.connect(dbname: 'pick_em_perfect')

# ask the user for the date of start of the week
# ask the user which day to update the results for

puts "What is the date of the beginning of this week?"
puts "Format must be in YYYY-MM-DD"
date = gets.chomp

puts "What is the day of the week that you would like to update the results for?"
game_day = gets.chomp

# display picks for that day of the week
# select all picks from after sunday
# and from the day of the week

puts "Who won the first game?"
game_1 = gets.chomp

puts "Who won the second game?"
game_2 = gets.chomp


# update results
def update_result(conn, team, date, game_day)
  conn.exec("
    UPDATE picks SET result = 'W'
    WHERE time_pick_submitted >= TO_DATE('#{date}', 'YYYY-MM-DD')
    AND game_day = '#{game_day}'
    AND team = '#{team}';
    ")
  puts 'winners updated'
end

def update_losers(conn, date, game_day, game_1, game_2)
  conn.exec("
    UPDATE picks SET result = 'L'
    WHERE time_pick_submitted >= TO_DATE('#{date}', 'YYYY-MM-DD')
    AND game_day = '#{game_day}'
    AND team != '#{game_1}'
    AND team != '#{game_2}';
    ")
end

update_result(conn, game_1, date, game_day)
update_result(conn, game_2, date, game_day)
update_losers(conn, date, game_day, game_1, game_2)

# results = conn.exec("
#   SELECT * FROM picks
#   WHERE time_pick_submitted >= TO_DATE('#{date}', 'YYYY-MM-DD')
#   AND game_day = '#{game_day}'
#   AND result = 'W';
#   ")
# results.each { |result| p result['id'] ; p result['team'] }
