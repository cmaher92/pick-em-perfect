# pull picks from form
#    - pull picks and database comparing differences
#    - check to see if any of these picks are new users, add to db if so
#    - finally, add picks to database unless it's a repeat

# to do
#   - improve the checking for repeats, it only will count if its the last day

 require 'google_drive'
 require 'pg'
 require 'pry'

# initializes connection to database
conn = PG.connect(dbname: 'pick_em_perfect')

# inititalizes connection to google sheets where form data is
session = GoogleDrive::Session.from_config("client_secret.json")
spreadsheet = session.file_by_title('My Form')
worksheet = spreadsheet.worksheets[0]

# pull picks from spreadsheet
  # total 14 picks
  # label each pick with the assoc. day
  # add column to database with the day of the game

game_day_mapper = [
  'monday', 'monday',
  'tuesday', 'tuesday',
  'wednesday','wednesday',
  'thursday', 'thursday',
  'friday', 'friday',
  'saturday', 'saturday',
  'sunday', 'sunday'
]

def pull_data_from_spreadsheet(worksheet, game_day_mapper)
  picks_from_form = []
  worksheet.rows[1..-1].each do |row|
    picks = []
    teams = []
    teams << row[3]
    teams << row[7..-1]
    teams = teams.flatten

    email = row[2].downcase
    time_pick_submitted = row[0]
    teams.each_with_index do |team, idx|
      pick = {}
      pick['email'] = email
      pick['time_pick_submitted'] = time_pick_submitted
      pick['team'] = team
      pick['game_day'] = game_day_mapper[idx]
      picks << pick
    end
    picks_from_form << picks
  end
  picks_from_form
end

def add_new_users(picks, conn)
  picks.each do |pick|
    result = conn.exec("SELECT * FROM users WHERE email = '#{pick[0]['email']}';")
    if result.values.empty?
      conn.exec("INSERT INTO users(email) VALUES('#{pick[0]['email']}');")
    else
      next
    end
  end
end

def add_pick_to_database(conn, pick_from_form, user_id)
  # given an array of picks for a user
  # add each one to the database
  pick_from_form.each do |pick|
    conn.exec("INSERT INTO picks(user_id, team, time_pick_submitted, game_day)
               VALUES (#{user_id}, '#{pick['team']}', '#{pick['time_pick_submitted']}', '#{pick['game_day']}');")
  end
end

def add_new_picks_to_db(picks_from_form, conn)
  # given an array of picks
  # check to see if pick exists in picks database
  # if it doesn't add it to database
  # if it does, next

  picks_from_form.each do |pick_from_form|
    user_id = conn.exec("SELECT id FROM users WHERE email = '#{pick_from_form[0]['email']}'")[0]['id']
    pick = conn.exec("SELECT * FROM picks
                      WHERE user_id = #{user_id}
                      AND time_pick_submitted = '#{pick_from_form[0]['time_pick_submitted']}';")
    if pick.values.empty?
      add_pick_to_database(conn, pick_from_form, user_id)
    else
      next
    end
  end
end

picks_from_form = pull_data_from_spreadsheet(worksheet, game_day_mapper)
add_new_users(picks_from_form, conn)
add_new_picks_to_db(picks_from_form, conn)
