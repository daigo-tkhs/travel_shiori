class TripPolicy < ApplicationPolicy
  # index アクションのためのスコープ定義
  class Scope < Scope
    def resolve
      scope.left_outer_joins(:trip_users)
           .where(trips: { owner: user })
           .or(scope.left_outer_joins(:trip_users).where(trip_users: { user: user }))
           .distinct
    end
  end
  
  # ユーザーがオーナーかどうか
  def owner?
    record.owner == user
  end

  # ユーザーが編集権限を持つメンバーかどうか (Tripモデルのeditable_by?メソッドを参照)
  def editor?
    record.editable_by?(user)
  end

  # ゲストアクセスを含めた閲覧可能かチェック
  def viewable?
    # ログインユーザーのアクセス
    return record.viewable_by?(user) if user.present?
    
    # ゲストアクセス
    check_guest_access?
  end

  # ==================================
  # CRUD操作
  # ==================================

  def show?
    viewable?
  end

  def new?
    user.present?
  end

  def create?
    user.present?
  end

  # 更新・編集はオーナーのみに制限
  def update?
    owner?
  end
  
  def edit?
    update?
  end

  # 削除はオーナーのみ許可
  def destroy?
    owner?
  end
  
  # ==================================
  # 特殊な操作
  # ==================================
  
  # 【変更①】共有設定と招待は「編集者」も可能に変更（元はowner?のみ）
  def sharing?
    editor?
  end
  
  def invite?
    editor?
  end
  
  # クローン（複製）はログインユーザーなら誰でも許可
  def clone?
    user.present?
  end
  
  # 【変更④】AIチャットは「閲覧可能なログインユーザー」なら誰でも利用可能に変更（元はeditor?のみ）
  # 閲覧者(Viewer)でもチャットに参加できるようになります
  def ai_chat?
    user.present? && viewable?
  end

  # チェックリストのインポート権限
  def import?
    # 編集権限があればインポート可能
    editor?
  end

  private
  
  # ゲストとしてアクセス可能かチェックするプライベートメソッド
  def check_guest_access?
    false
  end
end