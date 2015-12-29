# http://patorjk.com/software/taag/#p=display&f=Banner&t=Commands

module Sample

  class GameError < StandardError
  end





  #####
 #     #  ####  #    # ##### #####   ####  #      #      ###### #####
 #       #    # ##   #   #   #    # #    # #      #      #      #    #
 #       #    # # #  #   #   #    # #    # #      #      #####  #    #
 #       #    # #  # #   #   #####  #    # #      #      #      #####
 #     # #    # #   ##   #   #   #  #    # #      #      #      #   #
  #####   ####  #    #   #   #    #  ####  ###### ###### ###### #    #

  class Controller

    class NotStartedError < GameError
    end

    attr_reader :state

    def initialize(state)
      @state = state
    end


    def input(command_hash={})
      check_allowed!(command_hash)

      command = Commands::Factory.fab(command_hash)
      result = command.run(state)

      @state = result[1]
      return result[0]
    end

    private

    def check_allowed!(command_data)
      if @state.nil? && command_data[:command] != 'Start'
        raise NotStartedError
      end
    end

  end





  #####
 #     #  ####  #    # #    #   ##   #    # #####   ####
 #       #    # ##  ## ##  ##  #  #  ##   # #    # #
 #       #    # # ## # # ## # #    # # #  # #    #  ####
 #       #    # #    # #    # ###### #  # # #    #      #
 #     # #    # #    # #    # #    # #   ## #    # #    #
  #####   ####  #    # #    # #    # #    # #####   ####

  module Commands

    class InputError < GameError
    end

    class Factory

      class NotFoundError < GameError
      end

      def self.fab(input)
        input.is_a?(Hash) or raise NotFoundError, "data input must be a Hash, got '#{input}':#{input.class} instead"

        klass = case input[:command]
        when 'Echo'     then Commands::Echo
        when 'Start'    then Commands::Start
        when 'RollDice' then Commands::RollDice
        else raise NotFoundError, "Command was '#{input[:command]}' Not Found"
        end

        klass.new(input)
      end
    end

    class Base
      attr_reader :input

      def initialize(input)
        @input = input
      end
    end

    class Echo < Base
      def run(state)
        [input, state]
      end
    end

    class Start < Base
      class AlreadyStartedError < GameError
      end

      def run(state)
        check_unstarted!(state)
        check_input!(input)

        output = "started!"

        # new state template
        state = {
          players_order: [],
          players: {},
          commands: {},
          board: {},
        }

        # fill state template
        input[:players].each do |pid, phash|
          state[:players_order] << pid
          state[:players][pid] = phash
          state[:board][pid]   = nil
        end

        # determine next turn
        state[:commands] = {'H1' => ['RollDice']} # next turn, untested

        [output, state]
      end

      private

      def check_unstarted!(state)
        state.nil? or raise AlreadyStartedError
      end

      def check_input!(input)
        if input.keys != expected_input_keys
          raise InputError, "expected keys '#{expected_input_keys}',\t found keys: #{input.keys}"
        end
      end

      def expected_input_keys
        [:command, :players]
      end
    end

    class RollDice < Base
      def run(state)
        output = []

        d = Dice.roll(2)

        output << "#{input[:player]} rolled 2d6: #{d.join(', ')}."

        state[:board][input[:player]] = d
        # has_two_equal_dice = d.uniq.size==1
        # if has_two_equal_dice
        #  output << "Explosion, roll again!"
        # else
        state[:commands] = {'H1' => ['EndTurn']} # untested
        # end

        [output, state]
      end
    end

    class EndTurn < Base
      def run(state)
        output = []

        player_id = input[:player]
        state[:commands][player_id] = []
        output << "#{player_id} has ended their turn."

        # next_player_id = input[:player] + 1
        next_player_id = "H2"
        output << "#{next_player_id}, now it is your turn."
        state[:commands][next_player_id] = ['RollDice']

        [output, state]
      end
    end
  end





 ######
 #     # #        ##   #   # ###### #####
 #     # #       #  #   # #  #      #    #
 ######  #      #    #   #   #####  #    #
 #       #      ######   #   #      #####
 #       #      #    #   #   #      #   #
 #       ###### #    #   #   ###### #    #





  # class Player

  #   def initialize(game, key)
  #     @game, @key = game, key
  #     @game.players << self
  #   end

  # end

  # class HumanPlayer < Player

  #   def initialize(key)
  #     super(key)
  #   end

  # end

  # class RobotPlayer < Player

  #   def initialize(key)
  #     super(key)
  #   end

  # end

end
