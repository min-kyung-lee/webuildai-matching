# -*- coding: utf-8 -*-
#
# All rights reserved.

require "decisions/tinder"

class GiveController < ApplicationController
  include Scalient::Pundit
  include RecommendationHelper
  include Decisions::Tinder

  UNCOMMON_ITEM = ["item1", "item2", "item3", "item4", "item5", "item6", "other"]

  before_action :authenticate_user!, except: [:intake, :intake_save]
  before_action :set_give, only: [:show, :edit, :update, :destroy,:get_recommendation]

  def index
    authorize Give

    give = Give.arel_table

    @gives = policy_scope(Give)
                     .includes(
                         giver_location: [:giver],
                         give_items: []
                     )
                     .all.order(gives[:created_at].desc)

    params[:page] ||= 1
    @gives = @gives.paginate(:page => params[:page], :per_page => 20)
  end

  def intake
    operational_name = params[:operational_name]
    @organization = Organization.where(operational_name: operational_name).first
    if !@organization
      render text: "An operational name must be provided"
      return
    end

    @give = Give.new
    @give.pickup_day = "today"
    @give.build_giver_location
    @give.giver_location.build_address
    @current_local_time = Time.now.in_time_zone(@organization.time_zone)
    hour = @current_local_time.hour
    hour += 1 if @current_local_time.min > 30  # if it is more than 30 mins past the hour, round up
    @give.pickup_end_time = hour + 2

    set_form_time_ranges

    render layout: "give_intake"
  end

  def intake_save
    operational_name = params[:operational_name]
    @meets_item_safety = params["meets_item_safety"]
    @organization = Organization.where(operational_name: operational_name).first
    if !@organization
      render text: "No organization found for operational name #{operational_name}"
      return
    end
    @current_local_time = Time.now.in_time_zone(@organization.time_zone)

    @give = Give.new(give_params)

    set_form_time_ranges

    captcha_response = params["g-recaptcha-response"]

    conn = Faraday.new(:url => "https://www.google.com")
    response = conn.post do |req|
      req.url "/recaptcha/api/siteverify"
      req.headers["Accept"] = "application/json"
      req.headers["Content-Type"] = "application/json"

      req.params["secret"] = "6Lc8MWoUAAAAAMgsw5Kbby7dpkwC1XI003GkZHg6"
      req.params["response"] = captcha_response
    end

    verified = JSON.parse(response.body)
    if !verified["success"]
      @give.errors.add(:base, "You must click the \"I'm not a robot\" checkbox")
    end

    @zips = @organization.zips
    if !@zips.include?(@give.giver_location.address.zip)
      @give.errors.add(:base, "Pickup zip must be one of #{@zips.join(", ")}")
    end

    pickup_day = @give.pickup_day
    pickup_start_time = @give.pickup_start_time
    pickup_end_time = @give.pickup_end_time

    if pickup_day == "today"
      start_time = @current_local_time
      end_time = @current_local_time.clone
    else
      start_time = @current_local_time + 1.day
      end_time = start_time.clone
    end

    start_time = start_time.change({ hour: pickup_start_time.to_i }) \
      if pickup_start_time != "now"

    end_time = end_time.change({ hour: pickup_end_time.to_i })

    @give.pickup_start = start_time
    @give.pickup_end = end_time

    @errors = []

    if @give.giver_name.blank?
      @errors << "giver name"
      @give.errors.add(:base, "Company name can't be blank")
    end

    if @give.giver_location.address.line1.blank?
      @errors << "pickup address"
      @give.errors.add(:base, "Pickup address can't be blank")
    end

    if @give.giver_location.address.city.blank?
      @errors << "pickup city"
      @give.errors.add(:base, "Pickup city can't be blank")
    end

    if @give.giver_location.address.state.blank?
      @errors << "pickup state"
      @give.errors.add(:base, "Pickup state can't be blank")
    end

    if @give.name.blank?
      @errors << "name"
      @give.errors.add(:base, "Your name can't be blank")
    end

    if @give.phone.blank?
      @errors << "phone"
      @give.errors.add(:base, "Your phone number can't be blank")
    else
      # create a throw-away contact phone so we can use its validation method
      cp = ContactPhone.new
      cp.number = @give.phone
      if !cp.valid?
        @errors << "phone"
        @give.errors.add(:base, "We require a valid phone number in case we need to contact you regarding your give")
      end
    end

    if @give.people_served.blank?
      @errors << "people_served"
      @give.errors.add(:base, "You must indicate how many people this can feed")
    end

    if @organization.require_item_safety && !@meets_item_safety
      @errors << "meets_item_safety"
      @give.errors.add(:base, "Gives must meet item safety standards")
    end

    if @give.email.blank?
      @give.errors.add(:base, "Your email can't be blank")
      @errors << "email"
    else
      ce = ContactEmail.new
      ce.email = @give.email.strip
      if !ce.valid?
        @give.errors.add(:base, "Your email must be valid")
        @errors << "email"
      end
    end

    any_item = false
    @organization.item_types.each do |f|
      if @give.send(f.param_name) == "1"
        any_item = true
        if @give.send("#{f.param_name}_description").blank?
          @give.errors.add(:base, "#{f.name.humanize} description can't be blank")
          @errors << f.param_name
        end

        if @give.send("#{f.param_name}_unit").blank?
          @give.errors.add(:base, "#{f.name.humanize} unit can't be blank")
          @errors << f.param_name
        end

        if @give.send("#{f.param_name}_quantity").blank? || @give.send("#{f.param_name}_quantity").to_i < 1
          @give.errors.add(:base, "#{f.name.humanize} quantity must be an integer (e.g. 1 or 5) and greater than zero")
          @errors << f.param_name
        end
      end
    end

    if !any_item
      @give.errors.add(:base, "You must select some item to donate")
      @errors << "people_served"
    end

    if @give.errors.any? || !@give.valid?
      render :intake, layout: "give_intake"
      return
    end

    ActiveRecord::Base.transaction do
      giver_name = @give.giver_name

      givers = Giver.arel_table
      organizations_givers = OrganizationsGiver.arel_table
      org_giver = OrganizationsGiver
                  .includes(giver: [])
                  .where(
                      (givers[:name].matches giver_name)
                          .and(organizations_givers[:organization_id].eq @organization.id)
                  )
                  .references(:givers).first
      giver = org_giver.giver if org_giver

      if !giver
        giver = Giver.new
        giver.name = giver_name
        giver.save!

        authorization = OrganizationsGiver.new
        authorization.assign_attributes(giver: giver, organization: @organization)
        authorization.save!
      else
        existing_giver_locations = giver.locations.select do |dl|
          dl.address.line1.downcase == @give.giver_location.address.line1.downcase
        end

        @give.giver_location = existing_giver_locations.first \
          if existing_giver_locations.any?
      end

      @give.giver_location.giver = giver
      @give.giver_location.name = @give.giver_location.address.line1

      @give.save!

      giver_locations = GiverLocation.arel_table
      contacts = Contact.arel_table

      dlc = GiverLocationContact
                .includes(:giver_location, :contact)
                .where(
                    (giver_locations[:id].eq @give.giver_location.id)
                        .and(contacts[:first_name].eq @give.name.split.first)
                        .and(contacts[:last_name].eq @give.name.split.second)
                )
                .references(:giver_locations, :contacts)
                .first

      if dlc
        phone = ContactPhone.where(contact: dlc.contact,
                                   number: PhonyRails.normalize_number(@give.phone.strip)).first_or_initialize
        phone.save! if phone.new_record? && phone.valid?

        email = ContactEmail.where(contact: dlc.contact,
                                   email: @give.email.strip).first_or_initialize
        email.save! if email.new_record? && email.valid?
      else
        contact = Contact.new
        contact.first_name = @give.name.split.first
        contact.last_name = @give.name.split.second
        contact.save!

        phone = ContactPhone.new
        phone.contact = contact
        phone.number = @give.phone
        phone.save! if phone.valid?

        email = ContactEmail.new
        email.contact = contact
        email.email = @give.email
        email.save! if email.valid?

        dlc = GiverLocationContact.new
        dlc.giver_location = @give.giver_location
        dlc.contact = contact
        dlc.save!
      end

      authorization = OrganizationsGive.new
      authorization.assign_attributes(give: @give, organization: @organization)
      authorization.save!

      if !@give.other_info.blank?
        # Attach note directly to the give instead of the give_location
        note = Note.where(owner: @give, text: @give.other_info).first_or_initialize
        if note.new_record?
          # NOTE: We will assume the note in give intake should be traiged
          # by an ops member and moved to special instructions if appropriate
          # note.show_in_app = true
          note.save!
        end
      end

      ItemType.all.each do |f|
        if @give.send(f.param_name) == "1"
          di = GiveItem.new
          di.give = @give
          di.description = @give.send("#{f.param_name}_description")
          item = Item.where(name: f.name).first
          di.item = item if item
          # di.unit = @give.send("#{f.param_name}_unit")
          di.give_item_unit_id = @give.send("#{f.param_name}_unit")
          di.quantity = @give.send("#{f.param_name}_quantity")

          # This is handled in GiveItem before_save now
          # fdiu = ItemTypesGiveItemUnit.where(item_type_id: f.id, give_item_unit_id: di.give_item_unit_id).first
          # if fdiu && di.quantity
          #   di.weight = (fdiu.pounds_per_unit * di.quantity).to_i
          # end

          di.estimated = true
          di.save!
        end
      end

      users_organizations = UsersOrganization.arel_table
      users = User.arel_table

      give_admin = User
                           .includes(:users_organizations)
                           .where(
                               (users_organizations[:organization_id].eq @organization.id)
                                   .and(users[:first_name].eq "Give")
                                   .and(users[:last_name].eq "Intake")
                           )
                           .references(:users_organizations)
                           .first

      distribution_ = Distribution.new
      distribution_.give = @give
      distribution_.pickup_start = @give.pickup_start
      distribution_.pickup_end = @give.pickup_end_clamped
      distribution_.published_at = DateTime.now.in_time_zone(@organization.time_zone) + 1.minute
      distribution_.giver_contact_name = @give.name
      distribution_.giver_contact_phone = @give.phone
      distribution_.admin = give_admin

      match = Decisions::Tinder.next_match(@give, @organization.time_zone)
      if match
        recip = match.first
        distribution_.receiver_location = recip
        if recip.contacts.any?
          first_contact = recip.contacts.first
          distribution_.receiver_contact_name = first_contact.full_name
          if first_contact.contact_phones.any?
            distribution_.receiver_contact_phone = first_contact.contact_phones.first.number.phony_formatted
          end
        end
        # match.third[:proximity]
        # match.third[:utilization]
        # match.third[:recency]
        # match.third[:feature_6]
      end

      distribution_.save!

      @give.give_items.each do |di|
        distribution_item = DistributionItem.new
        distribution_item.distribution = distribution_
        distribution_item.give_item = distribution
        distribution_item.quantity_estimated = distribution.quantity
        distribution_item.save!
      end

      distribution_.publish! if distribution_.receiver_location

      # Inform org's Give Intake user a new give has been submitted
      Mailer.give_intake_dispatcher_email(distribution_, @organization).deliver
    end

    render layout: "give_intake"
  end

  def edit
    authorize @give

    @giver_locations = GiverLocation.where(active: true)
  end

  def new
    @giver_locations = policy_scope(GiverLocation)
                           .eager_load(:giver)
                           .references(:givers)
                           .where(active: true)

    if refers_to_table_in_joins?(@giver_locations, "givers")
      @giver_locations = @giver_locations
                             .order("givers_giver_locations.name")
                             .group("givers_giver_locations.id")
    else
      @giver_locations = @giver_locations.order("givers.name")
    end

    @give = Give.new

    authorize @give
  end

  def show
    authorize @give
    @giver_location = @give.giver_location

    @distribution_ = Distribution.new
    set_giver_phones
    set_nonprofits(@give)
    set_available_items
  end

  def update
    authorize @give

    respond_to do |format|
      if @give.update(give_params)
        format.html {redirect_to give_path(@give)}
        format.json {render :show, status: :ok, location: @give}
      else
        format.html {render :edit}
        format.json {render json: @give.errors, status: :unprocessable_entity}
      end
    end
  end

  def destroy
    authorize @give

    if @give.distributions.any?
      notice = "Give could not be removed because it has distributions"
      redirect_to give_path(@give), alert: notice
    else
      @give.destroy
      notice = "Give has been removed"
      redirect_to gives_path, notice: notice
    end
  end

  def create
    @give = Give.new(give_params)

    authorize @give

    ActiveRecord::Base.transaction do
      @give.save!

      authorization = OrganizationsGive.new
      authorization.assign_attributes(give: @give, organization: current_user.default_organization)
      authorization.save!

      # Why yes, even authorizations need to be authorized.
      authorize authorization, :create_with_new_give?
    end

    respond_to do |format|
      if @give.save
        format.html {redirect_to give_path(@give)}
        format.json {render :show, status: :created, location: @give}
      else
        format.html {render :new}
        format.json {render json: @give.errors, status: :unprocessable_entity}
      end
    end
  end


  def get_recommendation
    @tooltip_hash = {"item" => "item feature_3", "feature_6" => "feature_6","feature_4" => "feature_4 level", "feature_5" => "feature_5 rate","size" => "organization size", "give" => "last give time"}

    type = "common"
    items = params[:item]
    units = params[:unit]

    #first determine the item types.
    UNCOMMON_ITEM.each do |item|
      if items.include?(item)
        type = "uncommon"
      end
    end

    item_string = ""
    (0...items.length).each do |i|
      item_string+=items[i]+units[i].to_s
    end

    #get recommendations
    result = give_recommendation(12,items,item_string,type,Time.now,@give.giver_location,"give"+@give.id.to_s+"time"+Time.now.strftime("%H%M%S"))

    final_ranking = result[0]
    if final_ranking.length!=0
      @has_results = true
      @vote_result,@feature_6s,@full_score,@all_options = result[1],result[2],result[3],result[4]
      @features = receiverAnalytic.get_feature_ranges(result[4])



      @giver_location = @give.giver_location
      @receiver_locations = final_ranking.take(12).map{|id,score| receiverLocation.find(id)}
      @scores = final_ranking.take(12).map{|id,score| score}

      #get all the values for the feature_6s
      @sorted_feature_6s =  @feature_6s.map{|id, feature_6| feature_6}.sort_by{|num| num}
      @feature_5_values = @features[0]
      @median_feature_4_values = @features[1]
      @feature_5_rate_values = @features[2]
      @item_feature_3_values = @features[3]
      @size_values = @features[4]

      #get information for the explanations
      #return [min,max]
      @feature_6_range = [@sorted_feature_6s.min,@sorted_feature_6s.max]
      @item_feature_3_range = [@item_feature_3_values.first,@item_feature_3_values.last]
      @feature_5_rate_range = [@feature_5_rate_values.last,@feature_5_rate_values.first]
      @median_feature_4_range = [@median_feature_4_values.first,@median_feature_4_values.last]
      @size_range = [@size_values.first,@size_values.last]
      @feature_5_range = [((@feature_5_values.last)/7.0).round,((@feature_5_values.first)/7.0).round]


      @receiver_details = @receiver_locations.map { |r| {
        "id" => r.id,
        "rname" => r.receiver.name,
        "lname" => r.name,
        "lat" => r.address.latitude,
        "lng" => r.address.longitude,
        "rank" => @receiver_locations.index(r)+1,
      }}


      #default the first option.

      @receiver_location= @receiver_locations[0]
      @receiver = @receiver_location.receiver
      @receiver_analytic = @receiver_location.receiver_analytics.first
      @score = @scores[0].round(2)
      feature_6 = @feature_6s[@receiver_location.id]
      @stakeholder_rank = @vote_result[@receiver_location.id]

      @ops = Repeat.find_by_id(@receiver_location.repeat_id).display_timeslots

      ranges =Hash.new
      ranges["give"] = ["#{@feature_5_range[0]} week ago","3 months+"]
      ranges["feature_6"] = ["#{@feature_6_range[0]}"+" min","#{@feature_6_range[1]}"+" min"]
      ranges["item"] = ["very low(2)","normal(0)"]
      ranges["feature_5"] = ["#{@feature_5_rate_range[0]}%","#{@feature_5_rate_range[1]}%"]
      ranges["feature_4"] = ["$#{(@median_feature_4_range[0]*1.0/1000).round(1)}k","$#{(@median_feature_4_range[1]*1.0/1000).round(1)}k"]
      ranges["size"] = ["#{round_size(@size_range[0])}","#{round_size(@size_range[1])}"]

      ranges["score"] = [@full_score]
      @feature_ranges = ranges



      @detail_data = Hash.new

      feature_6_p = (feature_6-@feature_6_range[0])*1.0/(@feature_6_range[1]-@feature_6_range[0])
      @detail_data["feature_6"] = ["#{feature_6} min",feature_6_p.round(2)]

      item_v = @receiver_analytic.item_feature_3.round(2)
      item_realv = @receiver_analytic.item_feature_3
      item_p = (item_v-@item_feature_3_range[0])*1.0/(@item_feature_3_range[1]-@item_feature_3_range[0])
      @detail_data["item"] = [item_v,item_p.round(2)]

      feature_4_v = @receiver_analytic.median_feature_4
      feature_4_p = (feature_4_v-@median_feature_4_range[0])*1.0/(@median_feature_4_range[1]-@median_feature_4_range[0])
      @detail_data["feature_4"] = ["$#{feature_4_v.to_i}",feature_4_p.round(2)]


      feature_5_v = @receiver_analytic.feature_5_rate
      feature_5_p = (feature_5_v-@feature_5_rate_range[0])*1.0/(@feature_5_rate_range[1]-@feature_5_rate_range[0])
      @detail_data["feature_5"] = ["#{feature_5_v}%",feature_5_p.round(2)]

      size_v = @receiver_analytic.size
      size_p = (size_v-@size_range[0])*1.0/(@size_range[1]-@size_range[0])
      @detail_data["size"] = ["~ #{round_size(size_v)}",size_p.round(2)]

      if @receiver_analytic.feature_5_time.nil?
        feature_5_time = "three more"
        give_p = 0.50
        give_realp = Date.today.mjd - 3.months.ago.to_date.mjd
      else
        if @receiver_analytic.feature_5_time.to_date < 3.months.ago
          give_realp = Date.today.mjd - 3.months.ago.to_date.mjd
        else
          give_realp = Date.today.mjd - @receiver_analytic.feature_5_time.to_date.mjd
        end
        feature_5_time_num = (give_realp)/7.0
        give_p = ((feature_5_time_num*1.0-@feature_5_range[0])/(@feature_5_range[1]-@feature_5_range[0])).round(2)
        if give_p >1
          give_p = 1
        end
        if give_realp == (Date.today.mjd - 3.months.ago.to_date.mjd)
          feature_5_time = "three more"
          give_p = 0.50
        else
          feature_5_time = "#{feature_5_time_num.round} wks"
        end

      end

      @detail_data["give"] = [feature_5_time,give_p]
      @detail_data["feature_9"] = @receiver_location.get_feature_9s


      hindex = @feature_5_values.size/10
      @highlights = []

      if @sorted_feature_6s.index(feature_6) <= hindex
        @highlights.push("feature_6")
      end

      if @feature_5_values.index(give_realp) <= hindex
        @highlights.push("give")
      end

      if @median_feature_4_values.index(feature_4_v) <= hindex
        @highlights.push("feature_4")
      end

      if @feature_5_rate_values.index(feature_5_v) <= hindex
        @highlights.push("feature_5")
      end

      if @_feature_3_values.index(item_v) <= hindex
        @highlights.push("item")
      end

      @color_hash = {"R" => ["Partners","#e60000"],"F" => ["Operator","#ffad33"],"V" => ["Deliverers","#00b300"],"D" => ["Giver","#0073e6"]}
      params[:rank] = 1
    else
      @has_results = false
    end

    render layout:false
  end

  private

  def set_form_time_ranges
    day_of_week_today = @current_local_time.strftime("%A").downcase
    day_of_week_tomorrow = (@current_local_time + 1.day).strftime("%A").downcase

    hours_today = @organization.repeat.repeat_rules.select { |r|
      r.day.downcase == day_of_week_today
    }.first

    hours_tomorrow = @organization.repeat.repeat_rules.select { |r|
      r.day.downcase == day_of_week_tomorrow
    }.first

    @pickup_start_times_today, @pickup_end_times_today = get_time_ranges_for_day(hours_today)
    @pickup_start_times_tomorrow, @pickup_end_times_tomorrow = get_time_ranges_for_day(hours_tomorrow)

    @pickup_start_times_today_js = ""
    @pickup_start_times_today.each do |t|
      @pickup_start_times_today_js << "pickup_start.append('<option value=\"#{t[1]}\">#{t[0]}</option>');\n"
    end

    @pickup_end_times_today_js = ""
    @pickup_end_times_today.each do |t|
      @pickup_end_times_today_js << "pickup_end.append('<option value=\"#{t[1]}\">#{t[0]}</option>');\n"
    end

    @pickup_start_times_tomorrow_js = ""
    @pickup_start_times_tomorrow.each do |t|
      @pickup_start_times_tomorrow_js << "pickup_start.append('<option value=\"#{t[1]}\">#{t[0]}</option>');\n"
    end

    @pickup_end_times_tomorrow_js = ""
    @pickup_end_times_tomorrow.each do |t|
      @pickup_end_times_tomorrow_js << "pickup_end.append('<option value=\"#{t[1]}\">#{t[0]}</option>');\n"
    end

    if @give.pickup_day == "today"
      @pickup_start_times = @pickup_start_times_today
      @pickup_end_times = @pickup_end_times_today
    else
      @pickup_start_times = @pickup_start_times_tomorrow
      @pickup_end_times = @pickup_end_times_tomorrow
    end
  end

  def get_time_ranges_for_day(repeat_rule)
    return \
      if !repeat_rule

    start_hour = repeat_rule.start_seconds / 60 / 60
    end_hour = repeat_rule.end_seconds / 60 / 60

    pickup_start_times = []
    pickup_start_times << ["It is packaged and ready to go", "now"]

    for h in start_hour..end_hour
      display_time = Time.parse("#{h}:00").strftime("%l%P")
      pickup_start_times << ["From #{display_time}", h]
    end

    pickup_end_times = []
    start_hour += 2
    for h in start_hour..end_hour
      display_time = Time.parse("#{h}:00").strftime("%l%P")
      pickup_end_times << ["Before #{display_time}", h]
    end

    [pickup_start_times, pickup_end_times]
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_give
    @give = Give.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def give_params
    params.require(:give).permit(:giver_location_id, :pickup_start, :pickup_end, :people_served, :fits_in_car, :name, :giver_name,
                                     :email, :phone, :pickup_day, :other_info, :pickup_start_time, :pickup_end_time,
                                     :item1, :item1_unit, :item1_quantity, :item1_description,
                                     :item2, :item2_unit, :item2_quantity, :item2_description,
                                     :item3, :item3_unit, :item3_quantity, :item3_description,
                                     :item4, :item4_unit, :item4_quantity, :item4_description,
                                     :item5, :item5_unit, :item5_quantity, :item5_description,
                                     :item6, :item6_unit, :item6_quantity, :item6_description,
                                     :item7, :item7_unit, :item7_quantity, :item7_description,
                                     :item8, :item8_unit, :item8_quantity, :item8_description,
                                     :other, :other_unit, :other_quantity, :other_description,
                                     giver_location_attributes: [:name, address_attributes: [:line1, :city, :state, :zip]])
  end
end
