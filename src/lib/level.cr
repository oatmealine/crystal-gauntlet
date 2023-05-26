require "compress/zlib"

include Compress

# module for general level decoding, parsing and encoding
module CrystalGauntlet::Level
  extend self

  class ObjectData
    getter raw : Hash(String, String)

    def initialize(raw : Hash(String, String))
      @raw = raw
    end

    # nabbed from https://gd-docs.xyze.dev/#/resources/client/level-components/level-object

    # the ID of the object
    def id
      @raw["1"].to_i
    end
    # the X position of the object
    def x
      @raw["2"].to_f
    end
    # the Y position of the object
    def y
      @raw["3"].to_f
    end

    # strings
    private macro prop_s(key, name)
      def {{name.id}}
        @raw[{{key}}]?
      end
    end
    # integers
    private macro prop_i(key, name)
      def {{name.id}}
        @raw[{{key}}]?.try &.to_i?
      end
    end
    # floats
    private macro prop_f(key, name)
      def {{name.id}}
        @raw[{{key}}]?.try &.to_f?
      end
    end
    # booleans
    private macro prop_b(key, name)
      def {{name.id}}
        @raw[{{key}}]? == "1"
      end
    end

    # whether the object is horizontally flipped
    prop_b "4", :xflip
    # whether the object is vertically flipped
    prop_b "5", :yflip
    # the rotation of the objects in degrees, CW is positive, top is 0
    prop_f "6", :rotation
    # the Red component of the color in a trigger
    prop_i "7", :r
    # the Green component of the color in a trigger
    prop_i "8", :g
    # the Blue component of the color in a trigger
    prop_i "9", :b
    # the duration of an effect in a trigger
    prop_f "10", :duration
    # the Touch Triggered property of a trigger
    prop_b "11", :touch_triggered
    # the ID of a Secret Coin
    prop_i "12", :secret_coin_id
    # the checked property of some special objects (gamemode, speed, dual portals, etc.)
    prop_b "13", :checked
    # the Tint Ground property of the BG Color trigger
    prop_b "14", :tint_ground
    # the Player Color 1 property of any Color trigger
    prop_b "15", :player_color_1
    # the Player Color 2 property of any Color trigger
    prop_b "16", :player_color_2
    # the Blending property of any Color trigger
    prop_b "17", :blending
    # the legacy Color Channel ID property used in 1.9 levels. If set to a valid value, both the Main and Secondary Color Channel ID properties will be ignored.
    prop_i "19", :legacy_color_id
    # the Editor Layer 1 property of the object
    prop_i "20", :editor_layer
    # the Main Color Channel ID property of the object
    prop_i "21", :color_id
    # the Secondary Color Channel ID property of the object
    prop_i "22", :secondary_color_id
    # the Target Color ID property in an interactive object
    prop_i "23", :target_color_id
    # the Z Layer of the object
    prop_i "24", :z_layer
    # the Z Order of the object
    prop_i "25", :z_order
    # the Offset X property of the Move trigger
    prop_i "28", :move_x
    # the Offset Y property of the Move trigger
    prop_i "29", :move_y
    # the Easing type of the effect of a trigger
    prop_i "30", :easing
    # the text of the text object in base64
    prop_s "31", :text
    # the scaling of the object
    prop_f "32", :scale
    # a group ID given to the object
    prop_i "33", :single_group_id
    # the Group Parent property of the object
    prop_b "34", :group_parent
    # the opacity value of a trigger
    prop_f "35", :opacity
    # whether the HSV mode is enabled for the Main Color of the object
    prop_b "41", :color_has_hsv
    # whether the HSV mode is enabled for the Secondary Color of the object
    prop_b "42", :secondary_color_has_hsv
    # the HSV adjustment values of the Main Color of the object
    prop_s "43", :hsv_adjust
    # the HSV adjustment values of the Secondary Color of the object
    prop_s "44", :secondary_hsv_adjust
    # the Fade In property of the Pulse trigger
    prop_f "45", :pulse_fade_in
    # the Hold property of the Pulse trigger
    prop_f "46", :pulse_fade_hold
    # the Fade Out property of the Pulse trigger
    prop_f "47", :pulse_fade_out
    # the Pulse Mode property of the Pulse trigger
    prop_i "48", :pulse_mode
    # the HSV adjustment values of the Copied Color property of a trigger
    prop_s "49", :copied_hsv_adjust
    # the Copied Color Channel ID in a trigger
    prop_i "50", :copied_color_id
    # the Target Group ID in a trigger
    prop_i "51", :target_group_id
    # the Target Type property of the Pulse trigger
    prop_i "52", :pulse_target_type
    # the Y offset of the yellow from the blue teleportation portal
    prop_f "54", :teleport_portal_offset
    # The Smooth Ease property within Teleport Portals
    prop_b "55", :teleport_portal_ease
    # the Activate Group property of the trigger
    prop_b "56", :activate_group
    # the group IDs of the object
    prop_s "57", :group_ids
    # the Lock To Player X property of the Move trigger
    prop_b "58", :lock_to_player_x
    # the Lock To Player Y property of the Move trigger
    prop_b "59", :lock_to_player_y
    # the Copy Opacity property of a trigger
    prop_b "60", :copy_opacity
    # the Editor Layer 2 of an object
    prop_i "61", :editor_layer_2
    #	the Spawn Triggered property of a trigger
    prop_b "62", :spawn_triggered
    # the Spawn Delay property of the Spawn trigger
    prop_f "63", :spawn_delay
    # the Don't Fade property of the object
    prop_b "64", :dont_fade
    # the Main Only property of the Pulse trigger
    prop_b "65", :pulse_main_only
    # the Detail Only property of the Pulse trigger
    prop_b "66", :pulse_main_only
    # the Don't Enter property of the object
    prop_b "67", :dont_enter
    # the Degrees property of the Rotate trigger
    prop_i "68", :rotate_degrees
    # the Times 360 property of the Rotate trigger
    prop_i "69", :rotate_times_360
    # the Lock Object Rotation property of the Rotate trigger
    prop_b "70", :rotate_lock_object_rotation
    # the Secondary (Follow, Target Pos, Center) Group ID property of some triggers
    prop_i "71", :secondary_target_group_id
    # the X Mod property of the Follow trigger
    prop_f "72", :follow_x_mod
    # the Y Mod property of the Follow trigger
    prop_f "73", :follow_y_mod
    # the Strength property of the Shake trigger
    prop_f "75", :shake_strength
    # the Animation ID property of the Animate trigger
    prop_i "76", :animation_id
    # the Count property of the Pickup trigger or the Pickup Item
    prop_i "77", :pickup_count
    # the Subtract Count property of the Pickup trigger or the Pickup Item
    prop_b "78", :pickup_subtract_count
    # the Pickup Mode property of the Pickup Item
    prop_i "79", :pickup_mode
    # the Item/Block ID property of an object
    prop_i "80", :item_id
    # the Hold Mode property of the Touch trigger
    prop_b "81", :touch_hold_mode
    # the Toggle Mode property of the Touch trigger
    prop_i "82", :touchtoggle_mode
    # the Interval property of the Shake trigger
    prop_f "84", :shake_interval
    # the Easing Rate property of a trigger
    prop_f "85", :easing_rate
    # the Exclusive property of a Pulse trigger
    prop_b "86", :pulse_exclusive
    # the Multi-Trigger property of a trigger
    prop_b "87", :multi_trigger
    # the Comparison property of the Instant Count trigger
    prop_i "88", :instant_count_comparasion
    # the Dual Mode property of the Touch trigger
    prop_b "89", :touch_dual_mode
    # the Speed property of the Follow Player Y trigger
    prop_f "90", :follow_player_y_speed
    # the Follow Delay property of the Follow Player Y trigger
    prop_f "91", :follow_player_y_delay
    # the Y Offset property of the Follow Player Y trigger
    prop_f "92", :follow_player_y_y_offset
    # the Trigger On Exit property of the Collision trigger
    prop_b "93", :collision_trigger_on_exit
    # the Dynamic Block property of the Collision block
    prop_b "94", :collision_dynamic_block
    # the Block B ID property of the Collision trigger
    prop_i "95", :collision_block_b_id
    # the Disable Glow property of the object
    prop_b "96", :disable_glow
    # the Custom Rotation Speed property of the rotating object in degrees per second
    prop_f "97", :custom_rotation_speed
    # the Disable Rotation property of the rotating object
    prop_b "98", :disable_rotation
    # the Multi Activate property of Orbs
    prop_b "99", :orb_multi_activate
    # the Enable Use Target property of the Move trigger
    prop_b "100", :move_use_target
    # the Target Pos Coordinates property of the Move trigger
    prop_s "101", :move_target_pos
    # the Editor Disable property of the Spawn trigger
    prop_b "102", :spawn_editor_disable
    # the High Detail property of the object
    prop_b "103", :high_detail
    # The Multi Activate Property of Triggers
    prop_b "104", :trigger_multi_activate
    # the Max Speed property of the Follow Player Y trigger
    prop_f "105", :follow_player_y_max_speed
    # the Randomize Start property of the animated object
    prop_b "106", :animation_randomize_start
    # the Animation Speed property of the animated object
    prop_b "107", :animation_speed
    # the Linked Group ID property of the object
    prop_i "108", :linked_group_id
  end

  # security.webm
  TEST_STRING = "H4sIAAAAAAAAC61Xy5HYIAxtyLuDJCTB5JQatgAKSAspPvxssC1lc8jBZngPhNAP-PVF6YASpWBhKlQkFoCCzAVwNNSbWD6gSIEQQtECBbj9UgklFfgNtcX6Uf2-mQ7udAhYxuhvRGRTRBszJvyTkLrfYusyBAE2Qe3_jSD-X4LEEXT8-gl0hNbwaGQ08ah_OaB1dECzSa35otx72P9DQid-xv4fbJ3dGzjCDzhAYzzwoHDQAbyA3IDYgdoD4qtL1HiQhmj91dU-ucIHNDbCTmIl8MB46JjZydxICHOq9rldlUAXLXlMCBVB7BMApjLViLtumDpdl8QmI8SuRlhMTEe1WRpLILbdxqnCpXGkKaQh0BCBU-xLzS7j4iuEXfM1oyr8IW3bH7TPPjcg-_Ktr6dFth0MkYNRWDuoqAZjfMPJwcWTPyXt8gdOb7zvWofzaNipxcnYdO5AMzoE2UyJHUm6mWpCp602u5xTL8NAyPaOANAj2COSQyB4RPQIfahJjkNqAHuE5ZJOGDvGsK_ysFnEhzLRs0D0LMCWBYa_gZGW-JGg3LefX8EEHF_ELAdh1IOKpFE88i2FZx-2RUScRYQ8IryIUT9A-WGiCWzLaXKkKjpEAo94W2ESL7uR9IIXljFmCRxbOdXN-a5_zSHbkxgc32MwfI8hbNQ9rBCcrEBwsgLBqmK9fIeH-uhkBaKTFYhGVkTdhMsqzw0lz0DkGYic5MDoGSJahuj-w1gLZ6Uwr_MUuSuKtUbK8ZEvTQc8CypRn86yYRuQ-R7cfbA88v8EZAHpyr4ecKh6P0D3PvZz8xlwacvXljwXpNeQjGPI00yZHTy98Sl6iFKTYp9Kb6rfbMBUgEJ0cH3jYWPydSNYi89FLL3mOjaltsoQbNX2a1jvizMue7adok1thnSbEp_K9h7QjgdCOx4I3_EgEpakRNtVM2wKoBstcy2bcqKFnGghJ1rIiJa5BPkxQX5MkBMTlLNTbirVyk3aLmtTVjTc1nE0ZI17sUGcwhxHRydYIzm4E7TRD9roR2Y04nmtsmroFN9i3BBinTu3bd85yuMVgfrZSOFP5A2OaMJsj1Z7dLqPPtVh6wA7OefUI07G3teMty_YSVJ2i_acYvqI_QxlJw3nVgyN2XcjG2f4NCcH08oMpk-Y7NHRHi326DxggNjef_sDjsS5VJA4tysy34hL1NtV4hQs8QuW-AVLjKp0Uu9aNi0gYdgr3Qxwkoh_IelvM8V0gyTTDZIfidRAdWqWOjXLe3GT9-Qm883dCetJO02pfp1T_9xW_3DWd82eZlEwraV2SVO7pKld0tQuafosaUv5daVRzU8P1IOvEmm-2Wo0jNszmijRwHv9qGrsGBtY2rBxmibQ_TT9A3vViWgxFQAA"

  # todo: https://github.com/Cvolton/GMDprivateServer/blob/master/incl/levels/uploadGJLevel.php#L53
  DEFAULT_EXTRA_STRING = "29_29_29_40_29_29_29_29_29_29_29_29_29_29_29_29"

  # gddocs:
  # > A random gzip compressed string
  # i'm not sure it has any use; but setting it to an empty one .. works ?
  DEFAULT_LEVEL_INFO = ""

  # typically, you'd start right here
  def decode(level_data : String)
    io = IO::Memory.new(Base64.decode(level_data))
    parse(decompress(io))
  end
  def decompress(level_data : IO)
    Gzip::Reader.open(level_data, true) do |io|
      io.gets_to_end
    end
  end

  def array_to_hash(arr)
    key = nil
    hash = Hash(typeof(arr[0]), typeof(arr[1])).new
    arr.each() do |val|
      if key == nil
        key = val
      else
        hash[key.not_nil!] = val
        key = nil
      end
    end
    return hash
  end
  def parse(raw_level_data : String) : Array(Hash(String, String))
    objects = raw_level_data.chomp(";").split(";")
      .map { |v| array_to_hash(v.split(",")) }

    return objects
  end
  def to_objectdata(objects : Array(Hash(String, String))) : Array(ObjectData)
    return objects
      .select { |v| v.has_key?("1") }
      .map { |v| ObjectData.new(v) }
  end

  def gmd_parse(gmd_file : String)
    Level.array_to_hash(XML.parse(gmd_file).first_element_child.not_nil!.children.reject { |node| node.type == XML::Node::Type::TEXT_NODE }.map { |node| node.children.to_s})
  end

  # heavily references https://github.com/TeamHaxGD/GDDocs/blob/master/algorithms/level_length.c
  enum PortalSpeed
    # 0.5x
    Slow
    # 1x
    Normal
    # 2x
    Medium
    # 3x
    Fast
    # 4x
    VeryFast

    def portal_speed
      case self
      when .slow?
        251.16
      when .normal?
        311.58
      when .medium?
        387.42
      when .fast?
        478.0
      when .very_fast?
        576.0
      else
        0.0
      end
    end
  end

  def id_to_portal_speed(id : Int32)
    case id
    when 200
      PortalSpeed::Slow
    when 201
      PortalSpeed::Normal
    when 202
      PortalSpeed::Medium
    when 203
      PortalSpeed::Fast
    when 1334
      PortalSpeed::VeryFast
    end
  end

  def get_seconds_from_xpos(pos : Float64, start_speed : PortalSpeed, portals : Array(ObjectData))
    speed = 0.0
    last_obj_pos = 0.0
    last_segment = 0.0
    segments = 0.0

    speed = start_speed.portal_speed

    if portals.empty?
      return pos / speed
    end

    portals.each do |portal|
      s = portal.x - last_obj_pos

      if pos < s
        s /= speed
        last_segment = s
        segments += s

        speed = id_to_portal_speed(portal.id).not_nil!.portal_speed

        last_obj_pos = portal.x
      end
    end

    return ((pos - last_segment) / speed) + segments;
  end

  def measure_length(objects : Array(ObjectData), ka4 : Int32)
    start_speed = case ka4
      when 0
        PortalSpeed::Normal
      when 1
        PortalSpeed::Slow
      when 2
        PortalSpeed::Medium
      when 3
        PortalSpeed::Fast
      when 4
        PortalSpeed::VeryFast
      else
        PortalSpeed::Normal
      end

    max_x_pos = objects.reduce 0.0 { |a, b| Math.max(a, b.x) }

    portals = objects
      .select { |obj| id_to_portal_speed(obj.id) && obj.checked }
      .sort { |a, b| a.x <=> b.x }

    get_seconds_from_xpos(max_x_pos, start_speed, portals)
  end
end
