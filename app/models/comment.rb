class Comment < ActiveRecord::Base
  acts_as_authorizable
  
  belongs_to :idea
  belongs_to :author, :class_name => 'User'
  def comment_type
    'comment'
  end

  validates_presence_of :idea, :author, :text
  validate :idea_not_closed
  
  include SpamFiltering
  
  def spam_filtering_user
    author
  end
  
  def spam_filtering_text
    text
  end
  
  def idea_not_closed
    if !idea.nil? && idea.closed?
      errors.add_to_base("You are trying to comment on an idea within a closed current.  That's not allowed.")
    end
  end
  
  include InappropriateFlag
  unless !Comment.table_exists? 
    acts_as_tsearch :fields=>%w(text)
  end
  
  def after_create
    author.record_contribution! :comment
    send_later :check_spam!
  end
  
  def editing_expired?
    created_at < 15.minutes.ago
  end
  
  def editable_by?(user)
    user == author && !editing_expired?
  end
end
