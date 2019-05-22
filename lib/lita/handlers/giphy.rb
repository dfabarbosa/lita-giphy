require 'lita'
module Lita
  module Handlers
    class Giphy < Handler

      config :api_key, required: true
      config :rating, default: "pg"

      URL = "http://api.giphy.com/v1/gifs/search"

      route(/^(?:giphy|gif|animate)(?:\s+me)?\s+(.+)/i, :giphy, command: true, help: {
        "giphy QUERY" => "Grabs a gif tagged with QUERY."
      })

      route(/(\W|^)((sad)|(:disappointed:)|(:cry:))(\W|$)/i, :giphy_sad, command: false, help: {
        ":( or sad" => "Grabs a gif to cheer you up."
      })

      route(/(\W|^)(((haha)(ha)*)|lol|rofl|:joy:|:laughing:)(\W|$)/i, :giphy_lol, command: false, help: {
        "haha, lol or rofl" => "Grabs a gif to cheer you up more."
      })

      route(/(\W|^)(cansado|cansada|tired|sloth|sleep|sleepy)(\W|$)/i, :giphy_sloth, command: false, help: {
        "cansado, cansado, tired, sloth, sleep or sleepy" => "Grabs a gif to show you a sloth."
      })

      route(/(\W|^)(deal with it)(\W|$)/i, :giphy_deal, command: false, help: {
        "deal with it" => "Grabs a gif to deal with it."
      })


      def giphy(response)
        return unless validate(response)

        query = response.matches[0][0]
        response.reply get_gif(query)
      end

      def giphy_sad(response)
        return unless validate(response)
        response.reply get_gif("be happy")
      end

      def giphy_deal(response)
        return unless validate(response)
        response.reply get_gif("deal with it")
      end

      def giphy_lol(response)
        return unless validate(response)
        probability = 40
        random_chance = rand(100)
        response.reply get_gif("lol") if (random_chance < probability)
      end

      def giphy_sloth(response)
        return unless validate(response)
        probability = 50
        random_chance = rand(100)
        response.reply get_gif("sloth") if (random_chance < probability)
      end

      private

      def validate(response)
        if Lita.config.handlers.giphy.api_key.nil?
          response.reply "Giphy API key required"
          return false
        end

        true
      end

      def get_gif(query)
        process_response(http.get(
          URL,
          q: query,
          rating: Lita.config.handlers.giphy.rating,
          api_key: Lita.config.handlers.giphy.api_key
        ), query)
      end

      def process_response(http_response, query)
        data = MultiJson.load(http_response.body)

        puts "****************************************"
        puts data
        puts "****************************************"

        if data["meta"]["status"] == 200
          choice = data["data"].sample
          if choice.nil?
            reply_text = "I couldn't find anything for '#{query}'!"
          else
            reply_text = choice["images"]["original"]["url"]
          end
        else
          reason = data["meta"]["error_message"] || "unknown error"
          Lita.logger.warn(
            "Couldn't get image from Giphy: #{reason}"
          )
          reply_text = "Giphy request failed-- please check my logs."
        end

        reply_text
      end
    end

    Lita.register_handler(Giphy)
  end
end
