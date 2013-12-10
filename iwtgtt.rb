require 'rest-client'
require 'addressable/uri'
require 'json'
require 'nokogiri'

class Store
  attr_accessor :name, :address, :location

  def initialize(name, address, location)
    @name, @address, @location = name, address, location
  end
end

class Finder
  def self.url_to_coord(url)
    response = RestClient.get(url)
    response = JSON.parse(response)
    response = response["results"].first
    response = response["geometry"]
    response = response["location"]
    "#{response["lat"]},#{response["lng"]}"
  end

  def self.create_url_for_geocoding(address)
    address_str = address.gsub(/\s+/, '+')
    Addressable::URI.new(
      :scheme => "http",
      :host => "maps.googleapis.com",
      :path => "maps/api/geocode/json",
      :query_values => { :address => address_str, :sensor => false }
    ).to_s
  end

  def self.create_url_for_place(coord, store_type)
    Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/place/textsearch/json",
      :query_values => {:query => store_type,
                        :sensor => false,
                        :key=>"AIzaSyAu5qwvIIDcKQHMb1Mdy70CAX4D0ssXZi4",
                        :location => coord, :radius => "50"
                        }
    ).to_s
  end

  def self.get_store_coord(url)
    response = RestClient.get(url)
    response = JSON.parse(response)
    response = response["results"][0..9]
    stores = []

    response.each do |store|
      name = store["name"]
      address = store["formatted_address"]
      lat_and_lng = store["geometry"]["location"]
      coord_str = "#{lat_and_lng["lat"]},#{lat_and_lng["lng"]}"

      stores << Store.new(name, address, coord_str)
    end

    stores
  end

  def self.create_url_for_direction(origin, destination)
    Addressable::URI.new(
      :scheme => "https",
      :host => "maps.googleapis.com",
      :path => "maps/api/directions/json",
      :query_values => { :origin => origin,
                         :destination => destination,
                         :mode => "walking",
                         :sensor => false
                       }
    ).to_s
  end

  def self.display_directions(url)
    response = RestClient.get(url)
    response = JSON.parse(response)
    response = response["routes"].first
    response = response["legs"].first
    steps = response["steps"]
    steps.each do |step|
      direction_steps =  Nokogiri::HTML(step["html_instructions"]).text
      puts direction_steps.gsub("Destination", "\nDestination")
    end


  end

  def self.get_directions(address, store_type)
    origin_url = create_url_for_geocoding(address)
    origin_coord = url_to_coord(origin_url)
    places_url = create_url_for_place(origin_coord, store_type)
    stores = get_store_coord(places_url)

    stores.each do |store|
      puts store.name
      puts store.address
      direction_url = create_url_for_direction(origin_coord, store.location)
      display_directions(direction_url)
      puts
    end
    
    nil
  end
end