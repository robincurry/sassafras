$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'

gem     'color-tools'
require 'color'

gem     'activesupport'
require 'activesupport'

require 'erb'

module Sassafras

  class Theme

    attr_reader :base_rgb

    class << self
      def create(type, base)
        Theme.send(type, base)
      end

      def basic(base)
        Theme.new(base)
      end

      def complementary(base)
        ComplementaryTheme.new(base)
      end

      def analogous(base)
        AnalogousTheme.new(base)
      end

      def triadic(base)
        TriadicTheme.new(base)
      end

      def split_complementary(base)
        SplitComplementaryTheme.new(base)
      end

      def rectangle(base)
        RectangleTheme.new(base)
      end

      def square(base)
        SquareTheme.new(base)
      end
    end

    @@colors = {}
    
    def initialize(base)
      @base_rgb   = Color::RGB.const_get(base.to_s.camelize)
      @color_sets = {}
      @@colors.each do |name, steps|
        color = self.hue_adjusted_base_rgb(steps)
        @color_sets[name] = 
          Tints.new(color, name).colors.merge(
            Shades.new(color, name).colors)
      end
    end

    def base 
      @base_rgb.html
    end

    def base_tints; Tints.new(@base_rgb, 'base'); end
    def base_shades; Shades.new(@base_rgb, 'base'); end

    def color_sets
      @color_sets.merge({'base' => (base_tints.colors.merge(base_shades.colors))})
    end

    def sass
      returning "# Generated by Sassafras\n" do |str|
        color_sets.each do |name, colors|
          str << "# #{name}\n"
          colors.each do |name, hex|
            str << "!#{name} = #{hex}\n"
          end
          str << "\n"
        end
      end
    end

    def get_binding; binding; end

    protected

      def hue_adjusted_base_rgb(steps)
        one_step = 0.0555555555555

        hue = base_rgb.to_hsl.h
        sat = base_rgb.to_hsl.s
        lum = base_rgb.to_hsl.l

        hue += one_step * steps
        if hue > 1.0
          hue -= 1.0
        elsif hue < 0.0
          hue += 1.0
        end

        Color::HSL.from_fraction(hue, sat, lum).to_rgb
      end

      def self.color_set(name, block)
        instance_eval do
          @@colors[name] = block
        end
      end

  end

  class ColorSet 

    def initialize(base_rgb, prefix=nil)
      @rgb = base_rgb
      @prefix = prefix
      @colors = {}
    end
    
    def colors
      returning Hash.new do |hash|
        @colors.each do |name, hex|
          if @prefix
            hash["#{@prefix}_#{name}"] = hex
          else
            hash[name] = hex
          end
        end
      end
    end

    def method_missing(method, *args)
      return @colors[method.to_s] if @colors[method.to_s]
      super
    end

  end


  class Tints < ColorSet

    def initialize(base_rgb, prefix=nil)
      super(base_rgb, prefix)
      @colors = {
        'mid'      => @rgb.html,
        'light'    => @rgb.lighten_by(50).html,
        'lighter'  => @rgb.lighten_by(30).html,
        'lightest' => @rgb.lighten_by(10).html
      }
    end

  end

  class Shades < ColorSet
    
    def initialize(base_rgb, prefix=nil)
      super(base_rgb, prefix)
      @colors = {
        'mid'     => @rgb.html,
        'dark'    => @rgb.darken_by(50).html,
        'darker'  => @rgb.darken_by(30).html,
        'darkest' => @rgb.darken_by(10).html
      }
    end

  end

  class ComplementaryTheme < Theme

    @@colors = {}
    color_set 'complementary', +6

  end

  class AnalogousTheme < Theme

    @@colors = {}
    color_set 'support', -1
    color_set 'accent',  +1
    
  end

  class TriadicTheme < Theme

    @@colors = {}
    color_set 'accent1', +4
    color_set 'accent2', -4

  end

  class SplitComplementaryTheme < Theme

    @@colors = {}
    color_set 'complement1', +5
    color_set 'complement2', -5

  end

  class RectangleTheme < Theme

    @@colors = {}
    color_set 'accent1', +2
    color_set 'accent2', +6
    color_set 'accent3', -4
    
  end

  class SquareTheme < Theme

    @@colors = {}
    color_set 'accent1',    +3
    color_set 'complement', +6
    color_set 'accent2',    +9

  end

  class HTMLSwatch

    def initialize(theme)
      @theme = theme
    end

    def output
      File.open(File.dirname(__FILE__) + '/sassafras/swatch.html.erb') do |f|
        erb = ERB.new(f.read)
        erb.run(@theme.get_binding)
      end
    end
  end
  
end
