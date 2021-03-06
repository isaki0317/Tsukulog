class EndUser < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  validates :name, presence: true, length: { in: 2..20 }
  validates :introduction, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true
  validates :address, length: { maximum: 50 }

  has_many :contacts
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_posts, through: :favorites, source: :posts
  has_many :bookmarks, dependent: :destroy
  has_many :bookmark_posts, through: :bookmarks, source: :posts

  # トーク機能
  has_many :user_rooms
  has_many :chats
  has_many :rooms, through: :user_rooms

  # フォロー機能
  # 自分がフォローしてるユーザとの関連
  has_many :active_relationships, class_name: "Relationship", foreign_key: :following_id
  has_many :followings, through: :active_relationships, source: :follower
  # 自分がフォローされてるユーザーとの関連
  has_many :passive_relationships, class_name: "Relationship", foreign_key: :follower_id
  has_many :followers, through: :passive_relationships, source: :following

  # ブロック機能
  # 自分がブロックしているユーザーとの関連
  has_many :active_blocks, class_name: "Block", foreign_key: :blocker_id
  has_many :blockers, through: :active_blocks, source: :blocked
  # 自分をブロックしているユーザーとの関連
  has_many :passive_blocks, class_name: "Block", foreign_key: :blocked_id

  # 通知機能
  has_many :active_notifications, class_name: "Notification", foreign_key: :visitor_id, dependent: :destroy
  has_many :passive_notifications, class_name: "Notification", foreign_key: :visited_id, dependent: :destroy

  mount_uploader :images, ImagesUploader

  enum sex: {
    未選択です: 0,
    男性: 1,
    女性: 2,
  }

  enum experience: {
    初心者: 0,
    中級者: 1,
    上級者: 2,
    プロ: 3,
  }

  def active_for_authentication?
    super && is_deleted == false
  end

  # フォロー機能で使用
  # 特定のユーザーのpassive_relationshipsの中のfollowing_idが引数で渡したユーザーのものがあるかの判定
  def followed_by?(end_user)
    passive_relationships.find_by(following_id: end_user.id).present?
  end

  # 相互フォローを探す
  def matchers
    followings & followers
  end

  # ブロック機能で使用↓
  # 特定のユーザー(投稿者など)のpassive_blocksのblocker_idの中に、引数で渡したユーザーが存在するかの判定
  def blocked_by?(end_user)
    passive_blocks.find_by(blocker_id: end_user.id).present?
  end

  # 特定のユーザー(投稿者など)のactive_blocksのblocked_idの中に、引数で渡したユーザーが存在するかの判定
  def blocker_by?(end_user)
    active_blocks.find_by(blocked_id: end_user.id).present?
  end

  # 特定のユーザーのactive_relationshipsの中のfollower_idが引数で渡したユーザーのものがあるかの判定
  def follower_by?(end_user)
    active_relationships.find_by(follower_id: end_user.id).present?
  end

  # ログインユーザーがブロックしたユーザーが、自分のfollowerにいる場合は削除する
  def destry_follow!(end_user)
    follow = active_relationships.find_by(follower_id: end_user.id)
    follow.destroy!
  end

  # ログインユーザーがブロックした相手とのUserRoomを削除 & admin側でのUserRoom削除に使用
  def user_room_destroy!(current_end_user, end_user)
    rooms = current_end_user.user_rooms.pluck(:room_id)
    pair_room = UserRoom.find_by(end_user_id: end_user.id, room_id: rooms)
    unless pair_room.nil?
      user_room = UserRoom.find_by(end_user_id: current_end_user.id, room_id: pair_room.room_id)
      if user_room.present? && pair_room.present?
        pair_room.destroy!
        user_room.destroy!
      end
    end
  end

  # ブロック機能(transactionでひとくくり)
  def block!(end_user_id)
    ActiveRecord::Base.transaction do
      block = active_blocks.build(blocked_id: end_user_id)
      block.save!
      end_user = EndUser.find(end_user_id)
      if follower_by?(end_user)
        destry_follow!(end_user)
      end
      user_room_destroy!(self, end_user)
      notification_destroy_all!(self, end_user)
      #下記がないとnilが返る
      return true
      # 例外を起こしてくれる↓
      # raise ActiveRecord::RecordInvalid
      # logger.debug current_end_user.user_room_delete(current_end_user, @end_user).errors.inspect
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    p e
    return false
  end

  # ログインユーザーがブロックした相手とのお互いの通知をすべて削除
  def notification_destroy_all!(current_end_user, end_user)
    notice_visitor = Notification.where("visitor_id = ? and visited_id = ?", end_user.id, current_end_user.id)
    notice_visited = Notification.where("visitor_id = ? and visited_id = ?", current_end_user.id, end_user.id)
    if notice_visited.present?
      notice_visited.each(&:destroy!)
    end
    if notice_visitor.present?
      notice_visitor.each(&:destroy!)
    end
  end

  # フォローに対する通知
  def create_notification_follow(follow_user, end_user)
    notice = Notification.where(["visitor_id = ? and visited_id = ? and action = ?", follow_user.id, end_user.id, 'follow'])
    if notice.blank?
      notification = follow_user.active_notifications.new(
        visited_id: end_user.id,
        action: 'follow'
      )
      notification.save
    end
  end

  def self.search_for(value, how, order, terms)
    if how == 'match'
      end_users = EndUser.where("name = ?", value)
    else
      end_users = EndUser.where('name LIKE ?', '%' + value + '%')
    end
    if order == 'experience'
        end_users = end_users.order("#{order}": terms)
    else
      end_users = end_users.order(created_at: :desc)
    end
  end

  # guestログイン
  def self.guest
    find_or_create_by!(email: 'guest@example.com') do |end_user|
      end_user.password = SecureRandom.urlsafe_base64
      end_user.name = "ゲスト太郎"
    end
  end
end
