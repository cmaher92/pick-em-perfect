require 'google_drive'
require 'pg'
require 'pry'

session = GoogleDrive::Session.from_config("client_secret.json")
spreadsheet = session.file_by_title('pickemperfect_test')
worksheet = spreadsheet.worksheets[0]

conn = PG.connect(dbname: 'pick_em_perfect')


pull_picks_query = "
    SELECT * FROM picks
    WHERE time_pick_submitted >= TO_DATE('2018-04-15', 'YYYY-MM-DD')
    AND time_pick_submitted <  TO_DATE('2018-04-17', 'YYYY-MM-DD');
  "
picks = conn.exec(pull_picks_query)
picks = picks.select { |pick| pick['result'] != nil }
# remove picks without a result

def retrieve_email(conn, user_id)
  result = conn.exec("SELECT * FROM users WHERE id = #{user_id}")
  result[0]['email']
end

def generate_users(picks, conn)
  # generates a list of users with the following information
  # email, user_id, wins, loses
   users = []
   # iterate over the picks
   #    generate a list of users based on unique user_id's

   picks.each do |pick|
     if users.any? { |user| user['user_id'] == pick['user_id'] }
       next
     else
       user = {}
       user['email']        = retrieve_email(conn, pick['user_id'])
       user['user_id']      = pick['user_id']
       user['wins']         = 0
       user['loses']        = 0
       user['games_played'] = 0
       users << user
     end
   end
   users
end

def calculate_record(conn, users, picks)
  # for each user
  #   find all picks for each user and total their wins/losses
  users.map! do |user|
    users_picks = picks.select { |pick| pick['user_id'] == user['user_id'] }
    users_picks.each do |user_pick|
      if user_pick['result'] == 'W'
        user['wins']         += 1
        user['games_played'] += 1
      else
        user['loses']        += 1
        user['games_played'] += 1
      end
    end
    user
  end
  users
end

def query_picks(conn, user_id, day_of_week, start_date)


  picks = conn.exec("
    SELECT * FROM picks
    WHERE user_id = #{user_id}
    AND game_day = '#{day_of_week}'
    AND time_pick_submitted >= TO_DATE('#{start_date}', 'YYYY-MM-DD');
    ")

  picks
end

def add_picks(conn, users)
  puts 'What day of the week do you want to display the picks for?'
  puts 'monday, tuesday etc...'
  day_of_week = gets.chomp.downcase

  puts 'What date did you start allowing picks?'
  puts 'YYYY-MM-DD'
  start_date = gets.chomp.downcase

  users.map! do |user|
    user['picks'] = []
    users_picks = query_picks(conn, user['user_id'], day_of_week, start_date)
    users_picks.each do |pick|
      user['picks'] << pick['team']
    end
    user
  end
 users
end

def push_leaderboard_to_sheets(leaderboard, worksheet)
  # username, wins, games
  row = 2
  leaderboard.each do |user|
    worksheet[row, 1] = user['email'].split('@')[0]
    worksheet[row, 2] = user['wins']
    worksheet[row, 3] = user['loses']
    worksheet[row, 4] = user['picks']
    row += 1
  end
  worksheet.save
end

users = generate_users(picks, conn)
users_with_record = calculate_record(conn, users, picks)
users_with_record_and_picks = add_picks(conn, users_with_record)
users_with_record_and_picks_sorted = users_with_record_and_picks.sort_by { |pick| pick['wins'] }.reverse
push_leaderboard_to_sheets(users_with_record_and_picks_sorted, worksheet)
