RSpec.describe WatirScreenshotStitch do
  it "has a version number" do
    expect(WatirScreenshotStitch::VERSION).not_to be nil
  end
end

RSpec.describe WatirScreenshotStitch::Utilities do
  it "returns a valid directory" do
    expect{WatirScreenshotStitch::Utilities.directory}.not_to raise_error
  end
end
