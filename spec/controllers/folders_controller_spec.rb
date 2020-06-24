# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'authlogic/test_case'

describe FoldersController do
  let(:user) { FactoryBot.create(:user) }
  let(:space) { FactoryBot.create(:space, :owner => user) }
  let(:folder) { FactoryBot.create(:folder, :space => space) }
  let(:base_params) do
    { :locale => 'pt-BR', :format => :js, :space_id => space.id }
  end

  before do
    Folder.any_instance.stub(:can_upload_file?).and_return(true)
    login_as user
  end

  context "POST create" do
    let(:params) do
      base_params.merge( :folder => { :name => 'New folder',
                                      :parent_id => space.folders.first.id,
                                      :space_id => space.id })
    end

    it "should assign folder" do
      post :create, params
      assigns[:folder].should_not be_nil
    end

    it "should assing space" do
      post :create, params
      assigns[:space].should == space
    end

    it "should call FolderService.create" do
      FolderService.any_instance.should_receive(:create).and_call_original
      post :create, params
    end

    it "should set folder#user" do
      post :create, params
      assigns[:folder].user.should == user
    end

    it "should set folder#date_modified" do
      post :create, params
      assigns[:folder].date_modified.should_not be_nil
    end
  end

  context "DELETE destroy" do
    let(:params) { base_params.merge(:id => folder.to_param) }

    it "should call FolderService.destroy" do
      FolderService.any_instance.should_receive(:destroy).and_call_original
      delete :destroy_folder, params
    end
  end

  context "POST update" do
    let(:params) do
      base_params.merge(:id => folder.to_param, "folder" => { "name" => "New" })
    end

    it "should assign parent folder" do
      post :update, params
      assigns[:folder].should == folder.parent
    end

    it "should call FolderService.update" do
      update_params = params["folder"].
        merge("date_modified" => an_instance_of(Time))
      FolderService.any_instance.should_receive(:update).with(update_params).
        and_call_original
      post :update, params
    end
  end

  context "Myfiles" do
    context "POST do_the_upload" do
      let(:file) do
        File.open("#{Rails.root}/spec/fixtures/api/pdf_example.pdf")
      end
      let(:my_file_params) do
        { :folder_id => folder.to_param, :attachment => file }
      end
      let(:params) do
        base_params.merge(:space_id => space.to_param,
                          :id => folder.to_param, :myfile => my_file_params)
      end

      before do
        space.course.plan = FactoryBot.build(:plan, :billable => nil)
        Folder.any_instance.stub(:can_upload_file?) { true }
      end

      it "should call MyfileService.create" do
        MyfileService.any_instance.should_receive(:create).and_call_original
        post :do_the_upload, params
      end

      it "should assign myfile" do
        post :do_the_upload, params
        assigns[:myfile].should_not be_nil
      end

      it "should set the user in myfile" do
        post :do_the_upload, params
        assigns[:myfile].user.should == user
      end
    end

    context "DELETE destroy_file" do
      let(:myfile) { FactoryBot.create(:myfile) }
      let(:params) do
        base_params.merge(:space_id => space.to_param,
                          :id => folder.to_param, :file_id => myfile.to_param)
      end

      it "should call MyfileService.destroy" do
        MyfileService.any_instance.should_receive(:destroy).and_call_original
        delete :destroy_file, params
      end

      it "should assign myfile" do
        delete :destroy_file, params
        assigns[:myfile].should == myfile
      end
    end
  end
end
