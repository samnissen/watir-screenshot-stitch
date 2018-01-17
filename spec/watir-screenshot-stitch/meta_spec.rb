RSpec.describe WatirScreenshotStitch::Utilities do
  it "returns a valid directory" do
    expect{WatirScreenshotStitch::Utilities.directory}.not_to raise_error
  end
end
