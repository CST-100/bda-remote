module Craft
  # This module aims to encapsulate tools used to analyze or manipulate a KSP Craft file.
  class KspVessel
    def initialize(ship, parts, modules)
      @ship = ship
      @parts = parts
      @modules = modules
    end
    def ship
      @ship
    end
    def parts
      @parts
    end
    def modules
      @modules
    end
    def self.interpret(file)
      # read contents into memory
      puts "filename: #{file.original_filename}"
      puts "size: #{file.size}"
      puts "body: #{file.tempfile}"
      body = file.tempfile.read
      puts "opened: #{body.size()}"
      puts "line count: #{body.lines.count}"
      # rewind the file so the uploaded doesn't start at the end
      file.tempfile.rewind

      line = body.lines.first
      ship = /ship = (.+)/.match(line)[1]
      parts = body.lines.map { |e| /.*partName = (.+)/.match(e)[1] rescue nil }.compact
      modules = body.lines.map { |e| /.*name = (.+)/.match(e)[1] rescue nil }.compact
      return KspVessel.new(ship, parts, modules)
    end
  end

  def is_craft_file_valid?(file)
    # open the file, search through it, and identify all parts/modules
    craft = KspVessel.interpret(file)
    return false if craft.parts.count > 100
    return true
  end

end