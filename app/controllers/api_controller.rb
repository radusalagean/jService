class ApiController < ApplicationController



  def random
    count = params[:count].present? ? params[:count] : 1
    if(count.to_i > 100)
      count = 100
    end

    max_words = params[:max_words].present? ? params[:max_words].to_i : nil

    query = Clue.order(Arel.sql('RANDOM()'))

    if max_words
      query = query.where("array_length(string_to_array(answer, ' '), 1) <= ?", max_words)
    end

    @result = query.limit(count)

    respond_to do |format|
      # format.json { render :json => @result.to_json(:include => :category) }
      format.json { render :json => { result: "TEST" } }
    end
  end

  def final
    count = params[:count].present? ? params[:count] : 1
    if(count.to_i > 100)
      count = 100
    end
    
    @result = Clue.where(value: nil).order('RANDOM()').limit(count)
    respond_to do |format|
      format.json { render :json => @result.to_json(:include => :category) }
    end
  end

  def clues
    require 'chronic'
    clues = Clue
    clues = clues.where("value = ?", params[:value])  if params[:value].present?
    if(params[:min_date].present? && params[:max_date].present?)
      clues = clues.where("airdate between ? AND ?", Chronic.parse(params[:min_date]), Chronic.parse(params[:max_date]))
    else
      clues = clues.where("airdate > ?", Chronic.parse(params[:min_date])) if params[:min_date].present?
      clues = clues.where("airdate < ?", Chronic.parse(params[:max_date])) if params[:max_date].present?
    end
    clues = clues.where("game_id = ?", params[:game_id]) if params[:game_id].present?
    clues = clues.where("category_id = ?", params[:category]) if params[:category].present?
    offset = params[:offset].present? ? params[:offset] : 0

    @result = clues.limit(100).offset(offset)

    respond_to do |format|
      format.json { render :json => @result.to_json(:include => :category) }
    end
  end

  def categories
    offset = params[:offset].present? ? params[:offset] : 0
    count = params[:count].present? ? params[:count] : 1

    if(count.to_f > 100)
      count = 100
    end
    @categories = Category.limit(count).offset(offset)

    respond_to do |format|
      format.json { render json: @categories }
    end
  end

  def single_category
    @category = Category.find(params[:id])
    respond_to do |format|
      format.json { render :json => @category.to_json(:include => { :clues => { :except => [:created_at, :updated_at]}}) }
    end
  end

  def mark_invalid
    @clue = Clue.find(params[:id])
    @clue.increment(:invalid_count,1)
    @clue.save

    respond_to do |format|
      format.json {render :json => @clue.to_json() }
    end
  end
end
