# watir-screenshot-stitch

watir-screenshot-stitch attempts to compensate for Mozilla's decision
not to (yet?) expose Firefox's full page screenshot functionality
via geckodriver, [as indicated here](https://github.com/mozilla/geckodriver/issues/570),
by paging down a given URL by the size of the viewport, capturing
the entire page in the process.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'watir-screenshot-stitch'
```

### MiniMagick

watir-screenshot-stitch relies on [MiniMagick](https://github.com/minimagick/minimagick)
(and thus ImageMagick). You might need to review that gem's requirements and
installation before proceeding.

### Firefox

watir-screenshot-stitch is optimized for and tested on Firefox. Your
Watir / Selenium-Webdriver / geckodriver / Firefox stack must be correctly
configured. If you can find a good guide for installing and maintaining all
parts of this stack, you're a better Googler than me.

## Usage

### Stitching

watir-screenshot-stitch can be used with a typical Watir script. This

```ruby
require 'watir-screenshot-stitch'
path = "/my/path/image.png"
opts = { :page_height_limit => 5000 }

b = Watir::Browser.new :firefox
b.goto "https://github.com/mozilla/geckodriver/issues/570"
b.screenshot.save_stitch(path, b, opts)
```

will stitch together and save a full-page screenshot, up to 5000 pixels tall,
to `/my/path/image.png`.

### html2canvas

html2canvas is a JavaScript library watir-screenshot-stitch can employ to
try to create a canvas element of the entire page and covert it to a blob.
For instance,

```ruby
require 'watir-screenshot-stitch'

b = Watir::Browser.new :firefox
b.goto "https://github.com/watir/watir/issues/702"
b.screenshot.base64_canvas(b)
```

will return a base64 encoded image blob of the given site.

### Doubling resolution calculations, including macOS Retina

watir-screenshot-stitch uses CSS selectors to determine whether a
resulting screenshot's dimensions will be double
the page dimensions when a screenshot is captured,
as is the case for macOS 'Retina', and relies on this
logic to determine how to stitch together images.
This means that moving the browser window while it is be driven by
Watir can cause unpredictable results.

### Passing the browser?

This is obviously awkward and obtuse. Because watir-screenshot-stitch
patches Watir, it does not change the way Watir calls the Screenshot class,
which does not know about the Browser instance (it instead knows
about the driver). And watir-screenshot-stitch needs the browser to execute
JavaScript on the page.

### Options

A hash of key value pairs.

#### `:page_height_limit`
Should refer to a positive Integer greater than the viewport height.

### Maximum height
ImageMagick has a maximum pixel dimension of 65500, and all screenshots
will be capped to a maximum height of 65500 regardless of any options
to avoid errors.

## Development

TODO: This.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/watir-screenshot-stitch. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Watir::Screenshot::Stitch project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/samnissen/watir-screenshot-stitch/blob/master/CODE_OF_CONDUCT.md).
