module PL
  module Database

    # def self.db
    #   @__db_instance ||= InMemory.new
    # end

    class InMemory

      def initialize(env=nil)
        clear_everything
      end

      def clear_everything
      	@user_id_counter = 100
      	@users = {}
      end

      ##############
      #   Users    #
      ##############
      def create_user(attrs)
      	id = (@user_id_counter += 1)
      	attrs[:id] = id
      	user = User.new(attrs)
      	@users[id] = user
      	user
      end

      def get_user(id)
      	@users[id]
      end

  	end
  end
end