require "heroku/command"
require "excon"

# access devcenter documentation
class Heroku::Command::Docs < Heroku::Command::Base

  # docs TOPIC
  #
  # get devcenter documentation on TOPIC
  #
  def index
    unless topic = shift_argument
      error("Usage: heroku docs: TOPIC\nMust specify TOPIC to open docs for.")
    end

    docs(topic, "https://devcenter.heroku.com/articles/#{topic}")
  end

  private

  def docs(topic, url)
    head = Excon.head(url)
    case head.status
    when 200
      action("Opening #{topic} docs") do
        require('launchy')
        launchy = Launchy.open(url)
        if launchy.respond_to?(:join)
          launchy.join
        end
      end
    when 301, 302
      docs(head.headers['Location'])
    when 404
      message = [
        "No #{topic} article found."
      ]
      suggestions = json_decode(Excon.get('https://devcenter.heroku.com/articles.json', :query => { :q => topic, :source => 'heroku-docs' }).body)['devcenter']
      unless suggestions.empty?
        message << "Perhaps you meant one of these:"
        longest = suggestions.map {|suggestion| suggestion['url'].split('/articles/').last.length }.max
        suggestions.each do |suggestion|
          message << "  %-#{longest}s # %s" % [suggestion['url'].split('/articles/').last, suggestion['title']]
        end
      end
      error(message.join("\n"))
    end
  end

end
