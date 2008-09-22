require 'test_helper'

class EnginesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:engines)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_engine
    assert_difference('Engine.count') do
      post :create, :engine => { }
    end

    assert_redirected_to engine_path(assigns(:engine))
  end

  def test_should_show_engine
    get :show, :id => engines(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => engines(:one).id
    assert_response :success
  end

  def test_should_update_engine
    put :update, :id => engines(:one).id, :engine => { }
    assert_redirected_to engine_path(assigns(:engine))
  end

  def test_should_destroy_engine
    assert_difference('Engine.count', -1) do
      delete :destroy, :id => engines(:one).id
    end

    assert_redirected_to engines_path
  end
end
