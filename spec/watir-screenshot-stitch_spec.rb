RSpec.describe Watir::Screenshot do
  let(:png_header) { "\211PNG".force_encoding('ASCII-8BIT') }

  after(:each) do
    @browser.close if @browser
    File.delete(@path) if @path
  end

  context "driving firefox" do
    let(:browser_key) { :firefox }

    it "gets a base64 screenshot payload from base64_geckodriver" do
      @browser = Watir::Browser.new browser_key
      @browser.goto "https://github.com/mozilla/geckodriver/issues/570"
      out = @browser.screenshot.base64_geckodriver

      expect(out).to be_a(String)
      expect{
        MiniMagick::Image.read(Base64.decode64(out))
      }.not_to raise_error
      viewport = (@browser.execute_script "return window.innerHeight").to_f.to_i
      expect(MiniMagick::Image.read(Base64.decode64(out)).height).to be >= viewport
    end

    it "saves stitched-together screenshot" do
      @path = "#{Dir.tmpdir}/test#{Time.now.to_i}.png"
      expect(File).to_not exist(@path)
      opts = { :page_height_limit => 2500 }

      @browser = Watir::Browser.new browser_key
      @browser.goto "https://github.com/mozilla/geckodriver/issues/570"
      @browser.screenshot.save_stitch(@path, opts)

      expect(File).to exist(@path)
      expect(File.open(@path, "rb") { |io| io.read }[0..3]).to eq png_header

      image = MiniMagick::Image.open(@path)
      height = opts[:page_height_limit]

      s = Watir::Screenshot.new(@browser)
      s.instance_variable_set(:@browser, @browser)
      height = height * 2 if s.send(:retina?)

      expect(image.height).to be <= height
    end

    it "gets a base64 screenshot payload from base64_canvas" do
      @browser = Watir::Browser.new browser_key
      @browser.goto "https://github.com/mozilla/geckodriver/issues/570"
      out = @browser.screenshot.base64_canvas

      expect(out).to be_a(String)
      expect{
        MiniMagick::Image.read(Base64.decode64(out))
      }.not_to raise_error
      viewport = (@browser.execute_script "return window.innerHeight").to_f.to_i
      expect(MiniMagick::Image.read(Base64.decode64(out)).height).to be >= viewport
    end

    it "stops taking screenshots when page is the height of the screenshot" do
      @browser = Watir::Browser.new browser_key
      @browser.goto "https://google.com"

      s = Watir::Screenshot.new(@browser)
      s.instance_variable_set(:@browser, @browser)
      mac_factor   = 2 if s.send(:retina?)
      mac_factor ||= 1

      image = MiniMagick::Image.read(Base64.decode64(@browser.screenshot.base64_canvas))
      page_height = (@browser.execute_script "return Math.max( document.documentElement.scrollHeight, document.documentElement.getBoundingClientRect().height )").to_f.to_i
      expect(image.height).to eq(page_height*mac_factor)

      s = Watir::Screenshot.new @browser
      s.instance_variable_set(:@browser, @browser)
      expect(s.send(:one_shot?)).to be_truthy
    end

    it "recalulates the screen resolution each time" do
      @browser = Watir::Browser.new browser_key
      @screenshot = @browser.screenshot

      allow(@screenshot).to receive(:retina?).and_return(true)
      @screenshot.send(:calculate_dimensions)
      expect(@screenshot.instance_variable_get(:@mac_factor)).to eq(2)

      allow(@screenshot).to receive(:retina?).and_return(false)
      @screenshot.send(:calculate_dimensions)
      expect(@screenshot.instance_variable_get(:@mac_factor)).to eq(1)
    end

    # this cannot be tested right now because of:
    # Selenium::WebDriver::Error::UnknownError: [Exception... "Failure"  nsresult: "0x80004005 (NS_ERROR_FAILURE)"  location: "JS frame :: chrome://marionette/content/capture.js :: capture.canvas :: line 134"  data: no]
  	#   from capture.canvas@chrome://marionette/content/capture.js:134:3
  	#   from capture.viewport@chrome://marionette/content/capture.js:71:10
  	#   from takeScreenshot@chrome://marionette/content/listener.js:1776:14
  	#   from dispatch/</req<@chrome://marionette/content/listener.js:519:16
  	#   from dispatch/<@chrome://marionette/content/listener.js:517:16
  	#   from /Users/samuel.nissen/.rvm/gems/ruby-2.4.1/gems/selenium-webdriver-3.8.0/lib/selenium/webdriver/remote/response.rb:69:in `assert_ok'
    #   ...
    # it "stops taking screenshots when given full screenshot" do
      # @browser = Watir::Browser.new browser_key
      # @browser.goto "https://sixcolors.com"
      # image = MiniMagick::Image.read(Base64.decode64(@browser.screenshot.base64_canvas))
      # page_height = (@browser.execute_script "return Math.max( document.documentElement.scrollHeight, document.documentElement.getBoundingClientRect().height )").to_f.to_i
      # expect(image.height).to eq(page_height)
      # expect(s.send(:bug_shot?)).to be_truthy
    # end
  end

  context "driving chrome" do
    let(:browser_key) { :chrome }

    it "saves stitched-together screenshot" do
      @path = "#{Dir.tmpdir}/test#{Time.now.to_i}.png"
      expect(File).to_not exist(@path)
      opts = { :page_height_limit => 2500 }

      @browser = Watir::Browser.new browser_key
      @browser.goto "https://github.com/mozilla/geckodriver/issues/570"
      @browser.screenshot.save_stitch(@path, opts)

      expect(File).to exist(@path)
      expect(File.open(@path, "rb") { |io| io.read }[0..3]).to eq png_header

      image = MiniMagick::Image.open(@path)
      height = opts[:page_height_limit]

      s = Watir::Screenshot.new(@browser)
      s.instance_variable_set(:@browser, @browser)
      height = height * 2 if s.send(:retina?)

      expect(image.height).to be <= height
    end

    it "gets a base64 screenshot payload" do
      @browser = Watir::Browser.new browser_key
      @browser.goto "https://github.com/mozilla/geckodriver/issues/570"
      out = @browser.screenshot.base64_canvas

      expect(out).to be_a(String)
      expect{
        MiniMagick::Image.read(Base64.decode64(out))
      }
      viewport = (@browser.execute_script "return window.innerHeight").to_f.to_i
      expect(MiniMagick::Image.read(Base64.decode64(out)).height).to be >= viewport
    end

    it "stops taking screenshots when page is the height of the screenshot" do
      @browser = Watir::Browser.new browser_key
      @browser.goto "https://google.com"

      s = Watir::Screenshot.new(@browser)
      s.instance_variable_set(:@browser, @browser)
      mac_factor   = 2 if s.send(:retina?)
      mac_factor ||= 1

      image = MiniMagick::Image.read(Base64.decode64(@browser.screenshot.base64_canvas))
      page_height = (@browser.execute_script "return Math.max( document.documentElement.scrollHeight, document.documentElement.getBoundingClientRect().height )").to_f.to_i
      expect(image.height).to eq(page_height*mac_factor)

      s = Watir::Screenshot.new @browser
      s.instance_variable_set(:@browser, @browser)
      expect(s.send(:one_shot?)).to be_truthy
    end

    it "handles cross-domain images and svgs" do
      pending("a version of base64_canvas that can actually do this")

      @browser = Watir::Browser.new browser_key
      @browser.goto "https://advisors.massmutual.com/"
      path1 = "#{Dir.tmpdir}/base64-test#{Time.now.to_i}.png"
      path2 = "#{Dir.tmpdir}/save-test#{Time.now.to_i}.png"
      opts = { :page_height_limit => 10000 }

      @browser.goto "https://advisors.massmutual.com/"
      res = @browser.screenshot.base64_canvas
      @browser.screenshot.save_stitch(path2, opts)
      File.open(path1, 'wb') {|f| f.write(Base64.decode64(res)) }

      diff = []
      images = [
        ChunkyPNG::Image.from_file(path1),
        ChunkyPNG::Image.from_file(path2),
      ]

      images.first.height.times do |y|
        images.first.row(y).each_with_index do |pixel, x|
          diff << [x,y] unless pixel == images.last[x,y]
        end
      end
      # https://jeffkreeftmeijer.com/ruby-compare-images/
      # https://gist.github.com/jeffkreeftmeijer/923894

      expect((diff.length.to_f / images.first.pixels.length) * 100).to be >= (80.0)
    end
  end
end
