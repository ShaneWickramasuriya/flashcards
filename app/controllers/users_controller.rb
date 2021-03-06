class UsersController < ApplicationController

  def show
    @user = User.find(params[:id])
    @next_set = next_card_set unless current_user.user_sets.empty?
  end

  private

# find current users most recent user set, which card set was last attempted
  def set_most_recent_user_set
    @most_recent_user_set = current_user.user_sets.order(last_attempted: :desc).first
  end

  # sort card sets by difficulty, this is for giving correct suggestion to user, which card set to try next after finishing a set
  def sort_by_difficulty(language)
    sorted = []
    difficulties = CardSet.select(:difficulty).distinct.map { |set| set.difficulty }
    difficulties.each do |difficulty|
      CardSet.where(language: language, difficulty: difficulty).each do |set|
        sorted << set
      end
    end
    sorted
  end

  # create a list/array of card sets the current user has not yet completed for given language
  def completed_sets(language)
    completed_user_sets = current_user.user_sets.select { |user_set| user_set.completed }
    completed_card_sets = completed_user_sets.map do |user_set|
      user_set.card_set if user_set.card_set.language == language
    end
  end

  # function to find correct next set suggestion to user
  # finds all card sets for a language, based on the last attempted card set
  # sorts the cards by difficulty and remove ones the user has already completed
  def next_card_set
    set_most_recent_user_set
    card_set = @most_recent_user_set.card_set
    language = card_set.language
    # sets are cards sets sorted by difficulty, which not user has not yet completed
    # last attempted card set will be retained in the list, to find current proggress of user, even if he completed it
    sets = sort_by_difficulty(language) - (completed_sets(language) - [card_set])
    index = (sets.index(card_set) + 1) == sets.count ? 0 : (sets.index(card_set) + 1)
    sets[index] unless sets.count == 1 && @most_recent_user_set.completed
  end
end
