require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*0, 'spec_helper.rb'].flatten))

describe 'blank_db' do
	it 'should be accessible' do
		require 'fileutils'
		FileUtils.touch blank_db
	end
end

describe 'asset_path' do
	it 'should be an existing directory' do
		FileTest.directory?(asset_path).should be_true
	end

	it 'should include file `logo.xpm\'' do
		FileTest.exist?(File.join(asset_path, 'logo.xpm')).should be_true
	end
end
