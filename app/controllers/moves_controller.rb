class MovesController < ApplicationController
  def index
    @moves = Move.all
  end

  def show
    @move = Move.find_by(move_number: params[:id])

    if @move.nil?
      render json: { ok: false, :errors => "Move not found" }, status: :not_found 
    else
      render json: @move.as_json(only: [:type, :column], :include => { :player => { only: :name }}), status: :ok
    end
  end

  def create
    @game = Game.find_by(id: params[:gameId])
    @player = Player.find_by(id: params[:playerId])

    if @game.nil?
      render json: { :errors => "Game is not found"}, status: :not_found
    elsif @player.nil?
      render json: { :errors => "Player is not found"}, status: :not_found
    elsif !@game.players.include?(@player)
      render json: { :errors => "Player is not a part of the game" }, status: :not_found
    elsif @game.state == "Done"
      render json: {:errors => "Game is already in DONE state"}, status: 410
    elsif @game.moves.last.player.id == @player.id
      render json: { :errors => "Player tried to post when it's not their turn" }, status: 409
    elsif @game.moves.where(column: params[:column]).count >= 4
      render json: { :errors => "Column is full. Please choose another column." }, status: 400
    else
      Move.create!(category: 'Move', column: params[:column], move_number: @game.moves.count, game: @game, player: @player)

      if @game.moves.count == 16 && !@game.won?
        @game.update(state: "Done")
        render json: { :messages => "Game is Done. There is no winner"}, status: :ok
      elsif @game.won?
        render json: { :messages => "Move added successfully. and #{@player.name} just won the game! Congrats!"}, status: :ok
      else
        render json: { :messages => "Move added successfully"}, status: :ok 
      end 
    end
    
  end

  def quit
    @game = Game.find_by(id: params[:gameId])
    @player = Player.find_by(id: params[:playerId])

    if @game.nil?
      render json: { :errors => "Game is not found"}, status: :not_found
    elsif @player.nil?
      render json: { :errors => "Player is not found"}, status: :not_found
    elsif !@game.players.include?(@player)
      render json: { :errors => "Player is not a part of the game" }, status: :not_found
    elsif @game.state == "Done"
      render json: {:errors => "Game is already in DONE state"}, status: 410
    else
      loser_id = @player.id
      @winner = nil
      @game.players.each do |player|
        if player.id != loser_id
          @winner = player
        end
      end
      
      if !@winner.nil?
        @game.update(state: "Done", winner: @winner.name)
        total_moves = @game.moves.count

        Move.create!(category: 'Quit', move_number: total_moves, game: @game, player: @player)

        render json: { :messages => "Game is Done. Winner is #{@winner.name}"}, status: :ok       
      end
    end
  end

end
