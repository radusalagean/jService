

# Section: Questions

def sanitize_question(raw_question)
	# Trim leading and trailing whitespaces
	sanitized = raw_question.strip

	sanitized
end

def valid_question?(subject)
	# Check if the string is less than 3 characters
	return false if subject.strip.length < 3

	true
end

# End Section: Questions

# Section: Answers

def sanitize_answer(raw_answer)
	# Remove quotes from start and end of string
	sanitized = raw_answer.gsub(/^"(.+)"$/, '\1')

	# Remove all text wrapped with (), [] or {}
	sanitized = sanitized
		.gsub(/\s*\(.*?\)\s*/, ' ')
		.gsub(/\s*\[.*?\]\s*/, ' ')
		.gsub(/\s*\{.*?\}\s*/, ' ')

	# Remove specific characters: ()[]{}
	sanitized = sanitized.delete('()[]{}')

	# Remove multiple spaces
	sanitized = sanitized.gsub(/\s+/, ' ')

	# Trim leading and trailing whitespaces
	sanitized = sanitized.strip

	sanitized
end
  
def valid_answer?(subject, sanitized)
	# Check if the string is less than 1 character
	return false if subject.strip.length < 1

	# Check if the string contains / or \ characters
	return false if subject.include?('/') || subject.include?('\\')

	# Check if the string contains " of)" - this is a common pattern for multiple choice answers
	return false if subject.include?(" of)")

	# Check if the answer contains non-ASCII characters
	return false if subject.match?(/[^[:ascii:]]/)

	if sanitized
		# Check if contains more than 4 words
		return false if subject.split.length > 4
	end

	# If none of the above conditions are met, the answer is valid
	true
end

# End Section: Answers

 #Arguments are seasons to grab. [1,30] grabs seasons 1 through 30
  task :get_clues, [:arg1,:arg2]  => :environment  do |t, args|
  	require 'nokogiri'
  	require 'open-uri'
  	require 'chronic'


  	arg1int = args.arg1.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
    arg2int = args.arg2.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
  	if(arg1int && arg2int)
  	  	#get game list
  	  	gameIds = Array.new
	  	for i in args.arg1.to_i..args.arg2.to_i
			sleep(rand(1..3))
	  		seasonsUrl = 'http://j-archive.com/showseason.php?season='+i.to_s
	  		seasonList = Nokogiri::HTML(URI.open(seasonsUrl), nil, "UTF-8")
	  		linkList = seasonList.css('table td a')
	  		linkList.each do |ll|
	  			href = ll.attr('href');
	  			href = href.split('id=')
	  			hrefId = href[1]
	  			gameIds.push(hrefId)
	  		end
	  	end
	  	
	  	gameIds.each do |gid|
			sleep(rand(1..3))

		  	gameurl = 'http://www.j-archive.com/showgame.php?game_id='+gid.to_s
		  	game = Nokogiri::HTML(URI.open(gameurl), nil, "UTF-8")
		  	
		  	## OK, were going to do this twice, once for each round
		  	questions = game.css("#jeopardy_round .clue")
		  	
		  	#Define vars
		  	var_question = ''
		  	var_answer = ''
		  	var_value = ''
		  	var_category = ''
		  	var_airdate = nil 
		
		  	
		  	#get an array of the category names, we'll need these later
		  	categories = game.css('#jeopardy_round .category_name')
		  	categoryArr = Array.new
		  	categories.each do |c|
			  	categoryName = c.text().downcase
			  	categoryArr.push(Category.find_or_create_by(title: categoryName))
		  	end
		
		  	#get the airdate
		  	ad = game.css('#game_title h1').text().split(" - ")
		  	if(!ad[1].nil?)
		  		var_airdate = Chronic.parse(ad[1])
		  		puts "Working on: " + ad[1]
		  	end
		
		  	questions.each do |q|
				var_question = q.css('.clue_text:not(:has(*))').text()
				var_answer = q.css('.correct_response').text()
				index =	q.xpath('count(preceding-sibling::*)').to_i
				var_category = categoryArr[index]
				var_value = q.css('.clue_value').text[/[0-9\.]+/]

				# Question

				if !valid_question?(var_question)
					if var_question.length > 0
						puts "⛔️ Invalid raw question: " + var_question
					end
					next
				end

				old_question = var_question
				var_question = sanitize_question(var_question)
				if old_question != var_question
					puts "\n❓ Question sanitized:\n" + old_question + "\n⬇️\n" + var_question + "\n\n"
				end

				if !valid_question?(var_question)
					if var_question.length > 0
						puts "⛔️ Invalid sanitized question: " + var_question
					end
					next
				end

				# Answer

				if !valid_answer?(var_answer, sanitized = false)
					if var_answer.length > 0
						puts "⛔️ Invalid raw answer: " + var_answer
					end
					next
				end

				old_answer = var_answer
				var_answer = sanitize_answer(var_answer)
				if old_answer != var_answer
					# puts "\n🔍 Answer sanitized:\n" + old_answer + "\n⬇️\n" + var_answer + "\n\n"
				end

				if !valid_answer?(var_answer, sanitized = true)
					if var_answer.length > 0
						puts "⛔️ Invalid sanitized answer: " + var_answer
					end
					next
				end

				newClue = Clue.where(
					:question => var_question,
					:answer => var_answer,
					:category => var_category,
					:value => var_value,
					:airdate => var_airdate,
					:game_id => gid
				).first_or_create
		  	end
		 end #each
	  end #if
  end
