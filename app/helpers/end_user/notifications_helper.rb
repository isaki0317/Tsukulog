module EndUser::NotificationsHelper
  def unchecked_notifications
    @notifications = current_end_user.passive_notifications.where(checked: false)
  end

  def notification_form(notification)
    @comment = nil
    visitor = link_to notification.visitor.name, notification.visitor, class: "visitor_name"
    your_post = link_to 'あなたの投稿', notification.post, class: "your_post"
    chat_room = link_to 'DM', chat_path(notification.visitor_id), class: "chat_room"
    case notification.action
    when "follow"
      "#{visitor}があなたをフォローしました"
    when "favorite"
      "#{visitor}が#{your_post}にいいね！しました"
    when "comment" then
      @comment = Comment.find_by(id: notification.comment_id)
      "#{visitor}が#{your_post}にコメントしました"
    when "dm"
      "#{visitor}から#{chat_room}が届いてます"
    end
  end
end
