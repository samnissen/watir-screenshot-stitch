# watir-screenshot-stitch

watir-screenshot-stitch attempts to compensate for
the lack of full page screenshot functionality
in Selenium Webdriver.

It does so in three ways:

* Directly employing geckodriver's new full page screenshot
functionality (only on Firefox).
* Screenshot stitching, paging down a given URL by the size 
of the viewport, capturing screenshots and adjoining them.
* Employing a bundled
[html2canvas](https://github.com/niklasvh/html2canvas)
script against the page to generate a png from a `canvas`
element. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'watir-screenshot-stitch'
```

### MiniMagick

watir-screenshot-stitch relies on [MiniMagick](https://github.com/minimagick/minimagick)
(and thus ImageMagick). You might need to review that gem's requirements and
installation before proceeding.

### Browser Support

watir-screenshot-stitch is optimized for and tested on following browsers:
* Chrome 65+
* Firefox 58+
* Safari 11.1
* IE 11/10/9/8

Your Watir / Selenium-Webdriver / webdriver / Browser stack must be correctly
configured. If you can find a good guide for installing and maintaining all
parts of this stack, you're a better Googler than me.

## Usage

### Special note: Upgrading from <= 0.6.11

As warned in version 0.6.6 and beyond, the Watir::Screenshot
class will have access to the browser in watir-screenshot-stitch
version 0.7.0 and beyond, and it will not need to be
passed to the public methods. Previous implementations will break.

To adapt, change your function calls like so:

<table>
  <thead>
    <tr>
    <th>
      <= 0.6.5
    </th>
    <th>
      >= 0.6.6 && <= 0.6.11
    </th>
    <th>
      >= 0.7.0
    </th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>
        `save_stitch(path, browser, opts)`
      </td>
      <td>
        `save_stitch(path, nil, opts)` or
        `save_stitch(path, browser, opts)`
      </td>
      <td>
        `save_stitch(path, opts)`
      </td>
    </tr>
    <tr>
      <td>
        `base64_canvas(browser)`
      </td>
      <td>
        `base64_canvas(browser)` or `base64_canvas`
      </td>
      <td>
        `base64_canvas`
      </td>
    </tr>
  </tbody>
</table>

### Using geckodriver

watir-screenshot-stitch can employ a special function of geckodriver >= 0.24.0
while driving Firefox. This

```ruby
require 'watir-screenshot-stitch'
b = Watir::Browser.new :firefox
b.goto "https://github.com/mozilla/geckodriver/issues/570"
b.base64_geckodriver
```
will return a base64 encoded image blob of the given site.

In can be saved as a PNG by doing:
```ruby
png = b.screenshot.base64_geckodriver
path = "/my/path/image.png"
File.open(path, 'wb') { |f| f.write(Base64.decode64(png)) }
```

This is the option with the fewest complications, and should be used
if possible.

#### User geckodriver vs. webdrivers geckodriver

If using the webdrivers gem, watir-screenshot-stitch will attempt to
use the geckodriver included there, since that's likely to be
the driver employed by watir. If not, it falls back to the the system user's geckodriver.

### Stitching

watir-screenshot-stitch can be used with a typical Watir script. This

```ruby
require 'watir-screenshot-stitch'
path = "/my/path/image.png"
opts = { :page_height_limit => 5000 }

b = Watir::Browser.new :firefox
b.goto "https://github.com/mozilla/geckodriver/issues/570"
b.screenshot.save_stitch(path, opts)
```

will stitch together and save a full-page screenshot, up to 5000 pixels tall,
to `/my/path/image.png`.

### html2canvas

html2canvas is a JavaScript library watir-screenshot-stitch can employ to
try to create a canvas element of the entire page and covert it to a blob.
For instance, this

```ruby
require 'watir-screenshot-stitch'

b = Watir::Browser.new :firefox
b.goto "https://github.com/watir/watir/issues/702"
b.screenshot.base64_canvas
```

will return a base64 encoded image blob of the given site.

In can be saved as a PNG by doing:
```ruby
png = b.screenshot.base64_canvas
path = "/my/path/image.png"
File.open(path, 'wb') { |f| f.write(Base64.decode64(png)) }
```

This method of screenshotting
is less likely to have issues with stitching the images together,
and running out of memory but has limitations with certain element
types not being properly displayed. See their documentation for
more information.

### Doubling resolution calculations, including macOS Retina

watir-screenshot-stitch uses CSS selectors to determine whether a
resulting screenshot's dimensions will be double
the page dimensions when a screenshot is captured,
as is the case for macOS 'Retina', and relies on this
logic to determine how to stitch together images.
This means that moving the browser window while it is be driven by
Watir can cause unpredictable results.

### Options

A hash of key value pairs.

#### `:page_height_limit`
Should refer to a positive Integer greater than the viewport height.

### Maximum height
ImageMagick has a maximum pixel dimension of 65500, and all stitched
screenshots will be capped to a maximum height of 65500 regardless 
of any options to avoid errors.

## Development

Use `rspec` to run the tests, and see the
(contributing)[#Contributing] section below &mdash;
all are welcome.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/samnissen/watir-screenshot-stitch. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Watir::Screenshot::Stitch project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/samnissen/watir-screenshot-stitch/blob/master/CODE_OF_CONDUCT.md).
