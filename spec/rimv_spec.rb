require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*0, 'spec_helper.rb'].flatten))

describe 'blank_db' do
	it 'should be accessible' do
		require 'fileutils'
		FileUtils.touch blank_db
	end
end
