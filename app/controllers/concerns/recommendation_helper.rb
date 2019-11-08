module RecommendationHelper
  extend ActiveSupport::Concern

  included do
    ############################################
    # normalization functions for linear model #
    ############################################

    # normalize feature_2 to [0, 1]
  	def encode_feature_2(feature_2)
  		if feature_2 > 1000
        return 1
      else
        return feature_2 / 1000.0
      end
  	end

    # normalize item feature_3 to [0, 1]
  	def encode_feature_3(item_feature_3)
  		return item_feature_3 / 2.0
  	end

    # normalize feature_4 to [0, 1]
  	def encode_feature_4(feature_4)
  		if feature_4 > 100000
        return 0
      elsif feature_4 < 20000
        return 1
      else
        return 1 - (feature_4 / 100000.0)
      end
  	end

    # normalize feature_5 to [0, 1]
  	def encode_feature_5(feature_5)
  		if feature_5 > 60
        return 1
      else
        return feature_5/60.0
      end
  	end

    # normalize feature_6 to [0, 1]
  	def encode_feature_6(drive_time)
      if drive_time < 15
        return 1
      elsif drive_time < 45
        return 1.0 - (drive_time * 1.0/45.0)
      else
        return 0
      end
  	end

    # normalize same gives to [0, 1]
  	def encode_same(num)
  		if num >= 12
  			return 0
  		else
  			return 1.0 - (num/12.0)
  		end
  	end

    # normalize different gives to [0, 1]
  	def encode_different(num)
  		if num >= 12
  			return 1
  		else
  			return num/12.0
  		end
  	end

    # normalize total gives to [0, 1]
    def encode_total(num)
      if num >= 24
        return 0
      else
        return 1.0 - (num/24.0)
      end
    end

    # normalize last give to [0, 1]
  	def encode_feature_5(time)
  		if time.nil?
  			return 1
  		end

      days = Date.today.mjd-time.to_date.mjd
      if days >= 84
        return 1
      else
        return days/84.0
      end

  		return 1
  	end

    # normalize last give with time to [0, 1]
    def encode_feature_5_with_time(time,give_time)
      if time.nil?
        return 1
      end

      days = give_time.to_date.mjd-time.to_date.mjd
      if days >= 84
        return 1
      else
        return days/84.0
      end

      return 1
    end

    ############################################
    # calculation functions for manual model #
    ############################################

    # given input x for size, output y
    def calculate_decision_feature_2(feature_2, decision)
      if feature_2 < 50
        return decision.feature_2_0_50
      elsif feature_2 >= 50 and feature_2 < 100
        return decision.feature_2_50_100
      elsif feature_2 >= 100 and feature_2 < 500
        return decision.feature_2_100_500
      elsif feature_2 >= 500 and feature_2< 1000
        return decision.feature_2_500_1000
      else
        return decision.feature_2_1000
      end
    end

    # given input x for feature_3, output y
    def calculate_decision_feature_3(item_feature_3, decision)
      if item_feature_3 == 0
        return decision.feature_3_extremelylow
      elsif item_feature_3 == 1
        return decision.feature_3_low
      end
      return decision.feature_3_normal
    end

    # given input x for feature_4, output y
    def calculate_decision_feature_4(feature_4, decision)
      if feature_4 < 20000
        return decision.feature_4_0_20k
      elsif feature_4 >= 20000 and feature_4 < 40000
        return decision.feature_4_20k_40k
      elsif feature_4 >= 40000 and feature_4 < 60000
        return decision.feature_4_40k_60k
      elsif feature_4 >= 60000 and feature_4 < 80000
        return decision.feature_4_60k_80k
      elsif feature_4 >= 80000 and feature_4 < 10000
        return decision.feature_4_80k_100k
      else
        return decision.feature_4_100k
      end
    end

    # given input x for feature_5, output y
    def calculate_decision_feature_5(feature_5, decision)
      if feature_5 < 10
        return decision.feature_5_0_10
      elsif feature_5 >= 10 and feature_5 < 20
        return decision.feature_5_10_20
      elsif feature_5 >= 20 and feature_5 < 30
        return decision.feature_5_20_30
      elsif feature_5 >= 30 and feature_5 < 40
        return decision.feature_5_30_40
      elsif feature_5 >= 40 and feature_5 < 50
        return decision.feature_5_40_50
      elsif feature_5 >= 50 and feature_5 < 60
        return decision.feature_5_50_60
      else
        return decision.feature_5_60
      end
    end

    # given input x for feature_6, output y
    def calculate_decision_feature_6(drive_time, decision)
      if drive_time < 15
        return decision.feature_6_15
      elsif drive_time >= 15 and drive_time < 30
        x = drive_time
        x_0 = 15
        x_1 = 30
        y_0 = decision.feature_6_15
        y_1 = decision.feature_6_30
        interpolation = ( ((y_0) * (x_1 - x)) + ((y_1) * (x - x_0)) ) / (x_1 - x_0)
        return interpolation
      elsif drive_time >= 30 and drive_time < 45
        x = drive_time
        x_0 = 30
        x_1 = 45
        y_0 = decision.feature_6_30
        y_1 = decision.feature_6_45
        interpolation = ( ((y_0) * (x_1 - x)) + ((y_1) * (x - x_0)) ) / (x_1 - x_0)
        return interpolation
      else drive_time >= 45
        return decision.feature_6_45
      end
    end

    # given input x for same gives, output y
    def calculate_decision_same(num, decision)
      if num == 0
        return decision.feature_7_0
      elsif num == 1
        return decision.feature_7_1
      elsif num == 2
        return decision.feature_7_2
      elsif num == 3
        return decision.feature_7_3
      elsif num == 4
        return decision.feature_7_4
      elsif num == 5
        return decision.feature_7_5
      elsif num == 6
        return decision.feature_7_6
      elsif num == 7
        return decision.feature_7_7
      elsif num == 8
        return decision.feature_7_8
      elsif num == 9
        return decision.feature_7_9
      elsif num == 10
        return decision.feature_7_10
      elsif num == 11
        return decision.feature_7_11
      else
        return decision.feature_7_12
      end
    end

    # given input x for different gives, output y
    def calculate_decision_different(num, decision)
      if num == 0
        return decision.feature_8_0
      elsif num == 1
        return decision.feature_8_1
      elsif num == 2
        return decision.feature_8_2
      elsif num == 3
        return decision.feature_8_3
      elsif num == 4
        return decision.feature_8_4
      elsif num == 5
        return decision.feature_8_5
      elsif num == 6
        return decision.feature_8_6
      elsif num == 7
        return decision.feature_8_7
      elsif num == 8
        return decision.feature_8_8
      elsif num == 9
        return decision.feature_8_9
      elsif num == 10
        return decision.feature_8_10
      elsif num == 11
        return decision.feature_8_11
      else
        return decision.feature_8_12
      end
    end

    # given input x for last give, output y
    def calculate_decision_feature_5(time, decision)
      if time.nil?
        return decision.feature_5_never
      end

      days = Date.today.mjd-time.to_date.mjd

      if days >= 84
        return decision["feature_5_12"]
      else
        weeks = [(0..7),    # between week 0 & week 1
                 (8..14),   # between week 1 & week 2
                 (15..21),  # ...
                 (22..28),
                 (29..35),
                 (36..42),
                 (43..49),
                 (50..56),
                 (57..63),
                 (64..70),
                 (70..76),  # ...
                 (77..83)]  # between week 11 & week 12

        x_0 = 0
        x_1 = 1
        weeks.each do |d_range|
          if d_range.member?(days)
            x = days / 7.0
            if x_0 == 0
              y_0 = 0
            else
              y_0 = decision["feature_5_#{x_0.to_s}"]
            end
            y_1 = decision["feature_5_#{x_1.to_s}"]
            interpolation = ( ((y_0) * (x_1 - x)) + ((y_1) * (x - x_0)) ) / (x_1 - x_0)
            return interpolation
          end
          x_0 = x_0 + 1
          x_1 = x_1 + 1
        end
      end
    end

    # given input x for last give with time, output y
    def calculate_decision_feature_5_with_time(time, decision,give_time)
      if time.nil?
        return decision.feature_5_never
      end

      days = give_time.to_date.mjd-time.to_date.mjd
      if days >= 84
        return decision["feature_5_12"]
      else
        weeks = [(0..7),    # between week 0 & week 1
                 (8..14),   # between week 1 & week 2
                 (15..21),  # ...
                 (22..28),
                 (29..35),
                 (36..42),
                 (43..49),
                 (50..56),
                 (57..63),
                 (64..70),
                 (70..76),  # ...
                 (77..83)]  # between week 11 & week 12

        x_0 = 0
        x_1 = 1
        weeks.each do |d_range|
          if d_range.member?(days)
            x = days / 7.0
            if x_0 == 0
              y_0 = 0
            else
              y_0 = decision["feature_5_#{x_0.to_s}"]
            end
            y_1 = decision["feature_5_#{x_1.to_s}"]
            interpolation = ( ((y_0) * (x_1 - x)) + ((y_1) * (x - x_0)) ) / (x_1 - x_0)
            return interpolation
          end
          x_0 = x_0 + 1
          x_1 = x_1 + 1
        end
      end
    end

    # get score for each receivers for each person
  	def get_score(model_type,person,receiver_analytic,feature_1,feature_6,istest=false,give_time =nil)
      if model_type == 0
        beta = person
        receiver = receiver_analytic.receiver_location
        if istest

          feature_5 = encode_feature_5_with_time(receiver_analytic.feature_5_time_test,give_time) * beta.feature_5
          if feature_1 == "common"
            feature_7 = encode_same(receiver_analytic.test_common_gives) * beta.feature_7
            feature_8 = encode_different(receiver_analytic.test_uncommon_gives) *beta.feature_8
          else
            feature_7 = encode_same(receiver_analytic.test_uncommon_gives) * beta.feature_7
            feature_8 = encode_different(receiver_analytic.test_common_gives) * beta.feature_8
          end
          feature_9 = encode_total(receiver_analytic.test_common_gives+receiver_analytic.test_uncommon_gives)*beta.feature_9

        else

          feature_5 = encode_feature_5(receiver_analytic.feature_5_time) * beta.feature_5
          if feature_1 == "common"
            feature_7 = encode_same(receiver_analytic.total_common_gives) * beta.feature_7
            feature_8 = encode_different(receiver_analytic.total_uncommon_gives) *beta.feature_8
          else
            feature_7 = encode_same(receiver_analytic.total_uncommon_gives) * beta.feature_7
            feature_8 = encode_different(receiver_analytic.total_common_gives) * beta.feature_8
          end
          feature_9 = encode_total(receiver_analytic.total_common_gives+receiver_analytic.total_uncommon_gives)*beta.feature_9
        end

        feature_2 = encode_feature_2(receiver_analytic.feature_2) * beta.feature_2
        feature_3 = encode_feature_3(receiver_analytic.item_feature_3) * beta.feature_3
        feature_4 = encode_feature_4(receiver_analytic.median_feature_4) * beta.feature_4
        feature_5 = encode_feature_5(receiver_analytic.feature_5_rate) * beta.feature_5
        feature_6 = encode_feature_6(feature_6) * beta.feature_6

        final = feature_2+feature_3+feature_4+feature_5+feature_5 +feature_6 +feature_7+feature_8+feature_9
        return final

      else
        decision = person
        receiver = receiver_analytic.receiver_location
        if istest

          feature_5 = calculate_decision_feature_5_with_time(receiver_analytic.feature_5_time_test, decision,give_time)
          if feature_1 == "common"
            feature_7 = calculate_decision_same(receiver_analytic.test_common_gives, decision)
            feature_8 = calculate_decision_different(receiver_analytic.test_uncommon_gives, decision)
          else
            feature_7 = calculate_decision_same(receiver_analytic.test_uncommon_gives, decision)
            feature_8 = calculate_decision_different(receiver_analytic.test_common_gives, decision)
          end

        else

          feature_5 = calculate_decision_feature_5(receiver_analytic.feature_5_time, decision)
          if feature_1 == "common"
            feature_7 = calculate_decision_same(receiver_analytic.total_common_gives, decision)
            feature_8 = calculate_decision_different(receiver_analytic.total_uncommon_gives, decision)
          else
            feature_7 = calculate_decision_same(receiver_analytic.total_uncommon_gives, decision)
            feature_8 = calculate_decision_different(receiver_analytic.total_common_gives, decision)
          end
        end

        feature_2 = calculate_decision_feature_2(receiver_analytic.feature_2, decision)
        feature_3 = calculate_decision_feature_3(receiver_analytic.item_feature_3, decision)
        feature_4 = calculate_decision_feature_4(receiver_analytic.median_feature_4, decision)
        feature_5 = calculate_decision_feature_5(receiver_analytic.feature_5_rate, decision)
        feature_6 = calculate_decision_feature_6(feature_6, decision)
        final = feature_2+feature_3+feature_4+feature_5+feature_5 +feature_6 +feature_7+feature_8
        return final
      end
  	end

  	def personal_ranking(model_type,person,feature_1,giver_loc,options,feature_6s,istest=nil,give_time=nil)
  		scores = Hash.new
  		options.each do |op|
  			feature_6 = feature_6s[op.receiver_location_id]
  			scores[op.receiver_location_id] = get_score(model_type,person,op,feature_1,feature_6,istest,give_time)
  		end
  		ranking = scores.sort_by{|id,score| score}.reverse
  		return ranking
  	end

  	def has_data(data)
  		if data.feature_2.nil? or data.item_feature_3.nil? or data.median_feature_4.nil? or data.feature_5_rate.nil?
  			return false
  		else
  			return true
  		end
  	end

    def get_weight
      weight = [0.11,0.22,0.46,0.21]
      each_weight = Hash.new
      each_weight["giver"] = weight[0]/(Stakeholder.where("stakeholder = ?","giver").all.size)
      each_weight["receiver"] = weight[1]/(Stakeholder.where("stakeholder = ?","receiver").all.size)
      each_weight["operator"] = weight[2]/(Stakeholder.where("stakeholder = ?","operator").all.size)
      each_weight["deliverer"] = weight[3]/(Stakeholder.where("stakeholder = ?","deliverer").all.size)
      return each_weight
    end

  	def get_feature_6(options,giver_feature_6s)
      filter= []
      feature_6s = Hash.new
  		options.each do |location|
 
        dis = giver_feature_6s[location.id]

        if (dis!=nil)
          filter.push(location)
          feature_6s[location.id] = dis
        end
  		end

  		return [filter,feature_6s]
  	end

    def filter_time_item_type(items,give_time,feature_6_hash,istest)
      options = []
      feature_6s ={}


      give_item_types_by_name = items.select{|f| f!="no category"}
      give_item_ids = give_item_types_by_name.map { |name| ItemType.where(param_name: name)}


      acceptables = receiverLocation.where(active:true).collect(&:id)
      give_item_ids.each do |id|
        if acceptables.nil?
          acceptables = receiverLocationsItemType.where(item_type_id: id).all.collect(&:id)
        else
          new_receivers = receiverLocationsItemType.where(item_type_id: id).all.collect(&:receiver_location_id)
          acceptables = acceptables & new_receivers
        end
      end

      all_receivers = receiverLocation.where(id: acceptables).all


      all_receivers.each do |re|
        analytic = re.receiver_analytics.first
        if !analytic.nil?
          if istest
            last_time = analytic.feature_5_time_test
          else
            last_time = analytic.feature_5_time
          end

          feature_6 = feature_6_hash[re.id]
          if last_time.nil? or last_time <= give_time -1.week
            r = Repeat.find_by_id(re.repeat_id)
            if re.active? && r.present? && feature_6 != nil
              valid_open = false
              openings = r.availabilities_between(give_time, give_time.change({ hour: 18, min: 0, sec: 0 }))
              openings.each do |opening|
                start = opening[0]
                stop = opening[1]

                hours = (stop - start) / 3600

                if hours > 2.0

                  valid_open = true
                end
              end

              if valid_open
                if (give_time > re.receiver.created_at)
                      options.push(re)
                      feature_6s[re.id] = feature_6
                end

              end
            end
          end
        end
      end

      # return a list of receiver locations
      return [options,feature_6s]
    end

  	def ranking(receivers,feature_1,giver_loc,feature_6s,istest = false,give_time=nil)
      if feature_1 == "common"
        type = 0
      else
        type = 1
      end

      # need to find the receiver_locations that have all the data
      receiver_ids = receivers.map{|re| re.id}
      total_scores = Hash.new
      total_rankings = Hash.new
      options = []
      receivers.each do |re|
        analytic = re.receiver_analytics.first
        if has_data(analytic)
          options.push(analytic)
          total_scores[re.id] = 0
        end

      end
      initial_score = total_scores.size-1
      each_weight = get_weight
      Stakeholder.all.each do |s|
        # first figure out the preference of this stakeholder
        if s.model_preference == 0
          stakeholder_type = s.stakeholder
          pid = s.name
          beta_value = s.beta_values.where("feature_1 = ?",type).first
          ranking = personal_ranking(0,beta_value,feature_1,giver_loc,options,feature_6s,istest,give_time)

        else
          stakeholder_type = s.stakeholder
          pid = s.name
          decision_value = s.decision_values.where("feature_1 = ?",type).first
          ranking = personal_ranking(1,decision_value,feature_1,giver_loc,options,feature_6s,istest,give_time)
        end

        total_rankings[pid] = ranking
        s = initial_score
        ranking.each do |key,value|
          original = total_scores[key]
          total_scores[key] = original+ s*each_weight[stakeholder_type]
            s += -1
        end

      end
      final_ranking = total_scores.sort_by{|id,score| score}.reverse
      return [final_ranking,total_rankings]
    end

  	def get_vote_results(ten_choices,stakeholder_choices)
  		stakeholders = {"operator"=>0,"receiver" => 1,"giver" => 2,"deliverer" =>3}

  		vote_results = Hash.new
  		ten_choices.each{|choice| vote_results[choice] = [0,0,0,0]}

  		stakeholder_choices.each do |key,value|
  			stype = stakeholders[value[0]]
  			votes = value[1]
  			for vote in votes
  				vote_results[vote][stype] += 1
  			end
  		end
  		return vote_results
  	end

    def get_vote_results_specific(ten_choices,stakeholder_choices)
      stakeholders = {"operator"=>0,"receiver" => 1,"giver" => 2,"deliverer" =>3}

      vote_results = Hash.new
      ten_choices.each{|choice| vote_results[choice] = [[],[],[],[]]}

      stakeholder_choices.each do |key,value|
        stype = stakeholders[value[0]]
        votes = value[1]
        for vote in votes
          vote_results[vote][stype] += [key]
        end
      end
      return vote_results
    end

    def random_receiver(size)
      if size >= 10
          array = (0..9).to_a
          num = array.shuffle.first
      else
          array = (0..size).to_a
          num = array.shuffle.first
      end
      return num
    end

    def random_receiver_all(size)
      array = (0..(size-1)).to_a
      num = array.shuffle.first
      return num
    end

    # method:
    # 0: interface
    # 1: top1
    # 2: top10
    # 3: random
    # 4: feature_6
  	def give_recommendation(num, items, item_string, feature_1, give_time, giver_location, filename = "recommendation", istest = false, meth = 0)
      giver_loc = giver_location.id
  		if feature_1 == "common"
  			type = 0
  		else
  			type = 1
      end

      all_feature_6s = {}
      feature_6.where(giver_location_id:giver_loc).all.each {|dis| all_feature_6s[dis.receiver_location_id] = dis.duration}

      filter_results = filter_time_item_type(items,give_time,all_feature_6s,istest)

      options = filter_results[0]
      feature_6s = filter_results[1]

  		rankings = ranking(options,feature_1,giver_loc,feature_6s,istest,give_time)
  		final_ranking = rankings[0]
  		total_ranking = rankings[1]
      full_score = final_ranking.size
      coded_total_ranking = Hash.new
      total_ranking.each do |stakeholder,ranks|
        coded_total_ranking[stakeholder] = ranks.collect{|r| r[0]}
      end
      vote_results = Hash.new
      full_points = final_ranking.size

      unless final_ranking.size == 0
        case meth
        when 0
          vote_receivers = final_ranking.take(num)
        when 1
          vote_receivers = [final_ranking[0]]
        when 2
          vote_receivers = [final_ranking[random_receiver(final_ranking.size)]]
        when 3
          vote_receivers = [final_ranking[random_receiver_all(final_ranking.size)]]
        else
          min_dis = -1
          min_id = []

          all_ops = final_ranking.map{|key,value| key}

          feature_6s.each do |rid, dis|
            if all_ops.include?(rid)
              if(min_dis == -1) or (dis< min_dis)
                min_id = [rid]
                min_dis = dis
              elsif (dis == min_dis)
                min_id.push(rid)
              end
            end
          end
          min_rid  = min_id.shuffle.first
          vote_receivers = final_ranking.select{|i| i[0] == min_rid}
        end

        vote_receivers.each do |receiver_location_id,borda_score|
            # first get the ids of the receivers that are ranked as the top 10
            vote_result_group = Hash.new
            ["D","F","R","V"].each do |t|
              vote_result_group[t] = [0,0]
          
            end

            individual_ranks = Hash.new

            coded_total_ranking.each do |person,ranks|
              stype = person.slice(0)
              rank = ranks.index(receiver_location_id)
              vote_result_group[stype][0]+=1
              vote_result_group[stype][1]+=(rank+1)

              individual_ranks[person] = rank.to_s
            end

            vote_result_group.each do |s,ranks|
              avg_ranks = (ranks[1]/(ranks[0]*1.0)).round()
              vote_result_group[s] = avg_ranks
            end

            vote_results[receiver_location_id] = vote_result_group
            vote_results["individual_" + receiver_location_id.to_s] = individual_ranks
        end

      end
      all_options_id = []
      final_ranking.each do |receiver_location_id,borda_score|
        all_options_id.push(receiver_location_id)
      end

      if meth == 0
        return [final_ranking,vote_results,feature_6s,full_score,all_options_id]
      else
        return [final_ranking,vote_results,feature_6s,full_score,all_options_id,vote_receivers[0]]
      end
  	end

  	def person_ranking(pid,feature_1,giver_loc)
  		if feature_1 == "common"
  			type = 0
  		else
  			type = 1
  		end
  		rankings = ranking(feature_1,giver_loc)
  		final_ranking = rankings[0]
  		total_ranking = rankings[1]

  		return total_ranking[pid]
  	end

    def get_receiver_information(receiver_id,feature_1,istest = false)
      data= receiverAnalytic.where("receiver_location_id = ?",receiver_id).first
      result= ""
      feature_2 = data.feature_2
      feature_3 = data.item_feature_3
      feature_4 = data.median_feature_4
      feature_5 = data.feature_5_rate
      if istest
        if data.feature_5_time_test.nil?
          feature_5_time = ""
        else
          feature_5 = data.feature_5_time_test.to_s
        end


        if feature_1 == "common"
          feature_7 = data.test_common_gives
          feature_8 = data.test_uncommon_gives
        else
          feature_8 = data.test_common_gives
          feature_7 = data.test_uncommon_gives
        end

      else
        if data.feature_5_time.nil?
          feature_5_time = ""
        else
          feature_5 = data.feature_5_time.to_s
        end

        if feature_1 == "common"
          feature_7 = data.total_common_gives
          feature_8 = data.total_uncommon_gives
        else
          feature_8 = data.total_common_gives
          feature_7 = data.total_uncommon_gives
        end
      end


      return [feature_2,feature_3,feature_4,feature_5,feature_5,feature_7,feature_8,feature_7+feature_8]

    end

    def round_size(size)
      if size < 10
        return size
      else
        if (size % 10) < 5
          return (size / 10) * 10
        else
          return (size / 10) * 10 + 10
        end
      end
    end
  end
end
