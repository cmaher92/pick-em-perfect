require 'google_drive'
require 'pg'
require 'pry'

session = GoogleDrive::Session.from_config("client_secret.json")
conn = PG.connect(dbname: 'pick_em_perfect')

# select all from a date
SELECT * FROM picks
WHERE time_pick_submitted >= TO_DATE('2018-04-16', 'YYYY-MM-DD')
AND time_pick_submitted <  TO_DATE('2018-04-17', 'YYYY-MM-DD');

# update losers from a date
# UPDATE picks SET result = 'L'
# WHERE time_pick_submitted >= TO_DATE('2018-03-05', 'YYYY-MM-DD')
# AND time_pick_submitted <  TO_DATE('2018-03-06', 'YYYY-MM-DD')
# AND team != 'Cleveland Cavaliers'
# AND team != 'Buffalo Sabres';

# write a function that asks for the date in YYYY-MM-DD format
# and the two winning teams for that date
# update the winners
# update the losers
# print the results

def update_winners_and_losers(conn)
  puts 'What is the date you would like to update the winners and losers for?'
  puts "your response must by in 'YYYY-MM-DD' format"
  date = gets.chomp
  year_month_day = date.split('-')
  year_month_day.map! { |obj| obj.to_i }
  year_month_day[2] += 1
  year_month_day[0] = format('%04d', year_month_day[0])
  year_month_day[1] = format('%02d', year_month_day[1])
  year_month_day[2] = format('%02d', year_month_day[2])
  end_date = year_month_day.join('-')

  puts 'What team won the first game?'
  game_1_winner = gets.chomp
  conn.exec("
  UPDATE picks SET result = 'W'
  WHERE time_pick_submitted >= TO_DATE('#{date}', 'YYYY-MM-DD')
  AND time_pick_submitted <  TO_DATE('#{end_date}', 'YYYY-MM-DD')
  AND team = '#{game_1_winner}';
  ")

  puts "Updating game 1 winner..."
  sleep(2)

  puts "What team won the second game?"
  game_2_winner = gets.chomp
  conn.exec("
  UPDATE picks SET result = 'W'
  WHERE time_pick_submitted >= TO_DATE('#{date}', 'YYYY-MM-DD')
  AND time_pick_submitted <  TO_DATE('#{end_date}', 'YYYY-MM-DD')
  AND team = '#{game_2_winner}';
  ")

  puts "Updating game 2 winner..."
  sleep(2)

  conn.exec("
  UPDATE picks SET result = 'L'
  WHERE time_pick_submitted >= TO_DATE('#{date}', 'YYYY-MM-DD')
  AND time_pick_submitted <  TO_DATE('#{end_date}', 'YYYY-MM-DD')
  AND team != '#{game_1_winner}'
  AND team != '#{game_2_winner}';
  ")

  puts "Updating losers..."
  sleep(2)

  puts 'Here are all the picks for that date and their updated results:'
  results = conn.exec("
    SELECT * FROM picks
    WHERE time_pick_submitted >= TO_DATE('#{date}', 'YYYY-MM-DD')
    AND time_pick_submitted <  TO_DATE('#{end_date}', 'YYYY-MM-DD');
    ")
  results.each { |row| puts row['team'], row['result'] }
end


update_winners_and_losers(conn)
