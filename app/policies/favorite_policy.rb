class FavoritePolicy < ApplicationPolicy
  
  # Favoriteの作成権限
  def create?
    # 1. ログインユーザーがTripを閲覧できるかチェック
    # record は Favorite オブジェクト。record.trip で親の Trip にアクセス。
    TripPolicy.new(user, record.trip).show?
  end

  # Favoriteの削除権限
  def destroy?
    # 1. 削除対象のレコードが current_user のものであること
    # 2. Tripを閲覧できること (show? のチェックがあれば十分)
    record.user == user && TripPolicy.new(user, record.trip).show?
  end
end