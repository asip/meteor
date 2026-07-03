# -* coding: UTF-8 -*-
# frozen_string_literal: true

require 'meteor/element'
require 'meteor/root_element'
require 'meteor/attribute'
require 'meteor/attribute_map'
require 'meteor/parser'
require 'meteor/parsers'
require 'meteor/elements'
require 'meteor/exception/no_such_element_exception'
require 'meteor/core/kernel'
require 'meteor/core/util/file_reader'
require 'meteor/core/util/pattern_cache'
require 'meteor/ml/html4/parser_impl'
require 'meteor/ml/html/parser_impl'
require 'meteor/ml/xhtml4/parser_impl'
require 'meteor/ml/xhtml/parser_impl'
require 'meteor/ml/xml/parser_impl'

# Meteor -  A lightweight (X)HTML(5) & XML parser
#
# Copyright (C) 2008-present Yasumasa Ashida.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
# @author Yasumasa Ashida
# @version 0.9.30
#

module Meteor
  VERSION = '0.9.30'

  # require 'fileutils'

  ZERO = 0
  ONE = 1
  TWO = 2
  THREE = 3
  FOUR = 4
  FIVE = 5
  SIX = 6
  SEVEN = 7

  HTML = ZERO
  XHTML = ONE
  HTML4 = TWO
  XHTML4 = THREE
  XML = FOUR
end
