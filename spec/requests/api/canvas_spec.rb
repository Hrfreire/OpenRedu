# -*- encoding : utf-8 -*-
require  'api_spec_helper'

describe 'Canvas API' do
  let(:environment) { FactoryBot.create(:complete_environment) }
  let(:course) { environment.courses.first }
  let(:space) { course.spaces.first }
  let(:token) { _, _, token = generate_token(space.owner); token }
  let(:params) { { oauth_token: token, format: 'json' } }

  subject do
    FactoryBot.create(:canvas, container: space, user: space.owner)
  end

  context "GET /api/canvas/:id" do
    before do
      get "api/canvas/#{subject.id}", params
    end

    it_should_behave_like "a canvas"
  end

  context "POST /api/spaces/:id/canvas" do
    let(:canvas_params) do
      params[:canvas] = {
        name: "My awesome canvas",
        current_url: "http://foo.bar.com"
      }
      params
    end
    before do
      post "api/spaces/#{space.id}/canvas", canvas_params
    end

    it "should return the 201 HTTP code" do
      response.code.should == "201"
    end

    it "should create with the name specified" do
      parse(response.body)["name"].should == canvas_params[:canvas][:name]
    end

    it_should_behave_like "a canvas"

    context "with validation error" do
      before do
        canvas_params[:canvas][:current_url] = "not a URL"
        post "api/spaces/#{space.id}/canvas", canvas_params
      end

      it "should return the 422 HTTP code" do
        response.code.should == "422"
      end
    end
  end

  context "GET /api/spaces/:space_id/canvas" do
    it "should return the correct canvas representations" do
      canvas = 3.times.collect do
        FactoryBot.create(:canvas, container: space, user: space.owner)
      end

      get "api/spaces/#{space.id}/canvas", params

      parse(response.body).collect { |r| r["id"] }.
        to_set.should == canvas.collect(&:id).to_set
    end
  end
end
