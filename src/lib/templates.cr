module CrystalGauntlet::Templates
  extend self

  macro dir_header()
    path_split = context.request.path.split('/')
    "<div class='dir-header'>" + path_split.map_with_index { |v, i| "<a href='/#{path_split[1..i].join('/')}'>#{i == 0 ? "crystal-gauntlet" : v}</a>"}.join(" / ") + "</div>"
  end

  def footer()
    %(
      <div class="dim">
        Crystal #{Crystal::VERSION} <pre>#{Crystal::BUILD_COMMIT}</pre> running on <pre>#{System.hostname}</pre> for #{CrystalGauntlet.uptime_s}
      </div>
    )
  end
end
