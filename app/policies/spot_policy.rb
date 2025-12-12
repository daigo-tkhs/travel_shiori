class SpotPolicy < ApplicationPolicy
  
  # 閲覧権限は、旅程の閲覧権限に依存する
  def show?
    # record は Spot オブジェクト
    # record.trip は親の Trip オブジェクト
    TripPolicy.new(user, record.trip).show?
  end

  # 作成、更新、削除、移動の権限は、旅程の編集権限に依存する
  def create?
    TripPolicy.new(user, record.trip).editor?
  end

  def new?
    create?
  end

  def update?
    TripPolicy.new(user, record.trip).editor?
  end
  
  def edit?
    update?
  end

  def destroy?
    TripPolicy.new(user, record.trip).editor?
  end
  
  def move?
    update?
  end
end