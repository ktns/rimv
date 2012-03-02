require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*2, 'spec_helper.rb']))

describe Rimv::DB::Pool do
	describe '#new' do
		it 'should accept filename' do
			Rimv::DB::Pool.new(asset_path('logo.png')).should be_kind_of Rimv::DB::Pool
		end
	end
end
