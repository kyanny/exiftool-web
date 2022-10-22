#!/usr/bin/env ruby

require "sinatra"
require "sinatra/respond_with"
require "open3"

get "/" do
  scheme = request.env["rack.url_scheme"]
  host = request.env["HTTP_HOST"]
  path = request.env["REQUEST_PATH"]
  usage = <<USAGE
Usage:
  curl #{scheme}://#{host}#{path} -F file=@/path/to/image.jpg

Params:
  file: image file data.
  tags: comma-separated ExifTool tag names. See also https://exiftool.org/TagNames/

Example:
  curl #{scheme}://#{host}#{path} -F file=@/path/to/image.jpg -F tags="Make,Model,LensID,ISO,FocalLength,ExposureShift,FNumber,ExposureTime"

USAGE

  respond_to do |format|
    format.txt do
      usage
    end
    format.html do
      erb :index, locals: { out: nil }
    end
    format.on("*/*") do
      usage
    end
  end
end

post "/" do
  exiftool = "./Image-ExifTool-12.49/exiftool -s"
  file_path = "-"
  tags = params[:tags].to_s.split(",").map(&:strip).select{ _1.match?(/\A\w*\Z/) }.map{ _1.insert(0, "-") }.join(" ")
  stdin_data = params[:file][:tempfile].read
  cmd = "#{exiftool} #{tags} #{file_path}"

  respond_to do |format|
    format.txt do
      out, _ = Open3.capture2(cmd, stdin_data: stdin_data)
      out
    end
    format.html do
      cmd += " -h"
      out, _ = Open3.capture2(cmd, stdin_data: stdin_data)
      erb :index, locals: { out: out }
    end
    format.json do
      cmd += " -j"
      out, _ = Open3.capture2(cmd, stdin_data: stdin_data)
      out
    end
    format.on("*/*") do
      out, _ = Open3.capture2(cmd, stdin_data: stdin_data)
      out
    end
  end
end
