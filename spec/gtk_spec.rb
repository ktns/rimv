require File.dirname(__FILE__) + '/spec_helper.rb'

describe Rimv::MainWin do
	before :all do
		@main_win = MainWin.new db_stub
	end

	after :all do
	end
end
