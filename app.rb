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
  file:     image file data.
  tags:     comma-separated ExifTool tag names. See also https://exiftool.org/TagNames/
  template: ERB template for output. Tag data is accessible via t.TAG_NAME. e.g. <%= t.FNumber %>

Example:
  curl #{scheme}://#{host}#{path} -F file=@/path/to/image.jpg \
    -F tags="Make,Model,LensID,ISO,FocalLength,ExposureShift,FNumber,ExposureTime"

  curl #{scheme}://#{host}#{path} -F file=@/path/to/image.jpg \
    -F tags="Make,Model,LensID,ISO,FocalLength,ExposureShift,FNumber,ExposureTime" \
    -F template=' <table><th colspan="5"><td><%= t.Make %>@<%= t.Model %></td></th><th colspan="5"><td><%= t.LensID %></td></th><th><td>ISO <%= t.ISO %></td><td><%= t.FocalLength %> mm</td><td><%= t.ExposureShift %> ev</td><td>f<%= t.FNumber %></td><td><%= t.ExposureTime %> s</td></th></table>'

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
  tags = params[:tags].to_s.split(",").map(&:strip).select{ _1.match?(/\A\w*\Z/) }
  tags_args = tags.map{ "-#{_1}" }.join(" ")
  template = params[:template]
  stdin_data = params[:file][:tempfile].read
  cmd = "#{exiftool} #{tags_args} #{file_path}"

  if template.nil?
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
  else
    cmd += " -j"
    out, _ = Open3.capture2(cmd, stdin_data: stdin_data)
    json = JSON.parse(out)[0]
    t = OpenStruct.new
    tags.each do |tag|
      t.send("#{tag}=", json[tag])
    end
    ERB.new(template).result(binding)
  end
end
