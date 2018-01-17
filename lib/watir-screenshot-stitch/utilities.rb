module WatirScreenshotStitch
  module Utilities
    # Return a directory with the project libraries.
    def self.directory
      t = ["#{File.dirname(File.expand_path($0))}/../lib/#{WatirScreenshotStitch::NAME}",
           "#{Gem.dir}/gems/#{WatirScreenshotStitch::NAME}-#{WatirScreenshotStitch::VERSION}"]
      t.each {|i| return i if File.readable?(i) }
      raise "watir-screenshot-stitch could not be found in: #{t}"
    end # https://stackoverflow.com/a/5805783/1651458
  end
end
