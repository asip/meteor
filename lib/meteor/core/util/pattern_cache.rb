# -* coding: UTF-8 -*-
# frozen_string_literal: true

module Meteor
  module Core
    module Util
      #
      # Pattern Cache Class (パターン・キャッシュ クラス)
      #
      class PatternCache
        @@regex_cache = Hash.new

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
        #  @param [Fixnum] option option of Regex (オプション)
        #  @return [Regexp] pattern (パターン)
        #
        def self.get(*args)
          case args.length
            when ONE
              # get_1(args[0])
              if @@regex_cache[args[0].to_sym]
                @@regex_cache[args[0].to_sym]
              else
                @@regex_cache[args[0].to_sym] = Regexp.new(args[0], Regexp::MULTILINE)
              end
            when TWO
              # get_2(args[0], args[1])
              if @@regex_cache[args[0].to_sym]
                @@regex_cache[args[0].to_sym]
              else
                @@regex_cache[args[0].to_sym] = Regexp.new(args[0], args[1])
              end
            else
              raise ArgumentError
          end
        end

        ##
        ## get pattern (パターンを取得する)
        ## @param [String] regex regular expression (正規表現)
        ## @return [Regexp] pattern (パターン)
        ##
        # def self.get_1(regex)
        #  ## pattern = @@regex_cache[regex]
        #  ##
        #  ## if pattern == nil
        #  # if regex.kind_of?(String)
        #  if !@@regex_cache[regex.to_sym]
        #    # pattern = Regexp.new(regex)
        #    # @@regex_cache[regex] = pattern
        #    @@regex_cache[regex.to_sym] = Regexp.new(regex, Regexp::MULTILINE)
        #  end
        #
        #  # return pattern
        #  @@regex_cache[regex.to_sym]
        #  ## elsif regex.kind_of?(Symbol)
        #  ##  if !@@regex_cache[regex]
        #  ##    @@regex_cache[regex.object_id] = Regexp.new(regex.to_s, Regexp::MULTILINE)
        #  ##  end
        #  ##
        #  ##  @@regex_cache[regex]
        #  # end
        # end

        ##
        ## パターンを取得する
        ## @param [String] regex 正規表現
        ## @param [Fixnum] option オプション
        ## @return [Regexp] パターン
        ##
        # def self.get_2(regex, option)
        #  ## pattern = @@regex_cache[regex]
        #  ##
        #  ## if pattern == nil
        #  # if regex.kind_of?(String)
        #  if !@@regex_cache[regex.to_sym]
        #    # pattern = Regexp.new(regex)
        #    # @@regex_cache[regex] = pattern
        #    @@regex_cache[regex.to_sym] = Regexp.new(regex, option,"UTF-8")
        #  end
        #
        #  # return pattern
        #  @@regex_cache[regex.to_sym]
        #  ## elsif regex.kind_of?(Symbol)
        #  ##  if !@@regex_cache[regex]
        #  ##    @@regex_cache[regex] = Regexp.new(regex.to_s, option,"UTF-8")
        #  ##  end
        #  ##
        #  ##  @@regex_cache[regex]
        #  # end
        # end
      end
    end
  end
end
