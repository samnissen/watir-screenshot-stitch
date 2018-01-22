RSpec.describe Watir::Screenshot do
  let(:png_header) { "\211PNG".force_encoding('ASCII-8BIT') }

  it "has a version number" do
    expect(WatirScreenshotStitch::VERSION).not_to be nil
  end

  after(:each) do
    @browser.close if @browser
    File.delete(@path) if @path
  end

  it "saves stitched-together screenshot" do
    @path = "#{Dir.tmpdir}/test#{Time.now.to_i}.png"
    expect(File).to_not exist(@path)
    opts = { :page_height_limit => 2500 }

    @browser = Watir::Browser.new :firefox
    @browser.goto "https://github.com/mozilla/geckodriver/issues/570"
    @browser.screenshot.save_stitch(@path, @browser, opts)

    expect(File).to exist(@path)
    expect(File.open(@path, "rb") { |io| io.read }[0..3]).to eq png_header

    image = MiniMagick::Image.open(@path)
    height = opts[:page_height_limit]

    s = Watir::Screenshot.new(@browser.driver)
    s.instance_variable_set(:@browser, @browser)
    height = height * 2 if s.send(:retina?)
    
    expect(image.height).to be <= height
  end

  it "gets a base64 screenshot payload" do
    @browser = Watir::Browser.new :firefox
    @browser.goto "https://github.com/mozilla/geckodriver/issues/570"
    out = @browser.screenshot.base64_canvas(@browser)

    expect(out).to be_a(String)
    expect{
      MiniMagick::Image.read(Base64.decode64(out))
    }
    viewport = (@browser.execute_script "return window.innerHeight").to_f.to_i
    expect(MiniMagick::Image.read(Base64.decode64(out)).height).to be >= viewport
  end

  it "stops taking screenshots when page is the height of the screenshot" do
    @browser = Watir::Browser.new :firefox
    @browser.goto "https://google.com"

    s = Watir::Screenshot.new(@browser.driver)
    s.instance_variable_set(:@browser, @browser)
    mac_factor   = 2 if s.send(:retina?)
    mac_factor ||= 1

    image = MiniMagick::Image.read(Base64.decode64(@browser.screenshot.base64_canvas(@browser)))
    page_height = (@browser.execute_script "return Math.max( document.documentElement.scrollHeight, document.documentElement.getBoundingClientRect().height )").to_f.to_i
    expect(image.height).to eq(page_height*mac_factor)

    s = Watir::Screenshot.new @browser.driver
    s.instance_variable_set(:@browser, @browser)
    expect(s.send(:one_shot?)).to be_truthy
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
    # @browser = Watir::Browser.new :firefox
    # @browser.goto "https://sixcolors.com"
    # image = MiniMagick::Image.read(Base64.decode64(@browser.screenshot.base64_canvas(@browser)))
    # page_height = (@browser.execute_script "return Math.max( document.documentElement.scrollHeight, document.documentElement.getBoundingClientRect().height )").to_f.to_i
    # expect(image.height).to eq(page_height)
    # expect(s.send(:bug_shot?)).to be_truthy
  # end
end
