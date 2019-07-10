#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'xcodeproj'
require 'set'
require 'optparse'
require 'ostruct'


options = OpenStruct.new
options.includeTestTargets = false
optionParser = OptionParser.new do |opt|
    opt.on('--workspace WORKSPACE_PATH') { |o| options[:workspacePath] = o }
    opt.on('--include-test-targets') { |o| options[:includeTestTargets] = o }
end
optionParser.parse!

if options.workspacePath == nil
    puts "You must provide a workspace."
    puts optionParser.help()
    exit 1
end

workspacePath = options.workspacePath
includeTestTargets = options.includeTestTargets

workspace = Xcodeproj::Workspace.new_from_xcworkspace(workspacePath)

projects = workspace.file_references.map do |file|
    Xcodeproj::Project.open(file.absolute_path(File.dirname(workspacePath)))
end

@allTargets = Set[]
for project in projects
    if File.basename(project.path) != "Pods.xcodeproj"
        @allTargets += project.targets
    end
end


def linkedFrameworksForTarget(target)
    if !target.respond_to?(:frameworks_build_phase)
        return []
    end
    target.frameworks_build_phase.file_display_names.map do |f| File.basename(f, ".framework") end
end


def check(target)
    linkedFrameworks = linkedFrameworksForTarget(target)
    allTargets_str = @allTargets.map do |t| t.to_s end
    linkedFrameworks.each do |framework|
        if !framework.start_with?("Pods_") && allTargets_str.include?(framework)
            puts("\"#{target}\" -> \"#{framework}\"")
        end
    end
end

for project in projects
    for target in project.targets
        allTargets_str = @allTargets.map do |t| t.to_s end
        if allTargets_str.include?(target.to_s) && (includeTestTargets || !target.to_s.end_with?("Tests"))
            check(target)
        end
    end
end
