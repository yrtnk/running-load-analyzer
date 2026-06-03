require "rails_helper"

RSpec.describe "Activities", type: :request do
  let(:user) { create(:user) }

  describe "GET /activities" do
    context "when not logged in" do
      it "redirects to login" do
        get activities_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before { sign_in user }

      it "returns 200" do
        get activities_path
        expect(response).to have_http_status(:ok)
      end

      it "displays activities" do
        create(:activity, user: user, name: "Morning Run", start_date: Time.zone.now)
        get activities_path
        expect(response.body).to include("Morning Run")
      end

      it "does not show other users' activities" do
        other_user = create(:user)
        create(:activity, user: other_user, name: "Other User Run")
        get activities_path
        expect(response.body).not_to include("Other User Run")
      end

      it "shows empty state when no activities exist" do
        get activities_path
        expect(response.body).to include("アクティビティがありません")
      end

      context "with load_score" do
        it "displays load_score when present" do
          create(:activity, user: user, name: "Hard Run", load_score: 75.5)
          get activities_path
          expect(response.body).to include("75.5")
        end

        it "displays dash when load_score is nil" do
          create(:activity, user: user, name: "Easy Run", load_score: nil)
          get activities_path
          expect(response.body).to include("Easy Run")
        end
      end

      context "pagination" do
        it "paginates at 20 per page" do
          create_list(:activity, 25, user: user)
          get activities_path
          expect(response.body).to include("Morning Run")
          # 21件目以降はページ2に移動
          get activities_path, params: { page: 2 }
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
