require "watir-screenshot-stitch/version"
require "watir"
require "mini_magick"
require "os"
require "binding_of_caller"
require "base64"

MINIMAGICK_PIXEL_DIMENSION_LIMIT = 65500

module Watir
  class Screenshot

    #
    # Represents stitched together screenshot as Base64 encoded string.
    #
    # @example
    #   opts = {:page_height_limit => 5000}
    #   browser.screenshot.save_stitch("path/abc.png", browser, opts)
    #
    # @param [String] path
    # @param [Watir::Browser] browser
    # @param [Hash] opts
    #

    def save_stitch(path, browser, opts = {})
      @options = opts
      @path = path
      @browser = browser

      calculate_dimensions

      build_canvas

      gather_slices

      stitch_together

      @combined_screenshot.write @path
    end

    private
      def calculate_dimensions
        @start = MiniMagick::Image.read(Base64.decode64(self.base64))

        @viewport_height    = (@browser.execute_script "return window.innerHeight").to_f.to_i
        @page_height        = (@browser.execute_script "return Math.max( document.documentElement.scrollHeight, document.documentElement.getBoundingClientRect().height )").to_f.to_i

        @loops              = (@page_height / @viewport_height)
        @remainder          = (@page_height % @viewport_height)

        @mac_factor         = 2 if OS.mac?
        @mac_factor       ||= 1

      end

      def limit_page_height
        if @options[:page_height_limit] && ("#{@options[:page_height_limit]}".to_i > 0)
          @page_height      = [@options[:page_height_limit], @page_height].min
        end

        if (@page_height*@mac_factor > MINIMAGICK_PIXEL_DIMENSION_LIMIT)
          @page_height      = (MINIMAGICK_PIXEL_DIMENSION_LIMIT / @mac_factor)
        end # https://superuser.com/a/773436

        @loops              = (@page_height / @viewport_height)
        @remainder          = (@page_height % @viewport_height)
      end

      def build_canvas
        @combined_screenshot = MiniMagick::Image.new(@path)
        @combined_screenshot.run_command(:convert, "-size", "#{ @start.width }x#{ @page_height*@mac_factor }", "xc:white", @combined_screenshot.path)
      end

      def gather_slices
        @blocks = []

        @blocks << MiniMagick::Image.read(Base64.decode64(self.base64))

        @loops.times do |i|
          @browser.execute_script("window.scrollBy(0,#{@viewport_height})")
          @blocks << MiniMagick::Image.read(Base64.decode64(self.base64))
        end
      end

      def stitch_together
        @blocks.each_with_index do |next_screenshot, i|
          break if ( (@blocks.size == (i + 1)) && @crop_remainder )
          break if ( (@viewport_height * (i + 1) * @mac_factor) > MINIMAGICK_PIXEL_DIMENSION_LIMIT )

          if (@blocks.size == (i+1))
            # https://gist.github.com/maxivak/3924976
            next_screenshot.crop last_portion_crop(next_screenshot.width)

            height = geometry_height(next_screenshot.height, i)
          else
            height = (@viewport_height * i * @mac_factor)
          end
          puts "combine #{i} height #{height}"

          combine_screenshot(next_screenshot, height)
        end
      end

      def last_portion_crop(next_screenshot_width)
        "#{next_screenshot_width}x#{@remainder*@mac_factor}+0+#{(@viewport_height*@mac_factor - @remainder*@mac_factor)}!"
      end

      def geometry_height(next_screenshot_height, i)
        return (
          (
            next_screenshot_height * @mac_factor
          ) + (
            @viewport_height * (i - 1) * @mac_factor
          )
        ) + (
          (
            (
              @viewport_height * @mac_factor
            ) - (
              @remainder * @mac_factor
            )
          ) -
          next_screenshot_height
        )
      end

      def combine_screenshot(next_screenshot, offset)
        @combined_screenshot = @combined_screenshot.composite(next_screenshot) do |c|
          c.geometry "+0+#{offset}"
        end
      end
  end
end
