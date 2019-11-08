class CreatereceiverAnalytics < ActiveRecord::Migration
  def change
    create_table :receiver_analytics do |t|
      t.datetime :feature_5_time
      t.float :total_common_gives
	    t.float :total_uncommon_gives
      t.integer :receiver_location_id
      t.timestamps null: false
      t.integer :feature_2
      t.float :feature_5_rate
      t.float :median_feature_4
      t.float :item_feature_3
      t.float :test_common_gives, default: 0
	    t.float :test_uncommon_gives, default: 0
	    t.datetime :feature_5_time_test
    end

    create_table :beta_values do |t|
      t.integer  :feature_1
      t.decimal :feature_2
      t.decimal :feature_3
      t.decimal :feature_4
      t.decimal :feature_5
      t.decimal :feature_5
      t.decimal :feature_6
      t.decimal :feature_7
      t.decimal :feature_8
      t.decimal :feature_9
      t.timestamps null: false
      t.integer :stakeholder_id
    end
    create_table :feature_6s do |t|
      t.integer  :giver_location_id
      t.integer :receiver_location_id
      t.float :feature_6
      t.integer :duration
      t.timestamps null: false
    end
    change_table :receiver_locations do |t|
  		t.boolean :for_test,default: true
  	end

    create_table :decision_values do |t|
      t.integer :feature_1
      t.decimal :feature_2_0_50
      t.decimal :feature_2_50_100
      t.decimal :feature_2_100_500
      t.decimal :feature_2_500_1000
      t.decimal :feature_2_1000
      t.decimal :feature_3_extremelylow
      t.decimal :feature_3_low
      t.decimal :feature_3_normal
      t.decimal :feature_4_0_20k
      t.decimal :feature_4_20k_40k
      t.decimal :feature_4_40k_60k
      t.decimal :feature_4_60k_80k
      t.decimal :feature_4_80k_100k
      t.decimal :feature_4_100k
      t.decimal :feature_5_0_10
      t.decimal :feature_5_10_20
      t.decimal :feature_5_20_30
      t.decimal :feature_5_30_40
      t.decimal :feature_5_40_50
      t.decimal :feature_5_50_60
      t.decimal :feature_5_60
      t.decimal :feature_5_1
      t.decimal :feature_5_2
      t.decimal :feature_5_3
      t.decimal :feature_5_4
      t.decimal :feature_5_5
      t.decimal :feature_5_6
      t.decimal :feature_5_7
      t.decimal :feature_5_8
      t.decimal :feature_5_9
      t.decimal :feature_5_10
      t.decimal :feature_5_11
      t.decimal :feature_5_12
      t.decimal :feature_5_never
      t.decimal :feature_6_15
      t.decimal :feature_6_30
      t.decimal :feature_6_45
      t.decimal :feature_6_60
      t.decimal :feature_7_0
      t.decimal :feature_7_1
      t.decimal :feature_7_2
      t.decimal :feature_7_3
      t.decimal :feature_7_4
      t.decimal :feature_7_5
      t.decimal :feature_7_6
      t.decimal :feature_7_7
      t.decimal :feature_7_8
      t.decimal :feature_7_9
      t.decimal :feature_7_10
      t.decimal :feature_7_11
      t.decimal :feature_7_12
      t.decimal :feature_8_0
      t.decimal :feature_8_1
      t.decimal :feature_8_2
      t.decimal :feature_8_3
      t.decimal :feature_8_4
      t.decimal :feature_8_5
      t.decimal :feature_8_6
      t.decimal :feature_8_7
      t.decimal :feature_8_8
      t.decimal :feature_8_9
      t.decimal :feature_8_10
      t.decimal :feature_8_11
      t.decimal :feature_8_12
      t.integer :stakeholder_id
      t.timestamps null: false
    end

    create_table :stakeholders do |t|
      	t.string :stakeholder
      	t.string :name
      	t.integer :model_preference, default: 0
      	t.integer :type_preference, default: 0
      	t.timestamps null:false
    end


  end
end
