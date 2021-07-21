#
# Copyright 2019 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Generates classes from proto files. This script should not be run
# directly, it runs automatically as part of build phase instead.

#!/bin/bash
OUTPUT_DIR="./"
PROCESSING_DIR="third_party/sciencejournal/ios"

# Make sure the output and processing directories exist or create them.
mkdir -p "$OUTPUT_DIR"
mkdir -p "$PROCESSING_DIR"/Protos

# Copy the protos to the processing directory to work around import requirements.
for file in Protos/*; do
  if test -f "$file" && [ "$file" != Protos/$(basename $0) ] && [ "$file" != Protos/"ScienceJournalPortableFilter.pbascii" ]; then
    cp "$file" "$PROCESSING_DIR/$file"
  fi
done

# Process the copied files.
for file in "$PROCESSING_DIR"/Protos/*; do
  protoc "$file" --objc_out="$OUTPUT_DIR"
done

# Remove the processed protos.
for file in "$PROCESSING_DIR"/Protos/*; do
   if [ "${file: -6}" == ".proto" ]; then
       rm "$file"
   fi
done

# # Clean the imports on the generated files to work in the open source project's hierarchy.
for generatedFile in "third_party/sciencejournal/ios/Protos"/*; do
  sed -i "" "s/#import \"third_party\/sciencejournal\/ios\/Protos\//#import \"/g" $generatedFile
done
