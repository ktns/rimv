require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*1, 'spec_helper.rb']))

describe 'A module including Rimv::Keyval' do
	before :all do
		@module = Module.new do
			include Rimv::Keyval
		end
	end

	describe '.const_get' do
		subject{lambda {@module.const_get(@const_name)}}

		context 'with GDK_KEY_q' do
			before :all do
				@const_name = 'GDK_KEY_q'
			end

			it {should_not raise_error NameError}
		end

		context 'with undefined constant name' do
			before :all do
				@const_name = 'HOGE'
			end

			it {should raise_error NameError}
		end
	end
end
