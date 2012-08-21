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
      display(format_with_bang("No doc matches #{topic}."))
      action("Opening search for #{topic}") do
        require('launchy')
        launchy = Launchy.open("https://devcenter.heroku.com/articles?q=#{topic}")
        if launchy.respond_to?(:join)
          launchy.join
        end
      end
    end
  end

end
