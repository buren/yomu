require 'helper.rb'
require 'yomu'

describe Yomu do
  let(:data) { File.read 'spec/samples/sample.docx' }

  before do
    ENV['JAVA_HOME'] = nil
  end

  describe '.read' do
    it 'reads text' do
      text = Yomu.read :text, data

      expect( text ).to include 'The quick brown fox jumped over the lazy cat.'
    end

    it 'reads metadata' do
      metadata = Yomu.read :metadata, data

      expect( metadata['Content-Type'] ).to eql 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    end

    it 'reads metadata values with colons as strings' do
      data = File.read 'spec/samples/sample-metadata-values-with-colons.doc'
      metadata = Yomu.read :metadata, data

      expect( metadata['dc:title'] ).to eql 'problem: test'
    end

    it 'reads metadata time values as time values' do
      metadata = Yomu.read :metadata, data

      expect( metadata['Creation-Date'] ).to be_a Time
    end

    it 'reads mimetype' do
      mimetype = Yomu.read :mimetype, data

      expect( mimetype.content_type ).to eql 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      expect( mimetype.extensions ).to include 'docx'
    end
  end

  describe '.new' do
    it 'requires parameters' do
      expect { Yomu.new }.to raise_error ArgumentError
    end

    it 'accepts a root path' do
      yomu = Yomu.new 'spec/samples/sample.pages'

      expect( yomu ).to be_path
      expect( yomu ).not_to be_uri
      expect( yomu ).not_to be_stream
    end

    it 'accepts a relative path' do
      yomu = Yomu.new 'spec/samples/sample.pages'

      expect( yomu ).to be_path
      expect( yomu ).not_to be_uri
      expect( yomu ).not_to be_stream
    end

    it 'accepts a path with spaces' do
      yomu = Yomu.new 'spec/samples/sample filename with spaces.pages'

      expect( yomu ).to be_path
      expect( yomu ).not_to be_uri
      expect( yomu ).not_to be_stream
    end

    it 'accepts a URI' do
      yomu = Yomu.new 'http://svn.apache.org/repos/asf/poi/trunk/test-data/document/sample.docx'

      expect( yomu ).to be_uri
      expect( yomu ).not_to be_path
      expect( yomu ).not_to be_stream
    end

    it 'accepts a stream or object that can be read' do
      File.open 'spec/samples/sample.pages', 'r' do |file|
        yomu = Yomu.new file

        expect( yomu ).to be_stream
        expect( yomu ).not_to be_path
        expect( yomu ).not_to be_uri
      end
    end

    it 'refuses a path to a missing file' do
      expect { Yomu.new 'test/sample/missing.pages'}.to raise_error Errno::ENOENT
    end

    it 'refuses other objects' do
      [nil, 1, 1.1].each do |object|
        expect { Yomu.new object }.to raise_error TypeError
      end
    end
  end

  describe '.java' do
    specify 'with no specified JAVA_HOME' do
      expect( Yomu.send(:java) ).to eql 'java'
    end

    specify 'with a specified JAVA_HOME' do
      ENV['JAVA_HOME'] = '/path/to/java/home'

      expect( Yomu.send(:java) ).to eql '/path/to/java/home/bin/java'
    end
  end

  context 'initialized with a given path' do
    let(:yomu) { Yomu.new 'spec/samples/sample.pages' }

    specify '#text reads text' do
      expect( yomu.text).to include 'The quick brown fox jumped over the lazy cat.'
    end

    specify '#metadata reads metadata' do
      expect( yomu.metadata['Content-Type'] ).to eql 'application/vnd.apple.pages'
    end
  end

  context 'initialized with a given URI' do
    let(:yomu) { Yomu.new 'http://svn.apache.org/repos/asf/poi/trunk/test-data/document/sample.docx' }

    specify '#text reads text' do
      expect( yomu.text ).to include 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit.'
    end

    specify '#metadata reads metadata' do
      expect( yomu.metadata['Content-Type'] ).to eql 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    end
  end

  context 'initialized with a given stream' do
    let(:yomu) { Yomu.new File.open('spec/samples/sample.pages', 'rb') }

    specify '#text reads text' do
      expect( yomu.text ).to include 'The quick brown fox jumped over the lazy cat.'
    end

    specify '#metadata reads metadata' do
      expect( yomu.metadata['Content-Type'] ).to eql 'application/vnd.apple.pages'
    end
  end
end
