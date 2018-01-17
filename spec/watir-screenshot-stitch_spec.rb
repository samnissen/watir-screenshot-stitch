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
    height = height * 2 if OS.mac?
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
end
