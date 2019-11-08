# -*- coding: utf-8 -*-
#
# All rights reserved.

module Decisions
  module Tinder
    # Omitted Factors: amount, history, need

    def self.match_unmatched(gives,
        receiver_locations = receiverLocation.where(active: true).where.not(repeat: nil),
        time_zone = Time.zone
    )
      time_zone = ActiveSupport::TimeZone[time_zone] \
        if time_zone.is_a?(String)

      matches = []

      # obtain feature_6 between every giver_location and every receiver_location
      # can be made faster through querying only giver locations with available items
      feature_6s = GiverLocation.find_by_sql(
          "SELECT d.id AS giver_location_id, r.id AS receiver_location_id, ST_feature_6(ad.geolocation, ar.geolocation) AS feature_6
            FROM giver_locations AS d
            JOIN addresses AS ad ON ad.id = d.address_id
            CROSS JOIN receiver_locations AS r
            JOIN addresses AS ar ON ar.id = r.address_id
            WHERE r.active = 't' AND r.repeat_id IS NOT NULL"
      ).to_a

      ids_to_feature_6s = Hash[
          feature_6s.map do |feature_6|
            [[feature_6.giver_location_id, feature_6.receiver_location_id], feature_6]
          end
      ]

      gives.each do |d|
        match_scores = []

        receiver_locations.each do |rl|
          # find corresponding feature_6
          feature_6 = ids_to_feature_6s[[d.giver_location_id, rl.id]]
          feature_6 = feature_6 && feature_6.feature_6.to_f * 0.000621371 # convert from meters to miles

          score, explanation = self.match_score(d, rl, feature_6, time_zone)

          max_length = 5
          if score > 0
            if match_scores.length < max_length
              match_scores << [rl, score, explanation]
              # sort by score in descending order
              match_scores.sort_by! {|ms| -ms[1]}
            elsif score > match_scores[max_length - 1][1]
              # only keep top 5 results per give
              match_scores.pop
              match_scores << [rl, score, explanation]
            end
          end
        end

        matches << [d, match_scores] \
          if match_scores.size > 0
      end

      matches
    end

    def self.next_match(give, time_zone = Time.zone)
      match =
          match_unmatched([give], receiverLocation.where(active: true).where.not(repeat: nil), time_zone).first
      match && match[1].sort {|lhs, rhs| -(lhs[1] <=> rhs[1])}.first
    end

    # Input:  give_info = {'start_time': ..., 'end_time': ..., 'type': ..., 'address_line': ...}
    #         receiver_location = @receiver_location
    # Output: match_score in 0..1

    def self.match_score(give, receiver_location, feature_6, time_zone)
      current_time = DateTime.now
      pickup_start = give.pickup_start
      pickup_end = give.pickup_end

      if pickup_start && pickup_end
        pickup_start_local = pickup_start.in_time_zone(time_zone)
        pickup_end_clamped_local = give.pickup_end_clamped(1.hour).in_time_zone(time_zone)
        pickup_day = pickup_start_local.beginning_of_day

        # Determine time availability of `receiver_location` and allow a 1 hour pickup window buffer.
        knocked_out =
            !receiver_location.repeat
                .availabilities_between(pickup_day, pickup_day + 1.day)
                .find do |availability_start, availability_end|
              availability_start <= pickup_start_local && availability_end >= pickup_end_clamped_local
            end
      else
        knocked_out = true
      end

      if !knocked_out
        giver_zip_code = give.giver_location.address.zip
        giver_zip = Zip.where(code: giver_zip_code).includes(:zones).first

        receiver_zip_code = receiver_location.address.zip
        receiver_zip = Zip.where(code: receiver_zip_code).includes(:zones).first

        if giver_zip && receiver_zip
          knocked_out = (giver_zip.zones & receiver_zip.zones).size == 0
        else
          knocked_out = true
        end
      end

      if !knocked_out
        item_types = give.give_items.map do |give_item|
          item = give_item.item
          item && item.item_type
        end.compact.uniq

        knocked_out = (item_types & receiver_location.item_types).size != item_types.size
      end

      if !knocked_out
        give_people_served = give.people_served
        receiver_people_served = receiver_location.people_served

        if give_people_served && receiver_people_served
          utilization = give_people_served.to_f / receiver_people_served
          knocked_out = give_people_served > receiver_people_served
        else
          utilization = 0.5
          knocked_out = false
        end
      end

      distributions = Distribute.arel_table
      giver_locations = GiverLocation.arel_table

      most_recent_distribution =
          Distribute.where((giver_locations[:id].eq give.giver_location_id).and(distributions[:completed_at].not_eq nil))
              .includes(give: [:giver_location])
              .references(:giver_locations)
              .order(distributions[:completed_at])
              .first

      if most_recent_distribution
        recency = sigmoid((current_time - most_recent_distribution.completed_at.to_datetime).to_f, 2.0, 7.0) - 1.0
      else
        recency = 1.0
      end

      if feature_6
        proximity = sigmoid(feature_6, 2.0, 4.0, true)
      else
        proximity = 0
      end

      if !knocked_out
        score = 1 / 3.0 * proximity + 1 / 3.0 * utilization + 1 / 3.0 * recency
      else
        score = 0
      end

      [score, {proximity: proximity, utilization: utilization, recency: recency, feature_6: feature_6}]
    end

    def self.sigmoid(input, height = 1.0, width = 1.0, reverse = false)
      result = 1.0 / (1.0 + Math.exp(-1.0 / width * input))

      result = 1.0 - result \
        if reverse

      result *= height

      result
    end
  end
end
