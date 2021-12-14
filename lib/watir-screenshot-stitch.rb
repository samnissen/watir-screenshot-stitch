require "time"
require "watir-screenshot-stitch/version"
require "watir"
require "mini_magick"
require "os"
require "binding_of_caller"
require "base64"

MINIMAGICK_PIXEL_DIMENSION_LIMIT = 65500
MAXIMUM_SCREENSHOT_GENERATION_WAIT_TIME = 120
RANGE_MOD = 0.02

module Watir
  class Screenshot

    #
    # Employs a cutting edge feature in geckodriver version 0.24.0
    # to produce a Base64 encoded string of a full page screenshot.
    #
    # @warning
    #   This will fail if geckodriver is less than version 0.24.0.
    #
    # @info
    #   This is only a patch until this is baked into Selenium/Watir.
    #
    # @example
    #   browser.screenshot.base64_geckodriver
    #   #=> '7HWJ43tZDscPleeUuPW6HhN3x+z7vU/lufmH0qNTtTum94IBWMT46evImci1vnFGT'
    #
    # @return [String]
    #

    def base64_geckodriver
      ensure_geckodriver

      resource_url = build_driver_url

      raw = request_payload(resource_url)

      parse_gecko(raw)
    end

    #
    # Represents stitched together screenshot and writes to file.
    #
    # @example
    #   opts = {:page_height_limit => 5000}
    #   browser.screenshot.save_stitch("path/abc.png", browser, opts)
    #
    # @param [String] path
    # @deprecated
    #   @param [Watir::Browser] browser
    # @param [Hash] opts
    #

    def save_stitch(path, opts = {})
      return @browser.screenshot.save(path) if base64_capable?
      @options = opts
      @path = path
      calculate_dimensions

      return self.save(@path) if (one_shot? || bug_shot?)

      build_canvas
      gather_slices
      stitch_together

      @combined_screenshot.write @path
    end

    #
    # Employs html2canvas to produce a Base64 encoded string
    # of a full page screenshot.
    #
    # @example
    #   browser.screenshot.base64_canvas(browser)
    #   #=> '7HWJ43tZDscPleeUuPW6HhN3x+z7vU/lufmH0qNTtTum94IBWMT46evImci1vnFGT'
    #
    # @deprecated
    #   @param [Watir::Browser] browser
    #
    # @return [String]
    #

    def base64_canvas
      return self.base64 if base64_capable?
      output = nil

      return self.base64 if one_shot? || bug_shot?

      @browser.execute_script html2canvas_payload
      @browser.execute_script h2c_activator

      @browser.wait_until(timeout: MAXIMUM_SCREENSHOT_GENERATION_WAIT_TIME) {
        output = @browser.execute_script "return window.canvasImgContentDecoded;"
      }

      raise "Could not generate screenshot blob within #{MAXIMUM_SCREENSHOT_GENERATION_WAIT_TIME} seconds" unless output

      output.sub!(/^data\:image\/png\;base64,/, '')
    end

    private
      def parse_gecko(raw = '')
        JSON.parse(raw, symbolize_names: true)[:value]
      rescue JSON::ParserError => e
        raise "geckodriver response '#{raw}' was malformed"
      end

      def request_payload(request_url)
        url = URI.parse(request_url)
        req = Net::HTTP::Get.new(request_url)
        Net::HTTP.start(url.host, url.port) {|http| http.request(req) }.body
      rescue Errno::ECONNREFUSED => e
        raise "geckodriver could not be accessed at '#{request_url}'"
      end

      def build_driver_path
        bridge = @browser.driver.session_storage.instance_variable_get(:@bridge)
        sid = bridge.instance_variable_get(:@session_id)

        raise "Unable to get geckodriver session ID." unless sid

        "session/#{sid}/moz/screenshot/full"
      end

      def build_driver_url
        bridge = @browser.driver.session_storage.instance_variable_get(:@bridge)
        server_uri = bridge.instance_variable_get(:@http).instance_variable_get(:@server_url)

        raise "Unable to get geckodriver server URI." unless server_uri

        request_url = server_uri.to_s + build_driver_path
      end

      def ensure_geckodriver
        raise "base64_geckodriver only works on Firefox" unless @browser.name == :firefox

        if webdrivers_defined?
          current_version = Webdrivers::Geckodriver.current_version
        else
          current_version = Gem::Version.new(%x{geckodriver --version}.match(/geckodriver (\d+\.\d+\.\d+)/)[1])
        end

        correct_version = (current_version >= Gem::Version.new("0.24.0"))

        raise "base64_geckodriver requires version 0.24.x or greater" unless correct_version
      end

      def webdrivers_defined?
        Object.const_get("Webdrivers")
      rescue NameError
        nil
      end

      # in IE & Safari a regular screenshot is a full page screenshot only
      def base64_capable?
        [:internet_explorer, :safari].include? @browser&.name
      end

      def one_shot?
        calculate_dimensions unless @loops && @remainder
        ( (@loops == 1) && (@remainder == 0) )
      end

      def bug_shot?
        return false unless @browser&.name == :firefox
        calculate_dimensions unless @page_height

        image = MiniMagick::Image.read(Base64.decode64(self.base64))
        range = [
          ( @page_height.to_f - (@page_height.to_f * RANGE_MOD) ).to_i,
          ( @page_height.to_f + (@page_height.to_f * RANGE_MOD) ).to_i
        ]
        image.height.between? *range
      end # https://github.com/mozilla/geckodriver/issues/1129

      def h2c_activator
        case @browser.driver.browser
        when :firefox
          %<
            function genScreenshot () {
              var canvasImgContentDecoded;
              html2canvas(document.body, {
                onrendered: function (canvas) {
                 window.canvasImgContentDecoded = canvas.toDataURL("image/png");
              }});
            };
            genScreenshot();
          >.gsub(/\s+/, ' ').strip
        else
          %<
            function genScreenshot () {
              var canvasImgContentDecoded;
              html2canvas(document.body).then(function (canvas) {
                window.canvasImgContentDecoded = canvas.toDataURL("image/png");
              });
            };
            genScreenshot();
          >.gsub(/\s+/, ' ').strip
        end
      end

      def html2canvas_payload
        case @browser.driver.browser
        when :firefox
          path = File.expand_path("../../vendor/html2canvas-0.4.1.js", __FILE__)
          File.read(path)
        else
          path = File.expand_path("../../vendor/html2canvas.js", __FILE__)
          File.read(path)
        end
      end

      def calculate_dimensions
        @viewport_height    = (@browser.execute_script "return window.innerHeight").to_f.to_i
        @page_height        = (@browser.execute_script "return Math.max( document.documentElement.scrollHeight, document.documentElement.getBoundingClientRect().height )").to_f.to_i

        @mac_factor         = retina? ? 2 : 1

        limit_page_height

        @loops              = (@page_height / @viewport_height)
        @remainder          = (@page_height % @viewport_height)
      end

      def limit_page_height
        @original_page_height = @page_height

        if @options && ("#{@options[:page_height_limit]}".to_i > 0)
          @page_height      = [@options[:page_height_limit], @page_height].min
        end

        if (@page_height*@mac_factor > MINIMAGICK_PIXEL_DIMENSION_LIMIT)
          @page_height      = (MINIMAGICK_PIXEL_DIMENSION_LIMIT / @mac_factor)
        end # https://superuser.com/a/773436
      end

      def build_canvas
        @start = MiniMagick::Image.read(Base64.decode64(self.base64))
        @combined_screenshot = MiniMagick::Image.new(@path)
        @combined_screenshot.run_command(:convert, "-size", "#{ @start.width }x#{ @page_height*@mac_factor }", "xc:white", "-define", "png:color-type=6", @combined_screenshot.path)
      end

      def gather_slices
        @blocks = []

        scroll_to_top

        @blocks << MiniMagick::Image.read(Base64.decode64(self.base64))

        @loops.times do |i|
          @browser.execute_script("window.scrollBy(0,#{@viewport_height})")
          @blocks << MiniMagick::Image.read(Base64.decode64(self.base64))
        end
      end

      def scroll_to_top
        @browser.execute_script("document.body.scrollTop = document.documentElement.scrollTop = 0;")
      end

      def stitch_together
        @blocks.each_with_index do |next_screenshot, i|
          if (@blocks.size == (i+1)) && (@original_page_height == @page_height)
            next_screenshot.crop last_portion_crop(next_screenshot.width)
          end

          height = (@viewport_height * i * @mac_factor)
          combine_screenshot(next_screenshot, height)
        end
      end

      def last_portion_crop(next_screenshot_width)
        "#{next_screenshot_width}x#{@remainder*@mac_factor}+0+#{(@viewport_height*@mac_factor - @remainder*@mac_factor)}!"
      end # https://gist.github.com/maxivak/3924976

      def combine_screenshot(next_screenshot, offset)
        @combined_screenshot = @combined_screenshot.composite(next_screenshot) do |c|
          c.geometry "+0+#{offset}"
        end
      end

      def retina?
        payload = %{ var mq = window.matchMedia("only screen and (min--moz-device-pixel-ratio: 1.3), \
                                                  only screen and (-o-min-device-pixel-ratio: 2.6/2), \
                                                  only screen and (-webkit-min-device-pixel-ratio: 1.3), \
                                                  only screen  and (min-device-pixel-ratio: 1.3), \
                                                  only screen and (min-resolution: 1.3dppx)");
                      return (mq && mq.matches || (window.devicePixelRatio > 1)); }
        @browser.execute_script payload
      end
  end
end
