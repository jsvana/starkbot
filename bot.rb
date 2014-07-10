require 'cinch'
require 'json'

Dir["#{File.dirname(__FILE__)}/plugins/*.rb"].each {|file| require file }

bot = Cinch::Bot.new do
  config = JSON.parse(File.read('config.json'))

  configure do |c|
    c.server = config['server']
    c.channels = config['channels']
    c.nick = config['nick']
    if config['password']
      c.password = config['password']
    end
		c.plugins.prefix = lambda { |msg| Regexp.compile("^#{Regexp.escape(msg.bot.nick)}:?\s*") }
    c.plugins.plugins = config['plugins'].map do |p|
      Module.const_get(p)
    end
  end

  trap "SIGINT" do
    bot.quit
  end
end

bot.start
