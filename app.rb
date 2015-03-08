require 'action_view'
require 'compass'
require 'haml'
require 'rdiscount'
require 'sass'
require 'sinatra'
require 'yaml'

configure do
  Compass.configuration do |config|
    config.project_path = File.dirname(__FILE__)
    config.sass_dir = 'views'
    config.images_dir = 'public/images'
    config.http_fonts_path = '/fonts'
    config.http_images_path = '/images'
  end

  set :haml, {format: :html5, escape_html: true}
  set :sass, Compass.sass_engine_options
  set :scss, Compass.sass_engine_options
  set :markdown, :layout_engine => :haml
end

$data = YAML.load(File.read("bullshit.yaml"))

class PennyArcadeBullshit
  include ActionView::Helpers::DateHelper

  attr_reader :date, :description, :url, :id, :apology

  def self.load(id)
    bullshit = $data['bullshit']
    id = bullshit.length + id + 1 if id < 0
    return if id == 0 || id > bullshit.length
    return new(bullshit[-id], id)
  end

  def initialize(map, id)
    @date = Date.parse(map['date'])
    @description = map['description'].strip
    @url = map['url']
    @apology = HalfAssedApology.new(map['apology']) if map['apology']
    @id = id
  end

  def most_recent?
    @id == $data['bullshit'].length
  end

  def date_distance(date = nil)
    distance_of_time_in_words(@date, date || Date.today)
  end

  def bullshit_url
    return "/" if most_recent?
    "/bullshit/#{id}"
  end

  def pronoun
    ["Mike Krahulik", "Jerry Holkins", "Robert Khoo"].each do |name|
      return 'he' if description.include?(name)
    end
    return 'they'
  end
end

class HalfAssedApology
  attr_reader :date
  attr_reader :url
  attr_reader :override

  def initialize(map)
    if map.is_a?(String)
      @override = map
    else
      @date = Date.parse(map['date'])
      @url = map['url']
    end
  end
end

get '/style.css' do
  scss :style
end

get '/' do
  @bullshit = PennyArcadeBullshit.load(-1)
  @previous_bullshit = PennyArcadeBullshit.load(-2)
  haml :bullshit
end

get '/acknowledgments' do
  markdown :acknowledgments
end

get '/bullshit/:id' do
  halt 400, "Invalid id." unless params[:id] =~ /^\d+$/

  id = params[:id].to_i
  @bullshit = PennyArcadeBullshit.load(id)
  halt 404, "No such bullshit." unless @bullshit

  @next_bullshit = PennyArcadeBullshit.load(id + 1)
  @previous_bullshit = PennyArcadeBullshit.load(id - 1)
  haml :bullshit
end
