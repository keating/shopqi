#encoding: utf-8
require 'spec_helper'

describe PagesDrop do

  let(:shop) { Factory(:user).shop }

  it 'should get about-us page' do
    page_drop = PagesDrop.new shop
    page_drop.send('about-us').content.should_not be_nil
  end

end