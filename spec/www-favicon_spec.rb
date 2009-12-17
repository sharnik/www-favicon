require 'ostruct'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib/'

require 'www/favicon'
require 'fakeweb'

describe WWW::Favicon do
  before do
    @favicon = WWW::Favicon.new
    @htmls = [
      '<html><link rel="icon" href="/foo/favicon.ico" /></html>',
      '<html><link rel="Shortcut Icon" href="/foo/favicon.ico" /></html>',
      '<html><link rel="shortcut icon" href="/foo/favicon.ico" /></html>',
      '<html><link rel="shortcut icon" href="./foo/favicon.ico" /></html>',
      '<html><link rel="shortcut icon" href="http://example.com/foo/favicon.ico" /></html>',
    ]
  end

  describe '#find' do
    before do
      @favicon.stub!(:valid_favicon_url?).and_return(true)
    end

    it "should find from url" do
      @htmls.each do |html|
        FakeWeb.register_uri(:get, "http://example.com", :body => html)
        @favicon.find('http://example.com/').should == 'http://example.com/foo/favicon.ico'
      end
    end

    it "should find from html and url" do
      @htmls.each do |html|
        @favicon.find_from_html(html, 'http://example.com/').should == 'http://example.com/foo/favicon.ico'
      end
    end

    it "should use the request_url of the returned response to construct the favicon url for relative paths" do
      FakeWeb.register_uri(:get, "http://images.example.com", :body => '<html><link rel="Shortcut Icon" href="/foo/favicon.ico" /></html>')
      @favicon.find('http://images.example.com/').should == 'http://images.example.com/foo/favicon.ico'
    end
  
    it "should find from default path" do
      FakeWeb.register_uri(:get, "http://www.example.com", :body => '<html></html>')
      @favicon.find('http://www.example.com/').should == 'http://www.example.com/favicon.ico'
      @favicon.find_from_html('<html></html>', 'http://www.example.com/').should == 'http://www.example.com/favicon.ico'
    end
    
    it "should find from default path a .jpeg file" do
      FakeWeb.register_uri(:get, "http://www.example.com", :body => '<html></html>')
      @favicon.should_receive(:valid_favicon_url?).with('http://www.example.com/favicon.ico').and_return(false)
      @favicon.should_receive(:valid_favicon_url?).with('http://www.example.com/favicon.png').and_return(false)
      @favicon.should_receive(:valid_favicon_url?).with('http://www.example.com/favicon.gif').and_return(false)
      @favicon.should_receive(:valid_favicon_url?).with('http://www.example.com/favicon.jpg').and_return(false)
      @favicon.should_receive(:valid_favicon_url?).with('http://www.example.com/favicon.jpeg').and_return(true)
      @favicon.find_from_html('<html></html>', 'http://www.example.com/').should == 'http://www.example.com/favicon.jpeg'
    end

    it "should validate url" do
      FakeWeb.register_uri(:get, "http://www.example.com", :body => '<html></html>')
      @favicon.should_receive(:valid_favicon_url?)
      @favicon.find('http://www.example.com/')
    end

    it "should return nil if #valid_favicon_url? returns false" do
      FakeWeb.register_uri(:get, "http://www.example.com", :body => '<html></html>')
      @favicon.stub!(:valid_favicon_url?).and_return(false)
      @favicon.find('http://www.example.com/').should be_nil
    end
  end

  describe '#valid_favicon_url?' do
    before do
      FakeWeb.clean_registry
      @url = 'http://www.example.com/favicon.ico'
      @response = expectaction(:code => '200', :body => 'an image', :content_type => 'image/jpeg')
      FakeWeb.register_uri(:get, "http://www.example.com/favicon.ico", :body => 'an image', :content_type => 'image/jpeg')
    end

    it 'should return true if it is valid' do
      @favicon.valid_favicon_url?(@url).should == true
    end

    it 'should return false if the code is not 200' do
      FakeWeb.register_uri(:get, "http://www.example.com/favicon.ico", :body => "Nothing to be found 'round here", :status => ["404", "Not Found"])
      @favicon.valid_favicon_url?(@url).should == false
    end

    it 'should return false if the body is blank' do
      FakeWeb.register_uri(:get, "http://www.example.com/favicon.ico", :body => '', :content_type => 'image/jpeg')
      @favicon.valid_favicon_url?(@url).should == false
    end

    it 'should return false if the content type is not an image content type' do
      FakeWeb.register_uri(:get, "http://www.example.com/favicon.ico", :body => 'an image', :content_type => 'application/xml')
      @favicon.valid_favicon_url?(@url).should == false
    end
  end
end

def expectaction(attr)
  OpenStruct.new(attr)
end
