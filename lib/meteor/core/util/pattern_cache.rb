# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Core
    module Util
      #
      # Pattern Cache Class (パターン・キャッシュ クラス)
      #
      class PatternCache
        @@regex_cache = {} # rubocop:disable Style/ClassVars

        ##
        ## intializer (イニシャライザ)
        ##
        # def initialize
        # end

        #
        # get pattern (パターンを取得する)
        # @overload get(regex)
        #  @param [String] regex regular expression (正規表現)
        #  @return [Regexp] pattern (パターン)
        # @overload get(regex,option)
        #  @param [String] regex regular expression (正規表現)
        #  @param [Integer] option option of Regex (オプション)
        #  @return [Regexp] pattern (パターン)
        #
        def self.get(*args)
          case args.length
          when ONE
            get_one(args[0])
          when TWO
            get_two(args[0], args[1])
          else
            raise ArgumentError
          end
        end

        #
        # get pattern (パターンを取得する)
        # @param [String] regex regular expression (正規表現)
        # @return [Regexp] pattern (パターン)
        #
        def self.get_one(regex)
          if @@regex_cache[regex.to_sym]
            @@regex_cache[regex.to_sym]
          else
            @@regex_cache[regex.to_sym] = Regexp.new(regex, Regexp::MULTILINE)
          end
        end

        #
        # get pattern (パターンを取得する)
        # @param [String] regex (正規表現)
        # @param [Integer] option (オプション)
        # @return [Regexp] psttern (パターン)
        #
        def self.get_two(regex, option)
          if @@regex_cache[regex.to_sym]
            @@regex_cache[regex.to_sym]
          else
            @@regex_cache[regex.to_sym] = Regexp.new(regex, option)
          end
        end

        class << self
          private :get_one
          private :get_two
        end
      end
    end
  end
end
