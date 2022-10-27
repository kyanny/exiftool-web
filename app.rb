#!/usr/bin/env ruby

require "sinatra"
require "sinatra/respond_with"
require "open3"

before do
  json = File.read("Image-ExifTool.json")
  data = JSON.parse(json)
  @release = dist_path = data["release"]
  absolute_path = File.expand_path(dist_path)
  @exiftool = File.join(absolute_path, "exiftool")
  scheme = request.env["rack.url_scheme"]
  host = request.env["HTTP_HOST"]
  path = request.env["REQUEST_PATH"]
  @url = "#{scheme}://#{host}#{path}"
end

get "/" do
  usage = <<USAGE
Usage:
  curl -H Accept:application/json #{@url} -F file=@/path/to/image.jpg

Params:
  file: image file data.
  tags: comma-separated ExifTool tag names. See also https://exiftool.org/TagNames/

Example:
  curl -H Accept:application/json #{@url} -F file=@/path/to/image.jpg -F tags="Make,Model,LensID,ISO,FocalLength,ExposureShift,FNumber,ExposureTime"

USAGE

  respond_to do |format|
    format.on("*/*") do
      usage
    end
    format.html do
      erb :index
    end
  end
end

post "/" do
  tags = params[:tags].to_s.split(",").map(&:strip).select{ _1.match?(/\A\w*\Z/) }
  tags_args = tags.map{ "-#{_1}" }.join(" ")
  file = params.dig(:file, :tempfile)
  redirect to("/") if file.nil?
  stdin_data = file.read
  cmd = "#{@exiftool} -s #{tags_args} -"

  respond_to do |format|
    format.on("*/*") do
      cmd += " -j"
      @out, _ = Open3.capture2(cmd, stdin_data: stdin_data)
      @out
    end
    format.html do
      cmd += " -h"
      @out, _ = Open3.capture2(cmd, stdin_data: stdin_data)
      erb :index
    end
  end
end
