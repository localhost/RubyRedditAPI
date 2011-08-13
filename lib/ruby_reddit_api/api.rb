module Reddit

  # @author James Cook
  class Api < Base
    attr_accessor :user, :password
    attr_reader :last_action, :debug

    def initialize(user=nil,password=nil, options={})
      @user     = user
      @password = password
      @debug    = StringIO.new
    end

    def inspect
      "<Reddit::Api>"
    end

    # Browse submissions by subreddit
    # @param [String] Subreddit to browse
    # @return [Array<Reddit::Submission>]
    def browse(subreddit, options={})
      subreddit = sanitize_subreddit(subreddit)
      options.merge! :handler => "Submission"
      if options[:limit]
        options.merge!({:query => {:limit => options[:limit]}})
      end
      read("/r/#{subreddit}.json", options )
    end

    # Search reddit
    # @param [String, Hash] Search terms and options
    # @example
    #   search("programming", :in => "ruby", :sort => "relevance")
    # @return [Array<Reddit::Submission>]
    def search(terms=nil, options={})
      http_options = {:verb => "get", :query => {}}
      subreddit    = options[:in]
      sort         = options.fetch(:sort){ "relevance" }
      http_options[:query].merge!({:sort => sort})

      if subreddit
        http_options[:query].merge!({:restrict_sr => "1"})
      end

      if terms
        http_options[:query].merge!({:q => terms})
      end
      path = subreddit.to_s == "" ? "/r/search.json" : "/r/#{subreddit}/search.json"
      read(path, http_options)
    end

    # Fetch submissions by user
    # @param [Hash] Options
    # @return [Array<Reddit::Submission>]
    def submitted(options={})
      user = options.delete(:user) || @user
      options = merge_options({ :handler => "Submission", :query => {} }, options)
      read("/user/#{user}/submitted/.json", options)
    end

    # Fetch liked submissions (depends on the users' privacy settings)
    # @param [Hash] Options
    # @return [Array<Reddit::Submission>]
    def liked(options={})
      user = options.delete(:user) || @user
      options = merge_options({ :handler => "Submission", :query => {} }, options)
      read("/user/#{user}/liked/.json", options)
    end

    # Fetch disliked submissions (depends on the users' privacy settings)
    # @param [Hash] Options
    # @return [Array<Reddit::Submission>]
    def disliked(options={})
      user = options.delete(:user) || @user
      options = merge_options({ :handler => "Submission", :query => {} }, options)
      read("/user/#{user}/disliked/.json", options)
    end

    # Fetch saved submissions (logged in user only)
    # @param [Hash] Options
    # @return [Array<Reddit::Submission>]
    def saved(options={})
      return false unless logged_in?
      options = merge_options({ :handler => "Submission", :query => {} }, options)
      read("/saved/.json", options)
    end

    # Fetch hidden submissions (logged in user only)
    # @param [Hash] Options
    # @return [Array<Reddit::Submission>]
    def hidden(options={})
      user = options.delete(:user) || @user
      options = merge_options({ :handler => "Submission", :query => {} }, options)
      read("/user/#{@user}/hidden/.json", options)
    end

    # Read sent messages
    # @return [Array<Reddit::Message>]
    def sent_messages
      messages :sent
    end

    # Read received messages
    # @return [Array<Reddit::Message>]
    def received_messages
      messages :inbox
    end

    #Read unread messages
    # @return [Array<Reddit::Message>]
    def unread_messages
      messages :unread
    end

    # Read received comments
    # @return [Array<Reddit::Message>]
    def comments
      messages :comments
    end

    # Read post replies
    # @return [Array<Reddit::Message>]
    def post_replies
      messages :selfreply
    end

    protected
    def messages(kind)
      read("/message/#{kind.to_s}.json", :handler => "Message")
    end

    def merge_options(options, opt)
      # these options can be given directly, but actually belong in options[:query]
      [:count, :before, :after, :limit].each do |o|
        options[:query][o] = opt[o] if opt[o]
        opt.delete o
      end
      options[:query].merge! opt[:query] if opt[:query]
      opt.delete :query
      options.merge! opt
    end
  end
end
