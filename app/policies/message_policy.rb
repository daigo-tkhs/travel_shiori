class MessagePolicy < ApplicationPolicy
  
  # index/show 権限は、親である旅程の閲覧権限に依存する
  def index?
    TripPolicy.new(user, record.trip).show?
  end

  def show?
    index?
  end

  # 作成権限は、旅程の編集権限に依存する
  def create?
    TripPolicy.new(user, record.trip).editor?
  end

  # 編集・更新・削除権限
  def update?
    # 旅程の編集権限を持つ OR メッセージの作成者自身である
    TripPolicy.new(user, record.trip).editor? || record.user == user
  end
  
  def edit?
    update?
  end

  def destroy?
    update?
  end
end