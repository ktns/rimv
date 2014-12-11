require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*0, 'spec_helper.rb']))

describe 'blank_db' do
	it 'should be accessible' do
		require 'fileutils'
		FileUtils.touch blank_db
	end
end

describe 'asset_path' do
	it 'should be an existing directory' do
		expect(FileTest.directory?(asset_path)).to be_truthy
	end

	it 'should include file `logo.png\'' do
		expect(FileTest.exist?(File.join(asset_path, 'logo.png'))).to be_truthy
	end
end
