require 'cgi'
require 'cdsg.rb'

class GameController < ApplicationController
  def game
    redirect_to "/game/capitals?#{game_params.to_h.to_param}" if params[:capitals_mode] == '1'
    cookies[:session] = {
      value: CGI.escape(Time.now.to_s)
    }
    @cdsg = cdsg
  end

  def guess
    guess = guess_params[:guess].capitalize
    @cdsg = cdsg
    @cdsg.results << @cdsg.correct_state?(guess) if @cdsg.correct_state?(guess)
    if @cdsg.results.length == @cdsg.data.length
      redirect_to "/game/complete?region=#{params[:region]}"
    else
      game_redirect
    end
  end

  def hint
    @cdsg = cdsg
    game_redirect
  end

  def complete
    time_to_complete = Time.now - Time.new(CGI.unescape(cookies[:session]))
    if time_to_complete > 180
      flash[:notice] = "You completed the quiz in a human time: #{time_to_complete.to_s}s"
    else
      flash[:notice] = "You completed the quiz in a robot time: #{time_to_complete.to_s}s"
    end
    cookies.delete(:session)
  end

  def capitals
    @cdsg = cdsg
    @question = cdsg.data.each_key.to_a.select do |d|
      @cdsg.data[d]['capital'] != '#' && !@cdsg.results.keys.include?(d)
    end.shuffle.first
  end

  def cap_guess
    question = guess_params[:question]
    guess = guess_params[:guess].capitalize
    @cdsg = cdsg
    if @cdsg.correct_capital?(guess, question)
      @cdsg.results[question] = @cdsg.data[question]['capital']
    elsif (question == 'Sweden' && guess =~ /^[sS]tockholm$/)
      ## Sweden just doesn't want to work normally apparently.......
      @cdsg.results[question] = @cdsg.data[question]['capital']
    else
      logger.info("Given answer was #{guess.inspect} - answer is #{@cdsg.data[question]['capital'].inspect}")
    end
    if @cdsg.results.keys.length == @cdsg.data.length
      redirect_to "/game/complete?region=#{params[:region]}"
    else
      game_redirect
    end
  end

  private
    def game_params
      params.permit(:region, :capitals_mode, :hard_mode)
    end

    def progress_params
      params.permit(:region, :capitals_mode, :hard_mode, :results)
    end

    def guess_params
      params.permit(:guess, :question)
    end

    def cdsg
      gp = game_params.to_h.values.to_a
      @cdsg = CDSG.new(*gp)
      if params[:results] == nil
      elsif params[:results] == ''
      else
        results = params[:results].split(',').to_a
        if params[:capitals_mode] == '0'
          results.each { |r| @cdsg.results << r }
        elsif params[:capitals_mode] == '1'
          results.each { |r| @cdsg.results[r] = @cdsg.data[r]['capital'] }
        end
      end
      @cdsg
    end

    def game_redirect
     url_params = [
       "region=#{params[:region]}",
       "capitals_mode=#{params[:capitals_mode]}",
       "hard_mode=#{params[:hard_mode]}"
     ]
     if params[:capitals_mode] == '0'
       url_params << "results=#{@cdsg.results.join(',')}"
     elsif params[:capitals_mode] == '1'
       url_params << "results=#{@cdsg.results.keys.join(',')}"
     end
     if params[:hint]
       hint = @cdsg.hint(@cdsg.remaining_states.first, params[:hint_count].to_i)
       url_params << "hint=#{hint}"
       url_params << "hint_count=#{params[:hint_count]}"
     end
     redirect_to [
       (params[:capitals_mode] == '1' ? "/game/capitals?" : "/game?"),
       url_params.join('&')
     ].join
    end

end
