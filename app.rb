#!/usr/bin/env ruby

require "sinatra"
require "sinatra/respond_with"
require "open3"

get "/" do
  scheme = request.env["rack.url_scheme"]
  host = request.env["HTTP_HOST"]
  path = request.env["REQUEST_PATH"]
  url = "#{scheme}://#{host}#{path}"
  usage = <<USAGE
Usage:
  curl -H Accept:application/json #{url} -F file=@/path/to/image.jpg

Params:
  file: image file data.
  tags: comma-separated ExifTool tag names. See also https://exiftool.org/TagNames/

Example:
  curl -H Accept:application/json #{url} -F file=@/path/to/image.jpg -F tags="Make,Model,LensID,ISO,FocalLength,ExposureShift,FNumber,ExposureTime"

USAGE

  respond_to do |format|
    format.on("*/*") do
      usage
    end
    format.html do
      erb :index, locals: { out: nil, url: url }
    end
  end
end

post "/" do
  exiftool = "./Image-ExifTool-12.49/exiftool -s"
  file_path = "-"
  tags = params[:tags].to_s.split(",").map(&:strip).select{ _1.match?(/\A\w*\Z/) }
  tags_args = tags.map{ "-#{_1}" }.join(" ")
  stdin_data = params[:file][:tempfile].read
  cmd = "#{exiftool} #{tags_args} #{file_path}"

  respond_to do |format|
    format.on("*/*") do
      cmd += " -j"
      out, _ = Open3.capture2(cmd, stdin_data: stdin_data)
      out
    end
    format.html do
      cmd += " -h"
      out, _ = Open3.capture2(cmd, stdin_data: stdin_data)
      erb :index, locals: { out: out }
    end
  end
end
