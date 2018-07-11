=begin

						==Exercise 5==
					 Devops in the cloud
							By
					Anis Bishara - 303152409
					Hosam Khatib - 308408566

		# => We were asked to implement the functions from previous
			 ruby exercises, except this time using Sinatra.
		# => In the PowerPoint presentation we were asked to implement
			 'Register' and 'Show all' functionalities, but at the 
			 course's website it states: 'Implement all functions'.
			 We just noticed the latter, and we haven't implemented 
			 'All functions' yet, we'll do it if we find the time,
			 otherwise we'll finish them for next exercise. Hope we won't
			 get points reduced for this as it isn't our fault and does
			 not reflect lack of knowledge nor laziness.

		# => Run:    'ruby register.rb'
=end


require 'rubygems'
require 'sinatra'
require './User'
require './condb'

#DB Config:
#myhost = '127.0.0.1'
#myhost   = '35.166.101.156'
#user     = 'root'
#dbpasswd = 'admin1'
#dbname	 = 'students'
connect_db

=begin
Session class used to store info about the user currently logged in.
=end
class Session

	#Sessions constructor
	def initialize(name, email)
		@name = name
		@email = email
		@is_logged = true
	end

	def logout() 
		@is_logged = false
	end

	def login()
		@is_logged = true
	end

	def is_logged() 
		return @is_logged
	end

	def get_name()
		return @name
	end

	def get_email()
		return @email
	end

end

set :bind, '0.0.0.0'
set :port, 80


$hints = [] #stores hints
$users = Hash.new #stores email => User object
$users_counter #Stores the number of rows in 'users' table


$session = nil

def fetch_hints 
	rs = $dbcon.query('SELECT hint FROM hints')
	i = 0
	#printf('num of rows: %d', rs.num_rows)
	num_rows = rs.num_rows

	rs.each_hash do |row|
		$hints << row['hint']
	end
end

#Fetches users from DB and assigns in designated hash table.
def fetch_users
	rs = $dbcon.query('SELECT * FROM users')
	$users_counter = rs.num_rows
	rs.each_hash do |row|
		$users[row['email']] = User.new(row['name'], row['email'], row['passwd'], row['hintID'], row['hintAnswer'])
	end
end


fetch_users
fetch_hints

get '/start' do
	erb :select
end

get '/register' do
	hints = ""
	$hints.each_with_index do |hint, index|
		hints << "<option value=\""+index.to_s+"\">"+hint.to_s+"</option>"
	end
	erb :register, :locals => {:hints => hints}
end

post '/register/' do
	name 	  = params[:student_name]
	passwd	  = params[:passwd]
	email	  = params[:email_addr]
	hint_id   = params[:security_question]
	hint_answ = params[:security_answ]
	res = ""
	#res << "name: " +name+ "<br>"
	#res << "email: " +email+ "<br>"
	#res << "hint_id: " +hint_id+ "<br>"
	#res << "hint answ: " +hint_answ
	
	error_occurred = false


	
	email_regex = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]{2,}\z/
	if (email =~ email_regex).nil? then
		error_occurred = true
		res << "Email address invalid<br>"
	end

	#Check if user with this email address already exists
	fetch_users
	if ($users.key?(email)) then
		error_occurred = true
		res << "An account already exists for the given email.<br>"
	end

	password_regex = /[a-zA-Z0-9_~!@$%^&*()]{6,}/
	if (passwd =~ password_regex).nil? then
		error_occurred = true
		res << "Password security level is too low.<br>"
	end

	if error_occurred then
		res.prepend("<h3 style=\"color: red\">Please fix the following error(s):</h3><br>")
		res << "<br><b>Press back on your browser to re-fill the form</b><br>"
	else #everything's fine, insert into db.
		fetch_users
		p 'User Counter ' + $users_counter.to_s
		query = "INSERT INTO users (name,email,passwd,hintID,hintAnswer) VALUES('"+name.to_s+"','"+email.to_s+"','"+passwd.to_s+"','"+hint_id.to_s+"','"+hint_answ.to_s+"')"
		rs = $dbcon.query(query)
		res << "New user created and added to DB.<br>"
	end

	res << "Back to <a href=\"/start\">Start page</a>"
	res
end

get '/showall' do
	res = "<h2>The following is a list of all the users on the database:</h2><br><h4>"
	fetch_users
	$users.each do |k, v|
		res << v.print_data + "<br />"
	end
	res << "</h4><br> Back to <a href=\"/start\">Index</a>."
	res
end

get '/login' do
	if $session == nil then
		erb :login
	else 
		"<p>You are already logged in</p><p>Back to <a href=\"/start\">start page</a></p>"
	end
end

post '/login/' do
	email 	= params[:email]
	passwd  = params[:password]
	fetch_users
	res = ''
	if ($users.key?(email)) then
		if ($users[email].match_passwd(passwd))
			res << 'Logged in'
			$session = Session.new($users[email].get_name , email)
		
		else
			res << 'Wrong password.'
		end
	else
		res << 'No user exists with the given email address'
	end
	res << '<p>Back to <a href="/start">start page</a></p>'
	res
end

get '/recover' do
	erb :recover	
end

post '/recover/' do
	email = params[:email]
	hint_answer = params[:hint_answer]
	if ($users[email].match_security_answer(hint_answer)) then
		res = 'Your password is: ' + $users[email].get_password
	else
		res = 'Wrong answer.'
	end
	res
end	

#We pass the email as an argument in a get request.
get '/recover/' do
	email = params['email']
	if ($users.key?(email)) then
		hint = $hints[ $users[email].get_security_question ]
		erb :recoveranswer, :locals => {:hint => hint, :email => email}
	else
		res = ''
		res << '<p>No account exists for the given email.</p>'
		res << '<p>Back to <a href="/start">start page</a></p>'
		res
	end
end

get '/remove' do
	res = ''
	if $session != nil then
		hint = $hints[ $users[$session.get_email].get_security_question ]
		erb :deleteuser, :locals => {:hint => hint}
	else
		res << '<p>Please <a href="/login">login</a> first.</p>'
		res << '<p>Back to <a href="/start">start page</a></p>'
	end
end

post '/remove/' do
  hint_answer = params[:hint_answer]
  res = ''
  fetch_users
  if ($users[$session.get_email].match_security_answer(hint_answer)) then
  	query = 'DELETE FROM users WHERE users.email = \'' +$session.get_email+'\''
	rs = $dbcon.query(query)
	fetch_users
	res << '<p>Account Successfully Deleted.</p>'
	res << '<p>Back to <a href="/start">start page</a></p>'
	$session = nil
  else
  	res << '<p>Wrong answer. <a href="/remove">Try again</a>.</p>'
  end
  res
end



get '/logout' do
	res = ''
	if $session  == nil then
		res << 'You are not logged in.'
	else
		$session = nil
		res << 'Successfuly logged out.'
	end
	res << '<p>Back to <a href="/start">start page</a></p>'
	res
end

get '/' do
  "Did you mean to access the <a href=\"/start\">start page</a>?"
end

get '/quit' do
	Process.kill  'TERM',  Process.pid
end	