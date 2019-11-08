class ReceiverLocationsController < ApplicationController
  include RecommendationHelper
  before_action :authenticate_user!
  before_action :set_receiver, only: [:new, :show, :edit, :create, :update, :destroy, :sort_photos]
  before_action :set_receiver_location, only: [:show, :edit, :update, :destroy, :sort_photos,:get_info]
  before_action :set_repeat, only: [:show, :update, :edit, :destroy]

  def sort_photos
    authorize @receiver

    params[:photo].each_with_index do |id, index|
      Photo.where(id: id).update_all(position: index + 1)
    end
    head :ok
  end

  def edit
    authorize @receiver
  end

  # GET /receiver_locations/new
  def new
    authorize @receiver

    @receiver_location = receiverLocation.new
    @receiver_location.build_address
    # @contact_person = Contact.new
    # program.programs_availability_schemes.build(availability_scheme: as_dup)
    #@contact_person.contact_emails.build # (contact_person_email: ContactEmail.new)
    #@contact_person.contact_phones.build # (contact_person_email: ContactEmail.new)
  end

  # GET /receiver_locations/1/edit
  def show
    authorize @receiver

    # @contact_person = Contact.new
    @contacts = @receiver_location.contacts
    @photos = @receiver_location.photos
    @notes = @receiver_location.notes
    @photo_url = sort_photos_receiver_receiver_location_path(@receiver, @receiver_location)

    @traveling_to_receiver = SpecialInstruction.where(owner: @receiver_location, distribution_state: "traveling_to_receiver").first_or_initialize
    @arrived_at_receiver = SpecialInstruction.where(owner: @receiver_location, distribution_state: "arrived_at_receiver").first_or_initialize

    receiver_locations = receiverLocation.arel_table
    receiver_location_contacts = receiverLocationContact.arel_table
    contacts = Contact.arel_table
    contact_phones = ContactPhone.arel_table

    contact_phones_nodes =
        contact_phones
            .join(contacts)
            .on(contact_phones[:contact_id].eq contacts[:id])
            .join(receiver_location_contacts)
            .on(receiver_location_contacts[:contact_id].eq contacts[:id])
            .join(receiver_locations)
            .on(receiver_location_contacts[:receiver_location_id].eq receiver_locations[:id])
            .join_sources

    @contact_phones = ContactPhone
        .joins(contact_phones_nodes)
        .select(
            contacts[:first_name],
            contacts[:last_name],
            contact_phones[:number],
            contact_phones[:id]
        )
        .where(receiver_location_contacts[:receiver_location_id].eq @receiver_location.id)
        .order(
            contacts[:last_name],
            contacts[:first_name]
        )

  end

  # POST /receiver_locations
  # POST /receiver_locations.json
  def create
    authorize @receiver

    @receiver_location = receiverLocation.new(receiver_location_params)

    if !@receiver_location.valid?
      render action: :new
      return
    end

    respond_to do |format|
      if @receiver_location.save
        format.html {redirect_to receiver_receiver_location_url(@receiver, @receiver_location)}
        format.json {render :show, status: :created, location: @receiver_location}
      else
        format.html {render :new}
        format.json {render json: @receiver_location.errors, status: :unprocessable_entity}
      end
    end
  end

  # PATCH/PUT /receiver_locations/1
  # PATCH/PUT /receiver_locations/1.json
  def update
    authorize @receiver

    @receiver_location.update_attributes(receiver_location_params)

    if !@receiver_location.valid?
      render action: :edit
      return
    end

    @receiver_location.save!

    respond_to do |format|
      format.html {
        if params[:receiver_location][:repeat_attributes] && params[:receiver_location][:repeat_attributes][:_destroy] == ""
          redirect_to edit_receiver_receiver_location_path(@receiver, @receiver_location, anchor: "hours_of_operation")
        else
          redirect_to receiver_receiver_location_path(@receiver, @receiver_location), notice: "receiver location was updated successfully"
        end
      }
      format.json {head :no_content} # gracefully handle map pin drags
    end
  end

  # DELETE /receiver_locations/1
  # DELETE /receiver_locations/1.json
  def destroy
    authorize @receiver

    if Distribution.where(receiver_location: @receiver_location).any?
      notice = "receiver location could not be removed because it has existing distributions"
      redirect_to receiver_receiver_location_path(@receiver, @receiver_location), alert: notice
    else
      @receiver_location.destroy
      notice = "receiver location has been removed"
      redirect_to receiver_path(@receiver), notice: notice
    end
  end

  def get_info
    @tooltip_hash = {"item" => "item feature_3", "feature_6" => "feature_6","feature_4" => "feature_4 level", "feature_5" => "feature_5 rate","size" => "options size", "donation" => "last donation time"}
    @notes = Note.where("owner_type = 'receiverLocation' AND owner_id = ?",@receiver_location.id)
    @receiver = @receiver_location.receiver
    @receiver_analytic = @receiver_location.receiver_analytics.first
    @score = params[:score]
    @features = receiverAnalytic.get_feature_ranges(params[:fvalue])

    @ops = Repeat.find_by_id(@receiver_location.repeat_id).display_timeslots


    @receiver = @receiver_location.receiver
    @receiver_analytic = @receiver_location.receiver_analytics.first
    feature_6 = params[:feature_6].to_i

    @stakeholder_rank = params[:vote]
    @stakeholder_rank.each do |key,value|
      value_i = value.to_i
      @stakeholder_rank[key] = value_i

    end

    @sorted_feature_6s = params[:feature_6_range]
    @sorted_feature_6s.map!{|num| num.to_i}


    @last_donation_values = @features[0]
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
    @last_donation_range = [((@last_donation_values.last)/7.0).round,((@last_donation_values.first)/7.0).round]

    ranges =Hash.new
    ranges["donation"] = ["#{@last_donation_range[0]} week ago","3 months+"]
    ranges["feature_6"] = ["#{@feature_6_range[0]}"+" min","#{@feature_6_range[1]}"+" min"]
    ranges["item"] = ["very low(2)","normal(0)"]
    ranges["feature_5"] = ["#{@feature_5_rate_range[0]}%","#{@feature_5_rate_range[1]}%"]
    ranges["feature_4"] = ["$#{(@median_feature_4_range[0]*1.0/1000).round(1)}k","$#{(@median_feature_4_range[1]*1.0/1000).round(1)}k"]
    ranges["size"] = ["#{round_size(@size_range[0])}","#{round_size(@size_range[1])}"]

    ranges["score"] = [params[:fvalue].size]
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

    if @receiver_analytic.last_donation_time.nil?
      last_donation_time = "three more"
      donation_p = 0.50
      donation_realp = Date.today.mjd - 3.months.ago.to_date.mjd
    else
      if @receiver_analytic.last_donation_time.to_date < 3.months.ago
        donation_realp = Date.today.mjd - 3.months.ago.to_date.mjd
      else
        donation_realp = Date.today.mjd - @receiver_analytic.last_donation_time.to_date.mjd
      end
      last_donation_time_num = (donation_realp)/7.0
      donation_p = ((last_donation_time_num*1.0-@last_donation_range[0])/(@last_donation_range[1]-@last_donation_range[0])).round(2)
      if donation_p >1
        donation_p = 1
      end
      if donation_realp == Date.today.mjd - 3.months.ago.to_date.mjd
        last_donation_time = "three more"
        donation_p = 0.50
      else
        last_donation_time = "#{last_donation_time_num.round} wks"
      end

    end

    @detail_data["donation"] = [last_donation_time,donation_p]
    @detail_data["total_donation"] = @receiver_location.get_total_donations


    hindex = @last_donation_values.size/10
    @highlights = []

    if @sorted_feature_6s.index(feature_6) <= hindex
      @highlights.push("feature_6")
    end

    if @last_donation_values.index(donation_realp) <= hindex
      @highlights.push("donation")
    end

    if @median_feature_4_values.index(feature_4_v) <= hindex
      @highlights.push("feature_4")
    end

    if @feature_5_rate_values.index(feature_5_v) <= hindex
      @highlights.push("feature_5")
    end

    if @item_feature_3_values.index(item_v) <= hindex
      @highlights.push("item")
    end

    @color_hash = {"R" => ["Partners","#e60000"],"F" => ["Operator","#ffad33"],"V" => ["Deliverers","#00b300"],"D" => ["Donor","#0073e6"]}
    @labels =[["Prefer ready-to-eat","This receiver prefer ready-to-eat item","#FAE388"],["Scheduled give every Wed & Tr","Produce from GE.","#F6C8CD"]]

    render layout:false
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_receiver
    @receiver = receiver.find(params[:receiver_id])
  end

  def set_receiver_location
    @receiver_location = receiverLocation.find(params[:id])
    @owner = @receiver_location
  end

  def set_repeat
    @repeat = @receiver_location.repeat
    @repeats = @repeat ? @repeat.repeat_rules.repeat_type.chronological : nil
    @exceptions = @repeat ? @repeat.repeat_rules.exception_type.chronological : nil
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def receiver_location_params
    params.require(:receiver_location).permit(
        :name, :active, :receiver_id, :category, :phone, :people_served,
        address_attributes: [:id, :line1, :line2, :city, :state, :zip, :latitude, :longitude, :override_location, :override_neighborhood, :neighborhood],
        repeat_attributes: [
            :id, :start_date, :_destroy,
            repeat_rules_attributes: [
                :id, :rule_type, :month, :day_of_month, :day, :repetition, :start_hour, :start_minute, :end_hour,
                :end_minute, :start_seconds, :end_seconds, :repeat_id, :_destroy
            ]
        ],
        item_type_ids: []
    )
  end
end
