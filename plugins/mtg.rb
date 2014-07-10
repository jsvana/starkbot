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

  def query(query)
    url = "http://api.mtgdb.info/search/#{URI::encode(query)}"

    res = open(url).read

    JSON.parse(res)
  rescue OpenURI::HTTPError
    "Error fetching card data"
  rescue JSON::ParserError
    "Error parsing fetched card data"
  #rescue
    #"Unknown error"
  end

  def search(query)
    data = query(query)
    if data.is_a?(String)
      return data
    end

    if data.empty?
      "No results found"
    elsif data.length == 1
      formatCard(data[0])
    else
      "[#{data.length} results] #{formatCard(data[0])}"
    end
  end

  def formatLegality(card)
    legal = card['formats'].select { |f| f['legality'] == 'Legal' }.map { |f| f['name'] }.join(', ')
    banned = card['formats'].select { |f| f['legality'] == 'Banned' }.map { |f| f['name'] }.join(', ')

    out = card['name']
    unless legal.empty?
      out << ", legal in #{legal}"
    end
    unless banned.empty?
      out << ", banned in #{banned}"
    end

    out
  end

  def legality(query)
    data = query(query)
    if data.is_a?(String)
      return data
    end

    if data.empty?
      "No results found"
    elsif data.length == 1
      formatLegality(data[0])
    else
      "[#{data.length} results] #{formatLegality(data[0])}"
    end
  end

  def formatRulings(card)
    card['rulings'].map { |r| "#{r['releasedAt']}: #{r['rule']}" }.join(', ')
  end

  def rulings(query)
    data = query(query)
    if data.is_a?(String)
      return data
    end

    if data.empty?
      "No results found"
    elsif data.length == 1
      formatRulings(data[0])
    else
      "[#{data.length} results] #{formatRulings(data[0])}"
    end
  end

  def execute(m, command, query)
    command.downcase!

    if command == 'search'
      reply = search(query)
    elsif command == 'legality'
      reply = legality(query)
    elsif command == 'rulings'
      reply = rulings(query)
    else
      reply = 'Unknown command'
    end

    m.reply("#{m.user.nick}: #{reply}")
  end
end
