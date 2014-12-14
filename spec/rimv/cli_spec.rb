#
# Copyright (C) Katsuhiko Nishimra 2011, 2012, 2014.
#
# This file is part of rimv.
#
# rimv is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Foobar is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Foobar.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.join([File.dirname(__FILE__), %w<..>*1, 'spec_helper.rb'].flatten))

describe Rimv::CLI do
	describe '.parse' do
		let(:tag){random_tag}
		let(:tag2){random_tag}

		describe '-a' do
			it 'should invoke add mode' do
				expect(Rimv::Application).to receive(:new).with('add', *[anything]*5)
				Rimv::CLI.parse %w<-a>
			end
		end

		describe '--add' do
			it 'should invoke add mode' do
				expect(Rimv::Application).to receive(:new).with('add', *[anything]*5)
				Rimv::CLI.parse %w<--add>
			end
		end

		describe '-v' do
			it 'should invoke view mode' do
				expect(Rimv::Application).to receive(:new).with('view', *[anything]*5)
				Rimv::CLI.parse %w<-v>
			end
		end

		describe '--view' do
			it 'should invoke view mode' do
				expect(Rimv::Application).to receive(:new).with('view', *[anything]*5)
				Rimv::CLI.parse %w<--view>
			end
		end

		describe '-a -t tag' do
			it 'should invoke add mode with specified tag' do
				expect(Rimv::Application).to receive(:new).with('add', anything, [tag], *[anything]*3)
				Rimv::CLI.parse %w<-a -t> + [tag]
			end
		end

		describe '-a -t tag,tag' do
			it 'should invoke add mode with specified tags' do
				expect(Rimv::Application).to receive(:new).with('add', anything, [tag,tag2], *[anything]*3)
				Rimv::CLI.parse %w<-a -t> + ["#{tag},#{tag2}"]
			end
		end

		describe '-a -v' do
			it 'should be aborted' do
				expect{
					Rimv::CLI.parse %w<-a -v>
				}.to raise_error Rimv::CLI::ParseError
			end
		end

		describe '-a -t tag -p' do
			it 'should be aborted' do
				expect{
					Rimv::CLI.parse %w<-a -t tag -p>
				}.to raise_error Rimv::CLI::ParseError
			end
		end
	end
end
