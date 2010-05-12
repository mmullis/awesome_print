require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'active_record'
require 'ap/mixin/active_record'


if defined?(::ActiveRecord)

  # Create tableless ActiveRecord model.
  #------------------------------------------------------------------------------
  class User < ActiveRecord::Base
    def self.columns()
      @columns ||= []
    end

    def self.column(name, sql_type = nil, default = nil, null = true)
      columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
    end

    column :id, :integer
    column :name, :string
    column :rank, :integer
    column :admin, :boolean
    column :created_at, :datetime

    def self.table_exists?
      true
    end
  end
  
  class SubUser < User
    def self.columns
      User.columns
    end
  end
  
  describe "AwesomePrint/ActiveRecord" do
    before(:each) do
      stub_dotfile!
    end

    #------------------------------------------------------------------------------
    describe "ActiveRecord instance" do
      before(:each) do
        ActiveRecord::Base.default_timezone = :utc
        @diana = User.new(:name => "Diana", :rank => 1, :admin => false, :created_at => "1992-10-10 12:30:00")
        @laura = User.new(:name => "Laura", :rank => 2, :admin => true,  :created_at => "2003-05-26 14:15:00")
        @ap = AwesomePrint.new(:plain => true)
      end

      it "display single record" do
        out = @ap.send(:awesome, @diana)
        out.gsub(/0x([a-f\d]+)/, "0x01234567").should == <<-EOS.strip
#<User:0x01234567> {
            :id => nil,
    :created_at => Sat Oct 10 12:30:00 UTC 1992,
         :admin => false,
          :name => "Diana",
          :rank => 1
}
EOS
      end

      it "display multiple records" do
        out = @ap.send(:awesome, [ @diana, @laura ])
        out.gsub(/0x([a-f\d]+)/, "0x01234567").should == <<-EOS.strip
[
    [0] #<User:0x01234567> {
                :id => nil,
        :created_at => Sat Oct 10 12:30:00 UTC 1992,
             :admin => false,
              :name => "Diana",
              :rank => 1
    },
    [1] #<User:0x01234567> {
                :id => nil,
        :created_at => Mon May 26 14:15:00 UTC 2003,
             :admin => true,
              :name => "Laura",
              :rank => 2
    }
]
EOS
      end
    end

    #------------------------------------------------------------------------------
    describe "ActiveRecord class" do
      it "should print the class" do
        @ap = AwesomePrint.new(:plain => true)
        @ap.send(:awesome, User).should == <<-EOS.strip
class User < ActiveRecord::Base {
            :id => :integer,
    :created_at => :datetime,
         :admin => :boolean,
          :name => :string,
          :rank => :integer
}
        EOS
  
end

it "should print the class for non-direct subclasses of AR::Base" do
  @ap = AwesomePrint.new(:plain => true)
  @ap.send(:awesome, SubUser).should == <<-EOS.strip
class SubUser < User {
            :id => :integer,
    :created_at => :datetime,
         :admin => :boolean,
          :name => :string,
          :rank => :integer
}
  EOS
  
      end
    end
  end
end
