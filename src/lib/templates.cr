require "http-session"

module CrystalGauntlet::Templates
  extend self

  macro dir_header()
    %path_split = context.request.path.split('/')
    "<div class='dir-header'>" + %path_split.map_with_index { |v, i| "<a href='/#{%path_split[1..i].join('/')}'>#{i == 0 ? "crystal-gauntlet" : v}</a>"}.join(" / ") + "</div>"
  end

  def footer()
    %(
      <div class="dim">
        Crystal #{Crystal::VERSION} <pre>#{Crystal::BUILD_COMMIT}</pre> running on <pre>#{System.hostname}</pre> for #{CrystalGauntlet.uptime_s}
      </div>
    )
  end

  macro auth()
    if session = CrystalGauntlet.sessions.get(context)
      logged_in = true
      account_id = session.account_id
      user_id = session.user_id
      username = session.username
    else
      logged_in = false
      account_id = nil
      user_id = nil
      username = nil
    end

    if !logged_in
      context.response.headers.add("Location", "/login?#{URI::Params.encode({"redir" => context.request.path})}")
      context.response.status = HTTP::Status::SEE_OTHER
      return
    end
  end


  DIFFICULTIES = StaticArray[
    "auto",
    "easy",
    "normal",
    "hard",
    "harder",
    "insane",
    "demon"
  ]

  DEMON_DIFFICULTIES = StaticArray[
    "easy",
    "medium",
    "hard",
    "insane",
    "extreme"
  ]

  def get_difficulty_icon(difficulty : LevelDifficulty?, featured : Bool = false, epic : Bool = false, demon_difficulty : DemonDifficulty? = DemonDifficulty::Hard)
    "/assets/difficulties/#{DIFFICULTIES[difficulty.try &.to_i || -1]? || "na"}#{difficulty.try &.demon? ? "-#{DEMON_DIFFICULTIES[demon_difficulty.try &.to_i || -1]? || "hard"}" : ""}#{(featured && !epic) ? "-featured" : ""}#{epic ? "-epic" : ""}.png"
  end
end

module CrystalGauntlet
  record UserSession, username : String, account_id : Int32, user_id : Int32

  # todo: replace memory storage with sqlite maybe? has to be hand-written but oh well
  @@session_storage = HTTPSession::Storage::Memory(UserSession).new
  @@sessions : HTTPSession::Manager(UserSession) = HTTPSession::Manager.new(@@session_storage, HTTP::Cookie.new("surveillance_device", "", secure: false, http_only: true, max_age: 365.days))

  spawn do
    session_storage.run_gc_loop
  end

  def self.session_storage
    @@session_storage
  end
  def self.sessions
    @@sessions
  end
end
