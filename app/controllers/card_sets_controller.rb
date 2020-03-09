require 'faker'

class CardSetsController < ApplicationController
  def index
    @difficulty_value = 0
    @language = Language.find(params[:language_id])
    if params[:query].blank?
      @card_sets = CardSet.where(language: @language)
    else
      @card_sets = CardSet.search_by_title_and_description(params[:query]).select{ |set| set.language == @language }
      @card_sets = CardSet.where(language: @language) if @card_sets.blank?
    end

    @difficulties = CardSet.select(:difficulty).distinct.map { |set| set.difficulty }
    # ["Easy", "Medium", "Hard"]
    @user_sets = current_user.user_sets if user_signed_in?
    @temp
  end

  def show
    @answer = UserAnswer.new
    set_card_set
    @count = @card_set.flashcards.count
    @counter = @count
    # Check if the user has previously attempted the selected card set
    # Load the corresponding user set if attempted? returns true and resets points earned
    # points are reset so that we only hold points earned from current run
    if attempted?
      @user_set = UserSet.where(card_set: @card_set, user: current_user).first
      @user_set.last_attempted = Time.now
      @user_set.points_earned = 0
      @user_set.save
    # if not attempted before, create a new user set for the selected card set and generate correct number of unser answers, all set to false
    else
      @user_set = UserSet.new(user: current_user, card_set: @card_set, completed: false, points_earned: 0)
      @user_set.last_attempted = Time.now
      @user_set.save
      generate_user_answers(@user_set)
      assign_user_to_free_group
    end
  end

  private

  def set_card_set
    @card_set = CardSet.find(params[:id])
  end

  def attempted?
    set_card_set
    !UserSet.where(card_set: @card_set, user: current_user).first.blank?
  end

  def generate_user_answers(user_set)
    user_set.card_set.flashcards.each do |card|
      new_answer = UserAnswer.create(correct: false, flashcard: card, user_set: user_set)
    end
  end

  def assign_user_to_free_group
    current_language = @user_set.card_set.language
    matches = current_user.user_sets.select { |set| set.card_set.language.name == current_language }
    # check if user has completed any sets in this language before
    if matches.empty?
      # if not, then find last created group in that language that has less than 10 users
      group = Group.find_by(language: current_language, full: false)
      if group.nil?
      # if no free group exists, create group and add user to that group (via a group membership)
        new_group = Group.create(name: Faker::Hacker.say_something_smart, language: current_language, full: false)
        GroupMembership.create(group: new_group, user: current_user, language: current_language)
      else
        GroupMembership.create(group: group, user: current_user, language: current_language, points: 0)
        group.full = group.group_memberships.count == 10
        group.save
      end
    end
  end

end
