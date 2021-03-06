module Capybara
  module Node

    ##
    #
    # A {Capybara::Node::Simple} is a simpler version of {Capybara::Node::Base} which
    # includes only {Capybara::Node::Finders} and {Capybara::Node::Matchers} and does
    # not include {Capybara::Node::Actions}. This type of node is returned when
    # using {Capybara.string}.
    #
    # It is useful in that it does not require a session, an application or a driver,
    # but can still use Capybara's finders and matchers on any string that contains HTML.
    #
    class Simple
      include Capybara::Node::Finders
      include Capybara::Node::Matchers

      attr_reader :native

      def initialize(native)
        native = Nokogiri::HTML(native) if native.is_a?(String)
        @native = native
      end

      ##
      #
      # @return [String]    The text of the element
      #
      def text
        native.text
      end

      ##
      #
      # Retrieve the given attribute
      #
      #     element[:title] # => HTML title attribute
      #
      # @param  [Symbol] attribute     The attribute to retrieve
      # @return [String]               The value of the attribute
      #
      def [](name)
        attr_name = name.to_s
        if attr_name == 'value'
          value
        elsif 'input' == tag_name and 'checkbox' == native[:type] and 'checked' == attr_name
          native['checked'] == 'checked'
        else
          native[attr_name]
        end
      end

      ##
      #
      # @return [String]      The tag name of the element
      #
      def tag_name
        native.node_name
      end

      ##
      #
      # An XPath expression describing where on the page the element can be found
      #
      # @return [String]      An XPath expression
      #
      def path
        native.path
      end

      ##
      #
      # @return [String]    The value of the form element
      #
      def value
        if tag_name == 'textarea'
          native.content.sub(/\A\n/, '')
        elsif tag_name == 'select'
          if native['multiple'] == 'multiple'
            native.xpath(".//option[@selected='selected']").map { |option| option[:value] || option.content  }
          else
            option = native.xpath(".//option[@selected='selected']").first || native.xpath(".//option").first
            option[:value] || option.content if option
          end
        else
          native[:value]
        end
      end

      ##
      #
      # Whether or not the element is visible. Does not support CSS, so
      # the result may be inaccurate.
      #
      # @return [Boolean]     Whether the element is visible
      #
      def visible?
        native.xpath("./ancestor-or-self::*[contains(@style, 'display:none') or contains(@style, 'display: none') or name()='script' or name()='head']").size == 0
      end

      ##
      #
      # Whether or not the element is checked.
      #
      # @return [Boolean]     Whether the element is checked
      #
      def checked?
        native[:checked]
      end

      ##
      #
      # Whether or not the element is disabled.
      #
      # @return [Boolean]     Whether the element is disabled
      def disabled?
        native[:disabled]
      end

      ##
      #
      # Whether or not the element is selected.
      #
      # @return [Boolean]     Whether the element is selected
      #
      def selected?
        native[:selected]
      end

      def synchronize
        yield # simple nodes don't need to wait
      end

      def allow_reload!
        # no op
      end

      def unsynchronized
        yield # simple nodes don't need to wait
      end

      def title
        native.xpath("//title").first.text
      end

      def has_title?(content)
        title.match(Capybara::Helpers.to_regexp(content))
      end

      def has_no_title?(content)
        not has_title?(content)
      end

    private

      def resolve_query(query, exact=nil)
        elements = native.xpath(query.xpath(exact)).map do |node|
          self.class.new(node)
        end
        Capybara::Result.new(elements, query)
      end
    end
  end
end
