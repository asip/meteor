# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Exception
    #
    # Element Search Exception (要素検索例外)
    #
    # @!attribute [rw] message
    #  @return [String] message (メッセージ)
    #
    class NoSuchElementException
      attr_accessor :message

      #
      # initializer (イニシャライザ)
      # @overload initialize(name)
      #  @param [String,Symbol] name tag name (タグ名)
      # @overload initialize(attr_name,attr_value)
      #  @param [String,Symbol] attr_name attribute name (属性名)
      #  @param [String] attr_value attribute value (属性値)
      # @overload initialize(name,attr_name,attr_value)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @param [String,Symbol] attr_name attribute name (属性名)
      #  @param [String] attr_value attribute value (属性値)
      # @overload initialize(attr_name1,attr_value1,attr_name2,attr_value2)
      #  @param [String,Symbol] attr_name1 attribute name1 (属性名１)
      #  @param [String] attr_value1 attribute value1 (属性値１)
      #  @param [String,Symbol] attr_name2 attribute name2 (属性名２)
      #  @param [String] attr_value2 attribute value2 (属性値２)
      # @overload initialize(name,attr_name1,attr_value1,attr_name2,attr_value2)
      #  @param [String,Symbol] name tag name (タグ名)
      #  @param [String,Symbol] attr_name1 attribute name1 (属性名１)
      #  @param [String] attr_value1 attribute value1 (属性値１)
      #  @param [String,Symbol] attr_name2 attribute name2 (属性名２)
      #  @param [String] attr_value2 attribute value2 (属性値２)
      #
      def initialize(*args) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        case args.length
        when ONE
          initialize_one(args[0])
        when TWO
          initialize_two(args[0], args[1])
        when THREE
          initialize_three(args[0], args[1], args[2])
        when FOUR
          initialize_four(args[0], args[1], args[2], args[3])
        when FIVE
          initialize_five(args[0], args[1], args[2], args[3], args[4])
        end
      end

      def initialize_one(name)
        self.message = "element not found : #{name}"
      end

      private :initialize_one

      def initialize_two(attr_name, attr_value)
        self.message = "element not found : [#{attr_name}=#{attr_value}]"
      end

      private :initialize_two

      def initialize_three(name, attr_name, attr_value)
        self.message = "element not found : #{name}[#{attr_name}=#{attr_value}]"
      end

      private :initialize_three

      def initialize_four(attr_name1, attr_value1, attr_name2, attr_value2)
        self.message = "element not found : [#{attr_name1}=#{attr_value1}][#{attr_name2}=#{attr_value2}]"
      end

      private :initialize_four

      def initialize_five(name, attr_name1, attr_value1, attr_name2, attr_value2)
        self.message = "element not found : #{name}[#{attr_name1}=#{attr_value1}][#{attr_name2}=#{attr_value2}]"
      end

      private :initialize_five
    end
  end
end
