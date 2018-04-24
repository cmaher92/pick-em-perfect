require 'google_drive'
require 'pg'
require 'pry'

session = GoogleDrive::Session.from_config("client_secret.json")
spreadsheet = session.file_by_title('pickemperfect')
worksheet = spreadsheet.worksheets[0]

conn = PG.connect(dbname: 'pick_em_perfect')

# pull all picks from a date range
# create an array of hashes
# each hash contains { 'user_id', 'email', 'games_played', 'wins' }
# for each pick, check to see if user_id is already in the array of hashes

pull_picks_query = "SELECT * FROM picks
    WHERE time_pick_submitted >= TO_DATE('2018-03-05', 'YYYY-MM-DD')
    AND time_pick_submitted <  TO_DATE('2018-03-12', 'YYYY-MM-DD');"
picks = conn.exec(pull_picks_query)


# for each pick within the date-range
# check to see if the user_id has already made a pick
#   if he has, return the pick from that matches the user_id
#     if the result of pick is a win, add one to his wins_total
#     add one to his total games-played regardless
#   if he hasn't
#     create a hash
#     add id, his email, games_played, and wins
#     push onto leaderboards array

def retrieve_email(conn, user_id)
  result = conn.exec("SELECT * FROM users WHERE id = #{user_id}")
  result[0]['email']
end

def generate_leaderboard(picks, conn)
  leaderboard = []
  picks.each do |pick|
    # binding.pry if leaderboard.size == 8
    if leaderboard.any? { |user| user['id'] == pick['user_id'] }
      user = leaderboard.select { |user| user['id'] == pick['user_id'] }
      user[0]['wins'] += 1 if pick['result'] == 'W'
      user[0]['games_played'] += 1
    else
      user = {}
      user['id'] = pick['user_id']
      user['email'] = retrieve_email(conn, pick['user_id'])
      user['games_played'] = 1
      pick['result'] == 'W' ? user['wins'] = 1 : user['wins'] = 0
      leaderboard << user
    end
  end
  leaderboard
end

def push_leaderboard_to_sheets(leaderboard, worksheet)
  # username, wins, games
  row = 2
  leaderboard.each do |user|
    worksheet[row, 1] = user['email'].split('@')[0]
    worksheet[row, 2] = user['wins']
    worksheet[row, 3] = user['games_played']
    row += 1
  end
  worksheet.save
end

leaderboard = generate_leaderboard(picks, conn)
sorted_leaderboard = leaderboard.sort { |a, b| b['wins'] <=> a['wins'] }
push_leaderboard_to_sheets(sorted_leaderboard, worksheet)
