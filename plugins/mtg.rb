require 'cinch'

require 'json'
require 'open-uri'

class MTG
  include Cinch::Plugin

  match(/mtg (\w+) (.+)/)

  def formatCard(card)
    data = "#{card['name']} (#{card['manaCost']})"
    data << " #{card['type']}"
    if card['subType'] and not card['subType'].empty?
      data << " - #{card['subType']}"
    end
    unless card['description'].empty?
      data << " \"#{card['description']}\""
    end
    data << " {#{card['cardSetId']}}"
    if card['type'].include?('Creature')
      data << " #{card['power']}/#{card['toughness']}"
    elsif card['type'].include?('Planeswalker')
      data << " #{card['loyalty']}"
    end
    data << " #{card['rarity'][0]}"
  end

  def search(query)
    url = "http://api.mtgdb.info/search/#{URI::encode(query)}"

    res = open(url).read

    data = JSON.parse(res)

    if data.empty?
      "No results"
    elsif data.length == 1
      data[0]
    else
      #"[#{data.length} results] #{formatCard(data[0])}"
      data
    end
  rescue OpenURI::HTTPError
    "Error fetching card data"
  rescue JSON::ParserError
    "Error parsing fetched card data"
  #rescue
    #"Unknown error"
  end

  def legality(query)
    url = "http://api.mtgdb.info/search/#{URI::encode(query)}"

    res = open(url).read

    data = JSON.parse(res)

    if data.empty?
      "No results"
    elsif data.length == 1
      formatCard(data[0])
    else
      "[#{data.length} results] #{formatCard(data[0])}"
    end
  end

  def execute(m, command, query)
    command.downcase!

    if command == 'search'
      reply = search(query)
    elsif command == 'legality'
      reply = 'Unimplemented'
    else
      reply = 'Unknown command'
    end

    m.reply("#{m.user.nick}: #{reply}")
  end
end
