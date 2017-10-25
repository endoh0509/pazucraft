# Pazucraft

This is [pazcraft](https://github.com/chihayafuru/pazucraft) gem.  
You can convert to the development view for making the paper craft from the spherical image snapped with the RICOH THETA.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pazucraft', github: 'endoh0509/pazucraft'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pazucraft

## Usage

```ruby
require 'pazucraft'
input_file = 'img/in.jpg'
output_file = 'img/out.png'
Pazucraft::generate(input_file, output_file)
```

## Requirement

- ImageMagick
- rmagick

## Development

```bash
gem build pazucraft.gemspec
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

