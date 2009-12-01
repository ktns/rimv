#!/usr/bin/ruby
require "gtk2"

APP_NAME = "rview"
WINDOW_SIZE = [640, 480]

class MainWin < Gtk::Window
  def initialize
    super(APP_NAME)
    self.set_default_size(*WINDOW_SIZE)

    self.signal_connect("delete_event") do
      Gtk.main_quit
    end
    self.signal_connect("key-press-event") do |w, e|
      if e.keyval == Gdk::Keyval::GDK_q
        Gtk.main_quit
      end
    end
  end
end

if ARGV.empty?
  puts "Usage: #{$0} <file>"
  exit(1)
end
unless File.exist?(ARGV[0])
  puts "#{$0}: #{ARGV[0]}: No such file"
  exit(1)
end

image = Gtk::Image.new(ARGV[0])
width, height = image.pixbuf.width, image.pixbuf.height

if width > WINDOW_SIZE[0] || height > WINDOW_SIZE[1]
  image.pixbuf = image.pixbuf.scale(*WINDOW_SIZE)
end

main_win = MainWin.new
main_win.add(image)
main_win.show_all
Gtk.main
