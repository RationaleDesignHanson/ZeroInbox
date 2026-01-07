#!/usr/bin/env ruby
# Script to add a file to Xcode project

require 'fileutils'
require 'securerandom'

PROJECT_PATH = "/Users/matthanson/Zer0_Inbox/Zero_ios_2/Zero/Zero.xcodeproj/project.pbxproj"
FILE_TO_ADD = ARGV[0] || "Services/EmailSanitizer.swift"

# Generate unique IDs for Xcode (24 character hex strings)
def generate_id
  SecureRandom.hex(12).upcase
end

# Read the project file
content = File.read(PROJECT_PATH)

# Generate IDs
file_ref_id = generate_id
build_file_id = generate_id

puts "Generated File Reference ID: #{file_ref_id}"
puts "Generated Build File ID: #{build_file_id}"

# 1. Add PBXBuildFile entry (in the Build files section)
build_file_entry = "\t\t#{build_file_id} /* #{FILE_TO_ADD} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_id} /* #{FILE_TO_ADD} */; };\n"

# Find where to insert build file (after LocalFeedbackStore if it exists, otherwise after ModelTuningRewardsService)
if content =~ /(.*LocalFeedbackStore\.swift in Sources.*\n)/
  content.sub!($1, $1 + build_file_entry)
  puts "✓ Added PBXBuildFile entry (after LocalFeedbackStore)"
elsif content =~ /(.*ModelTuningRewardsService\.swift in Sources.*\n)/
  content.sub!($1, $1 + build_file_entry)
  puts "✓ Added PBXBuildFile entry (after ModelTuningRewardsService)"
else
  puts "✗ Could not find insertion point for PBXBuildFile"
  exit 1
end

# 2. Add PBXFileReference entry
file_ref_entry = "\t\t#{file_ref_id} /* #{FILE_TO_ADD} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{FILE_TO_ADD}; sourceTree = \"<group>\"; };\n"

# Find where to insert file reference (after LocalFeedbackStore if it exists)
if content =~ /(.*1BA25638EF93D07B1834D918 \/\* Services\/LocalFeedbackStore\.swift \*\/.*\n)/
  content.sub!($1, $1 + file_ref_entry)
  puts "✓ Added PBXFileReference entry (after LocalFeedbackStore)"
elsif content =~ /(.*2E10AD514CFE466DB3610B8F \/\* Services\/ModelTuningRewardsService\.swift \*\/.*\n)/
  content.sub!($1, $1 + file_ref_entry)
  puts "✓ Added PBXFileReference entry (after ModelTuningRewardsService)"
else
  puts "✗ Could not find insertion point for PBXFileReference"
  exit 1
end

# 3. Add to PBXSourcesBuildPhase (the actual build phase)
sources_entry = "\t\t\t\t#{build_file_id} /* #{FILE_TO_ADD} in Sources */,\n"

# Find the Sources build phase and add our file
if content =~ /(.*FA15F12C30677D12DB5D27F5 \/\* Services\/LocalFeedbackStore\.swift in Sources \*\/,\n)/
  content.sub!($1, $1 + sources_entry)
  puts "✓ Added to PBXSourcesBuildPhase (after LocalFeedbackStore)"
elsif content =~ /(.*C5FCB6B62EAA896F00DC7DB9 \/\* Services\/ModelTuningRewardsService\.swift in Sources \*\/,\n)/
  content.sub!($1, $1 + sources_entry)
  puts "✓ Added to PBXSourcesBuildPhase (after ModelTuningRewardsService)"
else
  puts "✗ Could not find insertion point for PBXSourcesBuildPhase"
  exit 1
end

# 4. Add to Services group in file hierarchy
group_entry = "\t\t\t\t#{file_ref_id} /* #{FILE_TO_ADD} */,\n"

# Find the Services group
if content =~ /(.*1BA25638EF93D07B1834D918 \/\* Services\/LocalFeedbackStore\.swift \*\/,\n)/
  content.sub!($1, $1 + group_entry)
  puts "✓ Added to Services group (after LocalFeedbackStore)"
elsif content =~ /(.*2E10AD514CFE466DB3610B8F \/\* Services\/ModelTuningRewardsService\.swift \*\/,\n)/
  content.sub!($1, $1 + group_entry)
  puts "✓ Added to Services group (after ModelTuningRewardsService)"
else
  puts "✗ Could not find insertion point for Services group"
  exit 1
end

# Backup original file
backup_path = "#{PROJECT_PATH}.backup.#{Time.now.to_i}"
FileUtils.cp(PROJECT_PATH, backup_path)
puts "✓ Created backup at #{backup_path}"

# Write modified content
File.write(PROJECT_PATH, content)
puts "✓ Updated project file"
puts "\n✅ Successfully added #{FILE_TO_ADD} to Xcode project"
