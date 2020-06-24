# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ApplicationController do
  controller do
    def show
      render :text => "show called"
    end
  end

  describe 'Check tour exploration' do
    context 'when logged in' do
      let(:user) { FactoryBot.create(:user) }
      before do
        login_as user
      end

      context 'when accessing some action with exploring_tour true' do
        before do
          get :show, :id => 'anyid', :exploring_tour => "true"
        end

        it 'responds with success' do
          response.should be_success
        end

        it 'keeps track of the visited url' do
          user.settings.visited?(request.path).should be_true
        end
      end

      context 'when accessing some action without exploring_tour params' do
        before do
          get :show, :id => 'anyid'
        end

        it 'responds with success' do
          response.should be_success
        end

        it 'does not keep track of the visited url' do
          user.settings.visited?(request.path).should be_false
        end
      end
    end

    context 'when not logged in' do
      context 'when accessing some action with exploring_tour true' do
        before do
          get :show, :id => 'anyid', :exploring_tour => "true"
        end

        it 'responds with success' do
          response.should be_success
        end

        it 'does not call visit!' do
          TourSetting.any_instance.should_not_receive(:visit!)
          get :show, :id => 'anyid', :exploring_tour => "true"
        end
      end

      context 'when accessing some action without exploring_tour params' do
        before do
          get :show, :id => 'anyid'
        end

        it 'responds with success' do
          response.should be_success
        end

        it 'does not call visit!' do
          TourSetting.any_instance.should_not_receive(:visit!)
          get :show, :id => 'anyid', :exploring_tour => "true"
        end
      end
    end
  end

  describe "Detect mobile" do
    # Necessário por causa da manipulação do view_paths
    render_views

    controller do
      def index
        render :text => "index called"
      end
    end

    let(:view_paths) { @controller.view_paths }
    let(:mobile_views_path) do
      ActionView::OptimizedFileSystemResolver.new("app/views/mobile")
    end

    context "when accessed from a mobile device" do
      before do
        mock_user_agent(:mobile => true)
      end

      it "prepends mobile views path" do
        get :index, :locale => 'pt-BR'
        view_paths.paths.should include(mobile_views_path)
      end
    end

    context "when accessed from a non mobile device" do
      before do
        mock_user_agent(:mobile => false)
      end

      it "does not prepend mobile views path" do
        get :index, :locale => 'pt-BR'
        view_paths.paths.should_not include(mobile_views_path)
      end
    end
  end

  describe "Rescue from CanCan::AccessDenied" do
    controller do
      def index
        raise CanCan::AccessDenied
      end
    end

    context "when accessed from a mobile device" do
      before do
        mock_user_agent(:mobile => true)
      end

      it "redirects to /entrar" do
        get :index, :locale => 'pt-BR'
        # Hardcoded porque anonymous controller sobrescreve as rotas
        response.should redirect_to("/entrar")
      end
    end

    context "when accessed from a non mobile device" do
      before do
        mock_user_agent(:mobile => false)
      end

      it "redirects to /" do
        get :index, :locale => 'pt-BR'
        # Hardcoded porque anonymous controller sobrescreve as rotas
        response.should redirect_to("/")
      end
    end

    context "when accessing an ApplicationControllerSubclass" do
      class ApplicationControllerSubclass < ApplicationController
        rescue_from CanCan::AccessDenied, :with => :deny_access

        private

        def deny_access(exception, &block)
          super(exception) do
            flash.delete(:error)
          end
        end
      end

      controller(ApplicationControllerSubclass) do
        def index
          raise CanCan::AccessDenied
        end
      end

      it "should accept a block" do
        get :index, :locale => 'pt-BR'
        flash[:error].should be_nil
      end
    end
  end
end
