#!/usr/bin/python

"""
  Generates a Swift String extension containing static variables for all strings
  in the main Localizable.strings file. This script runs automatically at build
  time in Xcode as a Run Script phase.
"""

##
#  Copyright 2019 Google LLC. All Rights Reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
##

import datetime
import getopt
import os
import re
import string
import sys


GENERATED_STRINGS_TEMPLATE = string.Template("""/*
 *  Copyright ${year} Google LLC. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

/*
 * THIS FILE IS AUTOMATICALLY GENERATED, DO NOT EDIT.
 */

 // swiftlint:disable line_length

import Foundation

extension String {

  ${strings}

}

// swiftlint:enable line_length
""")

def process_args(argv):
  """Process the command-line arguments for this script.

  Args:
    argv: The command line arguments.

  Returns:
    A tuple of the input and output files.
  """
  help_info = "generate_strings.py -i <input_file> -o <output_file>"
  try:
    opts, _ = getopt.getopt(argv, "hi:o:", ["ifile=", "ofile="])
  except getopt.GetoptError:
    print help_info
    sys.exit(2)
  for opt, arg in opts:
    if opt == '-h':
      print help_info
      sys.exit()
    elif opt in ("-i", "--ifile"):
      input_file = arg
    elif opt in ("-o", "--ofile"):
      output_file = arg
  return (input_file, output_file)


def process_strings_file(inputfile):
  """Read an input file and parse each line looking for string keys.

  Arguments:
    inputfile: The file to parse for string keys.

  Returns:
    An array of Swift variables that were processed.

  Raises:
    ValueError: If strings are not found.
  """
  swift_variables = []
  with open(inputfile, "r") as read_file:
    for line in read_file:
      line = line.strip()  # Strip whitespace from the line.
      if line == "":
        continue  # If this is a blank line, move to next.
      # If this isn't a comment...
      if re.search(r'/\*.*\*/', line) is None:
        # Keyed line. Looks like "the_key" = "The string"; where there may be
        # a missing semicolon or additional spaces on either side of the
        # = sign. Regex match the key (left side).
        match = re.search(r'\"(.*?)\"\s+=\s+\".*?\";?', line)
        if match:
          # The key.
          text_key = match.group(1)
          # Build a variable version with lowercased first letter and then
          # camel-cased, underscores removed.
          components = text_key.lower().split("_")
          for component in components:
            if component == components[0]:
              # Skip capitalizing the first word.
              variable_name = component
              continue
            # Capitalize the first letter of other words and add it to the var
            # name.
            variable_name += component[0].upper() + component[1:]
          # Create the Swift variable from these values, at it to the list.
          swift_variables.append(
              swift_variable_from_key(text_key, variable_name))

  if not swift_variables:
    raise ValueError("No strings found. Please check the format of your "
                     "strings file.")

  return swift_variables


def swift_variable_from_key(key, variable_name):
  """Generate a Swift static variable line for a string key and variable.

  Args:
    key: The string key for the variable.
    variable_name: The name of the variable.

  Returns:
    A string containing generated Swift code for a string.
  """
  return ("static public var " + variable_name + ": String { return \"" + key +
          "\".localized }")


def generate_strings_file(swift_variables, output_file):
  """Generate a complete Swift strings file from variables and save it.

  Args:
    swift_variables: An array of Swift variables.
    output_file: The file to write to.
  """
  generated = GENERATED_STRINGS_TEMPLATE.substitute({
      "strings" : "\n  ".join(swift_variables),
      "year" : datetime.datetime.now().year
  })
  write_file = open(output_file, "w")
  write_file.write(generated)
  write_file.close()


def main(argv):
  """ Check for require i/o files, process strings and generate the file. """
  input_file, output_file = process_args(argv)
  # Check files exist.
  if not os.path.isfile(input_file):
    raise ValueError("Input file not found: " + input_file)
  if not os.path.isfile(output_file):
    raise ValueError("Output file not found: " + output_file)
  # Process the strings file.
  swift_variables = process_strings_file(input_file)
  # Generate the output file and finish.
  generate_strings_file(swift_variables, output_file)
  quit()


if __name__ == "__main__":
  main(sys.argv[1:])