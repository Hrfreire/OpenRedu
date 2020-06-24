# -*- encoding : utf-8 -*-
require 'spec_helper'

describe StatusObserver do
  context "after create" do

    def create_activity_after(&block)
      yield if block_given?
      ActiveRecord::Observer.with_observers(:status_observer) do
        activity
      end
    end

    context "when statusable is user" do
      let(:activity) { FactoryBot.create(:activity, :user => owner, :statusable => statusable) }
      let(:statusable) { FactoryBot.create(:user) }
      let(:owner) { FactoryBot.create(:user) }


      def create_friendship(user1, user2)
        user1.be_friends_with user2
        user2.be_friends_with user1
        user1.friends.reload
        user2.friends.reload
        user2
      end

      def create_friendships(user1, *users)
        users.each { |u| create_friendship(user1, u) }
        users
      end

      context "owner with contacts" do
        before do
          create_activity_after do
            create_friendships(owner, *FactoryBot.create_list(:user, 5))
          end
        end

        it "associates the owner" do
          owner.status_user_associations.count.should == 1
        end

        it "associates the owner contacts" do
          owner.friends.reload
          contacts = owner.friends.map(&:status_user_associations).flatten

          owner.friends.count.should_not == 0
          contacts.should_not be_empty
          contacts.to_set.should be_subset(activity.status_user_associations.to_set)
        end
      end

      context "with statusable contacts" do
        before do
          create_activity_after do
            create_friendships(statusable, *FactoryBot.create_list(:user, 3))
          end
        end

        it "associates the statusable contacts" do
          contacts = statusable.friends.map(&:status_user_associations).flatten
          contacts.should_not be_empty
        end
      end
    end

    context "when statusable is Lecture" do
      before do
        @environment = FactoryBot.create(:environment)
        @course = FactoryBot.create(:course, :owner => @environment.owner,
                          :environment => @environment)
        @poster = FactoryBot.create(:user)
        @course.join(@poster)
        @space = FactoryBot.create(:space, :owner => @environment.owner,
                         :course => @course)
        @subject = FactoryBot.create(:subject, :owner => @poster, :space => @space)
        @lecture = FactoryBot.create(:lecture, :subject => @subject,
                           :owner => @environment.owner)

        @poster_contacts = 5.times.inject([]) do |acc, i|
          u = FactoryBot.create(:user)
          u.be_friends_with(@poster)
          @poster.be_friends_with(u)
          acc << u
        end

        @students = 3.times.inject([]) do |acc, u|
          user = FactoryBot.create(:user)
          @course.join(user)
          acc << user
        end

      end

      context "and status is type of Activity" do

        before do
          ActiveRecord::Observer.with_observers(:status_observer) do
            @activity = FactoryBot.create(:activity, :statusable => @lecture,
                                :user => @poster)
          end
        end

        it "associates the course students" do
          @course.approved_users.to_set.should == @activity.users.to_set
        end

        it "cannot associate the poster contacts" do
          (@poster_contacts.to_set & @activity.users.to_set).should be_empty
        end
      end
    end

    context "when statusable is Space" do
      before do
        @environment = FactoryBot.create(:environment)
        @course = FactoryBot.create(:course, :owner => @environment.owner,
                          :environment => @environment)
        @poster = FactoryBot.create(:user)
        @course.join(@poster)
        @space = FactoryBot.create(:space, :owner => @environment.owner,
                         :course => @course)

        @poster_contacts = 5.times.inject([]) do |acc, i|
          u = FactoryBot.create(:user)
          u.be_friends_with(@poster)
          @poster.be_friends_with(u)
          acc << u
        end

        @students = 3.times.inject([]) do |acc, u|
          user = FactoryBot.create(:user)
          @course.join(user)
          acc << user
        end

        ActiveRecord::Observer.with_observers(:status_observer) do
          @activity = FactoryBot.create(:activity, :statusable => @space,
                              :user => @poster)
        end
      end

      it "associates the course students" do
        @course.approved_users.to_set.should == @activity.users.to_set
      end

      it "cannot associate the poster contacts" do
        (@poster_contacts.to_set & @activity.users.to_set).should be_empty
      end

    end

    context "when statusable is UserCourseAssociation" do
      before do
        ActiveRecord::Observer.with_observers(:status_observer) do
          @uca = FactoryBot.create(:user_course_association)
          @uca.approve!
          3.times { @uca.course.join(FactoryBot.create(:user)) }
          @log = Log.setup(@uca)
        end
      end

      it "associates the course students" do
        @log.users.should_not be_empty
        @log.users.to_set.should == @uca.course.approved_users.to_set
      end
    end
  end
end
