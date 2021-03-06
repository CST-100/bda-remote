class CompetitionsController < AuthenticatedController
  before_action :require_session, only: [:new, :create, :edit, :start, :unstart, :extend, :template, :duplicate, :publish, :unpublish]

  include Serviceable
  skip_before_action :verify_authenticity_token
#  acts_as_service :competition, only: [:index, :show]
#  skip_before_action :authenticate_user!, only: [:index, :show, :start]

  # rescue_from ActiveRecord::RecordNotUnique, with: :duplicate_record

  def index
    @competitions = Rails.cache.fetch("competitions") do
      Competition.limit(10).order(updated_at: :desc)
    end
    respond_to do |format|
      format.json { render json: @collection }
      format.xml { render xml: @collection }
      format.html
    end 
  end

  def show
    @instance = Rails.cache.fetch("competition-#{params[:id]}") do
      Competition.includes(
          players: {},
          records: {},
          vessels: :player,
          heats: { heat_assignments: { vessel: :player } }
      ).find(params[:id])
    end

    respond_to do |format|
      format.json { render json: @instance }
      format.xml { render xml: @instance }
      format.html
    end
  end

  def edit
    @competition = Competition.find(params[:id])
    @rulesets = Ruleset.all.map { |e| [e.name, e.id] }
    redirect_to competition_path(@competition) unless current_user == @competition.user
  end

  def update
    @competition = Competition.find(params[:id])
    @competition.update(valid_params)
    @competition.save
    redirect_to competition_path(@competition)
  end

  def results
    @competition = Rails.cache.fetch("results-#{params[:id]}") do
      Competition.includes(records: { vessel: :player }).find(params[:id])
    end
    respond_to do |format|
      format.csv
    end
  end

  def new
    @competition = Competition.new
    @rulesets = Ruleset.all
  end

  def create
    @competition = Competition.new(valid_params)
    @competition.user_id = current_user.id
    @competition.save
    if @competition.errors.any?
      flash[:error] = @competition.errors.full_messages.to_sentence
      redirect_to new_competition_path
    else
      redirect_to competition_path(@competition)
    end
  end

  def start
    @instance = Competition.find(params[:id])
    @instance.start!
    if @instance.started?
      redirect_to competition_path(@instance)
    else
      head :bad_request
    end
  end

  def unstart
    @instance = Competition.find(params[:id])
    redirect_to competition_path(@instance) and return if @instance.records.any? || current_user != @instance.user
    @instance.unstart!
    redirect_to competition_path(@instance)
  end

  def extend
    @instance = Competition.find(params[:id])
    if @instance.running?
      if params[:strategy] == "ranked"
        @instance.extend!(Armory::TournamentRankingStrategy.new)
      else
        @instance.extend!
      end
      redirect_to competition_path(@instance)
    else
      flash[:error] = "sorry, dave"
      head :bad_request
    end
  end

  def publish
    @instance = Competition.find(params[:id])
    if @instance.private?
      @instance.publish!
    end
    redirect_to competition_path(@instance)
  end

  def unpublish
    @instance = Competition.find(params[:id])
    if @instance.public?
      @instance.unpublish!
    end
    redirect_to competition_path(@instance)
  end

  def template
    @competitions = Competition.all
  end

  def duplicate
    src = Competition.find(params[:competition][:original_id])
    redirect_to template_competitions_path and return if src.nil?
    dst = Competition.create(name: params[:competition][:name], user_id: current_user.id)
    if dst.errors.any?
      flash[:error] = dst.errors
      redirect_to template_competitions_path and return
    end
    # copy vessels
    src.vessel_assignments.each do |e|
      dst.vessel_assignments.create(vessel_id: e.vessel_id)
    end
    # copy rules
    src.rules.each do |e|
      dst.rules.create(strategy: e.strategy, params: e.params)
    end
    redirect_to competition_path(dst)
  end

  private

  def duplicate_record
    result = { error: "Name must be unique" }
    respond_to do |format|
      format.json { render json: result }
      format.xml { render xml: result }
      format.html { redirect_to new_competition_path }
    end
  end

  def valid_params
    params.require(:competition).permit(:name, :duration, :private, :ruleset_id, :max_stages)
  end
end
