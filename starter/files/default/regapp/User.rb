class User

	#User constructor
	def initialize(name, email, passwd, hint, answer)
		@name = name
		@email = email
		@passwd = passwd
		@hint = hint
		@answer = answer
	end

	#Returns this instance's data as a string (Won't include password.)
	def print_data()
		return "Name: "+@name+". Email: "+@email+". HintID: "+@hint+". Answer: "+@answer
	end

	#Match a given password with this instance's password
	def match_passwd(password)
		if password == @passwd then
			return true
		end
		return false
	end

	def match_security_answer(answer)
		if answer == @answer then
			return true
		end
		return false
	end

	def get_security_question()
		return @hint.to_i
	end

	def get_password()
		return @passwd
	end

	def get_name()
		return @name
	end
end