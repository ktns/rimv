require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*1, 'spec_helper.rb']))

describe Rimv::DB do
	describe '.digest' do
		subject {Rimv::DB.digest(IO.read(File.join(asset_path,'logo.png')))}

		it 'should return String' do
			is_expected.to be_kind_of String
		end
	end

	shared_examples_for 'acceptable' do |tag|
		subject{Rimv::DB.acceptable_tag?(tag)}
		it 'should return true' do
			is_expected.to be_truthy
		end
	end

	shared_examples_for 'unacceptable' do |tag|
		subject{Rimv::DB.acceptable_tag?(tag)}
		it 'should return false' do
			is_expected.to be_falsey
		end
	end

	describe '.acceptable_tag?' do
		for tag in %w<hoge ho.ge ho/ge h0.ge h0ge>
			describe("\b(#{tag})") do
				it_should_behave_like 'acceptable', tag
			end
		end

		for tag in %w<hoge/ /hoge h0ge\  ho,ge hoge,>
			describe("\b(#{tag})") do
				it_should_behave_like 'unacceptable', tag
			end
		end
	end
end
