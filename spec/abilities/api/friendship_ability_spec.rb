# -*- encoding : utf-8 -*-
require "api_spec_helper"
require 'cancan/matchers'

describe "Friendship abilities" do
  context "when user" do
    let(:user) { FactoryBot.create(:user) }
    let(:friend) { FactoryBot.create(:user) }
    let(:friendship) { friend.be_friends_with(user);
                       user.be_friends_with(friend).first }
    subject { Api::Ability.new(user) }

    it "should be able to manage friendship" do
      subject.should be_able_to :manage, friendship
    end
  end

  context "when redu_admin" do
    subject { Api::Ability.new(user) }
    let(:user) { FactoryBot.create(:user, :role => Role[:admin]) }
    it "should be able to manage all" do
      subject.should be_able_to :manage, :all
    end
  end

  context "when friend" do
    let(:user) { FactoryBot.create(:user) }
    let(:friend) { FactoryBot.create(:user) }
    let(:friendship) { friend.be_friends_with(user);
                       user.be_friends_with(friend).first }
    subject { Api::Ability.new(friend) }

    it "shold not be able read" do
      subject.should_not be_able_to :manage, friendship
    end
  end
end
